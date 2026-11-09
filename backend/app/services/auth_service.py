import logging
from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.permissions import Role
from app.core.security import (
    as_utc,
    create_access_token,
    generate_one_time_code,
    generate_refresh_token,
    hash_password,
    hash_token,
    utcnow,
    verify_password,
)
from app.models.email_verification import EmailVerification
from app.models.password_reset_token import PasswordResetToken
from app.models.user import User
from app.models.user_preference import UserPreference
from app.models.user_session import UserSession
from app.schemas.auth import (
    AuthResponse,
    LoginRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
)
from app.schemas.user import UserRead
from app.services import email_service

logger = logging.getLogger("smartcity.auth")

GENERIC_CODE_ERROR = "Invalid or expired code"


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(User.email == _normalize_email(email)))


# --- one-time codes ---------------------------------------------------------
def _issue_code(db: Session, model, user: User) -> str:
    """Invalidate older codes for this user and create a fresh one."""
    for old in db.scalars(
        select(model).where(model.user_id == user.id, model.is_used.is_(False))
    ):
        old.is_used = True

    code = generate_one_time_code()
    db.add(
        model(
            user_id=user.id,
            token_hash=hash_token(code),
            expires_at=utcnow() + timedelta(minutes=settings.EMAIL_CODE_EXPIRE_MINUTES),
        )
    )
    return code


def _consume_code(db: Session, model, user: User, code: str) -> bool:
    record = db.scalar(
        select(model).where(
            model.user_id == user.id,
            model.token_hash == hash_token(code.strip().upper()),
            model.is_used.is_(False),
        )
    )
    if record is None or as_utc(record.expires_at) < utcnow():
        return False
    record.is_used = True
    return True


def _safe_send(func, *args) -> None:
    # Failing to send an email must not break the request.
    try:
        func(*args)
    except Exception:  # noqa: BLE001
        logger.exception("Failed to send email")


# --- registration / verification -------------------------------------------
def register(db: Session, data: RegisterRequest) -> User:
    if get_user_by_email(db, data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    user = User(
        full_name=data.full_name,
        email=_normalize_email(data.email),
        hashed_password=hash_password(data.password),
        phone_number=data.phone_number,
        address=data.address,
        role=Role.CITIZEN.value,  # the client can never choose its own role
        is_active=True,
        is_email_verified=False,
    )
    db.add(user)
    db.flush()  # get user.id

    db.add(UserPreference(user_id=user.id))
    code = _issue_code(db, EmailVerification, user)
    db.commit()
    db.refresh(user)

    _safe_send(email_service.send_verification_code, user.email, user.full_name, code)
    user.verification_code = code
    return user


def verify_email(db: Session, email: str, code: str) -> None:
    user = get_user_by_email(db, email)
    if user is None or not _consume_code(db, EmailVerification, user, code):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, GENERIC_CODE_ERROR)
    user.is_email_verified = True
    db.commit()


def resend_verification(db: Session, email: str) -> str | None:
    user = get_user_by_email(db, email)
    if user is None or user.is_email_verified or not user.is_active:
        return None
    code = _issue_code(db, EmailVerification, user)
    db.commit()
    _safe_send(email_service.send_verification_code, user.email, user.full_name, code)
    return code


# --- login / sessions -------------------------------------------------------
def _create_session(
    db: Session, user: User, device_name: str | None, ip_address: str | None
) -> TokenResponse:
    refresh_token = generate_refresh_token()
    db.add(
        UserSession(
            user_id=user.id,
            refresh_token_hash=hash_token(refresh_token),
            device_name=device_name,
            ip_address=ip_address,
            expires_at=utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            last_used_at=utcnow(),
        )
    )
    db.commit()
    access_token, expires_in = create_access_token(user.id, user.role)
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
    )


def login(db: Session, data: LoginRequest, ip_address: str | None) -> AuthResponse:
    user = get_user_by_email(db, data.email)
    if user is None or not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Invalid email or password"
        )
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "This account is deactivated")
    if settings.REQUIRE_EMAIL_VERIFICATION and not user.is_email_verified:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail={
                "code": "email_not_verified",
                "message": "Please verify your email before logging in",
            },
        )

    tokens = _create_session(db, user, data.device_name, ip_address)
    from app.services.user_service import enrich_user_read

    return AuthResponse(**tokens.model_dump(), user=enrich_user_read(db, user))


def refresh(db: Session, refresh_token: str) -> TokenResponse:
    invalid = HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token")

    session = db.scalar(
        select(UserSession).where(
            UserSession.refresh_token_hash == hash_token(refresh_token)
        )
    )
    if session is None or session.is_revoked or as_utc(session.expires_at) < utcnow():
        raise invalid

    user = db.get(User, session.user_id)
    if user is None or not user.is_active:
        raise invalid

    # Rotate: the old refresh token stops working as soon as a new one is issued.
    new_refresh_token = generate_refresh_token()
    session.refresh_token_hash = hash_token(new_refresh_token)
    session.last_used_at = utcnow()
    session.expires_at = utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    db.commit()

    access_token, expires_in = create_access_token(user.id, user.role)
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=expires_in,
    )


def logout(db: Session, refresh_token: str) -> None:
    session = db.scalar(
        select(UserSession).where(
            UserSession.refresh_token_hash == hash_token(refresh_token)
        )
    )
    if session is not None and not session.is_revoked:
        session.is_revoked = True
        db.commit()


def revoke_all_sessions(db: Session, user_id: int) -> None:
    for session in db.scalars(
        select(UserSession).where(
            UserSession.user_id == user_id, UserSession.is_revoked.is_(False)
        )
    ):
        session.is_revoked = True


# --- forgot / reset password ------------------------------------------------
def forgot_password(db: Session, email: str) -> str | None:
    user = get_user_by_email(db, email)
    if user is None or not user.is_active:
        return None
    code = _issue_code(db, PasswordResetToken, user)
    db.commit()
    _safe_send(email_service.send_password_reset_code, user.email, user.full_name, code)
    return code


def reset_password(db: Session, data: ResetPasswordRequest) -> None:
    user = get_user_by_email(db, data.email)
    if user is None or not _consume_code(db, PasswordResetToken, user, data.code):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, GENERIC_CODE_ERROR)

    user.hashed_password = hash_password(data.new_password)
    # Receiving the reset email proves ownership of the address.
    user.is_email_verified = True
    revoke_all_sessions(db, user.id)
    db.commit()