from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from app.models.issue import Issue
from app.models.department import Department


def get_analytics_overview(db: Session):
    query = db.query(Issue).filter(Issue.is_active.is_(True))

    return {
        "total_issues": query.count(),
        "pending_issues": query.filter(
            func.lower(Issue.status) == "reported"
        ).count(),
        "in_progress_issues": query.filter(
            func.lower(Issue.status) == "in_progress"
        ).count(),
        "resolved_issues": query.filter(
            func.lower(Issue.status) == "resolved"
        ).count(),
        "high_priority_issues": query.filter(
            func.lower(Issue.priority) == "high"
        ).count(),
    }


def get_issue_analytics(db: Session):
    query = db.query(Issue).filter(Issue.is_active.is_(True))

    categories = (
        query.with_entities(
            Issue.category,
            func.count(Issue.id).label("issue_count"),
        )
        .group_by(Issue.category)
        .all()
    )

    statuses = (
        query.with_entities(
            Issue.status,
            func.count(Issue.id).label("issue_count"),
        )
        .group_by(Issue.status)
        .all()
    )

    monthly = (
        query.with_entities(
            extract("year", Issue.created_at).label("year"),
            extract("month", Issue.created_at).label("month"),
            func.count(Issue.id).label("issue_count"),
        )
        .group_by(
            extract("year", Issue.created_at),
            extract("month", Issue.created_at),
        )
        .order_by(
            extract("year", Issue.created_at),
            extract("month", Issue.created_at),
        )
        .all()
    )

    return {
        "categories": [
            {
                "category": category or "Uncategorized",
                "issue_count": count,
            }
            for category, count in categories
        ],
        "statuses": [
            {
                "status": status,
                "issue_count": count,
            }
            for status, count in statuses
        ],
        "monthly": [
            {
                "month": f"{int(year)}-{int(month):02d}",
                "issue_count": count,
            }
            for year, month, count in monthly
        ],
    }


def get_department_analytics(db: Session):
    departments = (
        db.query(Department)
        .order_by(Department.id)
        .all()
    )

    results = []

    for department in departments:
        issues = db.query(Issue).filter(
            Issue.department_id == department.id,
            Issue.is_active.is_(True),
        )

        results.append({
            "department_id": department.id,
            "department_name": department.name,
            "total_issues": issues.count(),
            "pending_issues": issues.filter(
                func.lower(Issue.status) == "reported"
            ).count(),
            "resolved_issues": issues.filter(
                func.lower(Issue.status) == "resolved"
            ).count(),
        })

    return {"departments": results}
