from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.issue_cluster import (
    IssueClusterResponse,
    ClusterIssueResponse,
    ClusterIssuesResponse,
)
from app.services.issue_cluster_service import (
    get_issue_clusters,
    get_issue_cluster_by_id,
    get_cluster_issues,
)

router = APIRouter()


@router.get("/", response_model=list[IssueClusterResponse])
def list_issue_clusters(
    category: str | None = Query(default=None),
    city: str | None = Query(default=None),
    db: Session = Depends(get_db),
):
    return get_issue_clusters(
        db=db,
        category=category,
        city=city,
    )


@router.get("/{cluster_id}", response_model=IssueClusterResponse)
def get_issue_cluster(
    cluster_id: int,
    db: Session = Depends(get_db),
):
    cluster = get_issue_cluster_by_id(db, cluster_id)

    if cluster is None:
        raise HTTPException(status_code=404, detail="Cluster not found")

    return cluster


@router.get("/{cluster_id}/issues", response_model=ClusterIssuesResponse)
def list_cluster_issues(
    cluster_id: int,
    db: Session = Depends(get_db),
):
    cluster = get_issue_cluster_by_id(db, cluster_id)

    if cluster is None:
        raise HTTPException(status_code=404, detail="Cluster not found")

    results = get_cluster_issues(db, cluster_id)

    issues = [
        {
            "id": issue.id,
            "title": issue.title,
            "description": issue.description,
            "category": issue.category,
            "status": issue.status,
            "priority": issue.priority,
            "similarity_score": similarity_score,
            "created_at": issue.created_at,
        }
        for issue, similarity_score in results
    ]

    return {
        "cluster_id": cluster.id,
        "cluster_name": cluster.name,
        "issues": issues,
    }
