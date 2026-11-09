from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


class IssueLocationOut(BaseModel):
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class EnergyIssueOut(BaseModel):
    id: int
    title: str
    description: str
    category: str
    status: str
    priority: str
    department_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    location: Optional[IssueLocationOut] = None


class EnergyIssueListOut(BaseModel):
    total: int
    items: List[EnergyIssueOut]

class EnergyIssueCreate(BaseModel):
    title: str
    description: str
    priority: str = "medium"
    reported_by: Optional[int] = None
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None
