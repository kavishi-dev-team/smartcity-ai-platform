from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.waste import (
    WasteIssueListResponse,
    WasteIssueResponse,
)
from app.services.waste_service import (
    get_waste_issue,
    list_waste_issues,
)

router = APIRouter(prefix="/issues", tags=["Waste issues"])


@router.get("", response_model=WasteIssueListResponse)
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


@router.get("/{issue_id}", response_model=WasteIssueResponse)
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