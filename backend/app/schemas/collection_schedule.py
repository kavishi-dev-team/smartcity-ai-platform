from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CollectionScheduleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    area: str
    collection_day: str
    collection_time: str | None = None
    waste_types: str | None = None
    instructions: str | None = None
    created_at: datetime


class CollectionScheduleListResponse(BaseModel):
    items: list[CollectionScheduleResponse]
    total: int = Field(ge=0)
    offset: int = Field(ge=0)
    limit: int = Field(ge=1, le=100)