from sqlalchemy.orm import Session

from app.models import (
    Issue,
    IssueLocation,
    IssueAttachment,
    AIAnalysis,
    IssueStatusHistory,
    IssueClusterMember,
    IssueAssignment,
    Department,
)


def get_issue_details(db: Session, issue_id: int):
    # 1. Get the main issue
    issue = (
        db.query(Issue)
        .filter(
            Issue.id == issue_id,
            Issue.is_active.is_(True),
        )
        .first()
    )

    if issue is None:
        return None

    # 2. Get location
    location = (
        db.query(IssueLocation)
        .filter(IssueLocation.issue_id == issue_id)
        .first()
    )

    location_data = None
    if location:
        location_data = {
            "latitude": location.latitude,
            "longitude": location.longitude,
            "address": location.address,
            "city": location.city,
        }

    # 3. Get evidence photos / attachments
    attachments = (
        db.query(IssueAttachment)
        .filter(IssueAttachment.issue_id == issue_id)
        .order_by(IssueAttachment.created_at.desc())
        .all()
    )

    attachment_data = [
        {
            "id": item.id,
            "file_name": item.file_name,
            "file_url": item.file_url,
            "file_type": item.file_type,
            "created_at": item.created_at,
        }
        for item in attachments
    ]

    # 4. Get AI analysis
    analyses = (
        db.query(AIAnalysis)
        .filter(AIAnalysis.issue_id == issue_id)
        .order_by(AIAnalysis.created_at.desc())
        .all()
    )

    analysis_data = [
        {
            "id": item.id,
            "analysis_type": item.analysis_type,
            "result": item.result,
            "explanation": item.explanation,
            "model_name": item.model_name,
            "confidence_score": item.confidence_score,
            "created_at": item.created_at,
        }
        for item in analyses
    ]

    # 5. Get status timeline
    history = (
        db.query(IssueStatusHistory)
        .filter(IssueStatusHistory.issue_id == issue_id)
        .order_by(IssueStatusHistory.created_at.asc())
        .all()
    )

    timeline_data = [
        {
            "id": item.id,
            "previous_status": item.previous_status,
            "new_status": item.new_status,
            "note": item.note,
            "created_at": item.created_at,
        }
        for item in history
    ]

    # 6. Get similar reports from the same cluster
    cluster_ids = (
        db.query(IssueClusterMember.cluster_id)
        .filter(IssueClusterMember.issue_id == issue_id)
        .subquery()
    )

    similar_items = (
        db.query(Issue, IssueClusterMember.similarity_score)
        .join(
            IssueClusterMember,
            IssueClusterMember.issue_id == Issue.id,
        )
        .filter(
            IssueClusterMember.cluster_id.in_(cluster_ids),
            Issue.id != issue_id,
            Issue.is_active.is_(True),
        )
        .all()
    )

    similar_data = []
    seen_ids = set()

    for similar_issue, score in similar_items:
        if similar_issue.id in seen_ids:
            continue

        seen_ids.add(similar_issue.id)

        similar_data.append({
            "id": similar_issue.id,
            "title": similar_issue.title,
            "category": similar_issue.category,
            "status": similar_issue.status,
            "priority": similar_issue.priority,
            "similarity_score": score,
        })

    # 7. Get responsible department
    department_id = issue.department_id

    if department_id is None:
        assignment = (
            db.query(IssueAssignment)
            .filter(IssueAssignment.issue_id == issue_id)
            .order_by(IssueAssignment.assigned_at.desc())
            .first()
        )

        if assignment:
            department_id = assignment.department_id

    department_data = None

    if department_id is not None:
        department = (
            db.query(Department)
            .filter(Department.id == department_id)
            .first()
        )

        if department:
            department_data = {
                "id": department.id,
                "name": department.name,
            }

    # 8. Return complete details
    return {
        "id": issue.id,
        "title": issue.title,
        "description": issue.description,
        "category": issue.category,
        "subcategory": issue.subcategory,
        "status": issue.status,
        "priority": issue.priority,
        "department": department_data,
        "created_at": issue.created_at,
        "updated_at": issue.updated_at,
        "location": location_data,
        "attachments": attachment_data,
        "ai_analysis": analysis_data,
        "similar_reports": similar_data,
        "status_timeline": timeline_data,
    }