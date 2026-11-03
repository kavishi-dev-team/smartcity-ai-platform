from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
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


def get_notification_user_id() -> int:
    # Replace this dependency with the team's authenticated user dependency.
    raise HTTPException(
        status_code=503,
        detail="Notification authentication integration is pending.",
    )


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