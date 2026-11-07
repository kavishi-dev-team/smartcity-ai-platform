"""Optional LOCAL DEVELOPMENT demo data for Member 2 Traffic screens.

From the backend folder: python ../tests/seed_traffic_demo.py --seed
Creates clearly labeled demo issues only in the LOCAL MySQL development database.
Do not run on shared/production databases.
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'backend'))

from app.core.config import settings
from app.db.session import SessionLocal
from app.models.user import User
from app.models.department import Department
from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.models.issue_status_history import IssueStatusHistory


SAMPLES = [
    ('[DEMO] Broken traffic signal', 'Traffic signal at the junction is not working.',
     'reported', 'high', 'Galle', 'Main Junction, Galle', 6.0535, 80.2210),
    ('[DEMO] Road blocked near school', 'A blocked lane has slowed down traffic.',
     'in_progress', 'critical', 'Kandy', 'School Road, Kandy', 7.2906, 80.6337),
    ('[DEMO] Traffic congestion near hospital', 'Long vehicle queue reported during the morning.',
     'resolved', 'medium', 'Galle', 'Hospital Road, Galle', 6.0541, 80.2142),
]


def main():
    parser = argparse.ArgumentParser(description='Seed optional demo traffic issues')
    parser.add_argument('--seed', action='store_true', help='Insert demo traffic data')
    args = parser.parse_args()
    if not args.seed:
        parser.error('Nothing changed. Run with --seed only for an empty local development database.')
    if settings.APP_ENV.lower() != 'development':
        raise SystemExit('Refusing to add demo issues outside APP_ENV=development')
    if not settings.DATABASE_URL.startswith('mysql+pymysql://'):
        raise SystemExit('This demo script expects local MySQL configuration')

    db = SessionLocal()
    try:
        user = db.query(User).filter_by(email='member2-demo@example.invalid').first()
        if user is None:
            # Deliberately unusable password: this demo record cannot authenticate.
            user = User(full_name='Member 2 Local Demo', email='member2-demo@example.invalid',
                        hashed_password='!disabled-demo-account', role='citizen', is_active=False)
            db.add(user)
            db.flush()

        department = db.query(Department).filter_by(name='Traffic Demo Department').first()
        if department is None:
            department = Department(name='Traffic Demo Department',
                                    description='Local test data only', is_active=True)
            db.add(department)
            db.flush()

        added = 0
        for title, description, status, priority, city, address, lat, lng in SAMPLES:
            if db.query(Issue.id).filter_by(title=title, category='traffic').first():
                continue
            issue = Issue(title=title, description=description, category='traffic',
                          status=status, priority=priority, reported_by=user.id,
                          department_id=department.id, is_active=True)
            db.add(issue)
            db.flush()
            db.add(IssueLocation(issue_id=issue.id, latitude=lat, longitude=lng,
                                 address=address, city=city))
            db.add(IssueStatusHistory(issue_id=issue.id, changed_by=user.id,
                                      previous_status=None, new_status=status,
                                      note='Demo data for Member 2 UI testing'))
            added += 1
        db.commit()
        print(f'Added {added} demo traffic issues. Existing demo records were not duplicated.')
        print('Open the Flutter Traffic screen and try searching for [DEMO] or filtering by Galle.')
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == '__main__':
    main()
