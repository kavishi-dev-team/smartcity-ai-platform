from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.permissions import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.user_preference import PreferenceRead, PreferenceUpdate
from app.services import user_service

router = APIRouter()


@router.get("", response_model=PreferenceRead)
def get_preferences(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    return user_service.get_or_create_preferences(db, current_user)


@router.patch("", response_model=PreferenceRead)
def update_preferences(
    data: PreferenceUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return user_service.update_preferences(db, current_user, data)