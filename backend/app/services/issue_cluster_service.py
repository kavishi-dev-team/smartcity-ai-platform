from sqlalchemy.orm import Session

from app.models.issue_cluster import IssueCluster
from app.models.issue_cluster_member import IssueClusterMember
from app.models.issue import Issue


def get_issue_clusters(
    db: Session,
    category: str | None = None,
    city: str | None = None,
):
    query = db.query(IssueCluster).filter(
        IssueCluster.status == "active"
    )

    if category:
        query = query.filter(IssueCluster.category.ilike(category))

    if city:
        query = query.filter(IssueCluster.city.ilike(city))

    return (
        query
        .order_by(IssueCluster.issue_count.desc())
        .all()
    )


def get_issue_cluster_by_id(db: Session, cluster_id: int):
    return (
        db.query(IssueCluster)
        .filter(IssueCluster.id == cluster_id)
        .first()
    )


def get_cluster_issues(db: Session, cluster_id: int):
    cluster = get_issue_cluster_by_id(db, cluster_id)

    if cluster is None:
        return None

    return (
        db.query(Issue, IssueClusterMember.similarity_score)
        .join(
            IssueClusterMember,
            Issue.id == IssueClusterMember.issue_id,
        )
        .filter(
            IssueClusterMember.cluster_id == cluster_id,
            Issue.is_active.is_(True),
        )
        .order_by(Issue.created_at.desc())
        .all()
    )
