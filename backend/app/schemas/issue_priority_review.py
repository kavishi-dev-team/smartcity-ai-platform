from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field


PriorityType = Literal["high", "medium", "low"]


class PriorityReviewRequest(BaseModel):
    final_priority: PriorityType
    review_note: Optional[str] = Field(default=None, max_length=1000)


class PriorityReviewResponse(BaseModel):
    id: int
    issue_id: int
    ai_suggested_priority: PriorityType
    final_priority: PriorityType
    reviewed_by: Optional[int] = None
    review_status: str
    review_note: Optional[str] = None
    created_at: datetime
    reviewed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
