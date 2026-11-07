from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class TrafficLocationOut(BaseModel):
    latitude: float
    longitude: float
    address: str | None = None
    city: str | None = None


class TrafficPhotoOut(BaseModel):
    id: int
    file_name: str
    file_url: str


class TrafficHistoryOut(BaseModel):
    previous_status: str | None = None
    new_status: str
    note: str | None = None
    created_at: datetime


class TrafficIssueOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    description: str
    category: str
    status: str
    priority: str
    department_id: int | None = None
    department_name: str | None = None
    location: TrafficLocationOut | None = None
    created_at: datetime
    updated_at: datetime


class TrafficListOut(BaseModel):
    items: list[TrafficIssueOut]
    total: int
    limit: int
    offset: int


class TrafficIssueDetailOut(TrafficIssueOut):
    photos: list[TrafficPhotoOut] = Field(default_factory=list)
    status_history: list[TrafficHistoryOut] = Field(default_factory=list)
    ai_summary: str | None = None
    similar_issues: list[TrafficIssueOut] = Field(default_factory=list)

class TrafficMapMarkerOut(BaseModel):
    id: int
    title: str
    status: str
    priority: str
    location: TrafficLocationOut


class TrafficMapOut(BaseModel):
    items: list[TrafficMapMarkerOut]
    total: int
    limit: int
