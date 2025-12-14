import os
import hmac
import hashlib
import smtplib
import re
import time
import logging

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import PlainTextResponse, Response
from fastapi.concurrency import run_in_threadpool
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI()

MAILGUN_WEBHOOK_SIGNING_KEY = os.getenv("MAILGUN_WEBHOOK_SIGNING_KEY", "").strip()

# Internal mailserver container (docker-mailserver)
MAILSERVER_HOST = os.getenv("MAILSERVER_HOST", "mailserver")
MAILSERVER_PORT = int(os.getenv("MAILSERVER_PORT", "25"))
MAILSERVER_HELO_DOMAIN = os.getenv("MAILSERVER_HELO_DOMAIN", "mail-ingest.local")
SMTP_TIMEOUT = float(os.getenv("SMTP_TIMEOUT_SECONDS", "15"))
SMTP_RETRY_ATTEMPTS = int(os.getenv("SMTP_RETRY_ATTEMPTS", "2"))
SMTP_RETRY_DELAY = float(os.getenv("SMTP_RETRY_DELAY_SECONDS", "2"))

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("mail-ingest")

# Prometheus metrics
REQUESTS_TOTAL = Counter(
    "mailgun_requests_total",
    "Mailgun webhook requests processed",
    labelnames=["result"],
)
SMTP_FORWARD_DURATION = Histogram(
    "smtp_forward_seconds",
    "SMTP forward latency",
    buckets=(0.1, 0.3, 1, 3, 5, 10, 30),
)
SMTP_ERRORS = Counter(
    "smtp_forward_errors_total",
    "SMTP forwarding failures by type",
    labelnames=["reason"],
)


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
    Blocking SMTP send into docker-mailserver. Retries a few times to avoid transient drops.
    """

    last_exc: Exception | None = None
    recipients = [addr.strip() for addr in re.split(r"[,;]", envelope_to) if addr.strip()]
    if not recipients:
        raise ValueError("No valid recipients after parsing")

    for attempt in range(1, SMTP_RETRY_ATTEMPTS + 1):
        try:
            with smtplib.SMTP(MAILSERVER_HOST, MAILSERVER_PORT, timeout=SMTP_TIMEOUT) as smtp:
                smtp.ehlo(MAILSERVER_HELO_DOMAIN)
                # internal, no TLS/auth needed
                smtp.mail(envelope_from)
                for rcpt in recipients:
                    smtp.rcpt(rcpt)
                smtp.data(raw_mime)
            return
        except Exception as exc:  # noqa: PERF203 - we want to surface all SMTP/network issues
            last_exc = exc
            logger.warning(
                "smtp_forward_attempt_failed %s",
                {
                    "attempt": attempt,
                    "max_attempts": SMTP_RETRY_ATTEMPTS,
                    "error": repr(exc),
                    "host": MAILSERVER_HOST,
                    "port": MAILSERVER_PORT,
                },
            )
            if attempt < SMTP_RETRY_ATTEMPTS:
                time.sleep(SMTP_RETRY_DELAY)

    if last_exc:
        raise last_exc


@app.get("/healthz", response_class=PlainTextResponse)
async def healthz():
    return "OK"


@app.get("/metrics")
async def metrics():
    data = generate_latest()
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)


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

    client_ip = request.client.host if request.client else "unknown"

    # --- Verify Mailgun signature ---
    timestamp = form.get("timestamp", "")
    token = form.get("token", "")
    signature = form.get("signature", "")

    if not verify_mailgun_signature(MAILGUN_WEBHOOK_SIGNING_KEY, timestamp, token, signature):
        logger.warning("invalid_mailgun_signature %s", {"client_ip": client_ip})
        raise HTTPException(status_code=403, detail="Invalid Mailgun signature")

    sender = form.get("sender") or form.get("from") or "unknown@localhost"
    recipient = form.get("recipient") or form.get("to") or "unknown@localhost"
    message_id = form.get("Message-Id") or form.get("message-id")

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

    logger.info(
        "forwarding_email %s",
        {
            "from": sender,
            "to": recipient,
            "mailserver": f"{MAILSERVER_HOST}:{MAILSERVER_PORT}",
            "client_ip": client_ip,
            "message_id": message_id,
            "raw_size_bytes": len(raw_bytes),
        },
    )

    start = time.perf_counter()
    try:
        # Run blocking SMTP send in a thread so we don't block the event loop
        await run_in_threadpool(smtp_forward, sender, recipient, raw_bytes)
        duration = time.perf_counter() - start
        SMTP_FORWARD_DURATION.observe(duration)
        REQUESTS_TOTAL.labels(result="success").inc()
        logger.info(
            "smtp_forward_success %s",
            {"duration_seconds": round(duration, 3), "client_ip": client_ip},
        )
    except smtplib.SMTPRecipientsRefused as e:
        SMTP_ERRORS.labels(reason="recipient_refused").inc()
        REQUESTS_TOTAL.labels(result="invalid_recipient").inc()
        logger.warning(
            "smtp_recipient_refused %s",
            {"error": repr(e), "recipient": recipient, "client_ip": client_ip},
        )
        raise HTTPException(status_code=422, detail="No valid recipients")
    except smtplib.SMTPDataError as e:
        SMTP_ERRORS.labels(reason="smtp_data_error").inc()
        duration = time.perf_counter() - start
        SMTP_FORWARD_DURATION.observe(duration)
        logger.warning(
            "smtp_data_error %s",
            {
                "error": repr(e),
                "code": getattr(e, "smtp_code", None),
                "client_ip": client_ip,
                "duration_seconds": round(duration, 3),
            },
        )
        code, message = e.smtp_code, (e.smtp_error or b"?").decode(errors="replace")
        if code in (550, 551, 552, 553, 554):
            raise HTTPException(status_code=422, detail=f"SMTP {code}: {message}")
        raise HTTPException(status_code=502, detail="Upstream SMTP rejected message")
    except ValueError as e:
        SMTP_ERRORS.labels(reason="parse_error").inc()
        REQUESTS_TOTAL.labels(result="parse_error").inc()
        logger.warning(
            "recipient_parsing_error %s",
            {"error": repr(e), "raw_recipient": recipient},
        )
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        SMTP_ERRORS.labels(reason=type(e).__name__).inc()
        duration = time.perf_counter() - start
        SMTP_FORWARD_DURATION.observe(duration)
        REQUESTS_TOTAL.labels(result="error").inc()
        logger.exception(
            "smtp_forward_unhandled_error %s",
            {
                "error": repr(e),
                "client_ip": client_ip,
                "duration_seconds": round(duration, 3),
            },
        )
        raise HTTPException(status_code=500, detail="Failed to forward mail to SMTP")

    return "OK"
