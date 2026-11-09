"""Sends emails over SMTP (HTML + plain-text), or logs them to the console when SMTP is not configured."""
import logging
import os
import smtplib
import ssl
from email.message import EmailMessage

from dotenv import load_dotenv

from app.core.config import BASE_DIR, settings

logger = logging.getLogger("smartcity.email")


def _load_smtp_config() -> dict:
    """Reload .env so SMTP credentials updated at runtime take effect immediately."""
    load_dotenv(BASE_DIR / ".env", override=True)
    host = os.getenv("SMTP_HOST", settings.SMTP_HOST).strip()
    port = int(os.getenv("SMTP_PORT", str(settings.SMTP_PORT)).strip() or "587")
    user = os.getenv("SMTP_USER", settings.SMTP_USER).strip()
    # Strip spaces so 16-char Google App Passwords ("xxxx xxxx xxxx xxxx") work out of the box
    password = os.getenv("SMTP_PASSWORD", settings.SMTP_PASSWORD).replace(" ", "").strip()
    email_from = os.getenv("EMAIL_FROM", settings.EMAIL_FROM).strip() or user or "no-reply@smartcity.local"
    return {
        "host": host,
        "port": port,
        "user": user,
        "password": password,
        "from": email_from,
    }


def _build_html_template(title: str, full_name: str, intro: str, code: str, expire_minutes: int, footer: str) -> str:
    return f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#EFF6FF;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#EFF6FF;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background-color:#FFFFFF;border-radius:12px;overflow:hidden;border:1px solid #DBEAFE;box-shadow:0 6px 20px rgba(30,58,138,0.08);">
          <tr>
            <td style="background:linear-gradient(135deg,#1E3A8A 0%,#2563EB 65%,#06B6D4 100%);padding:24px 28px;border-bottom:3px solid #38BDF8;">
              <div style="font-size:11px;font-weight:700;letter-spacing:1px;color:#DBEAFE;text-transform:uppercase;margin-bottom:6px;">
                Smart City AI Platform
              </div>
              <div style="font-size:22px;font-weight:800;color:#FFFFFF;">
                {title}
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <p style="margin:0 0 12px 0;font-size:15px;color:#0F172A;font-weight:600;">
                Hi {full_name},
              </p>
              <p style="margin:0 0 22px 0;font-size:14px;line-height:1.55;color:#334155;">
                {intro}
              </p>
              <div style="background-color:#EFF6FF;border:1.5px dashed #2563EB;border-radius:10px;padding:18px;text-align:center;margin-bottom:22px;">
                <div style="font-size:11px;font-weight:700;letter-spacing:1px;color:#1D4ED8;text-transform:uppercase;margin-bottom:6px;">
                  One-Time Security Code
                </div>
                <div style="font-size:30px;font-weight:800;letter-spacing:6px;color:#1E3A8A;font-family:'Courier New',monospace;">
                  {code}
                </div>
              </div>
              <p style="margin:0 0 8px 0;font-size:13px;color:#475569;">
                This code expires in <strong>{expire_minutes} minutes</strong>.
              </p>
              <p style="margin:0;font-size:12.5px;color:#64748B;line-height:1.5;">
                {footer}
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#F8FAFC;padding:14px 28px;border-top:1px solid #E2E8F0;text-align:center;font-size:12px;color:#64748B;">
              Smart City Municipal Operations &bull; Automated Security Notification
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""


def send_email(to_email: str, subject: str, body: str, html_body: str | None = None) -> None:
    smtp_cfg = _load_smtp_config()
    host = smtp_cfg["host"]
    port = smtp_cfg["port"]
    user = smtp_cfg["user"]
    password = smtp_cfg["password"]
    email_from = smtp_cfg["from"]

    if not host or not user or not password:
        logger.warning(
            "\n===== EMAIL (SMTP credentials not configured in backend/.env) =====\nTo: %s\nSubject: %s\n\n%s\n===================================================================",
            to_email,
            subject,
            body,
        )
        print(f"\n===== EMAIL to {to_email} =====\n{subject}\n\n{body}\n==========================\n")
        return

    message = EmailMessage()
    message["From"] = f"Smart City AI Platform <{email_from}>" if "<" not in email_from else email_from
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)
    if html_body:
        message.add_alternative(html_body, subtype="html")

    context = ssl.create_default_context()
    if port == 465:
        with smtplib.SMTP_SSL(host, port, timeout=20, context=context) as smtp:
            smtp.login(user, password)
            smtp.send_message(message)
    else:
        with smtplib.SMTP(host, port, timeout=20) as smtp:
            smtp.ehlo()
            smtp.starttls(context=context)
            smtp.ehlo()
            smtp.login(user, password)
            smtp.send_message(message)

    logger.info("Sent email '%s' to %s via %s:%s", subject, to_email, host, port)


def send_verification_code(to_email: str, full_name: str, code: str) -> None:
    expire_min = settings.EMAIL_CODE_EXPIRE_MINUTES
    plain = (
        f"Hi {full_name},\n\n"
        f"Your Smart City AI Platform verification code is: {code}\n\n"
        f"It expires in {expire_min} minutes.\n"
        "If you did not create an account, you can safely ignore this email."
    )
    html = _build_html_template(
        title="Verify Your Email Address",
        full_name=full_name,
        intro="Thank you for registering with the Smart City AI Platform. Enter the verification code below in the mobile app to activate your citizen account:",
        code=code,
        expire_minutes=expire_min,
        footer="If you did not create an account on the Smart City AI Platform, you can safely ignore this message.",
    )
    send_email(to_email, "Verify your Smart City account", plain, html_body=html)


def send_password_reset_code(to_email: str, full_name: str, code: str) -> None:
    expire_min = settings.EMAIL_CODE_EXPIRE_MINUTES
    plain = (
        f"Hi {full_name},\n\n"
        f"Your Smart City AI Platform password reset code is: {code}\n\n"
        f"It expires in {expire_min} minutes.\n"
        "If you did not request this, you can safely ignore this email."
    )
    html = _build_html_template(
        title="Password Reset Request",
        full_name=full_name,
        intro="We received a request to reset the password for your Smart City AI Platform account. Enter the security code below to set a new password:",
        code=code,
        expire_minutes=expire_min,
        footer="If you did not request a password reset, no changes have been made to your account and you can safely ignore this email.",
    )
    send_email(to_email, "Reset your Smart City password", plain, html_body=html)
