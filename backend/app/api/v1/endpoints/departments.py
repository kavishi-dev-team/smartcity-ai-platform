
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import Department
from app.schemas.department import DepartmentOut

router = APIRouter(prefix="/departments", tags=["Departments"])


@router.get("", response_model=List[DepartmentOut])
def get_departments(
    db: Session = Depends(get_db),
):
    departments = (
        db.query(Department)
        .filter(Department.is_active.is_(True))
        .order_by(Department.name.asc())
        .all()
    )

    return departments


@router.get("/{department_id}", response_model=DepartmentOut)
def get_department(
    department_id: int,
    db: Session = Depends(get_db),
):
    department = (
        db.query(Department)
        .filter(
            Department.id == department_id,
            Department.is_active.is_(True),
        )
        .first()
    )

    if not department:
        raise HTTPException(
            status_code=404,
            detail="Department not found",
        )

    return department
