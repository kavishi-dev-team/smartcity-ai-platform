from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.permissions import Role
from app.core.security import hash_password, verify_password
from app.models.department import Department
from app.models.department_member import DepartmentMember
from app.models.user import User
from app.models.user_preference import UserPreference
from app.schemas.user import (
    ChangePasswordRequest,
    StaffAccountCreate,
    StaffAccountUpdate,
    UserRead,
    UserUpdate,
)
from app.schemas.user_preference import PreferenceUpdate
from app.services.auth_service import get_user_by_email, revoke_all_sessions


def enrich_user_read(db: Session, user: User) -> UserRead:
    dept_id = None
    dept_name = None
    pos = None

    membership = (
        db.query(DepartmentMember)
        .filter(
            DepartmentMember.user_id == user.id,
            DepartmentMember.is_active.is_(True),
        )
        .order_by(DepartmentMember.id.asc())
        .first()
    )
    if membership:
        dept_id = membership.department_id
        pos = membership.position
        dept = db.get(Department, membership.department_id)
        if dept:
            dept_name = dept.name

    base = UserRead.model_validate(user)
    return base.model_copy(
        update={
            "department_id": dept_id,
            "department_name": dept_name,
            "position": pos,
        }
    )


def update_profile(db: Session, user: User, data: UserUpdate) -> UserRead:
    changes = data.model_dump(exclude_unset=True)
    for field, value in changes.items():
        if field == "full_name" and not value:
            continue  # name is required, ignore null
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return enrich_user_read(db, user)


def change_password(db: Session, user: User, data: ChangePasswordRequest) -> None:
    if not verify_password(data.current_password, user.hashed_password):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "Current password is incorrect"
        )
    user.hashed_password = hash_password(data.new_password)
    revoke_all_sessions(db, user.id)  # every device has to log in again
    db.commit()


def delete_account(db: Session, user: User, password: str) -> None:
    """Soft delete: other tables (issues, comments...) still reference this user."""
    if not verify_password(password, user.hashed_password):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Password is incorrect")

    user.is_active = False
    user.email = f"deleted_{user.id}@deleted.invalid"
    user.full_name = "Deleted User"
    user.phone_number = None
    user.address = None
    user.profile_photo_url = None
    revoke_all_sessions(db, user.id)
    db.commit()


def get_or_create_preferences(db: Session, user: User) -> UserPreference:
    prefs = db.scalar(select(UserPreference).where(UserPreference.user_id == user.id))
    if prefs is None:
        prefs = UserPreference(user_id=user.id)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)
    return prefs


def update_preferences(
    db: Session, user: User, data: PreferenceUpdate
) -> UserPreference:
    prefs = get_or_create_preferences(db, user)
    for field, value in data.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(prefs, field, value)
    db.commit()
    db.refresh(prefs)
    return prefs


# --- Staff & Role Management (Super Admin / City Manager) -------------------
def list_managed_users(
    db: Session,
    actor: User,
    role_filter: str | None = None,
    search: str | None = None,
) -> list[UserRead]:
    query = db.query(User).filter(~User.email.like("deleted_%@deleted.invalid"))

    # City Manager can view Department Officers and City Managers; Super Admin sees all
    if actor.role == Role.CITY_MANAGER.value and not role_filter:
        query = query.filter(
            User.role.in_(
                [
                    Role.SUPER_ADMIN.value,
                    Role.CITY_MANAGER.value,
                    Role.DEPARTMENT_OFFICER.value,
                ]
            )
        )
    elif role_filter:
        query = query.filter(User.role == role_filter)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            (User.full_name.ilike(term))
            | (User.email.ilike(term))
            | (User.phone_number.ilike(term))
        )

    users = query.order_by(User.id.asc()).all()
    return [enrich_user_read(db, u) for u in users]


