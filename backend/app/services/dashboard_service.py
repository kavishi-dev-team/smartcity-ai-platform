from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.issue import Issue


def get_citizen_dashboard(db: Session, user_id: int):
    reports = (
        db.query(Issue)
        .filter(
            Issue.reported_by == user_id,
            Issue.is_active.is_(True),
        )
        .order_by(Issue.created_at.desc())
        .all()
    )

    total_reports = len(reports)
    resolved_reports = sum(
        1 for issue in reports
        if issue.status.lower() == "resolved"
    )

    return {
        "total_reports": total_reports,
        "active_reports": total_reports - resolved_reports,
        "resolved_reports": resolved_reports,
        "recent_reports": reports[:5],
    }


def get_officer_dashboard(db: Session):
    active_issues = db.query(Issue).filter(
        Issue.is_active.is_(True)
    )

    total = active_issues.count()

    pending = active_issues.filter(
        func.lower(Issue.status) == "reported"
    ).count()

    high_priority = active_issues.filter(
        func.lower(Issue.priority) == "high"
    ).count()

    in_progress = active_issues.filter(
        func.lower(Issue.status) == "in_progress"
    ).count()

    resolved = active_issues.filter(
        func.lower(Issue.status) == "resolved"
    ).count()

    recent_issues = (
        active_issues
        .order_by(Issue.created_at.desc())
        .limit(5)
        .all()
    )

    return {
        "statistics": {
            "total": total,
            "pending": pending,
            "high_priority": high_priority,
            "in_progress": in_progress,
            "resolved": resolved,
        },
        "recent_issues": recent_issues,
    }
