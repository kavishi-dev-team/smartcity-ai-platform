from sqlalchemy.orm import Session
from google import genai
from google.genai import types
from google.genai import errors

from app.models.ai_chat_session import AIChatSession
from app.models.ai_chat_message import AIChatMessage
from app.core.config import settings


def create_chat_session(db: Session, user_id: int, title: str | None = None):
    session = AIChatSession(
        user_id=user_id,
        title=title,
        status="active",
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return session


def get_user_chat_sessions(db: Session, user_id: int):
    return (
        db.query(AIChatSession)
        .filter(
            AIChatSession.user_id == user_id,
            AIChatSession.status == "active",
        )
        .order_by(AIChatSession.updated_at.desc())
        .all()
    )


def get_chat_session(db: Session, session_id: int, user_id: int):
    return (
        db.query(AIChatSession)
        .filter(
            AIChatSession.id == session_id,
            AIChatSession.user_id == user_id,
        )
        .first()
    )


def get_chat_messages(db: Session, session_id: int):
    return (
        db.query(AIChatMessage)
        .filter(AIChatMessage.session_id == session_id)
        .order_by(AIChatMessage.created_at.asc())
        .all()
    )


def save_chat_message(
    db: Session,
    session_id: int,
    role: str,
    content: str,
):
    message = AIChatMessage(
        session_id=session_id,
        role=role,
        content=content,
    )

    db.add(message)
    db.commit()
    db.refresh(message)

    return message


def delete_chat_session(db: Session, session: AIChatSession):
    session.status = "deleted"
    db.commit()


def generate_assistant_reply(message: str, history: list) -> str:
    if not settings.GEMINI_API_KEY:
        raise RuntimeError("Gemini API key is not configured.")

    client = genai.Client(
        api_key=settings.GEMINI_API_KEY,
        http_options=types.HttpOptions(timeout=60000),
    )
    try:
        conversation = []

        for chat_message in history:
            conversation.append(
                types.Content(
                    role=(
                        "model"
                        if chat_message.role == "assistant"
                        else "user"
                    ),
                    parts=[types.Part(text=chat_message.content)],
                )
            )

        conversation.append(
            types.Content(
                role="user",
                parts=[types.Part(text=message)],
            )
        )

        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=conversation,
            config=types.GenerateContentConfig(
                system_instruction=(
                    "You are the Smart City AI Assistant. "
                    "Help citizens understand smart city services, "
                    "reporting issues, road damage, waste management, "
                    "water supply, traffic, and public services. "
                    "Remember the previous conversation and use it "
                    "to answer follow-up questions. "
                    "Give clear, friendly, practical answers. "
                    "If you do not know something, say so honestly."
                )
            ),
        )

        if not response.text:
            raise RuntimeError("Gemini returned an empty response.")

        return response.text.strip()

    except errors.APIError as e:
        if e.code == 503:
            return (
                "Sorry, the Smart City AI Assistant is temporarily busy. "
                "Please try again in a few moments."
            )
        raise

    finally:
        client.close()
