import re

PHONE_PATTERN = re.compile(r"^\+?[0-9]{9,15}$")


def validate_password_strength(value: str) -> str:
    if len(value) < 8:
        raise ValueError("Password must be at least 8 characters long")
    if not re.search(r"[a-z]", value):
        raise ValueError("Password must contain a lowercase letter")
    if not re.search(r"[A-Z]", value):
        raise ValueError("Password must contain an uppercase letter")
    if not re.search(r"[0-9]", value):
        raise ValueError("Password must contain a number")
    return value


def normalize_phone(value: str) -> str:
    cleaned = re.sub(r"[\s\-()]", "", value)
    if not PHONE_PATTERN.match(cleaned):
        raise ValueError("Enter a valid phone number")
    return cleaned