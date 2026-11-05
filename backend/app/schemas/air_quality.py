from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class AirQualityReadingOut(BaseModel):
    id: int
    area: str
    aqi: int
    category: str
    health_recommendation: str
    pm2_5: Optional[float] = None
    pm10: Optional[float] = None
    carbon_monoxide: Optional[float] = None
    nitrogen_dioxide: Optional[float] = None
    ozone: Optional[float] = None
    source: Optional[str] = None
    recorded_at: datetime


class AirQualityHistoryPoint(BaseModel):
    timestamp: datetime
    aqi: int
    pm2_5: Optional[float] = None
    pm10: Optional[float] = None


class AirQualityHistoryOut(BaseModel):
    area: str
    period: str
    average_aqi: int
    min_aqi: int
    max_aqi: int
    points: list[AirQualityHistoryPoint]
