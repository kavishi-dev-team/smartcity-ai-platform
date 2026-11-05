
from fastapi import FastAPI

from app.api.v1.endpoints import (
    energy,
    water,
    energy_water_analytics,
    assignments,
    departments,
    issues,
    analytics_issues,
)

app = FastAPI(
    title="Smart City AI Platform API",
    description="Backend API for the Smart City Management Platform",
    version="1.0.0",
)

# Energy and Water APIs
app.include_router(energy.router, prefix="/api/v1")
app.include_router(water.router, prefix="/api/v1")

# Existing Energy and Water Statistics API
app.include_router(
    energy_water_analytics.router,
    prefix="/api/v1",
)

# Department Assignment APIs
app.include_router(assignments.router, prefix="/api/v1")
app.include_router(departments.router, prefix="/api/v1")

# Shared Issue Map API
app.include_router(
    issues.router,
    prefix="/api/v1",
)

# Shared Issue Analytics API
app.include_router(
    analytics_issues.router,
    prefix="/api/v1",
)


@app.get("/")
def root():
    return {
        "message": "Smart City AI Platform API is running",
        "status": "success",
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.get("/api/v1")
def api_info():
    return {
        "message": "Smart City API v1",
        "modules": [
            "Authentication",
            "Traffic Management",
            "Waste Management",
            "Energy Management",
            "Water Management",
            "Air Quality",
            "Safety and Complaints",
            "AI and Analytics",
        ],
    }
