from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class WasteLocationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    latitude: float
    longitude: float
    address: str | None = None
    city: str | None = None


class WasteIssueResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    category: str
    status: str
    priority: str
    created_at: datetime
    updated_at: datetime

    locations: list[WasteLocationResponse] = Field(default_factory=list)


class WasteIssueListResponse(BaseModel):
    items: list[WasteIssueResponse]
    total: int = Field(ge=0)
    offset: int = Field(ge=0)
    limit: int = Field(ge=1, le=100)