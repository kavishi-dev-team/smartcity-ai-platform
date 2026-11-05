from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.endpoints.traffic import router as traffic_router

app = FastAPI(
    title="Smart City AI Platform API",
    description="Backend API for the Smart City Management Platform",
    version="1.0.0",
)

# Local Flutter Web development only. Review origin policy before deploying.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_methods=["GET", "POST", "PATCH", "OPTIONS"],
    allow_headers=["*"],
)

# Member 2 traffic endpoints. Other modules can register their own routers later.
app.include_router(traffic_router)

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
