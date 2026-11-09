
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Issue, IssueLocation
from app.models.issue_status_history import IssueStatusHistory
from app.models.user import User
from app.services.ai_analysis_service import analyze_issue


def _to_out(issue: Issue, location: Optional[IssueLocation]) -> dict:
    return {
        "id": issue.id,
        "title": issue.title,
        "description": issue.description,
        "category": issue.category,
        "subcategory": issue.subcategory,
        "status": issue.status,
        "priority": issue.priority,
        "department_id": issue.department_id,
        "created_at": issue.created_at,
        "updated_at": issue.updated_at,
        "location": (
            {
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address,
                "city": location.city,
            }
            if location
            else None
        ),
    }


def list_water_issues(
    db: Session,
    search: Optional[str] = None,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    subcategory: Optional[str] = None,
    reported_by: Optional[int] = None,
    skip: int = 0,
    limit: int = 50,
) -> dict:
    query = db.query(Issue).filter(
        Issue.category == "water", Issue.is_active.is_(True)
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

    total = query.count()
    issues = (
        query.order_by(Issue.created_at.desc()).offset(skip).limit(limit).all()
    )

    items = []
    for issue in issues:
        location = (
            db.query(IssueLocation)
            .filter(IssueLocation.issue_id == issue.id)
            .first()
        )
        items.append(_to_out(issue, location))
    return {"total": total, "items": items}


def get_water_issue(db: Session, issue_id: int) -> Optional[dict]:
    issue = (
        db.query(Issue)
        .filter(
            Issue.id == issue_id,
            Issue.category == "water",
            Issue.is_active.is_(True),
        )
        .first()
    )
    if issue is None:
        return None
    location = (
        db.query(IssueLocation).filter(IssueLocation.issue_id == issue.id).first()
    )
    return _to_out(issue, location)

def create_water_issue(db: Session, data) -> dict:
    reporter_id = getattr(data, "reported_by", None)
    if not reporter_id:
        first_user = db.scalar(select(User).order_by(User.id).limit(1))
        reporter_id = first_user.id if first_user else 1

    issue = Issue(
        title=data.title.strip(),
        description=data.description.strip(),
        category="water",
        subcategory=data.subcategory,
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
            note="Water issue reported by citizen.",
        )
    )
    db.commit()
    db.refresh(issue)

    try:
        analyze_issue(db, issue.id)
    except Exception:
        pass

    return _to_out(issue, location)
