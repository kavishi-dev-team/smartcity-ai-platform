from fastapi import APIRouter

from app.api.v1.endpoints import air_quality, safety_alerts

api_router = APIRouter()

api_router.include_router(air_quality.router)
api_router.include_router(safety_alerts.router)
# Teammates add their routers below, same pattern:
# api_router.include_router(traffic.router)
