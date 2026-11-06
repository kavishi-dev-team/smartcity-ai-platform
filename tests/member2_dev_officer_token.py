"""Local-only Member 2 officer demo setup and signed JWT token helper.

Run from backend folder with venv: python ../tests/member2_dev_officer_token.py --seed --department-id 1
This explicitly writes one demo User + DepartmentMember (if absent) to YOUR LOCAL DB.
Do not deploy as an endpoint, commit its printed token, or run against production.
"""
import argparse
import secrets
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'backend'))

from app.core.config import settings
from app.core.traffic_officer_auth import create_dev_access_token
from app.db.session import SessionLocal
from app.models.department import Department
from app.models.department_member import DepartmentMember
from app.models.user import User

DEMO_EMAIL = 'member2-demo-officer@example.invalid'


def main():
    parser = argparse.ArgumentParser(description='Generate a local-only officer JWT for Member 2 testing')
    parser.add_argument('--seed', action='store_true', help='Create/enable local demo officer and membership')
    parser.add_argument('--department-id', type=int, required=True, help='Existing active Department ID')
    args = parser.parse_args()
    if settings.APP_ENV.lower() not in {'development', 'dev', 'local', 'test', 'testing'}:
        raise SystemExit('REFUSED: do not run this demo tool in production')
    if settings.SECRET_KEY == 'development-only-change-this-secret' or not settings.SECRET_KEY:
        raise SystemExit('Set a unique SECRET_KEY in your private backend/.env first')
    db = SessionLocal()
    try:
        department = db.query(Department).filter(Department.id == args.department_id, Department.is_active.is_(True)).first()
        if department is None:
            raise SystemExit('No active department with that ID. Check the departments table.')
        officer = db.query(User).filter(User.email == DEMO_EMAIL).first()
        if args.seed:
            if officer is None:
                officer = User(
                    full_name='Member 2 Demo Traffic Officer', email=DEMO_EMAIL,
                    # Intentionally not a usable login password. This test account is
                    # authenticated ONLY by this one-time short-lived dev JWT helper.
                    hashed_password=secrets.token_urlsafe(48), role='officer', is_active=True,
                )
                db.add(officer)
                db.flush()
            elif not officer.is_active or (officer.role or '').lower() != 'officer':
                raise SystemExit('Demo email exists with conflicting role/status; refusing to modify account')
            member = db.query(DepartmentMember).filter(
                DepartmentMember.user_id == officer.id,
                DepartmentMember.department_id == department.id,
            ).first()
            if member is None:
                db.add(DepartmentMember(user_id=officer.id, department_id=department.id, position='Demo officer', is_active=True))
            elif not member.is_active:
                raise SystemExit('Demo membership is inactive; refusing to override')
            db.commit()
        if officer is None or not officer.is_active or (officer.role or '').lower() != 'officer':
            raise SystemExit('Demo officer not found. Run once with --seed (development DB only).')
        member = db.query(DepartmentMember).filter(
            DepartmentMember.user_id == officer.id,
            DepartmentMember.department_id == department.id,
            DepartmentMember.is_active.is_(True),
        ).first()
        if member is None:
            raise SystemExit('Demo officer has no active membership in selected department')
        token = create_dev_access_token(officer.id, ttl_minutes=30)
        print(f'Local demo officer ID: {officer.id} | Department: {department.name}')
        print('Temporary access token (valid 30 min; do not commit or share):')
        print(token)
        print('Paste into Officer Access screen. This demo token is NOT a production login.')
    finally:
        db.close()


if __name__ == '__main__':
    main()
