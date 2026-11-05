from typing import List

from pydantic import BaseModel, Field


class PossibleDuplicate(BaseModel):
    issue_id: int
    title: str
    similarity: float = Field(ge=0.0, le=1.0)


class AIAnalysisResponse(BaseModel):
    issue_id: int
    category: str
    category_confidence: float = Field(ge=0.0, le=1.0)
    priority: str
    matched_keywords: List[str]
    summary: str
    is_duplicate: bool
    possible_duplicates: List[PossibleDuplicate]
