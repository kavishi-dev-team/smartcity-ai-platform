from datetime import datetime, timedelta, timezone
import base64
import hashlib
import hmac
import json
import time

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import settings
from app.db.session import Base, get_db
from app.main import app
from app.models.ai_analysis import AIAnalysis
from app.models.department import Department
from app.models.department_member import DepartmentMember
from app.models.issue import Issue
from app.models.issue_assignment import IssueAssignment
from app.models.issue_comment import IssueComment
from app.models.issue_priority_review import IssuePriorityReview
from app.models.issue_status_history import IssueStatusHistory
from app.models.user import User


def token(user_id=3, *, expire=300, extra=None):
    header = {'alg': 'HS256', 'typ': 'JWT'}
    payload = {'sub': str(user_id), 'exp': int(time.time()) + expire, 'type': 'access'}
    if extra:
        payload.update(extra)
    enc = lambda obj: base64.urlsafe_b64encode(json.dumps(obj, separators=(',', ':')).encode()).rstrip(b'=').decode()
    signing = f'{enc(header)}.{enc(payload)}'
    digest = hmac.new(settings.SECRET_KEY.encode(), signing.encode(), hashlib.sha256).digest()
    return signing + '.' + base64.urlsafe_b64encode(digest).rstrip(b'=').decode()


