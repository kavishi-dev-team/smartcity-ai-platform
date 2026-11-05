from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.prioritized_issue import PrioritizedIssueResponse
from app.services.priority_issues_service import get_prioritized_issues

router = APIRouter()


@router.get(
    "/prioritized",
    response_model=list[PrioritizedIssueResponse],
)
def prioritized_issues(
    priority: Optional[str] = Query(default=None),
    category: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
):
    return get_prioritized_issues(
        db=db,
        priority=priority,
        category=category,
        status=status,
    )
