from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings

from app.api.v1.endpoints.issues import router as issues_router
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


app = FastAPI(
    title="Smart City AI Platform API",
    description="Backend API for the Smart City Management Platform",
    version="1.0.0",
)


# Existing member routes
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

app.include_router(issues_router, prefix="/api/v1")

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

# Member 6 - Prioritized Issues
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
