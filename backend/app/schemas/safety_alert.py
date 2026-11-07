from datetime import datetime, timezone
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

Severity = Literal["low", "medium", "high", "critical"]


def _as_utc(value: datetime) -> datetime:
    # MySQL returns naive datetimes; mark them as UTC so the app parses them correctly.
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


class SafetyAlertCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str = Field(min_length=3)
    alert_type: str = Field(min_length=2, max_length=100)
    severity: Severity = "medium"
    area: str = Field(min_length=2, max_length=150)
    safety_instructions: Optional[str] = None
    issue_id: Optional[int] = None


class SafetyAlertUpdate(BaseModel):
    """All fields optional: send only what you want to change."""
    title: Optional[str] = Field(default=None, min_length=3, max_length=200)
    description: Optional[str] = Field(default=None, min_length=3)
    alert_type: Optional[str] = Field(default=None, min_length=2, max_length=100)
    severity: Optional[Severity] = None
    area: Optional[str] = Field(default=None, min_length=2, max_length=150)
    safety_instructions: Optional[str] = None
    issue_id: Optional[int] = None
    is_active: Optional[bool] = None


class RelatedIssueOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    category: str
    status: str


class SafetyAlertOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    alert_type: str
    severity: str
    area: str
    safety_instructions: Optional[str] = None
    issue_id: Optional[int] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    @field_validator("created_at", "updated_at")
    @classmethod
    def _utc(cls, v: datetime) -> datetime:
        return _as_utc(v)


class SafetyAlertDetailOut(SafetyAlertOut):
    related_issue: Optional[RelatedIssueOut] = None
