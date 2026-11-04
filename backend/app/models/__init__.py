from app.models.user import User
from app.models.department import Department
from app.models.user_preference import UserPreference
from app.models.user_session import UserSession
from app.models.email_verification import EmailVerification
from app.models.password_reset_token import PasswordResetToken
from app.models.user_device import UserDevice

from app.models.issue import Issue
from app.models.issue_location import IssueLocation
from app.models.issue_comment import IssueComment
from app.models.issue_status_history import IssueStatusHistory
from app.models.issue_assignment import IssueAssignment
from app.models.issue_attachment import IssueAttachment
from app.models.department_member import DepartmentMember
from app.models.notification import Notification

from app.models.ai_analysis import AIAnalysis
from app.models.issue_priority_review import IssuePriorityReview
from app.models.issue_cluster import IssueCluster
from app.models.issue_cluster_member import IssueClusterMember
from app.models.ai_chat_session import AIChatSession
from app.models.ai_chat_message import AIChatMessage

__all__ = [
    "User",
    "Department",
    "UserPreference",
    "UserSession",
    "EmailVerification",
    "PasswordResetToken",
    "UserDevice",
    "Issue",
    "IssueLocation",
    "IssueComment",
    "IssueStatusHistory",
    "IssueAssignment",
    "IssueAttachment",
    "DepartmentMember",
    "Notification",
    "AIAnalysis",
    "IssuePriorityReview",
    "IssueCluster",
    "IssueClusterMember",
    "AIChatSession",
    "AIChatMessage",
]

from app.models.collection_schedule import CollectionSchedule
from app.models.air_quality_reading import AirQualityReading
from app.models.safety_alert import SafetyAlert
from app.models.audit_log import AuditLog

__all__.extend([
    "CollectionSchedule",
    "AirQualityReading",
    "SafetyAlert",
    "AuditLog",
])
