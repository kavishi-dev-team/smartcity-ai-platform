from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.ai_analysis import AIAnalysisResponse
from app.services.ai_analysis_service import analyze_issue
from app.models.ai_analysis import AIAnalysis

router = APIRouter()


@router.post(
    "/analyze-issue/{issue_id}",
    response_model=AIAnalysisResponse,
)
def analyze_issue_endpoint(
    issue_id: int,
    db: Session = Depends(get_db),
):
    result = analyze_issue(db, issue_id)

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Issue not found",
        )

    return result


@router.get(
    "/issues/{issue_id}/analysis",
    response_model=AIAnalysisResponse,
)
def get_issue_analysis(
    issue_id: int,
    db: Session = Depends(get_db),
):
    analysis = (
        db.query(AIAnalysis)
        .filter(AIAnalysis.issue_id == issue_id)
        .order_by(AIAnalysis.id.desc())
        .first()
    )

    if analysis is None:
        raise HTTPException(
            status_code=404,
            detail="AI analysis not found",
        )

    return analysis.result
