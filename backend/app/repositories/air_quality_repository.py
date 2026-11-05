from datetime import datetime
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.orm import Session

from app.models.air_quality_reading import AirQualityReading as AQ


def get_latest_per_area(db: Session, area: Optional[str] = None) -> list[AQ]:
    latest = select(AQ.area, func.max(AQ.recorded_at).label("max_time")).group_by(AQ.area)
    if area:
        latest = latest.where(AQ.area == area)
    latest = latest.subquery()

    stmt = (
        select(AQ)
        .join(latest, and_(AQ.area == latest.c.area, AQ.recorded_at == latest.c.max_time))
        .order_by(AQ.area)
    )
    return list(db.scalars(stmt).all())


def get_readings_since(db: Session, area: str, since: datetime) -> list[AQ]:
    stmt = (
        select(AQ)
        .where(AQ.area == area, AQ.recorded_at >= since)
        .order_by(AQ.recorded_at)
    )
    return list(db.scalars(stmt).all())
