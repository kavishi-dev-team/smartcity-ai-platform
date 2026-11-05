from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel
from pydantic import BaseModel, Field

class IssueAttachmentOut(BaseModel):
    id: int
    file_name: str
    file_url: str
    file_type: Optional[str] = None
    created_at: datetime


class AIAnalysisOut(BaseModel):
    id: int
    analysis_type: str
    result: Any
    explanation: Optional[str] = None
    model_name: Optional[str] = None
    confidence_score: Optional[int] = None
    created_at: datetime


class IssueStatusHistoryOut(BaseModel):
    id: int
    previous_status: Optional[str] = None
    new_status: str
    note: Optional[str] = None
    created_at: datetime


class SimilarIssueOut(BaseModel):
    id: int
    title: str
    category: str
    status: str
    priority: str
    similarity_score: Optional[float] = None


class DepartmentOut(BaseModel):
    id: int
    name: str


class IssueDetailsOut(BaseModel):
    id: int
    title: str
    description: str
    category: str
    subcategory: Optional[str] = None
    status: str
    priority: str
    department: Optional[DepartmentOut] = None
    created_at: datetime
    updated_at: datetime
    location: Optional[dict] = None
    attachments: list[IssueAttachmentOut] = Field(default_factory=list)
    ai_analysis: list[AIAnalysisOut] = Field(default_factory=list)
    similar_reports: list[SimilarIssueOut] = Field(default_factory=list)
    status_timeline: list[IssueStatusHistoryOut] = Field(default_factory=list)