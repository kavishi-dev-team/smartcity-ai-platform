from sqlalchemy import Boolean, Column, DateTime, Integer, String
from sqlalchemy.sql import func

from app.db.session import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(150), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)

    # One of: SUPER_ADMIN, CITY_MANAGER, DEPARTMENT_OFFICER, CITIZEN
    # (see app.core.permissions.Role)
    role = Column(String(50), nullable=False, default="CITIZEN")

    phone_number = Column(String(20), nullable=True)
    address = Column(String(500), nullable=True)
    profile_photo_url = Column(String(500), nullable=True)

    is_active = Column(Boolean, nullable=False, default=True)
    is_email_verified = Column(Boolean, nullable=False, default=False)

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