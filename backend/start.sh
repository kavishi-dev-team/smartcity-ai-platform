#!/bin/sh
set -e

echo "Waiting for database to be ready..."
python - << 'EOF'
import os
import sys
import time
from sqlalchemy import create_engine, text

db_url = os.getenv("DATABASE_URL")
if not db_url:
    print("DATABASE_URL is not set, skipping wait.")
    sys.exit(0)

max_attempts = 30
for attempt in range(1, max_attempts + 1):
    try:
        engine = create_engine(db_url, pool_pre_ping=True)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print(f"Database connection established successfully on attempt {attempt}.")
        sys.exit(0)
    except Exception as e:
        print(f"Waiting for database ({attempt}/{max_attempts})... {e}")
        time.sleep(2)

print("Timed out waiting for database connection.")
sys.exit(1)
EOF

echo "Applying database migrations..."
alembic upgrade heads

echo "Starting Smart City API..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