def create_staff_account(
    db: Session,
    actor: User,
    data: StaffAccountCreate,
) -> UserRead:
    if actor.role != Role.SUPER_ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Super Admin can register new staff accounts (Super Admin, City Manager, Department Officer).",
        )

    if get_user_by_email(db, data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    if data.department_id is not None:
        dept = db.get(Department, data.department_id)
        if not dept or not dept.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Selected department not found",
            )

    new_user = User(
        full_name=data.full_name,
        email=data.email,
        hashed_password=hash_password(data.password),
        phone_number=data.phone_number,
        address=data.address,
        role=data.role,
        is_active=True,
        is_email_verified=True,  # Staff accounts created by Super Admin are pre-verified
    )
    db.add(new_user)
    db.flush()

    db.add(UserPreference(user_id=new_user.id))

    if data.department_id is not None:
        default_pos = data.position or (
            "Department Officer"
            if data.role == Role.DEPARTMENT_OFFICER.value
            else "City Manager"
            if data.role == Role.CITY_MANAGER.value
            else "Super Admin"
        )
        db.add(
            DepartmentMember(
                department_id=data.department_id,
                user_id=new_user.id,
                position=default_pos,
                is_active=True,
            )
        )

    db.commit()
    db.refresh(new_user)
    return enrich_user_read(db, new_user)


def update_staff_account(
    db: Session,
    actor: User,
    target_user_id: int,
    data: StaffAccountUpdate,
) -> UserRead:
    if actor.role != Role.SUPER_ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Super Admin has full access to modify roles, status, or staff accounts.",
        )

    target = db.get(User, target_user_id)
    if not target:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User account not found",
        )

    if target.id == actor.id and data.is_active is False:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot deactivate your own Super Admin account.",
        )

    if target.id == actor.id and data.role and data.role != Role.SUPER_ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot downgrade your own Super Admin role.",
        )

    if data.full_name is not None:
        target.full_name = data.full_name.strip()
    if data.phone_number is not None:
        target.phone_number = data.phone_number
    if data.address is not None:
        target.address = data.address.strip() if data.address else None
    if data.role is not None:
        target.role = data.role
    if data.is_active is not None:
        target.is_active = data.is_active
        if not data.is_active:
            revoke_all_sessions(db, target.id)
    if data.new_password:
        target.hashed_password = hash_password(data.new_password)
        revoke_all_sessions(db, target.id)

    # Update primary department assignment if provided
    if data.department_id is not None:
        existing_memberships = (
            db.query(DepartmentMember)
            .filter(DepartmentMember.user_id == target.id)
            .all()
        )
        for m in existing_memberships:
            m.is_active = False

        if data.department_id > 0:
            dept = db.get(Department, data.department_id)
            if not dept:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Department not found",
                )
            primary = next(
                (
                    m
                    for m in existing_memberships
                    if m.department_id == data.department_id
                ),
                None,
            )
            pos_val = data.position or (
                primary.position if primary and primary.position else "Department Officer"
            )
            if primary:
                primary.is_active = True
                primary.position = pos_val
            else:
                db.add(
                    DepartmentMember(
                        department_id=data.department_id,
                        user_id=target.id,
                        position=pos_val,
                        is_active=True,
                    )
                )
    elif data.position is not None:
        active_m = (
            db.query(DepartmentMember)
            .filter(
                DepartmentMember.user_id == target.id,
                DepartmentMember.is_active.is_(True),
            )
            .first()
        )
        if active_m:
            active_m.position = data.position

    db.commit()
    db.refresh(target)
    return enrich_user_read(db, target)


def delete_managed_user(
    db: Session,
    actor: User,
    target_user_id: int,
) -> None:
    if actor.role != Role.SUPER_ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Super Admin has permission to delete staff or citizen accounts.",
        )

    target = db.get(User, target_user_id)
    if not target or target.email.endswith("@deleted.invalid"):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User account not found",
        )

    if target.id == actor.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own Super Admin account.",
        )

    memberships = (
        db.query(DepartmentMember)
        .filter(DepartmentMember.user_id == target.id)
        .all()
    )
    for m in memberships:
        m.is_active = False

    target.is_active = False
    target.email = f"deleted_{target.id}@deleted.invalid"
    target.full_name = "Deleted User"
    target.phone_number = None
    target.address = None
    target.profile_photo_url = None
    revoke_all_sessions(db, target.id)
    db.commit()

