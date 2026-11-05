"""Read-only public Department Information schemas for Member 2."""
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

from app.schemas.traffic import TrafficIssueOut


class DepartmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str | None = None
    responsibilities: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None
    office_address: str | None = None
    office_city: str | None = None
    office_latitude: float | None = None
    office_longitude: float | None = None
    operating_hours: str | None = None
    traffic_issue_count: int = Field(ge=0)


class DepartmentListOut(BaseModel):
    items: list[DepartmentOut]
    total: int = Field(ge=0)
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)


class DepartmentTrafficIssuesOut(BaseModel):
    items: list[TrafficIssueOut]
    total: int = Field(ge=0)
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)
