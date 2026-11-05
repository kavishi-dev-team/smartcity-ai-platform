from datetime import date, datetime, time, timedelta
from typing import Optional

from sqlalchemy.orm import Session

from app.models.safety_alert import SafetyAlert
from app.repositories import safety_alert_repository as repo
from app.schemas.safety_alert import SafetyAlertCreate, SafetyAlertUpdate


class InvalidIssueError(Exception):
    """The given issue_id does not exist."""


def list_alerts(
    db: Session,
    *,
    is_active: Optional[bool] = None,
    severity: Optional[str] = None,
    area: Optional[str] = None,
    alert_type: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    limit: int = 50,
    offset: int = 0,
) -> list[SafetyAlert]:
    start = datetime.combine(date_from, time.min) if date_from else None
    # date_to is inclusive: include everything up to the end of that day
    end = datetime.combine(date_to + timedelta(days=1), time.min) if date_to else None
    return repo.list_alerts(
        db, is_active=is_active, severity=severity, area=area,
        alert_type=alert_type, start=start, end=end, limit=limit, offset=offset,
    )


def get_alert(db: Session, alert_id: int) -> Optional[SafetyAlert]:
    return repo.get_alert(db, alert_id)


def create_alert(db: Session, data: SafetyAlertCreate) -> SafetyAlert:
    if data.issue_id is not None and not repo.issue_exists(db, data.issue_id):
        raise InvalidIssueError(f"Issue {data.issue_id} does not exist")
    return repo.add_alert(db, SafetyAlert(**data.model_dump(), is_active=True))


def update_alert(
    db: Session, alert_id: int, data: SafetyAlertUpdate
) -> Optional[SafetyAlert]:
    alert = repo.get_alert(db, alert_id)
    if alert is None:
        return None

    changes = data.model_dump(exclude_unset=True)
    new_issue_id = changes.get("issue_id")
    if new_issue_id is not None and not repo.issue_exists(db, new_issue_id):
        raise InvalidIssueError(f"Issue {new_issue_id} does not exist")

    # these columns are NOT NULL, so ignore an explicit null for them
    for field in ("title", "description", "alert_type", "severity", "area", "is_active"):
        if field in changes and changes[field] is None:
            del changes[field]

    for field, value in changes.items():
        setattr(alert, field, value)
    return repo.save_alert(db, alert)
