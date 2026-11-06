"""Creates one verified test user per role for local development.

    cd backend
    python -m app.db.seed_dev_users

Never run this against a real/production database.
"""
from sqlalchemy import select

from app.core.config import settings
from app.core.permissions import Role
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models.user import User
from app.models.user_preference import UserPreference

DEV_PASSWORD = "Password@123"

DEV_USERS = [
    ("Super Admin", "admin@smartcity-dev.com", Role.SUPER_ADMIN),
    ("City Manager", "manager@smartcity-dev.com", Role.CITY_MANAGER),
    ("Department Officer", "officer@smartcity-dev.com", Role.DEPARTMENT_OFFICER),
    ("Test Citizen", "citizen@smartcity-dev.com", Role.CITIZEN),
]


def main() -> None:
    if settings.APP_ENV == "production":
        raise SystemExit("Refusing to seed dev users in production")

    db = SessionLocal()
    try:
        for full_name, email, role in DEV_USERS:
            if db.scalar(select(User).where(User.email == email)):
                print(f"exists  {role.value:<20} {email}")
                continue
            user = User(
                full_name=full_name,
                email=email,
                hashed_password=hash_password(DEV_PASSWORD),
                role=role.value,
                is_active=True,
                is_email_verified=True,
            )
            db.add(user)
            db.flush()
            db.add(UserPreference(user_id=user.id))
            print(f"created {role.value:<20} {email}")
        db.commit()
    finally:
        db.close()
    print(f"\nPassword for all dev users: {DEV_PASSWORD}")


if __name__ == "__main__":
    main()