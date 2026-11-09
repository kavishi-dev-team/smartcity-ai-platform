from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import app.models  # noqa: F401  (registers every model so relationships resolve)
from app.api.v1.router import api_router
from app.core.config import settings

from app.api.v1.endpoints.traffic import router as traffic_router
from app.api.v1.endpoints.collection_schedules import (
    router as collection_schedules_router,
)
from app.api.v1.endpoints.notifications import (
    router as notifications_router,
)

from app.api.v1.endpoints import (
    dashboards,
    ai_analysis,
    ai_chat,
    issue_clusters,
    analytics,
    prioritized_issues,
    issue_priority_reviews,
)

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

# Member 6 - Prioritized Issues (must be registered before /issues/{issue_id})
app.include_router(
    prioritized_issues.router,
    prefix="/api/v1/issues",
    tags=["Prioritized Issues"],
)

# Member 6 - Issue Priority Reviews
app.include_router(
    issue_priority_reviews.router,
    prefix="/api/v1/issues",
    tags=["Priority Reviews"],
)

# Shared Issue Map API (also serves waste, traffic, and general issue routes)
app.include_router(
    issues.router,
    prefix="/api/v1",
)

# Shared Issue Analytics API
app.include_router(
    analytics_issues.router,
    prefix="/api/v1",
)


# Existing member routes (auth, users, preferences, air quality, safety, ...)
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

# Member 2 traffic endpoints
app.include_router(traffic_router)

app.include_router(
    collection_schedules_router,
    prefix="/api/v1",
)

app.include_router(
    notifications_router,
    prefix="/api/v1",
)


# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_origins=["*"] if settings.DEBUG else [],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Member 6 - Dashboard
app.include_router(
    dashboards.router,
    prefix="/api/v1/dashboard",
    tags=["Dashboard"],
)

# Member 6 - AI Analysis
app.include_router(
    ai_analysis.router,
    prefix="/api/v1/ai",
    tags=["AI Analysis"],
)

# Member 6 - AI Chat
app.include_router(
    ai_chat.router,
    prefix="/api/v1/ai/chat",
    tags=["AI Chat"],
)

# Member 6 - Issue Clusters
app.include_router(
    issue_clusters.router,
    prefix="/api/v1/issue-clusters",
    tags=["Issue Clusters"],
)

# Member 6 - Analytics
app.include_router(
    analytics.router,
    prefix="/api/v1/analytics",
    tags=["Analytics"],
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
            "Dashboard",
            "AI Analysis",
            "AI Chat",
            "Issue Clusters",
            "Analytics",
            "Prioritized Issues",
            "Priority Reviews",
        ],
    }