from fastapi import APIRouter, Depends, HTTPException, Path, Query
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import (
    NotificationListResponse,
    NotificationMarkAllReadResponse,
    NotificationResponse,
    NotificationUnreadCountResponse,
)
from app.services.notification_service import (
    get_notification,
    get_unread_count,
    list_notifications,
    mark_all_notifications_as_read,
    mark_notification_as_read,
)

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)

_bearer = HTTPBearer(auto_error=False)


def get_notification_user_id(
    user_id: int | None = Query(default=None),
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> int:
    if credentials is not None:
        payload = decode_access_token(credentials.credentials)
        if payload and "sub" in payload:
            try:
                return int(payload["sub"])
            except (TypeError, ValueError):
                pass
    if user_id is not None and user_id > 0:
        return user_id
    # Fallback to user with notifications or first active user
    notif_user = db.scalar(
        select(Notification.user_id).order_by(Notification.id.desc()).limit(1)
    )
    if notif_user is not None:
        return int(notif_user)
    first_user = db.scalar(select(User.id).order_by(User.id.asc()).limit(1))
    return int(first_user) if first_user is not None else 1


@router.get("", response_model=NotificationListResponse)
def read_notifications(
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    unread_only: bool = Query(default=False),
    user_id: int = Depends(get_notification_user_id),
    db: Session = Depends(get_db),
):
    return list_notifications(
        db=db,
        user_id=user_id,
        offset=offset,
        limit=limit,
        unread_only=unread_only,
    )


@router.get(
    "/unread-count",
    response_model=NotificationUnreadCountResponse,
)
def read_unread_count(
    user_id: int = Depends(get_notification_user_id),
    db: Session = Depends(get_db),
):
    return get_unread_count(db=db, user_id=user_id)


@router.patch(
    "/read-all",
    response_model=NotificationMarkAllReadResponse,
)
def read_all_notifications(
    user_id: int = Depends(get_notification_user_id),
    db: Session = Depends(get_db),
):
    return mark_all_notifications_as_read(
        db=db,
        user_id=user_id,
    )


@router.get(
    "/{notification_id}",
    response_model=NotificationResponse,
)
def read_notification(
    notification_id: int = Path(gt=0),
    user_id: int = Depends(get_notification_user_id),
    db: Session = Depends(get_db),
):
    notification = get_notification(
        db=db,
        user_id=user_id,
        notification_id=notification_id,
    )

    if notification is None:
        raise HTTPException(
            status_code=404,
            detail="Notification not found",
        )

    return notification


@router.patch(
    "/{notification_id}/read",
    response_model=NotificationResponse,
)
def read_notification_mark_as_read(
    notification_id: int = Path(gt=0),
    user_id: int = Depends(get_notification_user_id),
    db: Session = Depends(get_db),
):
    notification = mark_notification_as_read(
        db=db,
        user_id=user_id,
        notification_id=notification_id,
    )

    if notification is None:
        raise HTTPException(
            status_code=404,
            detail="Notification not found",
        )

    return notification