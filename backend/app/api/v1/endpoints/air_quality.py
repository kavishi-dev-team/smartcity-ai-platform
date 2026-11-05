from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.air_quality import AirQualityHistoryOut, AirQualityReadingOut
from app.services import air_quality_service

router = APIRouter(prefix="/air-quality", tags=["Air Quality"])


@router.get("", response_model=list[AirQualityReadingOut])
def get_air_quality(area: Optional[str] = None, db: Session = Depends(get_db)):
    """Latest reading for every area (or one area if ?area= is given)."""
    return air_quality_service.get_latest(db, area)


@router.get("/history", response_model=AirQualityHistoryOut)
def get_air_quality_history(
    area: str = Query(...),
    period: Literal["daily", "weekly", "monthly"] = "daily",
    db: Session = Depends(get_db),
):
    result = air_quality_service.get_history(db, area, period)
    if result is None:
        raise HTTPException(status_code=404, detail="No readings found for this area")
    return result