import os
import hmac
import hashlib
import smtplib

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import PlainTextResponse
from fastapi.concurrency import run_in_threadpool

app = FastAPI()

MAILGUN_API_KEY = os.getenv("MAILGUN_API_KEY", "").strip()

# Internal mailserver container (docker-mailserver)
MAILSERVER_HOST = os.getenv("MAILSERVER_HOST", "mailserver")
MAILSERVER_PORT = int(os.getenv("MAILSERVER_PORT", "25"))
MAILSERVER_HELO_DOMAIN = os.getenv("MAILSERVER_HELO_DOMAIN", "mail-ingest.local")


def verify_mailgun_signature(api_key: str, timestamp: str, token: str, signature: str) -> bool:
    """
    Mailgun: HMAC-SHA256(api_key, timestamp + token) == signature
    """
    if not api_key or not timestamp or not token or not signature:
        return False

    digest = hmac.new(
        key=api_key.encode("utf-8"),
        msg=f"{timestamp}{token}".encode("utf-8"),
        digestmod=hashlib.sha256,
    ).hexdigest()

    return hmac.compare_digest(digest, signature)


def smtp_forward(envelope_from: str, envelope_to: str, raw_mime: bytes) -> None:
    """
    Blocking SMTP send into docker-mailserver.
    """
    with smtplib.SMTP(MAILSERVER_HOST, MAILSERVER_PORT, timeout=15) as smtp:
        smtp.ehlo(MAILSERVER_HELO_DOMAIN)
        # internal, no TLS/auth needed
        smtp.mail(envelope_from)
        smtp.rcpt(envelope_to)
        smtp.data(raw_mime)


@app.get("/healthz", response_class=PlainTextResponse)
async def healthz():
    return "OK"


@app.post("/mailgun/incoming", response_class=PlainTextResponse)
async def mailgun_incoming(request: Request):
    """
    Mailgun Route webhook endpoint.

    Expect:
    - timestamp, token, signature
    - sender, recipient
    - body-mime (if using Store and Notify) OR body-plain/body-html as fallback
    """
    form = await request.form()

    # --- Verify Mailgun signature ---
    timestamp = form.get("timestamp", "")
    token = form.get("token", "")
    signature = form.get("signature", "")

    if not verify_mailgun_signature(MAILGUN_API_KEY, timestamp, token, signature):
        print("Invalid Mailgun signature")
        raise HTTPException(status_code=403, detail="Invalid Mailgun signature")

    sender = form.get("sender") or form.get("from") or "unknown@localhost"
    recipient = form.get("recipient") or form.get("to") or "unknown@localhost"

    # Prefer raw MIME if Mailgun provides it (Store and Notify)
    raw_mime = form.get("body-mime")

    if not raw_mime:
        # Fallback: very simple plain-text message if you're not using Store and Notify
        subject = form.get("subject") or ""
        body_plain = form.get("body-plain") or ""
        headers = [
            f"From: {sender}",
            f"To: {recipient}",
            f"Subject: {subject}",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=utf-8",
        ]
        raw_mime = "\r\n".join(headers) + "\r\n\r\n" + body_plain

    raw_bytes = raw_mime.encode("utf-8", errors="replace")

    print(f"Forwarding email from {sender} to {recipient} via {MAILSERVER_HOST}:{MAILSERVER_PORT}")

    try:
        # Run blocking SMTP send in a thread so we don't block the event loop
        await run_in_threadpool(smtp_forward, sender, recipient, raw_bytes)
    except Exception as e:
        print("Error forwarding mail:", repr(e))
        raise HTTPException(status_code=500, detail="Failed to forward mail to SMTP")

    return "OK"
