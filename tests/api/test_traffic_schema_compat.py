"""Regression: existing Traffic APIs must not require new Department columns.

Simulates a local database that has not yet applied Feature 5 migration.
This does NOT change the developer's MySQL database.
"""
import app.models
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.session import Base, get_db
from app.main import app


NEW_COLUMNS = (
    'responsibilities', 'contact_email', 'contact_phone', 'office_address',
    'office_city', 'office_latitude', 'office_longitude', 'operating_hours',
)


def test_traffic_list_and_details_work_before_department_migration():
    engine = create_engine(
        'sqlite+pysqlite://',
        connect_args={'check_same_thread': False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)

    with engine.begin() as conn:
        for column in NEW_COLUMNS:
            conn.exec_driver_sql(f'ALTER TABLE departments DROP COLUMN {column}')
        conn.exec_driver_sql(
            "INSERT INTO departments (id, name, is_active, created_at) "
            "VALUES (1, 'Road Maintenance', 1, CURRENT_TIMESTAMP)"
        )
        conn.exec_driver_sql(
            "INSERT INTO issues (id, title, description, category, status, "
            "priority, reported_by, department_id, is_active, created_at, updated_at) "
            "VALUES (1, 'Broken signal', 'Signal needs repair', 'traffic', "
            "'reported', 'high', 1, 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        )

    Session = sessionmaker(bind=engine)

    def override_db():
        with Session() as db:
            yield db

    app.dependency_overrides[get_db] = override_db
    try:
        with TestClient(app) as client:
            listing = client.get('/api/v1/issues?category=traffic')
            details = client.get('/api/v1/issues/1')
        assert listing.status_code == 200
        assert listing.json()['total'] == 1
        assert listing.json()['items'][0]['department_name'] == 'Road Maintenance'
        assert details.status_code == 200
        assert details.json()['department_name'] == 'Road Maintenance'
    finally:
        app.dependency_overrides.pop(get_db, None)
        engine.dispose()
