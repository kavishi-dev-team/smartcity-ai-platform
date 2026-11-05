from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.dashboard import (
    CitizenDashboardResponse,
    OfficerDashboardResponse,
)
from app.services.dashboard_service import (
    get_citizen_dashboard,
    get_officer_dashboard,
)

router = APIRouter()


@router.get(
    "/citizen",
    response_model=CitizenDashboardResponse,
)
def citizen_dashboard(
    user_id: int,
    db: Session = Depends(get_db),
):
    return get_citizen_dashboard(db, user_id)


@router.get(
    "/officer",
    response_model=OfficerDashboardResponse,
)
def officer_dashboard(
    db: Session = Depends(get_db),
):
    return get_officer_dashboard(db)
