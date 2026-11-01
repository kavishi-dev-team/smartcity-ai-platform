from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.models.user import User
from app.models.user_preference import UserPreference
from app.schemas.user import ChangePasswordRequest, UserUpdate
from app.schemas.user_preference import PreferenceUpdate
from app.services.auth_service import revoke_all_sessions


def update_profile(db: Session, user: User, data: UserUpdate) -> User:
    changes = data.model_dump(exclude_unset=True)
    for field, value in changes.items():
        if field == "full_name" and not value:
            continue  # name is required, ignore null
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user


def change_password(db: Session, user: User, data: ChangePasswordRequest) -> None:
    if not verify_password(data.current_password, user.hashed_password):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "Current password is incorrect"
        )
    user.hashed_password = hash_password(data.new_password)
    revoke_all_sessions(db, user.id)  # every device has to log in again
    db.commit()


def delete_account(db: Session, user: User, password: str) -> None:
    """Soft delete: other tables (issues, comments...) still reference this user."""
    if not verify_password(password, user.hashed_password):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Password is incorrect")

    user.is_active = False
    user.email = f"deleted_{user.id}@deleted.invalid"
    user.full_name = "Deleted User"
    user.phone_number = None
    user.address = None
    user.profile_photo_url = None
    revoke_all_sessions(db, user.id)
    db.commit()


def get_or_create_preferences(db: Session, user: User) -> UserPreference:
    prefs = db.scalar(select(UserPreference).where(UserPreference.user_id == user.id))
    if prefs is None:
        prefs = UserPreference(user_id=user.id)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)
    return prefs


def update_preferences(
    db: Session, user: User, data: PreferenceUpdate
) -> UserPreference:
    prefs = get_or_create_preferences(db, user)
    for field, value in data.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(prefs, field, value)
    db.commit()
    db.refresh(prefs)
    return prefs