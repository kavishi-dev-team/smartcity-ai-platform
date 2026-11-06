from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class AIChatSessionCreate(BaseModel):
    title: Optional[str] = Field(default=None, max_length=200)


class AIChatSessionResponse(BaseModel):
    id: int
    user_id: int
    title: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AIChatMessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=5000)


class AIChatMessageResponse(BaseModel):
    id: int
    session_id: int
    role: str
    content: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AIChatHistoryResponse(BaseModel):
    session: AIChatSessionResponse
    messages: List[AIChatMessageResponse]


class AIChatReplyResponse(BaseModel):
    user_message: AIChatMessageResponse
    assistant_message: AIChatMessageResponse
