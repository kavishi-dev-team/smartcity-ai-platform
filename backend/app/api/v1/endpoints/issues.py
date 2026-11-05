from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import Issue, IssueLocation
from app.schemas.waste import (
    WasteIssueListResponse,
    WasteIssueResponse,
)
from app.services.waste_service import (
    get_waste_issue,
    list_waste_issues,
)

router = APIRouter(prefix="/issues")


# NOTE: Must be declared BEFORE "/{issue_id}" so "map" is not parsed as an ID.
@router.get("/map", tags=["Issues"])
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


@router.get("", response_model=WasteIssueListResponse, tags=["Waste issues"])
def read_issues(
    category: Literal["waste"] = Query(default="waste"),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    # Currently implements the waste category only.
    return list_waste_issues(
        db,
        offset=offset,
        limit=limit,
    )


@router.get("/{issue_id}", response_model=WasteIssueResponse, tags=["Waste issues"])
def read_issue(
    issue_id: int = Path(gt=0),
    db: Session = Depends(get_db),
):
    issue = get_waste_issue(db, issue_id)

    if issue is None:
        raise HTTPException(
            status_code=404,
            detail="Waste issue not found",
        )

    return issue