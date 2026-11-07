
from sqlalchemy.orm import Session

from app.models import Issue, IssueLocation


def list_energy_issues(
    db: Session,
    search: str | None = None,
    status: str | None = None,
    priority: str | None = None,
    subcategory: str | None = None,
    city: str | None = None,
    skip: int = 0,
    limit: int = 100,
):
    query = db.query(Issue).filter(
        Issue.category == "energy",
        Issue.is_active.is_(True),
    )

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
