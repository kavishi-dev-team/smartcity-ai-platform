import json
from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.ai_analysis import AIAnalysis
from app.models.audit_log import AuditLog
from app.models.department import Department
from app.models.department_member import DepartmentMember
from app.models.issue import Issue
from app.models.issue_assignment import IssueAssignment
from app.models.issue_comment import IssueComment
from app.models.issue_priority_review import IssuePriorityReview
from app.models.issue_status_history import IssueStatusHistory
from app.models.user import User
from app.schemas.traffic_officer import (
    OfficerCommentOut, OfficerIssueOut, OfficerOption, OfficerPriorityReviewOut,
    OfficerUpdateIn, PriorityReviewIn,
)

OFFICER_ROLES = (
    'officer',
    'authorized_officer',
    'admin',
    'department_officer',
    'city_manager',
    'super_admin',
)
ADMIN_ROLES = ('admin', 'super_admin', 'city_manager')
PRIORITIES = ('low', 'medium', 'high', 'critical')
STATUSES = ('reported', 'under_review', 'assigned', 'in_progress', 'resolved', 'rejected')


def _get_issue(db: Session, issue_id: int, *, lock: bool = False) -> Issue:
    query = db.query(Issue).filter(Issue.id == issue_id, Issue.is_active.is_(True))
    if lock:
        query = query.with_for_update()
    issue = query.first()
    if issue is None:
        raise HTTPException(status_code=404, detail='Active issue not found')
    return issue


def _authorize_issue_access(db: Session, actor: User, issue: Issue) -> None:
    """Officers may manage their department's issues, or unassigned traffic
    issues for triage. Admins can manage issues across departments.
    Auth must check DB membership, never a client-supplied department/role.
    """
    role_lower = (actor.role or '').strip().lower()
    if role_lower in ADMIN_ROLES or role_lower == 'department_officer':
        return
    membership = db.query(DepartmentMember.id).join(Department).filter(
        DepartmentMember.user_id == actor.id,
        DepartmentMember.is_active.is_(True),
        Department.is_active.is_(True),
    )
    if issue.department_id is not None:
        membership = membership.filter(DepartmentMember.department_id == issue.department_id)
    if membership.first() is None:
        raise HTTPException(status_code=403, detail='Officer is not authorized for this traffic department')


def _authorize_department_assignment(db: Session, actor: User, issue: Issue, target_id: int) -> None:
    _authorize_issue_access(db, actor, issue)
    role_lower = (actor.role or '').strip().lower()
    if issue.department_id is None and role_lower not in ADMIN_ROLES and role_lower != 'department_officer':
        allowed = db.query(DepartmentMember.id).filter(
            DepartmentMember.user_id == actor.id,
            DepartmentMember.department_id == target_id,
            DepartmentMember.is_active.is_(True),
        ).first()
        if allowed is None:
            raise HTTPException(status_code=403, detail='Officers can claim unassigned issues for their department only')


def _current_assignment(db: Session, issue_id: int) -> IssueAssignment | None:
    return db.query(IssueAssignment).filter(IssueAssignment.issue_id == issue_id).order_by(
        IssueAssignment.assigned_at.desc(), IssueAssignment.id.desc()
    ).first()


def _recommended_priority(db: Session, issue_id: int) -> str | None:
    analyses = db.query(AIAnalysis).filter(AIAnalysis.issue_id == issue_id).order_by(
        AIAnalysis.created_at.desc(), AIAnalysis.id.desc()
    ).limit(8).all()
    for analysis in analyses:
        result = analysis.result
        if isinstance(result, dict):
            for key in ('recommended_priority', 'priority', 'suggested_priority'):
                value = result.get(key)
                if isinstance(value, str) and value.strip().lower() in PRIORITIES:
                    return value.strip().lower()
    return None


def _audit(db: Session, actor: User, issue: Issue, action: str, changes: dict) -> None:
    db.add(AuditLog(
        user_id=actor.id, action=action, entity_type='issue', entity_id=issue.id,
        details=json.dumps(changes, separators=(',', ':'), sort_keys=True),
    ))


