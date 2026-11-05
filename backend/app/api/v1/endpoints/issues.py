
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import Issue, IssueLocation

router = APIRouter(tags=["Issues"])


@router.get("/issues/map")
def get_issue_map(
    category: str = Query(..., pattern="^(energy|water)$"),
    subcategory: str | None = Query(None),
    db: Session = Depends(get_db),
):
    query = (
        db.query(Issue, IssueLocation)
        .join(IssueLocation, IssueLocation.issue_id == Issue.id)
        .filter(
            Issue.category == category,
            Issue.is_active.is_(True),
        )
    )

    if subcategory:
        query = query.filter(Issue.subcategory == subcategory)

    rows = query.order_by(Issue.created_at.desc()).all()

    return {
        "total": len(rows),
        "items": [
            {
                "id": issue.id,
                "title": issue.title,
                "category": issue.category,
                "subcategory": issue.subcategory,
                "status": issue.status,
                "priority": issue.priority,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "address": location.address,
                "city": location.city,
            }
            for issue, location in rows
        ],
    }
