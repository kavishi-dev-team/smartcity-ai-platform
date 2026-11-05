from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.ai_chat import (
    AIChatSessionCreate,
    AIChatSessionResponse,
    AIChatMessageCreate,
    AIChatMessageResponse,
    AIChatHistoryResponse,
    AIChatReplyResponse,
)
from app.services.ai_chat_service import (
    create_chat_session,
    get_user_chat_sessions,
    get_chat_session,
    get_chat_messages,
    save_chat_message,
    delete_chat_session,
    generate_assistant_reply,
)

router = APIRouter()


@router.post("/sessions", response_model=AIChatSessionResponse)
def create_session(
    request: AIChatSessionCreate,
    user_id: int,
    db: Session = Depends(get_db),
):
    return create_chat_session(db, user_id, request.title)


@router.get("/sessions", response_model=list[AIChatSessionResponse])
def list_sessions(
    user_id: int,
    db: Session = Depends(get_db),
):
    return get_user_chat_sessions(db, user_id)


@router.get(
    "/sessions/{session_id}/messages",
    response_model=AIChatHistoryResponse,
)
def get_session_messages(
    session_id: int,
    user_id: int,
    db: Session = Depends(get_db),
):
    session = get_chat_session(db, session_id, user_id)

    if session is None:
        raise HTTPException(status_code=404, detail="Chat session not found")

    messages = get_chat_messages(db, session_id)

    return {
        "session": session,
        "messages": messages,
    }


@router.post(
    "/sessions/{session_id}/messages",
    response_model=AIChatReplyResponse,
)
def send_message(
    session_id: int,
    request: AIChatMessageCreate,
    user_id: int,
    db: Session = Depends(get_db),
):
    session = get_chat_session(db, session_id, user_id)

    if session is None:
        raise HTTPException(
            status_code=404,
            detail="Chat session not found",
        )

    history = get_chat_messages(db, session_id)

    user_message = save_chat_message(
        db, session_id, "user", request.content
    )

    reply_text = generate_assistant_reply(
        request.content,
        history,
    )

    assistant_message = save_chat_message(
        db, session_id, "assistant", reply_text
    )

    return {
        "user_message": user_message,
        "assistant_message": assistant_message,
    }


@router.delete("/sessions/{session_id}")
def remove_session(
    session_id: int,
    user_id: int,
    db: Session = Depends(get_db),
):
    session = get_chat_session(db, session_id, user_id)

    if session is None:
        raise HTTPException(status_code=404, detail="Chat session not found")

    delete_chat_session(db, session)

    return {"message": "Chat session deleted successfully"}
