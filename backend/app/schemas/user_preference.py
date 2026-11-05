from typing import Literal

from pydantic import BaseModel, ConfigDict


class PreferenceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    push_notifications_enabled: bool
    email_notifications_enabled: bool
    report_status_notifications: bool
    nearby_issue_alerts: bool
    safety_alerts_enabled: bool
    language: str
    text_size: str
    high_contrast: bool
    reduce_animations: bool


class PreferenceUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    push_notifications_enabled: bool | None = None
    email_notifications_enabled: bool | None = None
    report_status_notifications: bool | None = None
    nearby_issue_alerts: bool | None = None
    safety_alerts_enabled: bool | None = None
    language: Literal["en", "si", "ta"] | None = None
    text_size: Literal["small", "medium", "large"] | None = None
    high_contrast: bool | None = None
    reduce_animations: bool | None = None