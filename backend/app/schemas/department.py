"""Department schemas (shared by the general and traffic modules)."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.traffic import TrafficIssueOut


class DepartmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: Optional[str] = None

    # Core fields from the general departments API
    is_active: Optional[bool] = None
    created_at: Optional[datetime] = None

    # Department information fields (traffic module)
    responsibilities: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    office_address: Optional[str] = None
    office_city: Optional[str] = None
    office_latitude: Optional[float] = None
    office_longitude: Optional[float] = None
    operating_hours: Optional[str] = None
    traffic_issue_count: Optional[int] = Field(default=None, ge=0)


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