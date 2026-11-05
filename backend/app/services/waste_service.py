from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.schemas.waste import (
    WasteIssueListResponse,
    WasteIssueResponse,
    WasteLocationResponse,
)


def _build_response(
    issue: Issue,
    locations: list[IssueLocation],
) -> WasteIssueResponse:
    return WasteIssueResponse(
        id=issue.id,
        title=issue.title,
        description=issue.description,
        category=issue.category,
        status=issue.status,
        priority=issue.priority,
        created_at=issue.created_at,
        updated_at=issue.updated_at,
        locations=[
            WasteLocationResponse.model_validate(location)
            for location in locations
        ],
    )


def list_waste_issues(
    db: Session,
    *,
    offset: int = 0,
    limit: int = 20,
) -> WasteIssueListResponse:
    conditions = (
        Issue.category == "waste",
        Issue.is_active.is_(True),
    )

    total = db.scalar(
        select(func.count())
        .select_from(Issue)
        .where(*conditions)
    ) or 0

    issues = db.scalars(
        select(Issue)
        .where(*conditions)
        .order_by(Issue.created_at.desc(), Issue.id.desc())
        .offset(offset)
        .limit(limit)
    ).all()

    locations_by_issue: dict[int, list[IssueLocation]] = {}

    if issues:
        issue_ids = [issue.id for issue in issues]

        locations = db.scalars(
            select(IssueLocation)
            .where(IssueLocation.issue_id.in_(issue_ids))
            .order_by(IssueLocation.id)
        ).all()

        for location in locations:
            locations_by_issue.setdefault(
                location.issue_id, []
            ).append(location)

    return WasteIssueListResponse(
        items=[
            _build_response(
                issue,
                locations_by_issue.get(issue.id, []),
            )
            for issue in issues
        ],
        total=total,
        offset=offset,
        limit=limit,
    )


def get_waste_issue(
    db: Session,
    issue_id: int,
) -> WasteIssueResponse | None:
    issue = db.scalar(
        select(Issue).where(
            Issue.id == issue_id,
            Issue.category == "waste",
            Issue.is_active.is_(True),
        )
    )

    if issue is None:
        return None

    locations = db.scalars(
        select(IssueLocation)
        .where(IssueLocation.issue_id == issue.id)
        .order_by(IssueLocation.id)
    ).all()

    return _build_response(issue, list(locations))