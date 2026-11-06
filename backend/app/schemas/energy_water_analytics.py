
from typing import List

from pydantic import BaseModel


class StatisticCount(BaseModel):
    name: str
    count: int


class MonthlyTrend(BaseModel):
    month: str
    total_reports: int
    resolved_reports: int


class AreaStatistic(BaseModel):
    area: str
    total_reports: int
    resolved_reports: int


class IssueTypeStatistics(BaseModel):
    total_reports: int
    resolved_reports: int
    category_breakdown: List[StatisticCount]
    status_breakdown: List[StatisticCount]
    monthly_trends: List[MonthlyTrend]
    area_wise: List[AreaStatistic]


class EnergyWaterAnalyticsOut(BaseModel):
    energy: IssueTypeStatistics
    water: IssueTypeStatistics
