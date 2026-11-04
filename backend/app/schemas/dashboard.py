from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


class DashboardIssue(BaseModel):
    id: int
    title: str
    description: str
    category: str
    status: str
    priority: str
    department_id: Optional[int] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DashboardStatistics(BaseModel):
    total: int
    pending: int
    high_priority: int
    in_progress: int
    resolved: int


class CitizenDashboardResponse(BaseModel):
    total_reports: int
    active_reports: int
    resolved_reports: int
    recent_reports: List[DashboardIssue]


class OfficerDashboardResponse(BaseModel):
    statistics: DashboardStatistics
    recent_issues: List[DashboardIssue]
