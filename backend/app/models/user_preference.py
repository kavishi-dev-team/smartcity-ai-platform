from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.sql import func

from app.db.session import Base


class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    push_notifications_enabled = Column(
        Boolean, nullable=False, default=True
    )
    email_notifications_enabled = Column(
        Boolean, nullable=False, default=True
    )
    report_status_notifications = Column(
        Boolean, nullable=False, default=True
    )
    nearby_issue_alerts = Column(Boolean, nullable=False, default=True)
    safety_alerts_enabled = Column(Boolean, nullable=False, default=True)

    language = Column(String(10), nullable=False, default="en")
    text_size = Column(String(20), nullable=False, default="medium")
    high_contrast = Column(Boolean, nullable=False, default=False)
    reduce_animations = Column(Boolean, nullable=False, default=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
