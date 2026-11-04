from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text
from sqlalchemy.sql import func

from app.db.session import Base


class CollectionSchedule(Base):
    __tablename__ = "collection_schedules"

    id = Column(Integer, primary_key=True, index=True)
    area = Column(String(150), nullable=False, index=True)
    collection_day = Column(String(50), nullable=False)
    collection_time = Column(String(50), nullable=True)
    waste_types = Column(String(255), nullable=True)
    instructions = Column(Text, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
