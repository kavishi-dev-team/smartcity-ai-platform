
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import (
    Issue,
    User,
    Department,
    DepartmentMember,
    IssueAssignment,
)
from app.schemas.assignment import (
    IssueAssignmentCreate,
    IssueAssignmentOut,
)

router = APIRouter(prefix="/assignments", tags=["Assignments"])


@router.post(
    "",
    response_model=IssueAssignmentOut,
    status_code=status.HTTP_201_CREATED,
)
def create_assignment(
    data: IssueAssignmentCreate,
    db: Session = Depends(get_db),
):
    # Check whether issue exists
    issue = db.query(Issue).filter(
        Issue.id == data.issue_id,
        Issue.is_active.is_(True),
    ).first()

    if not issue:
        raise HTTPException(
            status_code=404,
            detail="Issue not found",
        )

    # Check department
    department = db.query(Department).filter(
        Department.id == data.department_id,
        Department.is_active.is_(True),
    ).first()

    if not department:
        raise HTTPException(
            status_code=404,
            detail="Active department not found",
        )

    # Check assigned user
    assigned_user = db.query(User).filter(
        User.id == data.assigned_to,
        User.is_active.is_(True),
    ).first()

    if not assigned_user:
        raise HTTPException(
            status_code=404,
            detail="Active assigned user not found",
        )

    # Check assigning user
    assigning_user = db.query(User).filter(
        User.id == data.assigned_by,
        User.is_active.is_(True),
    ).first()

    if not assigning_user:
        raise HTTPException(
            status_code=404,
            detail="Active assigning user not found",
        )

    # Check department membership
    membership = db.query(DepartmentMember).filter(
        DepartmentMember.department_id == data.department_id,
        DepartmentMember.user_id == data.assigned_to,
        DepartmentMember.is_active.is_(True),
    ).first()

    if not membership:
        raise HTTPException(
            status_code=400,
            detail="Assigned user is not an active member of this department",
        )

    # Create assignment
    assignment = IssueAssignment(
        issue_id=data.issue_id,
        assigned_to=data.assigned_to,
        assigned_by=data.assigned_by,
        department_id=data.department_id,
        status="assigned",
        note=data.note,
    )

    try:
        issue.department_id = data.department_id
        db.add(assignment)
        db.commit()
        db.refresh(assignment)
    except Exception:
        db.rollback()
        raise

    return assignment


@router.get(
    "/{issue_id}",
    response_model=List[IssueAssignmentOut],
)
def get_issue_assignments(
    issue_id: int,
    db: Session = Depends(get_db),
):
    issue = db.query(Issue).filter(
        Issue.id == issue_id,
        Issue.is_active.is_(True),
    ).first()

    if not issue:
        raise HTTPException(
            status_code=404,
            detail="Issue not found",
        )

    assignments = (
        db.query(IssueAssignment)
        .filter(IssueAssignment.issue_id == issue_id)
        .order_by(IssueAssignment.assigned_at.desc())
        .all()
    )

    return assignments
