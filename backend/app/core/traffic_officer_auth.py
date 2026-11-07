import base64
import hashlib
import hmac
import json
import time

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.models.user import User

_bearer = HTTPBearer(auto_error=False)
_OFFICER_ROLES = {'officer', 'authorized_officer', 'admin'}
_DEFAULT_SECRET = 'development-only-change-this-secret'


def _b64decode(part: str) -> bytes:
    return base64.urlsafe_b64decode(part + '=' * (-len(part) % 4))


def _b64encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


def create_dev_access_token(user_id: int, *, ttl_minutes: int = 30) -> str:
    """For local test scripts only; not a login endpoint."""
    if settings.APP_ENV.lower() not in {'dev', 'development', 'local', 'test', 'testing'}:
        raise RuntimeError('Development tokens cannot be issued in this environment')
    if not settings.SECRET_KEY or settings.SECRET_KEY == _DEFAULT_SECRET:
        raise RuntimeError('Set a unique SECRET_KEY in backend/.env before issuing tokens')
    now = int(time.time())
    header = {'alg': 'HS256', 'typ': 'JWT'}
    payload = {'sub': str(user_id), 'iat': now, 'exp': now + ttl_minutes * 60, 'type': 'access'}
    body = f'{_b64encode(json.dumps(header, separators=(",", ":")).encode())}.{_b64encode(json.dumps(payload, separators=(",", ":")).encode())}'
    sig = hmac.new(settings.SECRET_KEY.encode(), body.encode(), hashlib.sha256).digest()
    return body + '.' + _b64encode(sig)


def _validate_token(token: str) -> str:
    forbidden = HTTPException(status_code=401, detail='Invalid or expired officer access token', headers={'WWW-Authenticate': 'Bearer'})
    if len(token) > 4096:
        raise forbidden
    try:
        a, b, c = token.split('.')
        header = json.loads(_b64decode(a))
        payload = json.loads(_b64decode(b))
        if not isinstance(header, dict) or header.get('alg') != 'HS256' or header.get('typ', 'JWT') != 'JWT':
            raise ValueError('Invalid JWT algorithm')
        if not isinstance(payload, dict):
            raise ValueError('Invalid payload')
        expected = hmac.new(settings.SECRET_KEY.encode(), f'{a}.{b}'.encode(), hashlib.sha256).digest()
        if not hmac.compare_digest(expected, _b64decode(c)):
            raise ValueError('Invalid signature')
        exp = payload.get('exp')
        if isinstance(exp, bool) or not isinstance(exp, (int, float)) or exp <= time.time():
            raise ValueError('Expired or missing exp')
        if payload.get('nbf') is not None and (not isinstance(payload['nbf'], (int, float)) or payload['nbf'] > time.time()):
            raise ValueError('JWT not active')
        if payload.get('type', payload.get('token_type', 'access')) not in {'access', 'access_token'}:
            raise ValueError('Not an access token')
        subject = payload.get('sub')
        if not isinstance(subject, str) or not subject.strip() or len(subject) > 255:
            raise ValueError('Invalid subject')
        return subject
    except (ValueError, TypeError, OverflowError, UnicodeError, json.JSONDecodeError, base64.binascii.Error) as exc:
        raise forbidden from exc


def require_traffic_officer(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    if not settings.SECRET_KEY or settings.SECRET_KEY == _DEFAULT_SECRET:
        raise HTTPException(status_code=503, detail='Server authentication is not configured')
    if credentials is None or credentials.scheme.lower() != 'bearer':
        raise HTTPException(status_code=401, detail='Officer access token required', headers={'WWW-Authenticate': 'Bearer'})
    sub = _validate_token(credentials.credentials)
    if sub.isdecimal():
        user = db.query(User).filter(User.id == int(sub)).first()
    else:
        user = db.query(User).filter(User.email == sub).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=401, detail='Account is invalid or inactive')
    if (user.role or '').strip().lower() not in _OFFICER_ROLES:
        raise HTTPException(status_code=403, detail='Officer permission required')
    return user
