from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.issue_priority_review import (
    PriorityReviewRequest,
    PriorityReviewResponse,
)
from app.services.issue_priority_review_service import review_issue_priority

router = APIRouter()


@router.post(
    "/{issue_id}/priority-review",
    response_model=PriorityReviewResponse,
)
def create_priority_review(
    issue_id: int,
    request: PriorityReviewRequest,
    reviewed_by: int,
    db: Session = Depends(get_db),
):
    try:
        result = review_issue_priority(
            db=db,
            issue_id=issue_id,
            final_priority=request.final_priority,
            reviewed_by=reviewed_by,
            review_note=request.review_note,
        )

        if result is None:
            raise HTTPException(
                status_code=404,
                detail="Issue not found",
            )

        return result

    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))