def _commit(db: Session) -> None:
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise


def get_officer_issue(db: Session, issue_id: int, actor: User) -> OfficerIssueOut:
    issue = _get_issue(db, issue_id)
    _authorize_issue_access(db, actor, issue)
    departments = db.query(Department.id, Department.name).filter(Department.is_active.is_(True)).order_by(Department.name).all()
    assignment = _current_assignment(db, issue.id)
    current_officer_id = assignment.assigned_to if assignment else None
    current_officer = db.query(User.full_name).filter(User.id == current_officer_id).scalar() if current_officer_id else None
    department_name = db.query(Department.name).filter(Department.id == issue.department_id).scalar() if issue.department_id else None
    officers = []
    if issue.department_id is not None:
        officers = db.query(User.id, User.full_name).join(
            DepartmentMember, DepartmentMember.user_id == User.id
        ).filter(
            DepartmentMember.department_id == issue.department_id,
            DepartmentMember.is_active.is_(True),
            User.is_active.is_(True),
            func.lower(User.role).in_(OFFICER_ROLES),
        ).distinct().order_by(User.full_name).all()
    if not officers:
        officers = db.query(User.id, User.full_name).filter(
            User.is_active.is_(True),
            func.lower(User.role).in_(OFFICER_ROLES),
        ).distinct().order_by(User.full_name).all()
    latest_review = db.query(IssuePriorityReview).filter(IssuePriorityReview.issue_id == issue.id).order_by(
        IssuePriorityReview.created_at.desc(), IssuePriorityReview.id.desc()
    ).first()
    rows = db.query(IssueComment, User.full_name).join(User, User.id == IssueComment.user_id).filter(
        IssueComment.issue_id == issue.id
    ).order_by(IssueComment.created_at.desc(), IssueComment.id.desc()).limit(50).all()
    return OfficerIssueOut(
        id=issue.id, title=issue.title, description=issue.description,
        status=issue.status, priority=issue.priority,
        department_id=issue.department_id, department_name=department_name,
        assigned_officer_id=current_officer_id, assigned_officer_name=current_officer,
        ai_recommended_priority=_recommended_priority(db, issue.id),
        latest_priority_review=OfficerPriorityReviewOut(
            ai_suggested_priority=latest_review.ai_suggested_priority,
            final_priority=latest_review.final_priority,
            review_status=latest_review.review_status,
            review_note=latest_review.review_note,
            reviewed_at=latest_review.reviewed_at,
        ) if latest_review else None,
        departments=[OfficerOption(id=d.id, name=d.name) for d in departments],
        officers=[OfficerOption(id=o.id, name=o.full_name) for o in officers],
        notes=[OfficerCommentOut(
            id=c.id, comment=c.comment, visibility=c.visibility,
            created_at=c.created_at, author_name=name,
        ) for c, name in rows],
    )


def assign_department(db: Session, issue_id: int, actor: User, department_id: int) -> dict:
    issue = _get_issue(db, issue_id, lock=True)
    _authorize_issue_access(db, actor, issue)
    _authorize_department_assignment(db, actor, issue, department_id)
    department = db.query(Department).filter(Department.id == department_id, Department.is_active.is_(True)).first()
    if department is None:
        raise HTTPException(status_code=404, detail='Active department not found')
    if issue.department_id == department_id:
        raise HTTPException(status_code=409, detail='This department is already assigned')
    before = issue.department_id
    issue.department_id = department_id
    db.add(IssueAssignment(
        issue_id=issue.id, department_id=department_id,
        assigned_to=None, assigned_by=actor.id,
        status='department_assigned', note='Department reassignment',
    ))
    _audit(db, actor, issue, 'traffic.department_assign', {'from': before, 'to': department_id})
    _commit(db)
    return {'message': 'Department assigned', 'department_id': department_id}


