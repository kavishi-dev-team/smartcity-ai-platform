from datetime import datetime

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.v1.endpoints.notifications import (
    get_notification_user_id,
    router,
)
from app.db.session import Base, get_db
from app.models.notification import Notification
from app.models.user import User


@pytest.fixture
def client():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def enable_foreign_keys(connection, _):
        connection.execute("PRAGMA foreign_keys=ON")

    TestSession = sessionmaker(bind=engine)

    Base.metadata.create_all(
        engine,
        tables=[User.__table__, Notification.__table__],
    )

    with TestSession() as db:
        db.add_all([
            User(
                id=1,
                full_name="Test User One",
                email="one@example.invalid",
                hashed_password="test-only",
            ),
            User(
                id=2,
                full_name="Test User Two",
                email="two@example.invalid",
                hashed_password="test-only",
            ),
        ])
        db.commit()

        db.add_all([
            Notification(
                id=1,
                user_id=1,
                title="Collection reminder",
                message="Separate your waste.",
                notification_type="collection",
                is_read=False,
                created_at=datetime(2026, 11, 1, 8),
            ),
            Notification(
                id=2,
                user_id=1,
                title="Report update",
                message="Your report is being reviewed.",
                notification_type="report",
                is_read=False,
                created_at=datetime(2026, 11, 2, 8),
            ),
            Notification(
                id=3,
                user_id=1,
                title="Previous update",
                message="Already read notification.",
                notification_type="report",
                is_read=True,
                created_at=datetime(2026, 10, 31, 8),
            ),
            Notification(
                id=4,
                user_id=2,
                title="Other user's notification",
                message="Private to user two.",
                notification_type="report",
                is_read=False,
                created_at=datetime(2026, 11, 3, 8),
            ),
        ])
        db.commit()

    test_app = FastAPI()
    test_app.include_router(router, prefix="/api/v1")

    def override_db():
        with TestSession() as db:
            yield db

    test_app.dependency_overrides[get_db] = override_db
    test_app.dependency_overrides[get_notification_user_id] = lambda: 1

    try:
        with TestClient(test_app) as test_client:
            yield test_client
    finally:
        test_app.dependency_overrides.clear()
        engine.dispose()


def test_list_only_returns_current_users_notifications(client):
    response = client.get("/api/v1/notifications")

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 3
    assert [item["id"] for item in data["items"]] == [2, 1, 3]


def test_pagination(client):
    response = client.get(
        "/api/v1/notifications",
        params={"offset": 1, "limit": 1},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 3
    assert data["offset"] == 1
    assert data["limit"] == 1
    assert [item["id"] for item in data["items"]] == [1]


def test_unread_filter(client):
    response = client.get(
        "/api/v1/notifications",
        params={"unread_only": True},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert {item["id"] for item in data["items"]} == {1, 2}
    assert all(not item["is_read"] for item in data["items"])


def test_notification_details(client):
    response = client.get("/api/v1/notifications/1")

    assert response.status_code == 200
    assert response.json()["title"] == "Collection reminder"
    assert response.json()["is_read"] is False


@pytest.mark.parametrize("notification_id", [4, 999])
def test_other_users_and_missing_details_return_404(
    client, notification_id
):
    response = client.get(
        f"/api/v1/notifications/{notification_id}"
    )

    assert response.status_code == 404


def test_unread_count(client):
    response = client.get("/api/v1/notifications/unread-count")

    assert response.status_code == 200
    assert response.json() == {"unread_count": 2}


def test_mark_as_read_persists_and_is_repeatable(client):
    url = "/api/v1/notifications/1/read"

    response = client.patch(url)
    assert response.status_code == 200
    assert response.json()["is_read"] is True

    assert client.get(
        "/api/v1/notifications/1"
    ).json()["is_read"] is True

    assert client.get(
        "/api/v1/notifications/unread-count"
    ).json() == {"unread_count": 1}

    assert client.patch(url).status_code == 200
    assert client.get(
        "/api/v1/notifications/unread-count"
    ).json() == {"unread_count": 1}


@pytest.mark.parametrize("notification_id", [4, 999])
def test_cannot_mark_other_users_or_missing_notifications(
    client, notification_id
):
    response = client.patch(
        f"/api/v1/notifications/{notification_id}/read"
    )

    assert response.status_code == 404

    # Switch identity only inside this isolated test application.
    client.app.dependency_overrides[
        get_notification_user_id
    ] = lambda: 2

    assert client.get(
        "/api/v1/notifications/4"
    ).json()["is_read"] is False


def test_mark_all_only_updates_current_users_notifications(client):
    response = client.patch("/api/v1/notifications/read-all")

    assert response.status_code == 200
    assert response.json() == {"updated_count": 2}

    assert client.get(
        "/api/v1/notifications/unread-count"
    ).json() == {"unread_count": 0}

    assert client.patch(
        "/api/v1/notifications/read-all"
    ).json() == {"updated_count": 0}

    client.app.dependency_overrides[
        get_notification_user_id
    ] = lambda: 2

    assert client.get(
        "/api/v1/notifications/unread-count"
    ).json() == {"unread_count": 1}


@pytest.mark.parametrize(
    "params",
    [
        {"offset": -1},
        {"limit": 0},
        {"limit": 101},
    ],
)
def test_invalid_pagination_returns_422(client, params):
    response = client.get(
        "/api/v1/notifications",
        params=params,
    )

    assert response.status_code == 422


def test_user_with_no_notifications(client):
    client.app.dependency_overrides[
        get_notification_user_id
    ] = lambda: 999

    response = client.get("/api/v1/notifications")

    assert response.status_code == 200
    assert response.json()["items"] == []
    assert response.json()["total"] == 0

    assert client.get(
        "/api/v1/notifications/unread-count"
    ).json() == {"unread_count": 0}


def test_pending_authentication_blocks_access(client):
    client.app.dependency_overrides.pop(
        get_notification_user_id
    )

    response = client.get("/api/v1/notifications")

    assert response.status_code == 503
    assert response.json() == {
        "detail": "Notification authentication integration is pending."
    }