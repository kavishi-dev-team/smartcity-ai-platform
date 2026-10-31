from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.collection_schedule import CollectionSchedule
from app.schemas.collection_schedule import (
    CollectionScheduleListResponse,
    CollectionScheduleResponse,
)


def list_collection_schedules(
    db: Session,
    offset: int = 0,
    limit: int = 20,
) -> CollectionScheduleListResponse:
    conditions = [CollectionSchedule.is_active.is_(True)]

    total = db.scalar(
        select(func.count())
        .select_from(CollectionSchedule)
        .where(*conditions)
    ) or 0

    schedules = db.scalars(
        select(CollectionSchedule)
        .where(*conditions)
        .order_by(CollectionSchedule.area, CollectionSchedule.id)
        .offset(offset)
        .limit(limit)
    ).all()

    return CollectionScheduleListResponse(
        items=[
            CollectionScheduleResponse.model_validate(schedule)
            for schedule in schedules
        ],
        total=total,
        offset=offset,
        limit=limit,
    )


def get_collection_schedule(
    db: Session,
    schedule_id: int,
) -> CollectionScheduleResponse | None:
    schedule = db.scalar(
        select(CollectionSchedule).where(
            CollectionSchedule.id == schedule_id,
            CollectionSchedule.is_active.is_(True),
        )
    )

    if schedule is None:
        return None

    return CollectionScheduleResponse.model_validate(schedule)