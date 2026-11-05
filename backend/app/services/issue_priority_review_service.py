from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.issue import Issue
from app.models.ai_analysis import AIAnalysis
from app.models.issue_priority_review import IssuePriorityReview


def review_issue_priority(
    db: Session,
    issue_id: int,
    final_priority: str,
    reviewed_by: int,
    review_note: str | None = None,
):
    allowed_priorities = {"high", "medium", "low"}

    if final_priority not in allowed_priorities:
        raise ValueError("Invalid priority value")

    issue = (
        db.query(Issue)
        .filter(
            Issue.id == issue_id,
            Issue.is_active.is_(True),
        )
        .first()
    )

    if issue is None:
        return None

    analysis = (
        db.query(AIAnalysis)
        .filter(AIAnalysis.issue_id == issue_id)
        .order_by(AIAnalysis.id.desc())
        .first()
    )

    if analysis is None:
        raise ValueError("AI analysis not found for this issue")

    analysis_result = analysis.result or {}
    ai_suggested_priority = str(
        analysis_result.get("priority", "")
    ).lower()

    if ai_suggested_priority not in allowed_priorities:
        raise ValueError("Invalid AI suggested priority")

    review = IssuePriorityReview(
        issue_id=issue.id,
        ai_suggested_priority=ai_suggested_priority,
        final_priority=final_priority,
        reviewed_by=reviewed_by,
        review_status="reviewed",
        review_note=review_note,
        reviewed_at=datetime.now(timezone.utc),
    )

    try:
        issue.priority = final_priority
        db.add(review)
        db.commit()
        db.refresh(review)
        return review

    except Exception:
        db.rollback()
        raise
