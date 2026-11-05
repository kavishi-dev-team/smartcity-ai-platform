from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.traffic_officer_auth import require_traffic_officer
from app.db.session import get_db
from app.models.user import User
from app.schemas.traffic_officer import (
    DepartmentAssignIn, OfficerAssignIn, OfficerIssueOut,
    OfficerUpdateIn, PriorityReviewIn,
)
from app.services.traffic_officer_service import (
    assign_department, assign_officer, get_officer_issue, review_priority, save_update,
)

router = APIRouter(prefix='/traffic/officer', tags=['Traffic Officer - Member 2'])


@router.get('/issues/{issue_id}', response_model=OfficerIssueOut)
def officer_issue(issue_id: int, db: Session = Depends(get_db), actor: User = Depends(require_traffic_officer)):
    return get_officer_issue(db, issue_id, actor)


@router.post('/issues/{issue_id}/department')
def department_assignment(issue_id: int, data: DepartmentAssignIn, db: Session = Depends(get_db), actor: User = Depends(require_traffic_officer)):
    return assign_department(db, issue_id, actor, data.department_id)


@router.post('/issues/{issue_id}/officer')
def officer_assignment(issue_id: int, data: OfficerAssignIn, db: Session = Depends(get_db), actor: User = Depends(require_traffic_officer)):
    return assign_officer(db, issue_id, actor, data.officer_id)


@router.post('/issues/{issue_id}/priority-review')
def priority_review(issue_id: int, data: PriorityReviewIn, db: Session = Depends(get_db), actor: User = Depends(require_traffic_officer)):
    return review_priority(db, issue_id, actor, data)


@router.patch('/issues/{issue_id}/status')
def traffic_status_update(issue_id: int, data: OfficerUpdateIn, db: Session = Depends(get_db), actor: User = Depends(require_traffic_officer)):
    return save_update(db, issue_id, actor, data)
