from fastapi import APIRouter

from app.api.v1.endpoints import (
    air_quality,
    auth,
    preferences,
    safety,
    safety_alerts,
    users,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
# preferences must be registered before users so "/users/me/preferences" is matched first
api_router.include_router(
    preferences.router, prefix="/users/me/preferences", tags=["Preferences"]
)
api_router.include_router(users.router, prefix="/users", tags=["Users"])

api_router.include_router(air_quality.router)
api_router.include_router(safety_alerts.router)
api_router.include_router(safety.router)
# Teammates add their routers below, same pattern:
# api_router.include_router(traffic.router)