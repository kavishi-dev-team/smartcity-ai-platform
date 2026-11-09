from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator

from app.schemas.auth_validators import normalize_phone, validate_password_strength
from app.schemas.user import UserRead


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    email: EmailStr
    phone_number: str
    address: str = Field(min_length=3, max_length=500)
    password: str = Field(max_length=64)
    confirm_password: str
    accept_terms: bool

    @field_validator("full_name")
    @classmethod
    def _strip_name(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Full name is too short")
        return v

    @field_validator("address")
    @classmethod
    def _strip_address(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 3:
            raise ValueError("Address is too short")
        return v

    @field_validator("phone_number")
    @classmethod
    def _phone(cls, v: str) -> str:
        return normalize_phone(v)

    @field_validator("password")
    @classmethod
    def _password(cls, v: str) -> str:
        return validate_password_strength(v)

    @model_validator(mode="after")
    def _check(self):
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match")
        if not self.accept_terms:
            raise ValueError("You must accept the Terms & Conditions")
        return self


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(max_length=64)
    device_name: str | None = Field(default=None, max_length=255)


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=16)


class ResendVerificationRequest(BaseModel):
    email: EmailStr


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=16)
    new_password: str = Field(max_length=64)
    confirm_password: str

    @field_validator("new_password")
    @classmethod
    def _password(cls, v: str) -> str:
        return validate_password_strength(v)

    @model_validator(mode="after")
    def _check(self):
        if self.new_password != self.confirm_password:
            raise ValueError("Passwords do not match")
        return self


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class AuthResponse(TokenResponse):
    user: UserRead
