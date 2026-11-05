from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.issue_details import IssueDetailsOut
from app.schemas.water import WaterIssueCreate
from app.services import issue_details_service, water_service


router = APIRouter(prefix="/water", tags=["Water"])


@router.get("/issues")
def read_water_issues(
    search: str | None = Query(default=None),
    status: str | None = Query(default=None),
    priority: str | None = Query(default=None),
    subcategory: str | None = Query(default=None),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return water_service.list_water_issues(
        db=db,
        search=search,
        status=status,
        priority=priority,
        subcategory=subcategory,
        skip=skip,
        limit=limit,
    )


@router.get("/issues/{issue_id}", response_model=IssueDetailsOut)
def read_water_issue(
    issue_id: int,
    db: Session = Depends(get_db),
):
    issue = issue_details_service.get_issue_details(db, issue_id)

    if issue is None or issue["category"] != "water":
        raise HTTPException(
            status_code=404,
            detail="Water issue not found",
        )

    return issue


@router.post("/issues", status_code=201)
def create_water_issue(
    data: WaterIssueCreate,
    db: Session = Depends(get_db),
):
    return water_service.create_water_issue(db, data)