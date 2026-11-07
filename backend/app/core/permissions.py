"""Roles and access-control dependencies."""
from enum import Enum

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.user import User


class Role(str, Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    CITY_MANAGER = "CITY_MANAGER"
    DEPARTMENT_OFFICER = "DEPARTMENT_OFFICER"
    CITIZEN = "CITIZEN"


# Everyone who is not a citizen uses the Officer side of the app.
STAFF_ROLES = (Role.SUPER_ADMIN, Role.CITY_MANAGER, Role.DEPARTMENT_OFFICER)

bearer_scheme = HTTPBearer(auto_error=False)


def _unauthorized(message: str = "Not authenticated") -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=message,
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise _unauthorized()

    payload = decode_access_token(credentials.credentials)
    if payload is None:
        raise _unauthorized("Invalid or expired token")

    try:
        user_id = int(payload["sub"])
    except (KeyError, ValueError):
        raise _unauthorized("Invalid token")

    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise _unauthorized("User not found or inactive")
    return user


def require_roles(*allowed: Role):
    """Usage: current_user = Depends(require_roles(Role.SUPER_ADMIN))"""
    allowed_values = {role.value for role in allowed}

    def dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_values:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action",
            )
        return current_user

    return dependency