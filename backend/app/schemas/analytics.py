from typing import List
from pydantic import BaseModel


class AnalyticsOverviewResponse(BaseModel):
    total_issues: int
    pending_issues: int
    in_progress_issues: int
    resolved_issues: int
    high_priority_issues: int


class CategoryAnalytics(BaseModel):
    category: str
    issue_count: int


class StatusAnalytics(BaseModel):
    status: str
    issue_count: int


class MonthlyAnalytics(BaseModel):
    month: str
    issue_count: int


class IssueAnalyticsResponse(BaseModel):
    categories: List[CategoryAnalytics]
    statuses: List[StatusAnalytics]
    monthly: List[MonthlyAnalytics]


class DepartmentAnalytics(BaseModel):
    department_id: int
    department_name: str
    total_issues: int
    pending_issues: int
    resolved_issues: int


class DepartmentAnalyticsResponse(BaseModel):
    departments: List[DepartmentAnalytics]
