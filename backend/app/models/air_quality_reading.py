from sqlalchemy import Column, DateTime, Float, Integer, String
from sqlalchemy.sql import func

from app.db.session import Base


class AirQualityReading(Base):
    __tablename__ = "air_quality_readings"

    id = Column(Integer, primary_key=True, index=True)
    area = Column(String(150), nullable=False, index=True)
    aqi = Column(Float, nullable=False)
    pm2_5 = Column(Float, nullable=True)
    pm10 = Column(Float, nullable=True)
    carbon_monoxide = Column(Float, nullable=True)
    nitrogen_dioxide = Column(Float, nullable=True)
    ozone = Column(Float, nullable=True)
    source = Column(String(100), nullable=True)
    recorded_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
