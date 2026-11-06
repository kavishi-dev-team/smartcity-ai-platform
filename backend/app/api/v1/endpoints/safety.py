import logging
from datetime import date
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User
from app.schemas.safety import (
    AssignmentIn,
    DepartmentOut,
    InternalNoteIn,
    IssueCountsOut,
    NoteOut,
    OfficerOut,
    PublicUpdateIn,
    SafetyIssueDetailOut,
    SafetyIssueListOut,
    SafetySummaryOut,
    StatusUpdateIn,
)
from app.services import safety_service as service

router = APIRouter(prefix="/safety", tags=["Safety Problems & Complaints"])
logger = logging.getLogger(__name__)

# NOTE: these live under /safety instead of the shared GET /issues route, because several
# modules want to own /issues?category=... and only one handler can serve that path.

PRIORITY_PATTERN = "^(low|medium|high|critical)$"


# ---------------------------------------------------------------------------
# Officer-only access.
# Once Member 1's auth is merged (app.core.permissions exists), staff roles are enforced
# automatically. Until then this runs in DEV MODE: no login check, and the first user in
# the database is recorded as the actor. Never deploy in dev mode.
# ---------------------------------------------------------------------------
def _build_officer_dependency():
    try:
        from app.core.permissions import Role, require_roles

        logger.info("Safety: officer endpoints are protected by role checks.")
        return require_roles(Role.SUPER_ADMIN, Role.CITY_MANAGER, Role.DEPARTMENT_OFFICER)
    except ImportError:
        logger.warning("Safety: auth not available yet - officer endpoints are in DEV MODE (open).")

        def dev_officer(db: Session = Depends(get_db)) -> User:
            user = db.scalar(select(User).order_by(User.id).limit(1))
            if user is None:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="No users exist yet. Run a seed script first.",
                )
            return user

        return dev_officer


require_officer = _build_officer_dependency()


def _handle(error: Exception) -> HTTPException:
    if isinstance(error, service.NotFoundError):
        return HTTPException(status_code=404, detail=str(error))
    return HTTPException(status_code=422, detail=str(error))


# ---------------------------------------------------------------------------
# Public (citizen) endpoints
# ---------------------------------------------------------------------------
@router.get("/summary", response_model=SafetySummaryOut)
def get_safety_summary(db: Session = Depends(get_db)):
    """Numbers for the three stat cards at the top of the Safety screen."""
    return service.get_summary(db)


@router.get("/issues", response_model=SafetyIssueListOut)
def list_safety_issues(
    category: Literal["safety", "complaint"] = "safety",
    search: Optional[str] = Query(default=None, max_length=100),
    status: Optional[str] = Query(
        default=None,
        max_length=100,
        description="One status, or several separated by commas, e.g. 'assigned,in_progress'",
    ),
    priority: Optional[str] = Query(default=None, pattern=PRIORITY_PATTERN),
    location: Optional[str] = Query(default=None, max_length=100),
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    try:
        return service.list_issues(
            db, category=category, search=search, status=status, priority=priority,
            location=location, date_from=date_from, date_to=date_to,
            page=page, page_size=page_size,
        )
    except service.InvalidRequestError as e:
        raise _handle(e)


# NOTE: declared before /issues/{issue_id} so "counts" is not read as an id.
@router.get("/issues/counts", response_model=IssueCountsOut)
def get_issue_counts(
    category: Literal["safety", "complaint"] = "complaint",
    db: Session = Depends(get_db),
):
    """Report counts per status, for the complaint history tabs."""
    return service.get_counts(db, category)


@router.get("/issues/{issue_id}", response_model=SafetyIssueDetailOut)
def get_safety_issue(issue_id: int, db: Session = Depends(get_db)):
    try:
        return service.get_issue_detail(db, issue_id)
    except service.NotFoundError as e:
        raise _handle(e)


# ---------------------------------------------------------------------------
# Officer-only endpoints
# ---------------------------------------------------------------------------
@router.get("/departments", response_model=list[DepartmentOut])
def list_departments(
    _officer: User = Depends(require_officer), db: Session = Depends(get_db)
):
    return service.list_departments(db)


@router.get("/departments/{department_id}/officers", response_model=list[OfficerOut])
def list_department_officers(
    department_id: int,
    _officer: User = Depends(require_officer),
    db: Session = Depends(get_db),
):
    try:
        return service.list_officers(db, department_id)
    except service.NotFoundError as e:
        raise _handle(e)


@router.post("/issues/{issue_id}/assignments", response_model=SafetyIssueDetailOut)
def assign_issue(
    issue_id: int,
    data: AssignmentIn,
    officer: User = Depends(require_officer),
    db: Session = Depends(get_db),
):
    """Set the responsible department and (optionally) hand the report to one of its officers."""
    try:
        return service.assign(db, issue_id, officer, data)
    except (service.NotFoundError, service.InvalidRequestError) as e:
        raise _handle(e)


@router.patch("/issues/{issue_id}/status", response_model=SafetyIssueDetailOut)
def update_issue_status(
    issue_id: int,
    data: StatusUpdateIn,
    officer: User = Depends(require_officer),
    db: Session = Depends(get_db),
):
    """Change the status. The optional note is shown to the citizen in the timeline."""
    try:
        return service.update_status(db, issue_id, officer, data)
    except (service.NotFoundError, service.InvalidRequestError) as e:
        raise _handle(e)


@router.post(
    "/issues/{issue_id}/updates",
    response_model=SafetyIssueDetailOut,
    status_code=status.HTTP_201_CREATED,
)
def add_public_update(
    issue_id: int,
    data: PublicUpdateIn,
    officer: User = Depends(require_officer),
    db: Session = Depends(get_db),
):
    """A citizen-visible update (appears in the timeline). The status does not change."""
    try:
        return service.add_public_update(db, issue_id, officer, data.note)
    except service.NotFoundError as e:
        raise _handle(e)


@router.get("/issues/{issue_id}/notes", response_model=list[NoteOut])
def list_internal_notes(
    issue_id: int,
    _officer: User = Depends(require_officer),
    db: Session = Depends(get_db),
):
    try:
        return service.list_notes(db, issue_id)
    except service.NotFoundError as e:
        raise _handle(e)


@router.post(
    "/issues/{issue_id}/notes", response_model=NoteOut, status_code=status.HTTP_201_CREATED
)
def add_internal_note(
    issue_id: int,
    data: InternalNoteIn,
    officer: User = Depends(require_officer),
    db: Session = Depends(get_db),
):
    """A staff-only note. Citizens never see it."""
    try:
        return service.add_internal_note(db, issue_id, officer, data.note)
    except service.NotFoundError as e:
        raise _handle(e)
