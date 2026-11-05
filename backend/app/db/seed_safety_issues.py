"""Seed demo safety reports and complaints (plus departments, officers, AI analysis, photos).

Run from the backend folder:
    python -m app.db.seed_safety_issues

Safe to run more than once: it only adds what is missing.
Uses an existing user as the reporter, or creates a demo citizen if none exists.
"""
from datetime import datetime, timedelta, timezone

from sqlalchemy import update

import app.models  # noqa: F401
from app.db.session import SessionLocal
from app.models.ai_analysis import AIAnalysis
from app.models.department import Department
from app.models.department_member import DepartmentMember
from app.models.issue import Issue
from app.models.issue_assignment import IssueAssignment
from app.models.issue_attachment import IssueAttachment
from app.models.issue_comment import IssueComment
from app.models.issue_location import IssueLocation
from app.models.issue_status_history import IssueStatusHistory
from app.models.user import User

FLOW = ["reported", "under_review", "assigned", "in_progress", "resolved"]
NOTES = {
    "reported": "Report submitted by citizen.",
    "under_review": "Report is being reviewed by the safety team.",
    "assigned": "Assigned to the responsible department.",
    "in_progress": "Work has started on site.",
    "resolved": "Problem fixed and verified.",
    "rejected": "Report could not be verified.",
}

# (title, description, category, priority, status, created_hours_ago, resolve_after_hours, address, city, lat, lng)
ISSUES = [
    ("Unsafe crossing", "No crossing signal and vehicles do not stop for pedestrians near the school gate.", "safety", "high", "in_progress", 50, None, "Galle Road", "Colombo 3", 6.9022, 79.8530),
    ("Damaged barrier", "Roadside safety barrier is broken and leaning onto the footpath.", "safety", "medium", "under_review", 75, None, "Baseline Road", "Colombo 9", 6.9271, 79.8774),
    ("Dark pedestrian path", "Several lamps are not working along the footpath, unsafe after dark.", "safety", "high", "reported", 26, None, "Park Road", "Colombo 5", 6.8911, 79.8651),
    ("Open drain", "Uncovered drain beside the bus stop. A child could fall in.", "safety", "critical", "assigned", 40, None, "Kandy Road", "Kadawatha", 7.0010, 79.9503),
    ("Broken street light", "Street light has been flickering and is now completely off.", "safety", "medium", "resolved", 90, 30, "High Level Road", "Nugegoda", 6.8649, 79.8997),
    ("Exposed wiring near school", "Loose electrical wires hanging from a pole next to the school wall.", "safety", "critical", "in_progress", 30, None, "Temple Road", "Mount Lavinia", 6.8389, 79.8653),
    ("Loose manhole cover", "Manhole cover moves when vehicles pass and makes a loud noise.", "safety", "high", "resolved", 70, 20, "Duplication Road", "Colombo 4", 6.8935, 79.8573),
    ("Blocked emergency exit", "Market emergency exit is blocked by stored goods.", "safety", "medium", "reported", 8, None, "Main Street", "Pettah", 6.9344, 79.8528),
    ("Unsafe construction site", "No safety fencing around an excavation next to the road.", "safety", "high", "under_review", 20, None, "Sri Jayawardenepura Road", "Rajagiriya", 6.9100, 79.8947),
    ("Missing road sign", "Stop sign was knocked down and never replaced at the junction.", "safety", "low", "resolved", 120, 60, "Station Road", "Dehiwala", 6.8518, 79.8650),
    ("Flooded underpass", "Underpass fills with water after rain and cars get stuck.", "safety", "high", "resolved", 200, 100, "Havelock Road", "Colombo 6", 6.8791, 79.8660),
    ("Stray dog pack near park", "A group of aggressive stray dogs near the children's play area.", "safety", "medium", "rejected", 55, None, "Independence Avenue", "Colombo 7", 6.9017, 79.8669),
    ("Slippery pedestrian bridge", "Metal surface of the pedestrian bridge is very slippery when wet.", "safety", "medium", "resolved", 80, 40, "Kotte Road", "Rajagiriya", 6.9106, 79.8919),
    ("Fallen tree branch", "Large branch hanging over the footpath after the storm.", "safety", "low", "resolved", 40, 12, "Bauddhaloka Mawatha", "Colombo 7", 6.9099, 79.8648),
    ("Noisy night construction", "Construction work continues past midnight every day.", "complaint", "medium", "in_progress", 60, None, "Hospital Road", "Kandy", 7.2906, 80.6337),
    ("Unsafe taxi driving", "Taxi drivers speeding and ignoring signals at the bus terminal.", "complaint", "high", "reported", 10, None, "Main Street", "Galle", 6.0329, 80.2168),
    ("Delayed emergency response", "Ambulance took over 40 minutes to arrive after the call.", "complaint", "critical", "under_review", 45, None, "Hospital Road", "Jaffna", 9.6615, 80.0255),
    ("Poor lighting at bus stand", "Bus stand is dark at night and people feel unsafe waiting.", "complaint", "medium", "resolved", 100, 36, "Bus Stand Road", "Kandy", 7.2931, 80.6350),
    ("Aggressive bus driver", "Bus driver shouted at passengers and refused to stop at the marked stop.", "complaint", "medium", "reported", 6, None, "Hospital Road", "Kandy", 7.2900, 80.6340),
    ("Noise from night market", "Loud music from the night market continues until 2 AM.", "complaint", "low", "rejected", 70, None, "Bus Stand Road", "Kandy", 7.2925, 80.6355),
]

