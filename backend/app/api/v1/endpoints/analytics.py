from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.analytics import (
    AnalyticsOverviewResponse,
    IssueAnalyticsResponse,
    DepartmentAnalyticsResponse,
)
from app.services.analytics_service import (
    get_analytics_overview,
    get_issue_analytics,
    get_department_analytics,
)

router = APIRouter()


@router.get("/overview", response_model=AnalyticsOverviewResponse)
def analytics_overview(db: Session = Depends(get_db)):
    return get_analytics_overview(db)


@router.get("/issues", response_model=IssueAnalyticsResponse)
def issue_analytics(db: Session = Depends(get_db)):
    return get_issue_analytics(db)


@router.get("/departments", response_model=DepartmentAnalyticsResponse)
def department_analytics(db: Session = Depends(get_db)):
    return get_department_analytics(db)
