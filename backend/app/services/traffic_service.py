from datetime import date, datetime, time, timedelta

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.models.department import Department
from app.models.issue_attachment import IssueAttachment
from app.models.issue_status_history import IssueStatusHistory
from app.models.ai_analysis import AIAnalysis
from app.schemas.traffic import (
    TrafficHistoryOut,
    TrafficIssueDetailOut,
    TrafficIssueOut,
    TrafficListOut,
    TrafficLocationOut,
    TrafficPhotoOut,
    TrafficMapMarkerOut,
    TrafficMapOut,
)


def _location(loc: IssueLocation | None) -> TrafficLocationOut | None:
    if loc is None:
        return None
    return TrafficLocationOut(
        latitude=loc.latitude,
        longitude=loc.longitude,
        address=loc.address,
        city=loc.city,
    )


def _issue(issue: Issue, location: IssueLocation | None, department_name: str | None) -> TrafficIssueOut:
    return TrafficIssueOut(
        id=issue.id,
        title=issue.title,
        description=issue.description,
        category=issue.category,
        status=issue.status,
        priority=issue.priority,
        department_id=issue.department_id,
        department_name=department_name,
        location=_location(location),
        created_at=issue.created_at,
        updated_at=issue.updated_at,
    )


def list_traffic_issues(
    db: Session,
    *,
    search: str | None,
    status: str | None,
    priority: str | None,
    city: str | None,
    date_from: date | None,
    date_to: date | None,
    limit: int,
    offset: int,
) -> TrafficListOut:
    query = db.query(Issue).filter(Issue.category == "traffic", Issue.is_active.is_(True))
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(or_(Issue.title.ilike(term), Issue.description.ilike(term)))
    if status and status.strip():
        query = query.filter(func.lower(Issue.status) == status.strip().lower())
    if priority and priority.strip():
        query = query.filter(func.lower(Issue.priority) == priority.strip().lower())
    if city and city.strip():
        matching_locations = select(IssueLocation.issue_id).where(
            IssueLocation.city.ilike(f"%{city.strip()}%")
        )
        query = query.filter(Issue.id.in_(matching_locations))
    if date_from:
        query = query.filter(Issue.created_at >= datetime.combine(date_from, time.min))
    if date_to:
        if date_to == date.max:
            query = query.filter(Issue.created_at <= datetime.max)
        else:
            query = query.filter(Issue.created_at < datetime.combine(date_to + timedelta(days=1), time.min))

    total = query.count()
    issues = query.order_by(Issue.created_at.desc(), Issue.id.desc()).offset(offset).limit(limit).all()
    if not issues:
        return TrafficListOut(items=[], total=total, limit=limit, offset=offset)

    issue_ids = [issue.id for issue in issues]
    department_ids = {issue.department_id for issue in issues if issue.department_id is not None}
    department_names = {
        dept.id: dept.name
        for dept in db.query(Department).filter(Department.id.in_(department_ids)).all()
    } if department_ids else {}

    # Pick the latest location if multiple rows exist for a given issue.
    locations = {}
    for loc in db.query(IssueLocation).filter(IssueLocation.issue_id.in_(issue_ids)).order_by(IssueLocation.id.desc()).all():
        locations.setdefault(loc.issue_id, loc)

    return TrafficListOut(
        items=[_issue(issue, locations.get(issue.id), department_names.get(issue.department_id)) for issue in issues],
        total=total,
        limit=limit,
        offset=offset,
    )


def get_traffic_issue(db: Session, issue_id: int) -> TrafficIssueDetailOut | None:
    issue = db.query(Issue).filter(
        Issue.id == issue_id, Issue.category == "traffic", Issue.is_active.is_(True)
    ).first()
    if issue is None:
        return None

    location = db.query(IssueLocation).filter(IssueLocation.issue_id == issue_id).order_by(IssueLocation.id.desc()).first()
    department = db.get(Department, issue.department_id) if issue.department_id is not None else None
    base = _issue(issue, location, department.name if department else None)

    photos = db.query(IssueAttachment).filter(IssueAttachment.issue_id == issue_id).order_by(IssueAttachment.id).all()
    history = db.query(IssueStatusHistory).filter(IssueStatusHistory.issue_id == issue_id).order_by(
        IssueStatusHistory.created_at, IssueStatusHistory.id
    ).all()
    ai_analysis = db.query(AIAnalysis).filter(AIAnalysis.issue_id == issue_id).order_by(AIAnalysis.id.desc()).first()

    # Nearest related reports by category and city (or recent traffic reports if city is unknown).
    related_query = db.query(Issue).filter(
        Issue.category == "traffic", Issue.is_active.is_(True), Issue.id != issue_id
    )
    if location and location.city:
        related_query = related_query.filter(
            Issue.id.in_(select(IssueLocation.issue_id).where(
                func.lower(IssueLocation.city) == location.city.lower()
            ))
        )
    related = related_query.order_by(Issue.created_at.desc(), Issue.id.desc()).limit(3).all()
    related_ids = [r.id for r in related]
    related_locations = {}
    if related_ids:
        for loc in db.query(IssueLocation).filter(IssueLocation.issue_id.in_(related_ids)).order_by(IssueLocation.id.desc()).all():
            related_locations.setdefault(loc.issue_id, loc)

    return TrafficIssueDetailOut(
        **base.model_dump(),
        photos=[TrafficPhotoOut(id=p.id, file_name=p.file_name, file_url=p.file_url) for p in photos],
        status_history=[TrafficHistoryOut(
            previous_status=h.previous_status,
            new_status=h.new_status,
            note=h.note,
            created_at=h.created_at,
        ) for h in history],
        ai_summary=ai_analysis.explanation if ai_analysis else None,
        similar_issues=[_issue(r, related_locations.get(r.id), None) for r in related],
    )


def list_traffic_map_markers(db: Session, *, status: str | None = None, city: str | None = None, limit: int = 500) -> TrafficMapOut:
    """Latest valid coordinates of active traffic reports; persisted MySQL data only."""
    # One marker per issue, even when an issue has several location updates.
    latest = (
        db.query(func.max(IssueLocation.id).label("location_id"))
        .group_by(IssueLocation.issue_id)
        .subquery()
    )
    query = (
        db.query(Issue, IssueLocation)
        .join(IssueLocation, IssueLocation.issue_id == Issue.id)
        .join(latest, IssueLocation.id == latest.c.location_id)
        .filter(
            Issue.category == "traffic",
            Issue.is_active.is_(True),
            IssueLocation.latitude.between(-90, 90),
            IssueLocation.longitude.between(-180, 180),
        )
    )
    if status and status.strip():
        query = query.filter(func.lower(Issue.status) == status.strip().lower())
    if city and city.strip():
        query = query.filter(IssueLocation.city.ilike(f"%{city.strip()}%"))

    total = query.count()
    rows = query.order_by(Issue.created_at.desc(), Issue.id.desc()).limit(limit).all()
    return TrafficMapOut(
        total=total,
        limit=limit,
        items=[TrafficMapMarkerOut(
            id=issue.id,
            title=issue.title,
            status=issue.status,
            priority=issue.priority,
            location=_location(location),
        ) for issue, location in rows],
    )
