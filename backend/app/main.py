from fastapi import FastAPI

from app.api.v1.endpoints.issues import router as issues_router
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints.collection_schedules import (
    router as collection_schedules_router,
)
app = FastAPI(
    title="Smart City AI Platform API",
    description="Backend API for the Smart City Management Platform",
    version="1.0.0",
)
app.include_router(issues_router, prefix="/api/v1")
app.include_router(collection_schedules_router, prefix="/api/v1")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)
app.include_router(
    collection_schedules_router,
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