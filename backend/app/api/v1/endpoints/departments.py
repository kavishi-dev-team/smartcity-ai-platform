from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.department import (
    DepartmentListOut,
    DepartmentOut,
    DepartmentTrafficIssuesOut,
)
from app.services.department_service import (
    get_department as get_department_by_id,
    list_department_traffic_issues,
    list_departments,
)

router = APIRouter(prefix="/departments", tags=["Departments"])


@router.get("", response_model=DepartmentListOut | list[DepartmentOut])
def get_departments(
    search: str | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=200),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
):
    page = list_departments(
        db,
        search=search,
        limit=limit if limit is not None else 100,
        offset=offset if offset is not None else 0,
    )
    if limit is not None or offset is not None or search is not None:
        return page
    return page.items


@router.get("/{department_id}", response_model=DepartmentOut)
def get_department(
    department_id: int,
    db: Session = Depends(get_db),
):
    department = get_department_by_id(db, department_id)

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