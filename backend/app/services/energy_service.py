
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Issue, IssueLocation
from app.models.issue_status_history import IssueStatusHistory
from app.models.user import User
from app.services.ai_analysis_service import analyze_issue


def list_energy_issues(
    db: Session,
    search: str | None = None,
    status: str | None = None,
    priority: str | None = None,
    subcategory: str | None = None,
    city: str | None = None,
    reported_by: int | None = None,
    skip: int = 0,
    limit: int = 100,
):
    query = db.query(Issue).filter(
        Issue.category == "energy",
        Issue.is_active.is_(True),
    )

    if reported_by is not None:
        query = query.filter(Issue.reported_by == reported_by)

    if search:
        query = query.filter(Issue.title.ilike(f"%{search}%"))

    if status:
        query = query.filter(Issue.status == status)

    if priority:
        query = query.filter(Issue.priority == priority)

    if subcategory:
        query = query.filter(Issue.subcategory == subcategory)

    if city:
        query = query.join(
            IssueLocation,
            IssueLocation.issue_id == Issue.id,
        ).filter(IssueLocation.city.ilike(f"%{city}%"))

    total = query.count()

    issues = (
        query.order_by(Issue.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    items = []

    for issue in issues:
        location = (
            db.query(IssueLocation)
            .filter(IssueLocation.issue_id == issue.id)
            .first()
        )

        items.append({
            "id": issue.id,
            "title": issue.title,
            "description": issue.description,
            "category": issue.category,
            "status": issue.status,
            "priority": issue.priority,
            "department_id": issue.department_id,
            "created_at": issue.created_at,
            "updated_at": issue.updated_at,
            "location": {
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address,
                "city": location.city,
            } if location else None,
        })

    return {
        "total": total,
        "items": items,
    }


def create_energy_issue(db: Session, data) -> dict:
    reporter_id = getattr(data, "reported_by", None)
    if not reporter_id:
        first_user = db.scalar(select(User).order_by(User.id).limit(1))
        reporter_id = first_user.id if first_user else 1

    issue = Issue(
        title=data.title.strip(),
        description=data.description.strip(),
        category="energy",
        status="reported",
        priority=(data.priority or "medium").lower(),
        reported_by=reporter_id,
        is_active=True,
    )
    db.add(issue)
    db.flush()

    location = IssueLocation(
        issue_id=issue.id,
        latitude=data.latitude,
        longitude=data.longitude,
        address=data.address,
        city=data.city,
    )
    db.add(location)

    db.add(
        IssueStatusHistory(
            issue_id=issue.id,
            previous_status=None,
            new_status="reported",
            changed_by=reporter_id,
            note="Energy issue reported by citizen.",
        )
    )
    db.commit()
    db.refresh(issue)

    try:
        analyze_issue(db, issue.id)
    except Exception:
        pass

    return {
        "id": issue.id,
        "title": issue.title,
        "description": issue.description,
        "category": issue.category,
        "status": issue.status,
        "priority": issue.priority,
        "department_id": issue.department_id,
        "created_at": issue.created_at,
        "updated_at": issue.updated_at,
        "location": {
            "latitude": location.latitude,
            "longitude": location.longitude,
            "address": location.address,
            "city": location.city,
        },
    }

