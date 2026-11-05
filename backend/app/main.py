from fastapi import FastAPI

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

app.include_router(
    dashboards.router,
    prefix="/api/v1/dashboard",
    tags=["Dashboard"],
)

app.include_router(
    ai_analysis.router,
    prefix="/api/v1/ai",
    tags=["AI Analysis"],
)

app.include_router(
    ai_chat.router,
    prefix="/api/v1/ai/chat",
    tags=["AI Chat"],
)

app.include_router(
    issue_clusters.router,
    prefix="/api/v1/issue-clusters",
    tags=["Issue Clusters"],
)

app.include_router(
    analytics.router,
    prefix="/api/v1/analytics",
    tags=["Analytics"],
)

app.include_router(
    prioritized_issues.router,
    prefix="/api/v1/issues",
    tags=["Prioritized Issues"],
)

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
