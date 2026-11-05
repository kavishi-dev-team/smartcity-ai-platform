
from typing import Optional

from sqlalchemy.orm import Session

from app.models import Issue, IssueLocation


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
    skip: int = 0,
    limit: int = 50,
) -> dict:
    query = db.query(Issue).filter(
        Issue.category == "water", Issue.is_active.is_(True)
    )
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
    issue = Issue(
    title=data.title,
    description=data.description,
    category="water",
    subcategory=data.subcategory,
    status="reported",
    priority=data.priority,
    reported_by=1,
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
    db.commit()
    db.refresh(issue)

    return _to_out(issue, location)
