from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.department import DepartmentListOut, DepartmentOut, DepartmentTrafficIssuesOut
from app.services.department_service import get_department, list_departments, list_department_traffic_issues

router = APIRouter(prefix='/departments', tags=['Departments - Member 2'])


@router.get('', response_model=DepartmentListOut)
def read_departments(
    search: str | None = Query(default=None, max_length=100),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    return list_departments(db, search=search, limit=limit, offset=offset)


@router.get('/{department_id}', response_model=DepartmentOut)
def read_department(department_id: int, db: Session = Depends(get_db)):
    department = get_department(db, department_id)
    if department is None:
        raise HTTPException(status_code=404, detail='Department not found')
    return department


@router.get('/{department_id}/issues', response_model=DepartmentTrafficIssuesOut)
def read_department_issues(
    department_id: int,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    if get_department(db, department_id) is None:
        raise HTTPException(status_code=404, detail='Department not found')
    return list_department_traffic_issues(db, department_id, limit=limit, offset=offset)
