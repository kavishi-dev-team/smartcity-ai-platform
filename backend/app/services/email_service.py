"""Sends emails over SMTP, or prints them to the console when SMTP is not configured."""
import logging
import smtplib
from email.message import EmailMessage

from app.core.config import settings

logger = logging.getLogger("smartcity.email")


def send_email(to_email: str, subject: str, body: str) -> None:
    if not settings.SMTP_HOST:
        # Development fallback: no mail server, show the email in the server log.
        logger.warning(
            "\n===== EMAIL (SMTP not configured) =====\nTo: %s\nSubject: %s\n\n%s\n=======================================",
            to_email,
            subject,
            body,
        )
        print(f"\n===== EMAIL to {to_email} =====\n{subject}\n\n{body}\n==========================\n")
        return

    message = EmailMessage()
    message["From"] = settings.EMAIL_FROM
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as smtp:
        smtp.starttls()
        if settings.SMTP_USER:
            smtp.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        smtp.send_message(message)


def send_verification_code(to_email: str, full_name: str, code: str) -> None:
    send_email(
        to_email,
        "Verify your Smart City account",
        f"Hi {full_name},\n\nYour verification code is: {code}\n\n"
        f"It expires in {settings.EMAIL_CODE_EXPIRE_MINUTES} minutes.\n"
        "If you did not create an account, you can ignore this email.",
    )


def send_password_reset_code(to_email: str, full_name: str, code: str) -> None:
    send_email(
        to_email,
        "Reset your Smart City password",
        f"Hi {full_name},\n\nYour password reset code is: {code}\n\n"
        f"It expires in {settings.EMAIL_CODE_EXPIRE_MINUTES} minutes.\n"
        "If you did not request this, you can ignore this email.",
    )