DEPARTMENTS = [
    ("Road Safety & Traffic", "Road signs, crossings, barriers and traffic safety."),
    ("Public Works", "Drains, manholes, bridges and public structures."),
    ("Electricity Board", "Street lighting and exposed wiring."),
    ("Environmental & Public Health", "Noise, animals, flooding and public health."),
]
OFFICERS = [
    ("Nimal Perera", "nimal.officer@smartcity.local", "Senior Officer"),
    ("Ayesha Fernando", "ayesha.officer@smartcity.local", "Field Inspector"),
    ("Kasun Silva", "kasun.officer@smartcity.local", "Safety Inspector"),
    ("Dilani Jayasinghe", "dilani.officer@smartcity.local", "Case Officer"),
]
PHOTO_TITLES = {
    "Unsafe crossing", "Open drain", "Exposed wiring near school",
    "Unsafe construction site", "Noisy night construction", "Unsafe taxi driving",
}


def _path(status: str) -> list[str]:
    if status == "rejected":
        return ["reported", "under_review", "rejected"]
    return FLOW[: FLOW.index(status) + 1]


def _reporter(db) -> User:
    user = db.query(User).filter(User.role.in_(["citizen", "CITIZEN"])).first() or db.query(User).first()
    if user is None:
        user = User(
            full_name="Demo Citizen",
            email="demo.citizen@smartcity.local",
            hashed_password="not-a-real-password-hash",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def _seed_issues(db, user: User, now: datetime) -> int:
    existing = {t for (t,) in db.query(Issue.title).filter(Issue.category.in_(["safety", "complaint"])).all()}
    created_count = 0
    for i, (title, desc, cat, prio, status, created_h, resolve_h, addr, city, lat, lng) in enumerate(ISSUES):
        if title in existing:
            continue
        created = now - timedelta(hours=created_h)
        if status == "resolved" and resolve_h is not None:
            updated = created + timedelta(hours=resolve_h)
        else:
            updated = now - timedelta(minutes=12 + 22 * (i % 4))  # "updated 12 / 34 / 56 min ago"
        updated = max(updated, created)

        issue = Issue(
            title=title, description=desc, category=cat, status=status,
            priority=prio, reported_by=user.id, is_active=True,
            created_at=created, updated_at=updated,
        )
        db.add(issue)
        db.flush()

        db.add(IssueLocation(
            issue_id=issue.id, latitude=lat, longitude=lng,
            address=addr, city=city, created_at=created,
        ))

        steps = _path(status)
        span = (updated - created) / max(1, len(steps) - 1)
        previous = None
        for n, step in enumerate(steps):
            db.add(IssueStatusHistory(
                issue_id=issue.id, changed_by=user.id,
                previous_status=previous, new_status=step,
                note=NOTES[step], created_at=created + span * n,
            ))
            previous = step
        created_count += 1
    db.commit()
    return created_count


def _seed_people(db) -> list[Department]:
    """Departments (only if none exist) and demo officers that belong to them."""
    if db.query(Department).count() == 0:
        for name, desc in DEPARTMENTS:
            db.add(Department(name=name, description=desc, is_active=True))
        db.commit()
    departments = db.query(Department).filter(Department.is_active.is_(True)).order_by(Department.id).all()
    if not departments:
        return []

    for n, (full_name, email, position) in enumerate(OFFICERS):
        user = db.query(User).filter(User.email == email).first()
        if user is None:
            user = User(
                full_name=full_name, email=email,
                hashed_password="not-a-real-password-hash",
                role="DEPARTMENT_OFFICER",
            )
            db.add(user)
            db.flush()
        dept = departments[n % len(departments)]
        has = db.query(DepartmentMember).filter(
            DepartmentMember.user_id == user.id, DepartmentMember.department_id == dept.id
        ).first()
        if has is None:
            db.add(DepartmentMember(department_id=dept.id, user_id=user.id, position=position, is_active=True))

    # the dev officer from Member 1's seed (if present) also joins the first department
    dev = db.query(User).filter(User.email == "officer@smartcity-dev.com").first()
    if dev and not db.query(DepartmentMember).filter(DepartmentMember.user_id == dev.id).first():
        db.add(DepartmentMember(department_id=departments[0].id, user_id=dev.id, position="Duty Officer", is_active=True))
    db.commit()
    return departments


def _seed_extras(db, departments: list[Department], reporter: User, now: datetime) -> None:
    """AI analysis, photos, assignments and internal notes for the demo issues."""
    for i, (title, _d, cat, prio, status, created_h, _r, *_rest) in enumerate(ISSUES):
        issue = db.query(Issue).filter(Issue.title == title, Issue.category == cat).first()
        if issue is None:
            continue
        created = issue.created_at

        if not db.query(AIAnalysis).filter(AIAnalysis.issue_id == issue.id).first():
            db.add(AIAnalysis(
                issue_id=issue.id, analysis_type="priority_analysis",
                result={
                    "suggested_category": cat,
                    "recommended_priority": prio,
                    "severity": prio,
                    "safety_risk": "High" if prio in ("high", "critical") else "Moderate",
                },
                explanation=(
                    f"The description of '{title}' mentions hazards to people on the road. "
                    f"Reports like this are usually treated as {prio} priority."
                ),
                model_name="demo-seed", confidence_score=78 + (i * 3) % 20,
            ))

        if title in PHOTO_TITLES and not db.query(IssueAttachment).filter(IssueAttachment.issue_id == issue.id).first():
            db.add(IssueAttachment(
                issue_id=issue.id, uploaded_by=reporter.id,
                file_name=f"photo-{issue.id}.jpg",
                file_url=f"https://picsum.photos/seed/smartcity{issue.id}/800/500",
                file_type="image/jpeg", file_size=120000,
            ))

        if departments and status in ("assigned", "in_progress", "resolved") \
                and not db.query(IssueAssignment).filter(IssueAssignment.issue_id == issue.id).first():
            dept = departments[i % len(departments)]
            member = db.query(DepartmentMember).filter(
                DepartmentMember.department_id == dept.id, DepartmentMember.is_active.is_(True)
            ).first()
            if member:
                # Core UPDATE with an explicit updated_at, so the column's onupdate=now()
                # does not overwrite the demo timestamps.
                db.execute(update(Issue).where(Issue.id == issue.id).values(
                    department_id=dept.id, updated_at=issue.updated_at))
                db.add(IssueAssignment(
                    issue_id=issue.id, assigned_to=member.user_id, assigned_by=member.user_id,
                    department_id=dept.id, status="assigned",
                    note="Please inspect and fix as soon as possible.",
                    assigned_at=created + timedelta(hours=1),
                ))
                if status in ("in_progress", "under_review") and not db.query(IssueComment).filter(IssueComment.issue_id == issue.id).first():
                    db.add(IssueComment(
                        issue_id=issue.id, user_id=member.user_id,
                        comment="Site visit done. Waiting for materials before work can start.",
                        created_at=now - timedelta(hours=2),
                    ))
    db.commit()


def run():
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc).replace(tzinfo=None)  # naive UTC, matches MySQL
        reporter = _reporter(db)
        added = _seed_issues(db, reporter, now)
        departments = _seed_people(db)
        _seed_extras(db, departments, reporter, now)
        print(f"Added {added} new reports/complaints. "
              f"Departments: {len(departments)}. Extras (AI analysis, photos, assignments) are up to date.")
    finally:
        db.close()


if __name__ == "__main__":
    run()
