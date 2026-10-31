from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.traffic import TrafficIssueDetailOut, TrafficListOut, TrafficMapOut
from app.services.traffic_service import get_traffic_issue, list_traffic_issues, list_traffic_map_markers

router = APIRouter(prefix="/api/v1", tags=["Traffic - Member 2"])


@router.get("/issues", response_model=TrafficListOut)
def read_traffic_issues(
    category: str = Query(default="traffic", description="Traffic list only; other categories belong to the shared issues API"),
    search: str | None = Query(default=None, max_length=200),
    status: str | None = Query(default=None, max_length=50),
    priority: str | None = Query(default=None, max_length=50),
    city: str | None = Query(default=None, max_length=100),
    date_from: date | None = None,
    date_to: date | None = None,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    if category.strip().lower() != "traffic":
        raise HTTPException(status_code=400, detail="Only traffic reports are available on this endpoint")
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status_code=422, detail="date_from must be on or before date_to")
    return list_traffic_issues(
        db,
        search=search,
        status=status,
        priority=priority,
        city=city,
        date_from=date_from,
        date_to=date_to,
        limit=limit,
        offset=offset,
    )


@router.get("/issues/{issue_id}", response_model=TrafficIssueDetailOut)
def read_traffic_issue(issue_id: int, db: Session = Depends(get_db)):
    issue = get_traffic_issue(db, issue_id)
    if issue is None:
        raise HTTPException(status_code=404, detail="Traffic issue not found")
    return issue


@router.get("/traffic/map", response_model=TrafficMapOut)
def read_traffic_map(
    status: str | None = Query(default=None, max_length=50),
    city: str | None = Query(default=None, max_length=100),
    limit: int = Query(default=500, ge=1, le=500),
    db: Session = Depends(get_db),
):
    """Read-only map markers; no sample values or new database tables."""
    return list_traffic_map_markers(db, status=status, city=city, limit=limit)
