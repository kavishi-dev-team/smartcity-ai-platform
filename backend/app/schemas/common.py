from pydantic import BaseModel


class MessageResponse(BaseModel):
    message: str
    verification_code: str | None = None
