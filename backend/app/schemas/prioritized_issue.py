from datetime import datetime
from typing import List

from pydantic import BaseModel, ConfigDict


class PrioritizedIssueResponse(BaseModel):
    issue_id: int
    title: str
    description: str
    category: str
    status: str
    ai_priority: str
    final_priority: str
    review_status: str | None = None
    priority_explanation: str | None = None
    matched_keywords: List[str] = []
    analysis_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
