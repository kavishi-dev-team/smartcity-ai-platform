from datetime import datetime, timezone
from typing import Any, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

IssueStatus = Literal[
    "reported", "under_review", "assigned", "in_progress", "resolved", "rejected"
]


def _as_utc(value: datetime) -> datetime:
    # MySQL returns naive datetimes; mark them as UTC so the app parses them correctly.
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


# ------------------------------ summary ------------------------------
class SafetySummaryOut(BaseModel):
    active_alerts: int
    open_reports: int
    resolved_total: int
    # None when there are no resolved reports yet
    resolved_in_sla_percent: Optional[int] = None
    sla_hours: int
    updated_at: datetime


class IssueCountsOut(BaseModel):
    """How many reports are in each status (for the complaint history tabs)."""
    total: int = 0
    reported: int = 0
    under_review: int = 0
    assigned: int = 0
    in_progress: int = 0
    resolved: int = 0
    rejected: int = 0


# ------------------------------ issue pieces ------------------------------
class LocationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None


class SafetyIssueOut(BaseModel):
    id: int
    reference: str  # e.g. SF-2217 / CP-12
    title: str
    description: str
    category: str
    status: str
    priority: str
    address: Optional[str] = None
    city: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    @field_validator("created_at", "updated_at")
    @classmethod
    def _utc(cls, v: datetime) -> datetime:
        return _as_utc(v)


class SafetyIssueListOut(BaseModel):
    items: list[SafetyIssueOut]
    total: int
    page: int
    page_size: int
    total_pages: int


class StatusHistoryOut(BaseModel):
    """One step of the timeline. previous == new means a plain update with no status change."""
    model_config = ConfigDict(from_attributes=True)

    previous_status: Optional[str] = None
    new_status: str
    note: Optional[str] = None
    created_at: datetime

    @field_validator("created_at")
    @classmethod
    def _utc(cls, v: datetime) -> datetime:
        return _as_utc(v)


class DepartmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str


class OfficerOut(BaseModel):
    id: int
    full_name: str
    position: Optional[str] = None


class AssignmentOut(BaseModel):
    department_id: int
    department_name: Optional[str] = None
    assigned_to: int
    assigned_to_name: Optional[str] = None
    assigned_by_name: Optional[str] = None
    status: str
    note: Optional[str] = None
    assigned_at: datetime

    @field_validator("assigned_at")
    @classmethod
    def _utc(cls, v: datetime) -> datetime:
        return _as_utc(v)


class AttachmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    file_name: str
    file_url: str
    file_type: Optional[str] = None


class AIAnalysisOut(BaseModel):
    """Written by the AI module (Member 6). We only display it."""
    analysis_type: str
    recommended_priority: Optional[str] = None
    result: Any = None
    explanation: Optional[str] = None
    confidence_score: Optional[int] = None
    model_name: Optional[str] = None
    created_at: datetime

    @field_validator("created_at")
    @classmethod
    def _utc(cls, v: datetime) -> datetime:
        return _as_utc(v)


class NoteOut(BaseModel):
    id: int
    author_name: Optional[str] = None
    note: str
    created_at: datetime

    @field_validator("created_at")
    @classmethod
    def _utc(cls, v: datetime) -> datetime:
        return _as_utc(v)


class SafetyIssueDetailOut(SafetyIssueOut):
    location: Optional[LocationOut] = None
    history: list[StatusHistoryOut] = Field(default_factory=list)
    department: Optional[DepartmentOut] = None
    assignment: Optional[AssignmentOut] = None
    attachments: list[AttachmentOut] = Field(default_factory=list)
    ai_analysis: Optional[AIAnalysisOut] = None
    related: list[SafetyIssueOut] = Field(default_factory=list)


# ------------------------------ officer inputs ------------------------------
class StatusUpdateIn(BaseModel):
    status: IssueStatus
    # Shown to the citizen in the timeline
    note: Optional[str] = Field(default=None, max_length=1000)


class PublicUpdateIn(BaseModel):
    note: str = Field(min_length=2, max_length=1000)


class InternalNoteIn(BaseModel):
    note: str = Field(min_length=2, max_length=2000)


class AssignmentIn(BaseModel):
    department_id: int
    assigned_to: Optional[int] = None  # an officer of that department
    note: Optional[str] = Field(default=None, max_length=1000)
