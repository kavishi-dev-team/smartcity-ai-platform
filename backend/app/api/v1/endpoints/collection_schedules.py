from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.collection_schedule import (
    CollectionScheduleListResponse,
    CollectionScheduleResponse,
)
from app.services.collection_service import (
    get_collection_schedule,
    list_collection_schedules,
)

router = APIRouter(
    prefix="/collection-schedules",
    tags=["Collection schedules"],
)


@router.get("", response_model=CollectionScheduleListResponse)
def read_collection_schedules(
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return list_collection_schedules(
        db=db,
        offset=offset,
        limit=limit,
    )


@router.get("/{schedule_id}", response_model=CollectionScheduleResponse)
def read_collection_schedule(
    schedule_id: int = Path(gt=0),
    db: Session = Depends(get_db),
):
    schedule = get_collection_schedule(db, schedule_id)

    if schedule is None:
        raise HTTPException(
            status_code=404,
            detail="Collection schedule not found",
        )

    return schedule