@pytest.fixture()
def env():
    engine = create_engine('sqlite+pysqlite://', connect_args={'check_same_thread': False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    with Session() as db:
        db.add_all([
            Department(id=1, name='Roads'), Department(id=2, name='Transport'),
            Department(id=3, name='Inactive', is_active=False),
            User(id=1, full_name='Citizen', email='citizen@example.test', hashed_password='x', role='citizen'),
            User(id=2, full_name='Other Citizen', email='second@example.test', hashed_password='x', role='citizen'),
            User(id=3, full_name='Traffic Officer', email='officer@example.test', hashed_password='x', role='officer'),
            User(id=4, full_name='Transport Officer', email='officer2@example.test', hashed_password='x', role='officer'),
            User(id=5, full_name='Administrator', email='admin@example.test', hashed_password='x', role='admin'),
            User(id=6, full_name='Unassigned Officer', email='unassigned@example.test', hashed_password='x', role='officer'),
            DepartmentMember(user_id=3, department_id=1), DepartmentMember(user_id=4, department_id=2),
            Issue(id=11, title='Signal failure', description='Traffic signal broken', reported_by=1,
                  category='traffic', status='reported', priority='medium', department_id=1, is_active=True),
            Issue(id=12, title='Waste bin', description='Full', reported_by=1, category='waste', status='reported', priority='medium'),
            AIAnalysis(issue_id=11, analysis_type='priority', result={'recommended_priority': 'high'}, explanation='Safety risk'),
        ])
        db.commit()

    def override():
        with Session() as db:
            yield db
    app.dependency_overrides[get_db] = override
    try:
        yield TestClient(app), Session
    finally:
        app.dependency_overrides.clear()
        engine.dispose()


def auth(uid=3):
    return {'Authorization': f'Bearer {token(uid)}'}


def path(suffix=''):
    return f'/api/v1/traffic/officer/issues/11{suffix}'


def test_auth_required_and_citizen_forbidden(env):
    client, _ = env
    assert client.get(path()).status_code == 401
    assert client.get(path(), headers={'Authorization':'Bearer unsigned'}).status_code == 401
    assert client.get(path(), headers={'Authorization':f'Bearer {token(1)}'}).status_code == 403
    assert client.get(path(), headers={'Authorization':f'Bearer {token(6)}'}).status_code == 403
    assert client.get(path(), headers={'Authorization':f'Bearer {token(3,expire=-10)}'}).status_code == 401
    assert client.get(path(), headers={'Authorization':f'Bearer {token(1,extra={"role":"admin"})}'}).status_code == 403
    assert client.get('/api/v1/issues?category=traffic').status_code == 200


def test_management_is_traffic_only_and_staff_option_list(env):
    client, _ = env
    assert client.get('/api/v1/traffic/officer/issues/12', headers=auth()).status_code == 404
    response = client.get(path(), headers=auth())
    assert response.status_code == 200, response.text
    item = response.json()
    assert item['status'] == 'reported' and item['priority'] == 'medium'
    assert item['ai_recommended_priority'] == 'high'
    assert [o['id'] for o in item['officers']] == [3]
    assert {d['id'] for d in item['departments']} == {1, 2}


def test_assign_department_and_officer_persist(env):
    client, Session = env
    assert client.post(path('/department'), headers=auth(), json={'department_id': 99}).status_code == 404
    assert client.post(path('/department'), headers=auth(), json={'department_id': 3}).status_code == 404
    assigned = client.post(path('/department'), headers=auth(), json={'department_id': 2})
    assert assigned.status_code == 200, assigned.text
    assert client.get(path(), headers=auth(4)).json()['department_id'] == 2
    assert client.get(path(), headers=auth(3)).status_code == 403
    assert client.post(path('/department'), headers=auth(4), json={'department_id': 2}).status_code == 409
    assert client.post(path('/officer'), headers=auth(4), json={'officer_id': 3}).status_code == 422
    assign = client.post(path('/officer'), headers=auth(4), json={'officer_id': 4})
    assert assign.status_code == 200, assign.text
    assert client.get(path(), headers=auth(4)).json()['assigned_officer_id'] == 4
    assert client.post(path('/officer'), headers=auth(4), json={'officer_id': 4}).status_code == 409
    with Session() as db:
        assignments = db.query(IssueAssignment).filter(IssueAssignment.issue_id == 11).order_by(IssueAssignment.id).all()
        assert len(assignments) == 2
        assert assignments[0].assigned_to is None and assignments[0].department_id == 2
        assert assignments[1].assigned_to == 4
        assert db.query(Issue).filter(Issue.id == 11).one().department_id == 2


def test_keep_priority_and_override_reasons(env):
    client, Session = env
    assert client.post(path('/priority-review'), headers=auth(), json={'decision': 'override','priority':'critical'}).status_code == 422
    kept = client.post(path('/priority-review'), headers=auth(), json={'decision': 'keep'})
    assert kept.status_code == 200, kept.text
    assert kept.json()['priority'] == 'high'
    over = client.post(path('/priority-review'), headers=auth(), json={
        'decision':'override', 'priority':'critical', 'reason':'School crossing requires rapid repairs'
    })
    assert over.status_code == 200, over.text
    with Session() as db:
        issue = db.get(Issue, 11)
        assert issue.priority == 'critical'
        reviews = db.query(IssuePriorityReview).filter_by(issue_id=11).order_by(IssuePriorityReview.id).all()
        assert len(reviews) == 2
        assert reviews[0].review_status == 'kept' and reviews[1].review_status == 'overridden'
        assert reviews[1].review_note == 'School crossing requires rapid repairs'


def test_no_ai_recommendation_fails_keep_and_allows_manual_override(env):
    client, Session = env
    with Session() as db:
        db.query(AIAnalysis).filter_by(issue_id=11).delete()
        db.commit()
    assert client.post(path('/priority-review'), headers=auth(), json={'decision':'keep'}).status_code == 409
    r = client.post(path('/priority-review'), headers=auth(), json={'decision':'override', 'priority':'high','reason':'Officer inspection'})
    assert r.status_code == 200
    item = client.get(path(), headers=auth()).json()
    assert item['ai_recommended_priority'] is None
    assert item['latest_priority_review']['ai_suggested_priority'] == 'not_available'


def test_status_and_visibility_and_public_timeline(env):
    client, Session = env
    changed = client.patch(path('/status'), headers=auth(), json={
        'status': 'under_review',
        'internal_note': 'Suspected internal investigation',
        'public_update': 'Road team is reviewing the report',
    })
    assert changed.status_code == 200, changed.text
    assert changed.json()['status'] == 'under_review'
    public = client.get('/api/v1/issues/11').json()
    assert public['status'] == 'under_review'
    assert public['status_history'][-1]['note'] == 'Road team is reviewing the report'
    assert 'Suspected internal investigation' not in json.dumps(public)
    officer = client.get(path(), headers=auth()).json()
    assert {c['visibility'] for c in officer['notes']} == {'public','internal'}
    with Session() as db:
        assert db.query(IssueComment).filter_by(visibility='internal').count() == 1
        assert db.query(IssueStatusHistory).filter_by(issue_id=11).count() == 1


def test_citizen_update_is_blocked_and_atomic_no_op(env):
    client, Session = env
    res = client.patch(path('/status'), headers=auth(1), json={'status':'resolved'})
    assert res.status_code == 403
    assert client.patch(path('/status'), headers=auth(), json={}).status_code == 422
    assert client.patch(path('/status'), headers=auth(), json={'status':'reported'}).status_code == 409
    assert client.patch(path('/status'), headers=auth(), json={'status':'made_up'}).status_code == 422
    with Session() as db:
        assert db.get(Issue, 11).status == 'reported'
        assert db.query(IssueComment).count() == 0


def test_all_statuses_and_citizen_public_only(env):
    client, _ = env
    for status in ('submitted', 'under_review', 'assigned', 'in_progress', 'resolved', 'rejected'):
        res = client.patch(path('/status'), headers=auth(), json={'status': status, 'public_update':f'Public notice: {status}'})
        assert res.status_code == 200, (status,res.text)
    assert client.get(path(), headers=auth()).json()['status'] == 'rejected'
    public = client.get('/api/v1/issues/11/history').json()
    assert len(public) == 6
    assert public[-1]['new_status'] == 'rejected'


def test_save_note_without_status_change(env):
    client, Session = env
    r = client.patch(path('/status'), headers=auth(), json={'public_update': 'Still monitoring', 'internal_note':'Private briefing'})
    assert r.status_code == 200, r.text
    with Session() as db:
        issue = db.get(Issue, 11)
        assert issue.status == 'reported'
        assert db.query(IssueStatusHistory).count() == 1
        assert db.query(IssueComment).count() == 2
    assert client.get('/api/v1/issues/11/history').json()[0]['note'] == 'Still monitoring'


def test_nontraffic_mutations_forbidden(env):
    client, Session = env
    assert client.post('/api/v1/traffic/officer/issues/12/department', json={'department_id':2}, headers=auth()).status_code == 404
    assert client.patch('/api/v1/traffic/officer/issues/12/status', json={'status':'resolved'}, headers=auth()).status_code == 404
    with Session() as db:
        assert db.get(Issue,12).status == 'reported'


def test_department_scoped_permissions_prevent_cross_team_mutations(env):
    client, Session = env
    assert client.get(path(), headers=auth(4)).status_code == 403
    assert client.patch(path('/status'), headers=auth(4), json={'status': 'resolved'}).status_code == 403
    assert client.post(path('/priority-review'), headers=auth(4), json={'decision': 'keep'}).status_code == 403
    assert client.post(path('/officer'), headers=auth(4), json={'officer_id': 4}).status_code == 403
    assert client.get(path(), headers=auth(5)).status_code == 200
    with Session() as db:
        assert db.get(Issue,11).status == 'reported'
        assert db.query(IssueAssignment).count() == 0


def test_unassigned_issue_can_only_be_claimed_by_officers_department(env):
    client, Session = env
    with Session() as db:
        db.get(Issue, 11).department_id = None
        db.commit()
    assert client.get(path(), headers=auth(3)).status_code == 200
    assert client.post(path('/department'), headers=auth(3), json={'department_id': 2}).status_code == 403
    assert client.post(path('/department'), headers=auth(3), json={'department_id': 1}).status_code == 200
    assert client.get(path(), headers=auth(3)).status_code == 200


def test_update_public_timeline_never_leaks_internal_notes(env):
    client, _ = env
    assert client.patch(path('/status'), headers=auth(), json={'internal_note':'FOR OFFICERS ONLY'}).status_code == 200
    for p in ('/api/v1/issues/11','/api/v1/issues/11/history','/api/v1/issues?category=traffic'):
        response = client.get(p)
        assert response.status_code == 200, response.text
        assert 'FOR OFFICERS ONLY' not in response.text
