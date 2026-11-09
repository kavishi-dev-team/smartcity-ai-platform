import math
import re
from datetime import date, datetime, time, timedelta, timezone
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.issue import Issue
from app.models.user import User
from app.repositories import safety_issue_repository as repo
from app.schemas.safety import (
    AIAnalysisOut,
    AssignmentIn,
    AssignmentOut,
    DepartmentOut,
    IssueCountsOut,
    LocationOut,
    NoteOut,
    OfficerOut,
    AttachmentOut,
    SafetyIssueDetailOut,
    SafetyIssueListOut,
    SafetyIssueOut,
    SafetySummaryOut,
    StatusHistoryOut,
    StatusUpdateIn,
)

SLA_HOURS = 72
PREFIX = {"safety": "SF", "complaint": "CP"}
VALID_STATUSES = ("reported", "under_review", "assigned", "in_progress", "resolved", "rejected")
_REFERENCE = re.compile(r"^\s*(?:SF|CP)-?(\d+)\s*$", re.IGNORECASE)
_WORD = re.compile(r"[a-z]{4,}")


class NotFoundError(Exception):
    """The report does not exist (or is not a safety report / complaint)."""


class InvalidRequestError(Exception):
    """The request is understood but cannot be done (message is safe to show)."""


def make_reference(category: str, issue_id: int) -> str:
    return f"{PREFIX.get(category, 'IS')}-{issue_id}"


def _naive(dt: datetime) -> datetime:
    if dt.tzinfo:
        return dt.astimezone(timezone.utc).replace(tzinfo=None)
    return dt


def parse_statuses(value: Optional[str]) -> Optional[list[str]]:
    """'in_progress,assigned' -> ['in_progress', 'assigned'] (validated)."""
    if not value:
        return None
    parts = [p.strip() for p in value.split(",") if p.strip()]
    for p in parts:
        if p not in VALID_STATUSES:
            raise InvalidRequestError(f"Unknown status '{p}'")
    return parts or None


# ------------------------------ summary + counts ------------------------------
def get_summary(db: Session, reported_by: Optional[int] = None) -> SafetySummaryOut:
    resolved = repo.resolved_issue_times(db, "safety", reported_by=reported_by)
    within = sum(
        1 for created, updated in resolved
        if _naive(updated) - _naive(created) <= timedelta(hours=SLA_HOURS)
    )
    percent = round(within * 100 / len(resolved)) if resolved else None
    return SafetySummaryOut(
        active_alerts=repo.count_active_alerts(db),
        open_reports=repo.count_open_issues(db, "safety", reported_by=reported_by),
        resolved_total=len(resolved),
        resolved_in_sla_percent=percent,
        sla_hours=SLA_HOURS,
        updated_at=datetime.now(timezone.utc),
    )


def get_counts(db: Session, category: str, reported_by: Optional[int] = None) -> IssueCountsOut:
    by_status = repo.count_by_status(db, category, reported_by=reported_by)
    values = {s: by_status.get(s, 0) for s in VALID_STATUSES}
    return IssueCountsOut(total=sum(by_status.values()), **values)


# ------------------------------ list ------------------------------
def _to_out(issue, location) -> SafetyIssueOut:
    return SafetyIssueOut(
        id=issue.id,
        reference=make_reference(issue.category, issue.id),
        title=issue.title,
        description=issue.description,
        category=issue.category,
        status=issue.status,
        priority=issue.priority,
        address=location.address if location else None,
        city=location.city if location else None,
        created_at=issue.created_at,
        updated_at=issue.updated_at,
    )