def assign_officer(db: Session, issue_id: int, actor: User, officer_id: int) -> dict:
    issue = _get_issue(db, issue_id, lock=True)
    _authorize_issue_access(db, actor, issue)
    if issue.department_id is None:
        raise HTTPException(status_code=409, detail='Assign a department before selecting an officer')
    user = db.query(User).filter(
        User.id == officer_id,
        User.is_active.is_(True),
        func.lower(User.role).in_(OFFICER_ROLES),
    ).first()
    if user is None:
        raise HTTPException(status_code=422, detail='Officer must be an active staff account')
    current = _current_assignment(db, issue.id)
    if current is not None and current.assigned_to == officer_id:
        raise HTTPException(status_code=409, detail='This officer is already assigned')
    db.add(IssueAssignment(
        issue_id=issue.id, department_id=issue.department_id,
        assigned_to=officer_id, assigned_by=actor.id, status='assigned',
    ))
    _audit(db, actor, issue, 'traffic.officer_assign', {'officer_id': officer_id, 'department_id': issue.department_id})
    _commit(db)
    return {'message': 'Officer assigned', 'officer_id': officer_id}


def review_priority(db: Session, issue_id: int, actor: User, data: PriorityReviewIn) -> dict:
    issue = _get_issue(db, issue_id, lock=True)
    _authorize_issue_access(db, actor, issue)
    ai_priority = _recommended_priority(db, issue.id)
    if data.decision == 'keep' and ai_priority is None:
        raise HTTPException(status_code=409, detail='No AI recommendation is available to keep')
    chosen = (ai_priority if data.decision == 'keep' else data.priority)
    assert chosen is not None
    if data.decision == 'override' and chosen == issue.priority:
        raise HTTPException(status_code=409, detail='The selected priority is already current')
    previous = issue.priority

    review = IssuePriorityReview(
        issue_id=issue.id,
        ai_suggested_priority=ai_priority or 'not_available',
        final_priority=chosen,
        reviewed_by=actor.id,
        review_status='kept' if data.decision == 'keep' else 'overridden',
        review_note=(data.reason or '').strip() if data.decision == 'override' else 'Kept AI recommendation',
        reviewed_at=datetime.now(timezone.utc),
    )
    db.add(review)
    issue.priority = chosen
    _audit(db, actor, issue, 'traffic.priority_review', {
        'decision': data.decision, 'previous': previous, 'new': chosen, 'ai_recommendation_available': ai_priority is not None,
    })
    _commit(db)
    return {'message': 'Priority review saved', 'priority': chosen, 'decision': data.decision}


def save_update(db: Session, issue_id: int, actor: User, data: OfficerUpdateIn) -> dict:
    issue = _get_issue(db, issue_id, lock=True)
    _authorize_issue_access(db, actor, issue)
    target = 'reported' if data.status == 'submitted' else data.status
    old = issue.status
    internal = (data.internal_note or '').strip()
    public = (data.public_update or '').strip()
    changed = target is not None and target != old
    if not changed and not internal and not public:
        raise HTTPException(status_code=409, detail='No changes to save')
    if target is not None and target not in STATUSES:
        raise HTTPException(status_code=422, detail='Unsupported traffic status')
    if changed:
        issue.status = target
    if changed or public:
        # Status history remains citizen-readable: only *explicitly public*
        # notes are ever placed in this field. Never put internal notes here.
        db.add(IssueStatusHistory(
            issue_id=issue.id, changed_by=actor.id,
            previous_status=old, new_status=target or old,
            note=public or None,
        ))
    if internal:
        db.add(IssueComment(issue_id=issue.id, user_id=actor.id, comment=internal, visibility='internal'))
    if public:
        db.add(IssueComment(issue_id=issue.id, user_id=actor.id, comment=public, visibility='public'))
    _audit(db, actor, issue, 'traffic.issue_update', {
        'previous_status': old, 'new_status': issue.status,
        'has_internal_note': bool(internal), 'has_public_update': bool(public),
    })
    _commit(db)
    return {'message': 'Traffic issue updated', 'status': issue.status}
