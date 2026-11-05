from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.schemas.notification import (
    NotificationListResponse,
    NotificationMarkAllReadResponse,
    NotificationResponse,
    NotificationUnreadCountResponse,
)


def list_notifications(
    db: Session,
    user_id: int,
    offset: int = 0,
    limit: int = 20,
    unread_only: bool = False,
) -> NotificationListResponse:
    conditions = [Notification.user_id == user_id]

    if unread_only:
        conditions.append(Notification.is_read.is_(False))

    total = db.scalar(
        select(func.count())
        .select_from(Notification)
        .where(*conditions)
    ) or 0

    notifications = db.scalars(
        select(Notification)
        .where(*conditions)
        .order_by(
            Notification.created_at.desc(),
            Notification.id.desc(),
        )
        .offset(offset)
        .limit(limit)
    ).all()

    return NotificationListResponse(
        items=[
            NotificationResponse.model_validate(item)
            for item in notifications
        ],
        total=total,
        offset=offset,
        limit=limit,
    )


def get_notification(
    db: Session,
    user_id: int,
    notification_id: int,
) -> NotificationResponse | None:
    notification = db.scalar(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        )
    )

    if notification is None:
        return None

    return NotificationResponse.model_validate(notification)


def mark_notification_as_read(
    db: Session,
    user_id: int,
    notification_id: int,
) -> NotificationResponse | None:
    try:
        db.execute(
            update(Notification)
            .where(
                Notification.id == notification_id,
                Notification.user_id == user_id,
            )
            .values(is_read=True)
        )
        db.commit()
    except Exception:
        db.rollback()
        raise

    return get_notification(
        db=db,
        user_id=user_id,
        notification_id=notification_id,
    )


def mark_all_notifications_as_read(
    db: Session,
    user_id: int,
) -> NotificationMarkAllReadResponse:
    try:
        result = db.execute(
            update(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.is_read.is_(False),
            )
            .values(is_read=True)
        )
        db.commit()
    except Exception:
        db.rollback()
        raise

    return NotificationMarkAllReadResponse(
        updated_count=result.rowcount,
    )


def get_unread_count(
    db: Session,
    user_id: int,
) -> NotificationUnreadCountResponse:
    count = db.scalar(
        select(func.count())
        .select_from(Notification)
        .where(
            Notification.user_id == user_id,
            Notification.is_read.is_(False),
        )
    ) or 0

    return NotificationUnreadCountResponse(unread_count=count)