def list_issues(
    db: Session,
    *,
    category: str = "safety",
    reported_by: Optional[int] = None,
    search: Optional[str] = None,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    location: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    page: int = 1,
    page_size: int = 10,
) -> SafetyIssueListOut:
    statuses = parse_statuses(status)
    search = search.strip() if search else None
    reference_id = None
    if search:
        m = _REFERENCE.match(search)
        if m:
            reference_id = int(m.group(1))

    start = datetime.combine(date_from, time.min) if date_from else None
    # date_to is inclusive: include everything up to the end of that day
    end = datetime.combine(date_to + timedelta(days=1), time.min) if date_to else None

    issues, total = repo.list_issues(
        db, category=category, reported_by=reported_by, search=search or None, statuses=statuses,
        priority=priority, location=location.strip() if location else None,
        start=start, end=end, reference_id=reference_id,
        limit=page_size, offset=(page - 1) * page_size,
    )
    locations = repo.get_locations(db, [i.id for i in issues])
    return SafetyIssueListOut(
        items=[_to_out(i, locations.get(i.id)) for i in issues],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=max(1, math.ceil(total / page_size)),
    )


# ------------------------------ detail ------------------------------
def _find_issue(db: Session, issue_id: int) -> Issue:
    issue = repo.get_issue(db, issue_id)
    if issue is None or not issue.is_active or issue.category not in PREFIX:
        raise NotFoundError("Report not found")
    return issue


def _recommended_priority(result) -> Optional[str]:
    if isinstance(result, dict):
        for key in ("recommended_priority", "priority", "suggested_priority"):
            value = result.get(key)
            if isinstance(value, str) and value:
                return value
    return None


def _related(db: Session, issue: Issue, location, limit: int = 5) -> list[SafetyIssueOut]:
    """Other reports of the same kind: same city scores higher, shared title words add more."""
    candidates = repo.related_candidates(db, issue)
    locations = repo.get_locations(db, [issue.id] + [c.id for c in candidates])
    my_city = (locations.get(issue.id).city if locations.get(issue.id) else None)
    my_words = set(_WORD.findall(issue.title.lower()))

    scored = []
    for c in candidates:
        loc = locations.get(c.id)
        score = 0
        if my_city and loc and loc.city and loc.city.lower() == my_city.lower():
            score += 2
        score += len(my_words & set(_WORD.findall(c.title.lower())))
        if score > 0:
            scored.append((score, c, loc))
    scored.sort(key=lambda t: (t[0], t[1].updated_at), reverse=True)
    return [_to_out(c, loc) for _, c, loc in scored[:limit]]


def _assignment_out(db: Session, issue: Issue) -> Optional[AssignmentOut]:
    a = repo.latest_assignment(db, issue.id)
    if a is None:
        return None
    users = repo.get_users(db, [a.assigned_to, a.assigned_by])
    dept = repo.get_department(db, a.department_id)
    return AssignmentOut(
        department_id=a.department_id,
        department_name=dept.name if dept else None,
        assigned_to=a.assigned_to,
        assigned_to_name=users[a.assigned_to].full_name if a.assigned_to in users else None,
        assigned_by_name=users[a.assigned_by].full_name if a.assigned_by in users else None,
        status=a.status,
        note=a.note,
        assigned_at=a.assigned_at,
    )


def get_issue_detail(db: Session, issue_id: int) -> SafetyIssueDetailOut:
    issue = _find_issue(db, issue_id)
    location = repo.get_locations(db, [issue.id]).get(issue.id)
    base = _to_out(issue, location)

    dept = repo.get_department(db, issue.department_id) if issue.department_id else None
    analysis = repo.latest_ai_analysis(db, issue.id)

    return SafetyIssueDetailOut(
        **base.model_dump(),
        location=LocationOut.model_validate(location) if location else None,
        history=[StatusHistoryOut.model_validate(h) for h in repo.get_history(db, issue.id)],
        department=DepartmentOut.model_validate(dept) if dept else None,
        assignment=_assignment_out(db, issue),
        attachments=[AttachmentOut.model_validate(a) for a in repo.get_attachments(db, issue.id)],
        ai_analysis=AIAnalysisOut(
            analysis_type=analysis.analysis_type,
            recommended_priority=_recommended_priority(analysis.result),
            result=analysis.result,
            explanation=analysis.explanation,
            confidence_score=analysis.confidence_score,
            model_name=analysis.model_name,
            created_at=analysis.created_at,
        ) if analysis else None,
        related=_related(db, issue, location),
    )


