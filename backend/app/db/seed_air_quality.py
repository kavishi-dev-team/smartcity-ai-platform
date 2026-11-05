"""Seed demo air quality data.

Run from the backend folder:
    python -m app.db.init_db            # creates tables if they don't exist
    python -m app.db.seed_air_quality
"""
import random
from datetime import datetime, timedelta, timezone

import app.models  # noqa: F401
from app.db.session import SessionLocal
from app.models.air_quality_reading import AirQualityReading

AREAS = {"Colombo 1": 55, "Colombo 4": 70, "Kandy": 40, "Galle": 35, "Jaffna": 30}


def run():
    random.seed(42)
    db = SessionLocal()
    try:
        if db.query(AirQualityReading).count() > 0:
            print("Already seeded, skipping.")
            return
        now = datetime.now(timezone.utc).replace(tzinfo=None)  # naive UTC, matches MySQL
        rows = []
        for area, base in AREAS.items():
            for step in range(30 * 8):  # every 3 hours for 30 days
                aqi = max(10, base + random.randint(-20, 30))
                rows.append(AirQualityReading(
                    area=area, aqi=float(aqi),
                    pm2_5=round(aqi * 0.45, 1), pm10=round(aqi * 0.7, 1),
                    carbon_monoxide=round(aqi * 0.02, 2),
                    nitrogen_dioxide=round(aqi * 0.25, 1),
                    ozone=round(aqi * 0.4, 1),
                    source="seed",
                    recorded_at=now - timedelta(hours=3 * step),
                ))
        db.add_all(rows)
        db.commit()
        print(f"Seeded {len(rows)} readings.")
    finally:
        db.close()


if __name__ == "__main__":
    run()
