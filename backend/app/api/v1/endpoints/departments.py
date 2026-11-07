from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import Department
from app.schemas.department import DepartmentOut, DepartmentTrafficIssuesOut
from app.services.department_service import (
    get_department as get_department_by_id,
    list_department_traffic_issues,
)

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


@router.get(
    "/{department_id}/issues",
    response_model=DepartmentTrafficIssuesOut,
    tags=["Departments - Member 2"],
)
def read_department_issues(
    department_id: int,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    if get_department_by_id(db, department_id) is None:
        raise HTTPException(status_code=404, detail="Department not found")
    return list_department_traffic_issues(
        db,
        department_id,
        limit=limit,
        offset=offset,
    )