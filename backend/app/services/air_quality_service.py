from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.repositories import air_quality_repository as repo
from app.schemas.air_quality import (
    AirQualityHistoryOut,
    AirQualityHistoryPoint,
    AirQualityReadingOut,
)

PERIOD_DAYS = {"daily": 1, "weekly": 7, "monthly": 30}


def _utcnow_naive() -> datetime:
    # MySQL DATETIME columns come back timezone-naive, so we compare in naive UTC.
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _as_utc(dt: datetime) -> datetime:
    # Attach UTC so the API returns "...Z" timestamps the Flutter app can parse correctly.
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def classify(aqi: int) -> tuple[str, str]:
    """Return (category, health recommendation) for an AQI value."""
    if aqi <= 50:
        return "Good", "Air quality is good. Enjoy outdoor activities."
    if aqi <= 100:
        return "Moderate", "Acceptable. Unusually sensitive people should limit long outdoor exertion."
    if aqi <= 150:
        return "Unhealthy for Sensitive Groups", "Children, elderly and people with asthma should reduce outdoor activity."
    if aqi <= 200:
        return "Unhealthy", "Everyone should reduce prolonged outdoor exertion. Consider a mask."
    if aqi <= 300:
        return "Very Unhealthy", "Avoid outdoor activity. Keep windows closed."
    return "Hazardous", "Stay indoors. Follow official health advice."


def _to_out(r) -> AirQualityReadingOut:
    aqi = round(r.aqi)
    category, advice = classify(aqi)
    return AirQualityReadingOut(
        id=r.id, area=r.area, aqi=aqi, category=category,
        health_recommendation=advice,
        pm2_5=r.pm2_5, pm10=r.pm10,
        carbon_monoxide=r.carbon_monoxide,
        nitrogen_dioxide=r.nitrogen_dioxide,
        ozone=r.ozone, source=r.source,
        recorded_at=_as_utc(r.recorded_at),
    )


def get_latest(db: Session, area: Optional[str] = None) -> list[AirQualityReadingOut]:
    return [_to_out(r) for r in repo.get_latest_per_area(db, area)]


def get_history(db: Session, area: str, period: str) -> Optional[AirQualityHistoryOut]:
    since = _utcnow_naive() - timedelta(days=PERIOD_DAYS[period])
    rows = repo.get_readings_since(db, area, since)
    if not rows:
        return None

    if period == "daily":  # last 24h, every reading
        points = [
            AirQualityHistoryPoint(
                timestamp=_as_utc(r.recorded_at), aqi=round(r.aqi),
                pm2_5=r.pm2_5, pm10=r.pm10,
            )
            for r in rows
        ]
    else:  # weekly / monthly -> one averaged point per day
        buckets = defaultdict(list)
        for r in rows:
            buckets[r.recorded_at.date()].append(r)
        points = []
        for day, items in sorted(buckets.items()):
            pm25s = [i.pm2_5 for i in items if i.pm2_5 is not None]
            pm10s = [i.pm10 for i in items if i.pm10 is not None]
            points.append(AirQualityHistoryPoint(
                timestamp=datetime(day.year, day.month, day.day, tzinfo=timezone.utc),
                aqi=round(sum(i.aqi for i in items) / len(items)),
                pm2_5=round(sum(pm25s) / len(pm25s), 1) if pm25s else None,
                pm10=round(sum(pm10s) / len(pm10s), 1) if pm10s else None,
            ))

    values = [p.aqi for p in points]
    return AirQualityHistoryOut(
        area=area, period=period,
        average_aqi=round(sum(values) / len(values)),
        min_aqi=min(values), max_aqi=max(values), points=points,
    )
