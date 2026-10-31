"""Seed demo safety alerts.

Run from the backend folder:
    python -m app.db.seed_safety_alerts
"""
from datetime import datetime, timedelta, timezone

import app.models  # noqa: F401
from app.db.session import SessionLocal
from app.models.safety_alert import SafetyAlert

# (title, description, type, severity, area, instructions, active, days_ago)
ALERTS = [
    ("Flood warning near river bank",
     "Heavy rain has raised the river level. Low-lying roads may flood within hours.",
     "flood", "critical", "Colombo 4",
     "Avoid low-lying roads. Move vehicles to higher ground. Keep emergency numbers ready.",
     True, 0),
    ("Poor air quality advisory",
     "Air quality has dropped to unhealthy levels due to traffic congestion and dust.",
     "air_quality", "high", "Colombo 1",
     "Limit outdoor activity. Wear a mask outdoors. Keep windows closed.",
     True, 1),
    ("Gas leak reported in market area",
     "A gas leak has been reported near the central market. Emergency crews are on site.",
     "gas_leak", "critical", "Kandy",
     "Stay away from the market area. Do not use open flames. Follow crew instructions.",
     True, 0),
    ("Road closure due to fallen tree",
     "A fallen tree is blocking the main road. Expect heavy delays.",
     "road_hazard", "medium", "Galle",
     "Use alternative routes. Drive slowly near the area.",
     True, 2),
    ("Water supply interruption",
     "Scheduled pipe repairs will interrupt water supply for several hours.",
     "infrastructure", "low", "Jaffna",
     "Store drinking water in advance. Supply will resume after repairs.",
     True, 3),
    ("Landslide risk after heavy rain",
     "Slopes in hilly areas are unstable. Residents should be prepared to evacuate.",
     "landslide", "high", "Kandy",
     "Move away from steep slopes if you notice cracks or tilting trees.",
     False, 9),
    ("Street light outage",
     "Several street lights are out, reducing night visibility on main roads.",
     "infrastructure", "low", "Colombo 1",
     "Take extra care when walking at night. Report any hazards.",
     False, 14),
    ("Dengue awareness alert",
     "Mosquito breeding sites are increasing. Clear stagnant water around homes.",
     "public_health", "medium", "Galle",
     "Remove stagnant water. Use repellent. Seek medical advice for high fever.",
     False, 21),
]


def run():
    db = SessionLocal()
    try:
        if db.query(SafetyAlert).count() > 0:
            print("Safety alerts already seeded, skipping.")
            return
        now = datetime.now(timezone.utc).replace(tzinfo=None)  # naive UTC, matches MySQL
        for title, desc, a_type, severity, area, instr, active, days_ago in ALERTS:
            created = now - timedelta(days=days_ago, hours=2)
            db.add(SafetyAlert(
                title=title, description=desc, alert_type=a_type,
                severity=severity, area=area, safety_instructions=instr,
                is_active=active, created_at=created, updated_at=created,
            ))
        db.commit()
        print(f"Seeded {len(ALERTS)} safety alerts.")
    finally:
        db.close()


if __name__ == "__main__":
    run()
