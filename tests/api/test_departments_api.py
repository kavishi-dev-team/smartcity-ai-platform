from datetime import datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.db.session import Base, get_db
import app.models as all_models  # noqa: F401 - registers metadata
from app.models.department import Department
from app.models.issue import Issue
from app.models.issue_location import IssueLocation


@pytest.fixture()
def client():
    engine = create_engine('sqlite+pysqlite://',
                           connect_args={'check_same_thread': False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    with Session() as db:
        db.add_all([
            Department(id=1, name='Traffic Control', description='Manages signals',
                       responsibilities='Traffic signals and road safety',
                       contact_email='traffic@example.org', contact_phone='0110000000',
                       office_address='Main Road', office_city='Galle',
                       office_latitude=6.05, office_longitude=80.22,
                       operating_hours='Mon-Fri 08:00-16:00', is_active=True),
            Department(id=2, name='Road Maintenance', is_active=True),
            Department(id=3, name='Private archive', is_active=False),
        ])
        db.flush()
        db.add_all([
            Issue(id=1, title='Broken signal', description='Red signal failed', category='traffic',
                  status='reported', priority='high', reported_by=1, department_id=1, is_active=True,
                  created_at=datetime(2026, 10, 20), updated_at=datetime(2026, 10, 20)),
            Issue(id=2, title='Road blocked', description='Road surface broken', category='traffic',
                  status='in_progress', priority='medium', reported_by=1, department_id=1, is_active=True,
                  created_at=datetime(2026, 10, 21), updated_at=datetime(2026, 10, 21)),
            Issue(id=3, title='Waste bin', description='Overflow', category='waste',
                  status='reported', priority='low', reported_by=1, department_id=1, is_active=True),
            Issue(id=4, title='Hidden report', description='Old traffic', category='traffic',
                  status='reported', priority='low', reported_by=1, department_id=1, is_active=False),
            Issue(id=5, title='Road at Galle', description='Pothole', category='traffic',
                  status='reported', priority='low', reported_by=1, department_id=2, is_active=True),
            Issue(id=6, title='Archived department issue', description='Hidden', category='traffic',
                  status='reported', priority='low', reported_by=1, department_id=3, is_active=True),
        ])
        db.flush()
        db.add_all([
            IssueLocation(issue_id=1, latitude=6.05, longitude=80.21, address='Old street', city='Galle'),
            IssueLocation(issue_id=1, latitude=6.06, longitude=80.23, address='Latest street', city='Galle'),
        ])
        db.commit()

    def override():
        with Session() as db:
            yield db

    app.dependency_overrides[get_db] = override
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_db, None)
        engine.dispose()


def test_directory_active_and_traffic_counts_only(client):
    response = client.get('/api/v1/departments')
    assert response.status_code == 200
    data = response.json()
    assert data['total'] == 2
    assert [d['name'] for d in data['items']] == ['Road Maintenance', 'Traffic Control']
    assert {d['id']: d['traffic_issue_count'] for d in data['items']} == {1: 2, 2: 1}


def test_details_metadata_and_empty_fields(client):
    item = client.get('/api/v1/departments/1').json()
    assert item['responsibilities'] == 'Traffic signals and road safety'
    assert item['contact_email'] == 'traffic@example.org'
    assert item['office_address'] == 'Main Road'
    assert item['office_latitude'] == 6.05
    assert item['operating_hours'] == 'Mon-Fri 08:00-16:00'
    other = client.get('/api/v1/departments/2').json()
    assert other['contact_phone'] is None  # never invent phone numbers
    assert other['office_city'] is None


def test_department_directory_search_and_pagination(client):
    res = client.get('/api/v1/departments', params={'search': 'TRAFFIC'})
    assert res.status_code == 200
    assert res.json()['total'] == 1
    assert res.json()['items'][0]['id'] == 1
    paged = client.get('/api/v1/departments', params={'limit': 1, 'offset': 1}).json()
    assert paged['total'] == 2
    assert paged['items'][0]['id'] == 1


def test_department_issues_only_active_traffic_and_latest_location(client):
    response = client.get('/api/v1/departments/1/issues')
    assert response.status_code == 200
    data = response.json()
    assert data['total'] == 2
    assert {item['id'] for item in data['items']} == {1, 2}
    issue = next(item for item in data['items'] if item['id'] == 1)
    assert issue['location']['address'] == 'Latest street'
    assert issue['department_name'] == 'Traffic Control'


def test_department_reports_pagination_and_other_department(client):
    page = client.get('/api/v1/departments/1/issues?limit=1&offset=1').json()
    assert page['total'] == 2
    assert len(page['items']) == 1
    assert page['items'][0]['id'] == 1
    assert client.get('/api/v1/departments/2/issues').json()['total'] == 1


def test_not_found_inactive_departments(client):
    assert client.get('/api/v1/departments/999').status_code == 404
    assert client.get('/api/v1/departments/3').status_code == 404
    assert client.get('/api/v1/departments/3/issues').status_code == 404


def test_invalid_pagination(client):
    assert client.get('/api/v1/departments?limit=0').status_code == 422
    assert client.get('/api/v1/departments?offset=-1').status_code == 422
    assert client.get('/api/v1/departments/1/issues?limit=101').status_code == 422


def test_previous_traffic_routes_still_available(client):
    assert client.get('/api/v1/issues?category=traffic').status_code == 200
    assert client.get('/api/v1/traffic/map').status_code == 200
