
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.energy_water_analytics_service import (
    get_energy_water_statistics,
)

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/issues")
def get_issue_analytics(
    category: str = Query(..., pattern="^(energy|water)$"),
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    db: Session = Depends(get_db),
):
    if start_date and end_date and start_date > end_date:
        raise HTTPException(
            status_code=400,
            detail="start_date cannot be after end_date",
        )

    statistics = get_energy_water_statistics(
        db=db,
        start_date=start_date,
        end_date=end_date,
    )

    return {
        "category": category,
        **statistics[category],
    }
