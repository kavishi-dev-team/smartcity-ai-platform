
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.energy_water_analytics import EnergyWaterAnalyticsOut
from app.services import energy_water_analytics_service

router = APIRouter(
    prefix="/energy-water",
    tags=["Energy & Water Analytics"],
)


@router.get(
    "/statistics",
    response_model=EnergyWaterAnalyticsOut,
)
def get_statistics(
    start_date: Optional[date] = Query(default=None),
    end_date: Optional[date] = Query(default=None),
    reported_by: Optional[int] = Query(default=None),
    db: Session = Depends(get_db),
):
    if start_date and end_date and start_date > end_date:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=400,
            detail="Start date cannot be after end date",
        )

    return energy_water_analytics_service.get_energy_water_statistics(
        db=db,
        start_date=start_date,
        end_date=end_date,
        reported_by=reported_by,
    )
