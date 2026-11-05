"""Department directory queries. No updates and no other module data writes."""
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.department import Department
from app.models.issue import Issue


def active_department_query(db: Session):
    return db.query(Department).filter(Department.is_active.is_(True))


def get_active_department(db: Session, department_id: int):
    return active_department_query(db).filter(Department.id == department_id).first()


def active_traffic_counts(db: Session, ids: list[int]) -> dict[int, int]:
    if not ids:
        return {}
    rows = (db.query(Issue.department_id, func.count(Issue.id))
            .filter(Issue.department_id.in_(ids),
                    Issue.category == 'traffic', Issue.is_active.is_(True))
            .group_by(Issue.department_id).all())
    return {department_id: count for department_id, count in rows}
