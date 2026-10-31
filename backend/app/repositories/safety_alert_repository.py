from datetime import datetime
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.issue import Issue
from app.models.safety_alert import SafetyAlert


def list_alerts(
    db: Session,
    *,
    is_active: Optional[bool],
    severity: Optional[str],
    area: Optional[str],
    alert_type: Optional[str],
    start: Optional[datetime],
    end: Optional[datetime],
    limit: int,
    offset: int,
) -> list[SafetyAlert]:
    stmt = select(SafetyAlert)
    if is_active is not None:
        stmt = stmt.where(SafetyAlert.is_active == is_active)
    if severity:
        stmt = stmt.where(SafetyAlert.severity == severity)
    if area:
        stmt = stmt.where(SafetyAlert.area == area)
    if alert_type:
        stmt = stmt.where(SafetyAlert.alert_type == alert_type)
    if start:
        stmt = stmt.where(SafetyAlert.created_at >= start)
    if end:
        stmt = stmt.where(SafetyAlert.created_at < end)
    stmt = stmt.order_by(SafetyAlert.created_at.desc(), SafetyAlert.id.desc())
    stmt = stmt.limit(limit).offset(offset)
    return list(db.scalars(stmt).all())


def get_alert(db: Session, alert_id: int) -> Optional[SafetyAlert]:
    return db.get(SafetyAlert, alert_id)


def issue_exists(db: Session, issue_id: int) -> bool:
    return db.get(Issue, issue_id) is not None


def add_alert(db: Session, alert: SafetyAlert) -> SafetyAlert:
    db.add(alert)
    db.commit()
    db.refresh(alert)
    return alert


def save_alert(db: Session, alert: SafetyAlert) -> SafetyAlert:
    db.commit()
    db.refresh(alert)
    return alert
