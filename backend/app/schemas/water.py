
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class WaterIssueCreate(BaseModel):
    title: str
    description: str
    subcategory: Optional[str] = None
    priority: str = "medium"
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None


class WaterIssueLocationOut(BaseModel):
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class WaterIssueOut(BaseModel):
    id: int
    title: str
    description: str
    category: str
    subcategory: Optional[str] = None
    status: str
    priority: str
    department_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    location: Optional[WaterIssueLocationOut] = None

    model_config = ConfigDict(from_attributes=True)
