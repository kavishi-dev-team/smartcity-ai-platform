from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.schemas.auth_validators import normalize_phone, validate_password_strength


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    email: str
    phone_number: str | None = None
    address: str | None = None
    profile_photo_url: str | None = None
    role: str
    is_active: bool
    is_email_verified: bool
    created_at: datetime
    verification_code: str | None = None
    department_id: int | None = None
    department_name: str | None = None
    position: str | None = None


class StaffAccountCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: str = Field(min_length=2, max_length=150)
    email: str
    phone_number: str | None = None
    address: str | None = Field(default=None, max_length=500)
    role: str = Field(pattern="^(SUPER_ADMIN|CITY_MANAGER|DEPARTMENT_OFFICER)$")
    department_id: int | None = None
    position: str | None = Field(default=None, max_length=100)
    password: str = Field(min_length=8, max_length=64)

    @field_validator("full_name")
    @classmethod
    def _name(cls, v: str) -> str:
        return v.strip()

    @field_validator("email")
    @classmethod
    def _email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("phone_number")
    @classmethod
    def _phone(cls, v: str | None) -> str | None:
        return normalize_phone(v) if v and v.strip() else None

    @field_validator("password")
    @classmethod
    def _password(cls, v: str) -> str:
        return validate_password_strength(v)


class StaffAccountUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: str | None = Field(default=None, min_length=2, max_length=150)
    phone_number: str | None = None
    address: str | None = Field(default=None, max_length=500)
    role: str | None = Field(
        default=None,
        pattern="^(SUPER_ADMIN|CITY_MANAGER|DEPARTMENT_OFFICER|CITIZEN)$",
    )
    department_id: int | None = None
    position: str | None = Field(default=None, max_length=100)
    is_active: bool | None = None
    new_password: str | None = Field(default=None, max_length=64)

    @field_validator("phone_number")
    @classmethod
    def _phone(cls, v: str | None) -> str | None:
        return normalize_phone(v) if v and v.strip() else None

    @field_validator("new_password")
    @classmethod
    def _password(cls, v: str | None) -> str | None:
        return validate_password_strength(v) if v else None


class UserUpdate(BaseModel):
    """PATCH /users/me — only the fields that are sent are changed."""

    model_config = ConfigDict(extra="forbid")

    full_name: str | None = Field(default=None, min_length=2, max_length=150)
    phone_number: str | None = None
    address: str | None = Field(default=None, max_length=500)
    profile_photo_url: str | None = Field(default=None, max_length=500)

    @field_validator("full_name")
    @classmethod
    def _name(cls, v):
        return v.strip() if v is not None else v

    @field_validator("phone_number")
    @classmethod
    def _phone(cls, v):
        return normalize_phone(v) if v else v


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(max_length=64)
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
        if self.new_password == self.current_password:
            raise ValueError("New password must be different from the current one")
        return self


class DeleteAccountRequest(BaseModel):
    password: str = Field(max_length=64)