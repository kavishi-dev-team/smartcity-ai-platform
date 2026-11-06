from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.safety_alert import (
    SafetyAlertCreate,
    SafetyAlertDetailOut,
    SafetyAlertOut,
    SafetyAlertUpdate,
)
from app.services import safety_alert_service as service

router = APIRouter(prefix="/safety-alerts", tags=["Safety Alerts"])

# TODO (Member 1 auth): POST and PATCH are officer-only. When permissions.py is ready,
# add  officer=Depends(require_officer)  to those two routes. GET stays open to citizens.


@router.get("", response_model=list[SafetyAlertOut])
def list_safety_alerts(
    is_active: Optional[bool] = Query(
        default=None, description="true = active alerts, false = previous alerts"
    ),
    severity: Optional[str] = Query(default=None, pattern="^(low|medium|high|critical)$"),
    area: Optional[str] = None,
    alert_type: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    return service.list_alerts(
        db, is_active=is_active, severity=severity, area=area,
        alert_type=alert_type, date_from=date_from, date_to=date_to,
        limit=limit, offset=offset,
    )


@router.get("/{alert_id}", response_model=SafetyAlertDetailOut)
def get_safety_alert(alert_id: int, db: Session = Depends(get_db)):
    alert = service.get_alert(db, alert_id)
    if alert is None:
        raise HTTPException(status_code=404, detail="Safety alert not found")
    return SafetyAlertDetailOut.model_validate(
        {**SafetyAlertOut.model_validate(alert).model_dump(), "related_issue": alert.issue}
    )


@router.post("", response_model=SafetyAlertOut, status_code=status.HTTP_201_CREATED)
def create_safety_alert(data: SafetyAlertCreate, db: Session = Depends(get_db)):
    try:
        return service.create_alert(db, data)
    except service.InvalidIssueError as e:
        raise HTTPException(status_code=422, detail=str(e))


@router.patch("/{alert_id}", response_model=SafetyAlertOut)
def update_safety_alert(
    alert_id: int, data: SafetyAlertUpdate, db: Session = Depends(get_db)
):
    try:
        alert = service.update_alert(db, alert_id, data)
    except service.InvalidIssueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    if alert is None:
        raise HTTPException(status_code=404, detail="Safety alert not found")
    return alert
