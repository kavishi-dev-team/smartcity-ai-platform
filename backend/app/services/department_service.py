from sqlalchemy.orm import Session

from app.models.department import Department
from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.repositories.department_repository import (
    active_department_query, get_active_department, active_traffic_counts,
)
from app.schemas.department import DepartmentOut, DepartmentListOut, DepartmentTrafficIssuesOut
from app.schemas.traffic import TrafficIssueOut, TrafficLocationOut


def department_output(dept: Department, count: int) -> DepartmentOut:
    return DepartmentOut(
        id=dept.id, name=dept.name, description=dept.description,
        responsibilities=dept.responsibilities, contact_email=dept.contact_email,
        contact_phone=dept.contact_phone, office_address=dept.office_address,
        office_city=dept.office_city, office_latitude=dept.office_latitude,
        office_longitude=dept.office_longitude, operating_hours=dept.operating_hours,
        traffic_issue_count=count,
    )


def list_departments(db: Session, *, search: str | None, limit: int, offset: int) -> DepartmentListOut:
    query = active_department_query(db)
    if search and search.strip():
        query = query.filter(Department.name.ilike(f'%{search.strip()}%'))
    total = query.count()
    departments = query.order_by(Department.name.asc(), Department.id.asc()).offset(offset).limit(limit).all()
    counts = active_traffic_counts(db, [d.id for d in departments])
    return DepartmentListOut(items=[department_output(d, counts.get(d.id, 0)) for d in departments],
                             total=total, limit=limit, offset=offset)


def get_department(db: Session, department_id: int) -> DepartmentOut | None:
    dept = get_active_department(db, department_id)
    if dept is None:
        return None
    return department_output(dept, active_traffic_counts(db, [department_id]).get(department_id, 0))


def list_department_traffic_issues(db: Session, department_id: int, *, limit: int, offset: int) -> DepartmentTrafficIssuesOut:
    query = db.query(Issue).filter(
        Issue.department_id == department_id,
        Issue.category == 'traffic',
        Issue.is_active.is_(True),
    )
    total = query.count()
    issues = query.order_by(Issue.created_at.desc(), Issue.id.desc()).offset(offset).limit(limit).all()
    ids = [i.id for i in issues]
    locations = {}
    if ids:
        for loc in (db.query(IssueLocation)
                    .filter(IssueLocation.issue_id.in_(ids))
                    .order_by(IssueLocation.id.desc()).all()):
            locations.setdefault(loc.issue_id, loc)
    dept = db.get(Department, department_id)
    result = []
    for issue in issues:
        loc = locations.get(issue.id)
        location = (TrafficLocationOut(latitude=loc.latitude, longitude=loc.longitude,
                                       address=loc.address, city=loc.city) if loc else None)
        result.append(TrafficIssueOut(
            id=issue.id, title=issue.title, description=issue.description,
            category=issue.category, status=issue.status, priority=issue.priority,
            department_id=issue.department_id, department_name=dept.name if dept else None,
            location=location, created_at=issue.created_at, updated_at=issue.updated_at,
        ))
    return DepartmentTrafficIssuesOut(items=result, total=total, limit=limit, offset=offset)
