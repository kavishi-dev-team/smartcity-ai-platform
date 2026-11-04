from sqlalchemy import Column, DateTime, ForeignKey, Integer, Float
from sqlalchemy.sql import func

from app.db.session import Base


class IssueClusterMember(Base):
    __tablename__ = "issue_cluster_members"

    id = Column(Integer, primary_key=True, index=True)

    cluster_id = Column(
        Integer,
        ForeignKey("issue_clusters.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    issue_id = Column(
        Integer,
        ForeignKey("issues.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    similarity_score = Column(Float, nullable=True)

    added_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
