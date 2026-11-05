from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.issue import Issue
from app.models.ai_analysis import AIAnalysis
from app.models.issue_priority_review import IssuePriorityReview

def get_prioritized_issues(
    db: Session,
    priority: str | None = None,
    category: str | None = None,
    status: str | None = None,
):
    latest_analysis = (
        db.query(
            AIAnalysis.issue_id,
            func.max(AIAnalysis.id).label("latest_id"),
        )
        .group_by(AIAnalysis.issue_id)
        .subquery()
    )

    query = (
        db.query(Issue, AIAnalysis)
        .join(
            latest_analysis,
            Issue.id == latest_analysis.c.issue_id,
        )
        .join(
            AIAnalysis,
            AIAnalysis.id == latest_analysis.c.latest_id,
        )
        .filter(Issue.is_active.is_(True))
    )

    if category:
        query = query.filter(Issue.category.ilike(category))

    if status:
        query = query.filter(Issue.status.ilike(status))

    results = query.all()

    priority_order = {
        "high": 1,
        "medium": 2,
        "low": 3,
    }

    prioritized_issues = []

    for issue, analysis in results:
        analysis_result = analysis.result or {}
        ai_priority = analysis_result.get("priority", "low").lower()

        review = (
            db.query(IssuePriorityReview)
            .filter(IssuePriorityReview.issue_id == issue.id)
            .order_by(IssuePriorityReview.id.desc())
            .first()
        )
        
        final_priority = review.final_priority if review else issue.priority
        review_status = review.review_status if review else None

        if priority and ai_priority != priority.lower():
            continue

        prioritized_issues.append({
            "issue_id": issue.id,
            "title": issue.title,
            "description": issue.description,
            "category": issue.category,
            "status": issue.status,
            "ai_priority": ai_priority,
            "final_priority": final_priority,
            "review_status": review_status,
            "priority_explanation": analysis.explanation,
            "matched_keywords": analysis_result.get(
                "matched_keywords", []
            ),
            "analysis_id": analysis.id,
            "created_at": issue.created_at,
        })

    prioritized_issues.sort(
        key=lambda item: priority_order.get(
            item["ai_priority"], 4
        )
    )

    return prioritized_issues
