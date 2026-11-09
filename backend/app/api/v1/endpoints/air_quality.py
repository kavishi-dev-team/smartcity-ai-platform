from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.air_quality import AirQualityHistoryOut, AirQualityReadingOut
from app.services import air_quality_service

router = APIRouter(prefix="/air-quality", tags=["Air Quality"])


@router.get("", response_model=list[AirQualityReadingOut])
def get_air_quality(
    area: Optional[str] = None,
    refresh: bool = False,
    db: Session = Depends(get_db),
):
    """Latest live reading for all Sri Lankan cities (or filtered by ?area=)."""
    return air_quality_service.get_latest(db, area, force_refresh=refresh)


@router.get("/location", response_model=AirQualityReadingOut)
def get_air_quality_by_location(
    lat: float = Query(..., description="Latitude in Sri Lanka"),
    lon: float = Query(..., description="Longitude in Sri Lanka"),
    area: Optional[str] = Query(None, description="Optional custom place/town name"),
):
    """Live real-time air quality telemetry for any picked coordinate or town in Sri Lanka."""
    return air_quality_service.get_live_by_coordinates(
        lat=lat,
        lon=lon,
        area_name=area,
    )


@router.get("/history", response_model=AirQualityHistoryOut)
def get_air_quality_history(
    area: str = Query(...),
    period: Literal["daily", "weekly", "monthly"] = "daily",
    lat: Optional[float] = Query(None),
    lon: Optional[float] = Query(None),
    db: Session = Depends(get_db),
):
    result = air_quality_service.get_history(
        db,
        area,
        period,
        lat=lat,
        lon=lon,
    )
    if result is None:
        raise HTTPException(status_code=404, detail="No readings found for this area")
    return result