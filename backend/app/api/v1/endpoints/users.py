from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.permissions import Role, get_current_user, require_roles
from app.db.session import get_db
from app.models.user import User
from app.schemas.common import MessageResponse
from app.schemas.user import (
    ChangePasswordRequest,
    DeleteAccountRequest,
    StaffAccountCreate,
    StaffAccountUpdate,
    UserRead,
    UserUpdate,
)
from app.services import user_service

router = APIRouter()


@router.get("/me", response_model=UserRead)
def get_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return user_service.enrich_user_read(db, current_user)


@router.patch("/me", response_model=UserRead)
def update_me(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return user_service.update_profile(db, current_user, data)


@router.patch("/me/password", response_model=MessageResponse)
def change_password(
    data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_service.change_password(db, current_user, data)
    return MessageResponse(message="Password changed successfully")


@router.delete("/me", response_model=MessageResponse)
def delete_me(
    data: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_service.delete_account(db, current_user, data.password)
    return MessageResponse(message="Account deleted")


# --- Staff & Role Administration Endpoints ----------------------------------
@router.get("/staff", response_model=list[UserRead])
def list_staff_and_users(
    role: str | None = Query(default=None),
    search: str | None = Query(default=None),
    current_user: User = Depends(
        require_roles(Role.SUPER_ADMIN, Role.CITY_MANAGER)
    ),
    db: Session = Depends(get_db),
):
    """
    Super Admin has full access to view and filter all accounts (Super Admin, City Manager, Department Officer, Citizen).
    City Manager has read access to view the staff directory.
    """
    return user_service.list_managed_users(
        db, current_user, role_filter=role, search=search
    )


@router.post(
    "/staff",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
)
def register_staff_account(
    data: StaffAccountCreate,
    current_user: User = Depends(require_roles(Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    """
    Super Admin only: Register a new Department Officer, City Manager, or Super Admin
    and optionally link them to a municipal department.
    """
    return user_service.create_staff_account(db, current_user, data)


@router.patch("/staff/{target_user_id}", response_model=UserRead)
def update_staff_account(
    target_user_id: int,
    data: StaffAccountUpdate,
    current_user: User = Depends(require_roles(Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    """
    Super Admin only: Update a staff member's role, department assignment, position,
    active status, or reset their password.
    """
    return user_service.update_staff_account(
        db, current_user, target_user_id, data
    )


@router.delete("/staff/{target_user_id}", response_model=MessageResponse)
def delete_staff_or_citizen_account(
    target_user_id: int,
    current_user: User = Depends(require_roles(Role.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    """
    Super Admin only: Delete a staff member (Department Officer, City Manager, Super Admin)
    or Citizen account, revoking all sessions and deactivating department memberships.
    """
    user_service.delete_managed_user(db, current_user, target_user_id)
    return MessageResponse(message="Account deleted successfully")

