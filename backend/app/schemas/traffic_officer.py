from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

StatusValue = Literal['submitted', 'reported', 'under_review', 'assigned', 'in_progress', 'resolved', 'rejected']
PriorityValue = Literal['low', 'medium', 'high', 'critical']


class OfficerOption(BaseModel):
    id: int
    name: str


class OfficerCommentOut(BaseModel):
    id: int
    comment: str
    visibility: Literal['public', 'internal']
    created_at: datetime
    author_name: str


class OfficerPriorityReviewOut(BaseModel):
    ai_suggested_priority: str
    final_priority: str
    review_status: str
    review_note: str | None = None
    reviewed_at: datetime | None = None


class OfficerIssueOut(BaseModel):
    id: int
    title: str
    description: str
    status: str
    priority: str
    department_id: int | None = None
    department_name: str | None = None
    assigned_officer_id: int | None = None
    assigned_officer_name: str | None = None
    ai_recommended_priority: str | None = None
    latest_priority_review: OfficerPriorityReviewOut | None = None
    departments: list[OfficerOption] = Field(default_factory=list)
    officers: list[OfficerOption] = Field(default_factory=list)
    notes: list[OfficerCommentOut] = Field(default_factory=list)


class DepartmentAssignIn(BaseModel):
    department_id: int = Field(gt=0)


class OfficerAssignIn(BaseModel):
    officer_id: int = Field(gt=0)


class PriorityReviewIn(BaseModel):
    decision: Literal['keep', 'override']
    priority: PriorityValue | None = None
    reason: str | None = Field(default=None, max_length=1000)

    @model_validator(mode='after')
    def validate_action(self):
        if self.decision == 'override' and (self.priority is None or not (self.reason or '').strip()):
            raise ValueError('Priority override requires a new priority and a reason')
        if self.decision == 'keep' and self.priority is not None:
            raise ValueError('Keep recommended priority does not take an override value')
        return self


class OfficerUpdateIn(BaseModel):
    status: StatusValue | None = None
    internal_note: str | None = Field(default=None, max_length=3000)
    public_update: str | None = Field(default=None, max_length=3000)

    @model_validator(mode='after')
    def at_least_one_action(self):
        if self.status is None and not (self.internal_note or '').strip() and not (self.public_update or '').strip():
            raise ValueError('Choose a status or enter an update')
        return self
