"""Member 2 traffic module end-to-end read API tests (in-memory SQLite)."""
from datetime import datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.db.session import Base, get_db
from app.models.department import Department
from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.models.issue_status_history import IssueStatusHistory
from app.models.issue_attachment import IssueAttachment
from app.models.ai_analysis import AIAnalysis


@pytest.fixture()
def client(monkeypatch):
    engine = create_engine(
        'sqlite+pysqlite://',
        connect_args={'check_same_thread': False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    testing_session = sessionmaker(bind=engine)
    db = testing_session()
    dept = Department(id=1, name='Road Maintenance')
    db.add(dept)
    db.flush()
    db.add_all([
        Issue(id=1, title='Broken signal', description='Signal at market not working', category='traffic',
              status='reported', priority='high', reported_by=1, department_id=1, is_active=True,
              created_at=datetime(2026, 10, 20, 10), updated_at=datetime(2026, 10, 20, 11)),
        Issue(id=2, title='Blocked road', description='Accident near school', category='traffic',
              status='in_progress', priority='low', reported_by=1, is_active=True,
              created_at=datetime(2026, 10, 18, 10), updated_at=datetime(2026, 10, 18, 11)),
        Issue(id=3, title='Overflowing bin', description='Waste in market', category='waste',
              status='reported', priority='high', reported_by=1, is_active=True),
        Issue(id=4, title='Inactive signal', description='This item is archived', category='traffic',
              status='reported', priority='high', reported_by=1, is_active=False),
        Issue(id=5, title='Queue at market', description='Traffic jam near market', category='traffic',
              status='reported', priority='medium', reported_by=1, is_active=True,
              created_at=datetime(2026, 10, 19, 10), updated_at=datetime(2026, 10, 19, 11)),
    ])
    db.flush()
    db.add_all([
        IssueLocation(issue_id=1, latitude=6.05, longitude=80.2, city='Galle', address='Market Road'),
        IssueLocation(issue_id=2, latitude=7.0, longitude=80.0, city='Kandy'),
        IssueLocation(issue_id=5, latitude=6.06, longitude=80.2, city='Galle'),
        IssueAttachment(issue_id=1, uploaded_by=1, file_name='signal.jpg', file_url='https://example.com/signal.jpg'),
        IssueStatusHistory(issue_id=1, changed_by=1, previous_status=None, new_status='reported', note='Created'),
        AIAnalysis(issue_id=1, analysis_type='traffic', result={'priority':'high'}, explanation='Traffic light malfunction'),
    ])
    db.commit()
    db.close()

    def override():
        session = testing_session()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()
        engine.dispose()


def test_traffic_list_excludes_other_categories_and_inactive(client):
    response = client.get('/api/v1/issues?category=traffic')
    assert response.status_code == 200
    result = response.json()
    assert result['total'] == 3
    assert {item['id'] for item in result['items']} == {1, 2, 5}
    assert result['items'][0]['id'] == 1


def test_search_priority_city_status_filters(client):
    response = client.get('/api/v1/issues', params={
        'search': 'signal', 'priority': 'high', 'status': 'reported', 'city': 'galle'
    })
    assert response.status_code == 200
    result = response.json()
    assert result['total'] == 1
    assert result['items'][0]['title'] == 'Broken signal'
    assert result['items'][0]['department_name'] == 'Road Maintenance'
    assert result['items'][0]['location']['city'] == 'Galle'


def test_date_and_pagination(client):
    response = client.get('/api/v1/issues', params={'date_from': '2026-10-19', 'date_to': '2026-10-19'})
    assert response.status_code == 200
    assert response.json()['total'] == 1
    assert response.json()['items'][0]['id'] == 5
    paged = client.get('/api/v1/issues', params={'limit': 1, 'offset': 1}).json()
    assert paged['total'] == 3
    assert len(paged['items']) == 1
    assert paged['items'][0]['id'] == 5


def test_traffic_details_photos_history_ai_and_related(client):
    response = client.get('/api/v1/issues/1')
    assert response.status_code == 200
    data = response.json()
    assert data['location']['address'] == 'Market Road'
    assert data['photos'][0]['file_name'] == 'signal.jpg'
    assert data['status_history'][0]['new_status'] == 'reported'
    assert data['ai_summary'] == 'Traffic light malfunction'
    assert [issue['id'] for issue in data['similar_issues']] == [5]


def test_invalid_requests_and_non_traffic_details(client):
    assert client.get('/api/v1/issues/3').status_code == 404
    assert client.get('/api/v1/issues/999').status_code == 404
    assert client.get('/api/v1/issues?category=waste').status_code == 400
    assert client.get('/api/v1/issues?limit=0').status_code == 422
    assert client.get('/api/v1/issues?date_from=2026-10-21&date_to=2026-10-20').status_code == 422


def test_empty_results(client):
    response = client.get('/api/v1/issues?search=nonexistent-item')
    assert response.status_code == 200
    assert response.json()['items'] == []
    assert response.json()['total'] == 0


def test_traffic_map_markers_use_real_locations(client):
    response = client.get('/api/v1/traffic/map')
    assert response.status_code == 200
    data = response.json()
    assert data['total'] == 3
    assert len(data['items']) == 3
    by_id = {item['id']: item for item in data['items']}
    assert set(by_id) == {1, 2, 5}
    assert by_id[1]['location']['latitude'] == 6.05
    assert by_id[1]['status'] == 'reported'
    assert 'location' in by_id[2]


def test_traffic_map_latest_location_and_filter(client):
    # Client shares in-memory SQLite via dependency override.
    from app.db.session import get_db
    generator = app.dependency_overrides[get_db]()
    db = next(generator)
    try:
        db.add(IssueLocation(issue_id=1, latitude=6.10, longitude=80.30,
                             city='Matara', address='New junction'))
        db.commit()
    finally:
        generator.close()
    response = client.get('/api/v1/traffic/map', params={'city': 'matara', 'status': 'reported'})
    assert response.status_code == 200
    data = response.json()
    assert data['total'] == 1
    assert data['items'][0]['id'] == 1
    assert data['items'][0]['location']['address'] == 'New junction'
    assert client.get('/api/v1/traffic/map?limit=0').status_code == 422


def test_traffic_map_excludes_invalid_coordinates(client):
    from app.db.session import get_db
    generator = app.dependency_overrides[get_db]()
    db = next(generator)
    try:
        db.add(IssueLocation(issue_id=1, latitude=100.0, longitude=80.30,
                             city='Galle', address='Invalid latitude'))
        db.commit()
    finally:
        generator.close()
    response = client.get('/api/v1/traffic/map')
    assert response.status_code == 200
    assert response.json()['total'] == 2
    assert 1 not in [x['id'] for x in response.json()['items']]
