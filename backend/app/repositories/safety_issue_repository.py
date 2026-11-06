from datetime import datetime
from typing import Optional, Sequence

from sqlalchemy import and_, exists, func, or_, select
from sqlalchemy.orm import Session

from app.models.ai_analysis import AIAnalysis
from app.models.department import Department
from app.models.department_member import DepartmentMember
from app.models.issue import Issue
from app.models.issue_assignment import IssueAssignment
from app.models.issue_attachment import IssueAttachment
from app.models.issue_comment import IssueComment
from app.models.issue_location import IssueLocation
from app.models.issue_status_history import IssueStatusHistory
from app.models.safety_alert import SafetyAlert
from app.models.user import User

CLOSED_STATUSES = ("resolved", "rejected")


# ------------------------------ counts ------------------------------
def count_active_alerts(db: Session) -> int:
    stmt = select(func.count(SafetyAlert.id)).where(SafetyAlert.is_active.is_(True))
    return db.scalar(stmt) or 0


def count_open_issues(db: Session, category: str) -> int:
    stmt = select(func.count(Issue.id)).where(
        Issue.category == category,
        Issue.is_active.is_(True),
        Issue.status.notin_(CLOSED_STATUSES),
    )
    return db.scalar(stmt) or 0


def count_by_status(db: Session, category: str) -> dict[str, int]:
    stmt = (
        select(Issue.status, func.count(Issue.id))
        .where(Issue.category == category, Issue.is_active.is_(True))
        .group_by(Issue.status)
    )
    return {status: count for status, count in db.execute(stmt).all()}


def resolved_issue_times(db: Session, category: str) -> list[tuple[datetime, datetime]]:
    stmt = select(Issue.created_at, Issue.updated_at).where(
        Issue.category == category,
        Issue.is_active.is_(True),
        Issue.status == "resolved",
    )
    return [(c, u) for c, u in db.execute(stmt).all()]


# ------------------------------ list ------------------------------
def _filters(
    *,
    category: str,
    search: Optional[str],
    statuses: Optional[list[str]],
    priority: Optional[str],
    location: Optional[str],
    start: Optional[datetime],
    end: Optional[datetime],
    reference_id: Optional[int],
) -> list:
    conditions = [Issue.category == category, Issue.is_active.is_(True)]
    if search:
        like = f"%{search}%"
        match = [Issue.title.ilike(like), Issue.description.ilike(like)]
        if reference_id is not None:  # searching "SF-2217" matches id 2217
            match.append(Issue.id == reference_id)
        conditions.append(or_(*match))
    if statuses:
        conditions.append(Issue.status.in_(statuses))
    if priority:
        conditions.append(Issue.priority == priority)
    if location:
        like = f"%{location}%"
        conditions.append(
            exists().where(
                and_(
                    IssueLocation.issue_id == Issue.id,
                    or_(IssueLocation.city.ilike(like), IssueLocation.address.ilike(like)),
                )
            )
        )
    if start:
        conditions.append(Issue.created_at >= start)
    if end:
        conditions.append(Issue.created_at < end)
    return conditions