# ------------------------------ officer lookups ------------------------------
def list_departments(db: Session) -> list[DepartmentOut]:
    return [DepartmentOut.model_validate(d) for d in repo.list_departments(db)]


def list_officers(db: Session, department_id: int) -> list[OfficerOut]:
    if repo.get_department(db, department_id) is None:
        raise NotFoundError("Department not found")
    return [
        OfficerOut(id=u.id, full_name=u.full_name, position=m.position)
        for u, m in repo.list_officers(db, department_id)
    ]


def list_notes(db: Session, issue_id: int) -> list[NoteOut]:
    _find_issue(db, issue_id)
    comments = repo.list_comments(db, issue_id)
    users = repo.get_users(db, list({c.user_id for c in comments}))
    return [
        NoteOut(
            id=c.id,
            author_name=users[c.user_id].full_name if c.user_id in users else None,
            note=c.comment,
            created_at=c.created_at,
        )
        for c in comments
    ]


# ------------------------------ officer actions ------------------------------
def _clean(text: Optional[str]) -> Optional[str]:
    text = text.strip() if text else None
    return text or None


def update_status(db: Session, issue_id: int, actor: User, data: StatusUpdateIn) -> SafetyIssueDetailOut:
    issue = _find_issue(db, issue_id)
    if data.status == issue.status:
        raise InvalidRequestError(f"The report is already '{issue.status}'")
    repo.add_history(
        db, issue_id=issue.id, changed_by=actor.id,
        previous=issue.status, new=data.status, note=_clean(data.note),
    )
    issue.status = data.status
    issue.updated_at = func.now()
    db.commit()
    return get_issue_detail(db, issue_id)


def add_public_update(db: Session, issue_id: int, actor: User, note: str) -> SafetyIssueDetailOut:
    """A message the citizen can see in the timeline. The status stays the same."""
    issue = _find_issue(db, issue_id)
    repo.add_history(
        db, issue_id=issue.id, changed_by=actor.id,
        previous=issue.status, new=issue.status, note=_clean(note),
    )
    issue.updated_at = func.now()
    db.commit()
    return get_issue_detail(db, issue_id)


def add_internal_note(db: Session, issue_id: int, actor: User, note: str) -> NoteOut:
    """Staff-only. Never returned by the citizen detail endpoint."""
    issue = _find_issue(db, issue_id)
    row = repo.add_comment(db, issue_id=issue.id, user_id=actor.id, comment=_clean(note) or note)
    db.commit()
    db.refresh(row)
    return NoteOut(id=row.id, author_name=actor.full_name, note=row.comment, created_at=row.created_at)


def assign(db: Session, issue_id: int, actor: User, data: AssignmentIn) -> SafetyIssueDetailOut:
    issue = _find_issue(db, issue_id)
    dept = repo.get_department(db, data.department_id)
    if dept is None or not dept.is_active:
        raise InvalidRequestError("That department does not exist")

    issue.department_id = dept.id

    if data.assigned_to is not None:
        officer = repo.get_user(db, data.assigned_to)
        if officer is None or not repo.is_department_member(db, dept.id, officer.id):
            raise InvalidRequestError("That officer is not an active member of this department")
        repo.add_assignment(
            db, issue_id=issue.id, assigned_to=officer.id, assigned_by=actor.id,
            department_id=dept.id, note=_clean(data.note),
        )
        # Handing a report to an officer moves it forward automatically
        if issue.status in ("reported", "under_review"):
            repo.add_history(
                db, issue_id=issue.id, changed_by=actor.id,
                previous=issue.status, new="assigned",
                note=f"Assigned to {officer.full_name} ({dept.name}).",
            )
            issue.status = "assigned"

    issue.updated_at = func.now()
    db.commit()
    return get_issue_detail(db, issue_id)
