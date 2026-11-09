from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class AirQualityReadingOut(BaseModel):
    id: int
    area: str
    district: Optional[str] = None
    province: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    aqi: int
    category: str
    health_recommendation: str
    pm2_5: Optional[float] = None
    pm10: Optional[float] = None
    carbon_monoxide: Optional[float] = None
    nitrogen_dioxide: Optional[float] = None
    sulphur_dioxide: Optional[float] = None
    ozone: Optional[float] = None
    uv_index: Optional[float] = None
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
