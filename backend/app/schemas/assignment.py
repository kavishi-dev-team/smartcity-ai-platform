
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class IssueAssignmentCreate(BaseModel):
    issue_id: int
    assigned_to: int
    assigned_by: int
    department_id: int
    note: Optional[str] = None


class IssueAssignmentOut(BaseModel):
    id: int
    issue_id: int
    assigned_to: int
    assigned_by: int
    department_id: int
    status: str
    note: Optional[str] = None
    assigned_at: datetime

    model_config = ConfigDict(from_attributes=True)