def list_issues(
    db: Session,
    *,
    category: str,
    search: Optional[str],
    statuses: Optional[list[str]],
    priority: Optional[str],
    location: Optional[str],
    start: Optional[datetime],
    end: Optional[datetime],
    reference_id: Optional[int],
    limit: int,
    offset: int,
) -> tuple[list[Issue], int]:
    conditions = _filters(
        category=category, search=search, statuses=statuses, priority=priority,
        location=location, start=start, end=end, reference_id=reference_id,
    )
    total = db.scalar(select(func.count(Issue.id)).where(*conditions)) or 0
    stmt = (
        select(Issue)
        .where(*conditions)
        .order_by(Issue.updated_at.desc(), Issue.id.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(db.scalars(stmt).all()), total


# ------------------------------ one issue ------------------------------
def get_issue(db: Session, issue_id: int) -> Optional[Issue]:
    return db.get(Issue, issue_id)


def get_locations(db: Session, issue_ids: Sequence[int]) -> dict[int, IssueLocation]:
    """First location of each issue."""
    if not issue_ids:
        return {}
    stmt = (
        select(IssueLocation)
        .where(IssueLocation.issue_id.in_(issue_ids))
        .order_by(IssueLocation.id.desc())  # later rows are overwritten, so the first one wins
    )
    return {loc.issue_id: loc for loc in db.scalars(stmt).all()}


def get_history(db: Session, issue_id: int) -> list[IssueStatusHistory]:
    stmt = (
        select(IssueStatusHistory)
        .where(IssueStatusHistory.issue_id == issue_id)
        .order_by(IssueStatusHistory.created_at.asc(), IssueStatusHistory.id.asc())
    )
    return list(db.scalars(stmt).all())


def get_attachments(db: Session, issue_id: int) -> list[IssueAttachment]:
    stmt = (
        select(IssueAttachment)
        .where(IssueAttachment.issue_id == issue_id)
        .order_by(IssueAttachment.id.asc())
    )
    return list(db.scalars(stmt).all())


def latest_ai_analysis(db: Session, issue_id: int) -> Optional[AIAnalysis]:
    stmt = (
        select(AIAnalysis)
        .where(AIAnalysis.issue_id == issue_id)
        .order_by(AIAnalysis.created_at.desc(), AIAnalysis.id.desc())
        .limit(1)
    )
    return db.scalars(stmt).first()


def latest_assignment(db: Session, issue_id: int) -> Optional[IssueAssignment]:
    stmt = (
        select(IssueAssignment)
        .where(IssueAssignment.issue_id == issue_id)
        .order_by(IssueAssignment.assigned_at.desc(), IssueAssignment.id.desc())
        .limit(1)
    )
    return db.scalars(stmt).first()


def related_candidates(db: Session, issue: Issue, limit: int = 50) -> list[Issue]:
    stmt = (
        select(Issue)
        .where(
            Issue.category == issue.category,
            Issue.is_active.is_(True),
            Issue.id != issue.id,
        )
        .order_by(Issue.updated_at.desc())
        .limit(limit)
    )
    return list(db.scalars(stmt).all())


# ------------------------------ people / departments ------------------------------
def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.get(User, user_id)


def get_users(db: Session, user_ids: Sequence[int]) -> dict[int, User]:
    if not user_ids:
        return {}
    stmt = select(User).where(User.id.in_(list(user_ids)))
    return {u.id: u for u in db.scalars(stmt).all()}


def list_departments(db: Session) -> list[Department]:
    stmt = select(Department).where(Department.is_active.is_(True)).order_by(Department.name)
    return list(db.scalars(stmt).all())


def get_department(db: Session, department_id: int) -> Optional[Department]:
    return db.get(Department, department_id)


def get_departments(db: Session, ids: Sequence[int]) -> dict[int, Department]:
    if not ids:
        return {}
    stmt = select(Department).where(Department.id.in_(list(ids)))
    return {d.id: d for d in db.scalars(stmt).all()}


def list_officers(db: Session, department_id: int) -> list[tuple[User, DepartmentMember]]:
    stmt = (
        select(User, DepartmentMember)
        .join(DepartmentMember, DepartmentMember.user_id == User.id)
        .where(
            DepartmentMember.department_id == department_id,
            DepartmentMember.is_active.is_(True),
            User.is_active.is_(True),
        )
        .order_by(User.full_name)
    )
    return [(u, m) for u, m in db.execute(stmt).all()]


def is_department_member(db: Session, department_id: int, user_id: int) -> bool:
    stmt = select(func.count(DepartmentMember.id)).where(
        DepartmentMember.department_id == department_id,
        DepartmentMember.user_id == user_id,
        DepartmentMember.is_active.is_(True),
    )
    return (db.scalar(stmt) or 0) > 0


# ------------------------------ writes (the service commits) ------------------------------
def add_history(
    db: Session, *, issue_id: int, changed_by: int,
    previous: Optional[str], new: str, note: Optional[str],
) -> IssueStatusHistory:
    row = IssueStatusHistory(
        issue_id=issue_id, changed_by=changed_by,
        previous_status=previous, new_status=new, note=note,
    )
    db.add(row)
    return row


def add_assignment(
    db: Session, *, issue_id: int, assigned_to: int, assigned_by: int,
    department_id: int, note: Optional[str],
) -> IssueAssignment:
    row = IssueAssignment(
        issue_id=issue_id, assigned_to=assigned_to, assigned_by=assigned_by,
        department_id=department_id, status="assigned", note=note,
    )
    db.add(row)
    return row


def add_comment(db: Session, *, issue_id: int, user_id: int, comment: str) -> IssueComment:
    row = IssueComment(issue_id=issue_id, user_id=user_id, comment=comment)
    db.add(row)
    return row


def list_comments(db: Session, issue_id: int) -> list[IssueComment]:
    stmt = (
        select(IssueComment)
        .where(IssueComment.issue_id == issue_id)
        .order_by(IssueComment.created_at.desc(), IssueComment.id.desc())
    )
    return list(db.scalars(stmt).all())
