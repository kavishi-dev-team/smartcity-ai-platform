
from datetime import date, timedelta

from sqlalchemy import func, extract
from sqlalchemy.orm import Session

from app.models import Issue, IssueLocation


def _get_statistics(
    db: Session,
    category: str,
    start_date: date | None = None,
    end_date: date | None = None,
    reported_by: int | None = None,
):
    query = db.query(Issue).filter(
        Issue.category == category,
        Issue.is_active.is_(True),
    )

    if reported_by is not None:
        query = query.filter(Issue.reported_by == reported_by)

    if start_date:
        query = query.filter(
            Issue.created_at >= start_date
        )

    # Include the complete end date
    if end_date:
        query = query.filter(
            Issue.created_at < end_date + timedelta(days=1)
        )

    total_reports = query.count()

    resolved_reports = query.filter(
        Issue.status == "resolved"
    ).count()

    category_rows = (
        query.with_entities(
            Issue.category,
            func.count(Issue.id),
        )
        .group_by(Issue.category)
        .all()
    )

    status_rows = (
        query.with_entities(
            Issue.status,
            func.count(Issue.id),
        )
        .group_by(Issue.status)
        .all()
    )

    monthly_rows = (
        query.with_entities(
            extract("year", Issue.created_at).label("year"),
            extract("month", Issue.created_at).label("month"),
            func.count(Issue.id).label("total"),
        )
        .group_by("year", "month")
        .order_by("year", "month")
        .all()
    )

    monthly_trends = []

    for year, month, total in monthly_rows:
        month_start = date(int(year), int(month), 1)

        month_query = query.filter(
            extract("year", Issue.created_at) == year,
            extract("month", Issue.created_at) == month,
        )

        resolved = month_query.filter(
            Issue.status == "resolved"
        ).count()

        monthly_trends.append({
            "month": month_start.strftime("%Y-%m"),
            "total_reports": total,
            "resolved_reports": resolved,
        })

    area_rows = (
        query.join(
            IssueLocation,
            IssueLocation.issue_id == Issue.id,
        )
        .with_entities(
            IssueLocation.city,
            func.count(Issue.id),
        )
        .group_by(IssueLocation.city)
        .all()
    )

    area_wise = []

    for city, total in area_rows:
        area_query = (
            query.join(
                IssueLocation,
                IssueLocation.issue_id == Issue.id,
            )
            .filter(IssueLocation.city == city)
        )

        resolved = area_query.filter(
            Issue.status == "resolved"
        ).count()

        area_wise.append({
            "area": city or "Unknown",
            "total_reports": total,
            "resolved_reports": resolved,
        })

    return {
        "total_reports": total_reports,
        "resolved_reports": resolved_reports,
        "category_breakdown": [
            {"name": name, "count": count}
            for name, count in category_rows
        ],
        "status_breakdown": [
            {"name": name, "count": count}
            for name, count in status_rows
        ],
        "monthly_trends": monthly_trends,
        "area_wise": area_wise,
    }


def get_energy_water_statistics(
    db: Session,
    start_date: date | None = None,
    end_date: date | None = None,
    reported_by: int | None = None,
):
    return {
        "energy": _get_statistics(
            db=db,
            category="energy",
            start_date=start_date,
            end_date=end_date,
            reported_by=reported_by,
        ),
        "water": _get_statistics(
            db=db,
            category="water",
            start_date=start_date,
            end_date=end_date,
            reported_by=reported_by,
        ),
    }
