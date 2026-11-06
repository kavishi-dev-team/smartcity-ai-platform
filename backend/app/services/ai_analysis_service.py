from sqlalchemy.orm import Session

from app.ai.classifier import classify_issue
from app.ai.priority_engine import calculate_priority
from app.ai.duplicate_detector import detect_duplicate
from app.ai.summarizer import summarize_issue

from app.models.issue import Issue
from app.models.ai_analysis import AIAnalysis


def analyze_issue(db: Session, issue_id: int) -> dict:
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

    classification = classify_issue(
        issue.title,
        issue.description,
    )

    priority = calculate_priority(
        issue.title,
        issue.description,
    )

    summary = summarize_issue(
        issue.title,
        issue.description,
    )

    existing_issues = (
        db.query(Issue)
        .filter(
            Issue.id != issue_id,
            Issue.is_active.is_(True),
        )
        .all()
    )

    duplicate_result = detect_duplicate(
        issue.title,
        issue.description,
        existing_issues,
    )

    result = {
        "issue_id": issue.id,
        "category": classification["category"],
        "category_confidence": classification["confidence"],
        "priority": priority["priority"],
        "matched_keywords": priority["matched_keywords"],
        "summary": summary["summary"],
        "is_duplicate": duplicate_result["is_duplicate"],
        "possible_duplicates": duplicate_result["duplicates"],
    }

    analysis_record = AIAnalysis(
        issue_id=issue.id,
        analysis_type="issue_analysis",
        result=result,
        explanation="Keyword-based classification, priority calculation, summarization and duplicate detection.",
        model_name="rule_based_v1",
        confidence_score=round(
            classification["confidence"] * 100
        ),
    )

    try:
        db.add(analysis_record)
        db.commit()
    except Exception:
        db.rollback()
        raise

    return result
