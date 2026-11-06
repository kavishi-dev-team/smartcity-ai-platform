
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.energy import (
    EnergyIssueCreate,
    EnergyIssueListOut,
    EnergyIssueOut,
)
from app.schemas.issue_details import IssueDetailsOut
from app.services import energy_service, issue_details_service

router = APIRouter(prefix="/energy", tags=["Energy"])


# Get all energy reports with search and filters
@router.get("/issues", response_model=EnergyIssueListOut)
def get_energy_issues(
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    subcategory: Optional[str] = Query(None),
    city: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
):
    return energy_service.list_energy_issues(
        db=db,
        search=search,
        status=status,
        priority=priority,
        subcategory=subcategory,
        city=city,
        skip=skip,
        limit=limit,
    )


# Get one energy report with complete details
@router.get("/issues/{issue_id}", response_model=IssueDetailsOut)
def get_issue(
    issue_id: int,
    db: Session = Depends(get_db),
):
    issue = issue_details_service.get_issue_details(db, issue_id)

    if issue is None or issue["category"] != "energy":
        raise HTTPException(
            status_code=404,
            detail="Energy report not found",
        )

    return issue


# Create a new energy report
@router.post(
    "/issues",
    response_model=EnergyIssueOut,
    status_code=201,
)
def create_issue(
    data: EnergyIssueCreate,
    db: Session = Depends(get_db),
):
    return energy_service.create_energy_issue(db, data)
