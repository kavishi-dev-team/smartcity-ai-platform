from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


class IssueClusterResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    city: Optional[str] = None
    center_latitude: Optional[float] = None
    center_longitude: Optional[float] = None
    status: str
    issue_count: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ClusterIssueResponse(BaseModel):
    id: int
    title: str
    description: str
    category: str
    status: str
    priority: str
    similarity_score: Optional[float] = None
    created_at: datetime


class ClusterIssuesResponse(BaseModel):
    cluster_id: int
    cluster_name: str
    issues: List[ClusterIssueResponse]
