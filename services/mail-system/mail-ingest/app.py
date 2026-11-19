import os
import hmac
import hashlib
import smtplib
import re
import json
import time
import uuid
import logging
import threading
from email.message import EmailMessage
from email.policy import SMTP
from email.utils import formatdate

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


# Reject a webhook whose Mailgun timestamp is further than this from our clock.
MAX_TIMESTAMP_SKEW_SECONDS = int(os.getenv("MAX_TIMESTAMP_SKEW_SECONDS", "300"))

# Remember each accepted Mailgun token for this long and refuse to process it twice.
REPLAY_WINDOW_SECONDS = int(os.getenv("REPLAY_WINDOW_SECONDS", "900"))

# Refuse a request body larger than this before any form parsing happens.
MAX_BODY_BYTES = int(os.getenv("MAX_BODY_BYTES", str(30 * 1024 * 1024)))

REJECTED_TOTAL = Counter(
    "mailgun_rejected_total",
    "Mailgun webhook requests rejected before forwarding",
    labelnames=["reason"],
)

# token -> unix time the reservation expires. Only ever holds tokens from
# requests whose signature already verified, so an unauthenticated caller
# cannot fill it or evict anything.
_seen_tokens: dict[str, float] = {}
_seen_tokens_lock = threading.Lock()


def _prune_seen_tokens(now: float) -> None:
    """Drop expired reservations. Caller holds the lock."""

    for token in [t for t, expiry in _seen_tokens.items() if expiry <= now]:
        del _seen_tokens[token]


def reserve_token(token: str, now: float | None = None) -> bool:
    """
    Claim a Mailgun token for the replay window.

    Returns True when the token is new and now reserved, False when it is a
    replay. Release the reservation with release_token() if the request could
    not be processed, so that Mailgun's retry of a genuinely failed delivery is
    not mistaken for a replay.
    """

    now = time.time() if now is None else now
    with _seen_tokens_lock:
        _prune_seen_tokens(now)
        if token in _seen_tokens:
            return False
        _seen_tokens[token] = now + REPLAY_WINDOW_SECONDS
        return True


def release_token(token: str) -> None:
    """Give a token back after a failed delivery so Mailgun may retry it."""

    with _seen_tokens_lock:
        _seen_tokens.pop(token, None)


def timestamp_is_fresh(timestamp: str, now: float | None = None) -> bool:
    """True when Mailgun's timestamp is within MAX_TIMESTAMP_SKEW_SECONDS of our clock."""

    now = time.time() if now is None else now
    try:
        sent_at = float(timestamp)
    except (TypeError, ValueError):
        return False
    return abs(now - sent_at) <= MAX_TIMESTAMP_SKEW_SECONDS


async def read_body_within_limit(request: Request) -> bytes:
    """
    Read the request body, refusing anything over MAX_BODY_BYTES.

    This runs before request.form() so an oversized upload is dropped without
    being parsed. A declared Content-Length is checked first; the streaming
    count then covers chunked bodies and a Content-Length that lies. The body
    is cached on the request so that request.form() reuses it rather than
    trying to read the consumed stream again.
    """

    declared = request.headers.get("content-length")
    if declared is not None:
        try:
            declared_length = int(declared)
        except ValueError:
            REJECTED_TOTAL.labels(reason="bad_content_length").inc()
            raise HTTPException(status_code=400, detail="Invalid Content-Length")
        if declared_length > MAX_BODY_BYTES:
            REJECTED_TOTAL.labels(reason="body_too_large").inc()
            raise HTTPException(status_code=413, detail="Request body too large")

    chunks: list[bytes] = []
    received = 0
    async for chunk in request.stream():
        received += len(chunk)
        if received > MAX_BODY_BYTES:
            REJECTED_TOTAL.labels(reason="body_too_large").inc()
            raise HTTPException(status_code=413, detail="Request body too large")
        chunks.append(chunk)

    body = b"".join(chunks)
    request._body = body
    return body


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


def mailgun_message_header(form, name: str) -> str:
    """Read a header from Mailgun's signed webhook fields without allowing CRLF injection."""

    for candidate in (name, name.lower(), name.title()):
        value = form.get(candidate)
        if value:
            return re.sub(r"[\r\n]+", " ", str(value)).strip()

    try:
        message_headers = json.loads(str(form.get("message-headers") or "[]"))
    except (TypeError, ValueError, json.JSONDecodeError):
        return ""

    for item in message_headers:
        if (
            isinstance(item, list)
            and len(item) == 2
            and str(item[0]).casefold() == name.casefold()
        ):
            return re.sub(r"[\r\n]+", " ", str(item[1])).strip()
    return ""


def build_fallback_message(
    sender: str,
    recipient: str,
    subject: str,
    body_plain: str,
    reply_to: str = "",
) -> bytes:
    """Build a safe MIME message when Mailgun does not supply body-mime."""

    message = EmailMessage(policy=SMTP)
    message["From"] = sender
    message["To"] = recipient
    message["Subject"] = subject
    message["Date"] = formatdate(localtime=True)
    message["Message-ID"] = f"<{uuid.uuid4()}@{MAILSERVER_HELO_DOMAIN}>"
    if reply_to:
        message["Reply-To"] = reply_to
    message.set_content(body_plain)
    return message.as_bytes()


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
    # Enforce the size cap before the form is parsed.
    await read_body_within_limit(request)

    form = await request.form()

    client_ip = request.client.host if request.client else "unknown"

    # --- Verify Mailgun signature ---
    timestamp = form.get("timestamp", "")
    token = form.get("token", "")
    signature = form.get("signature", "")

    if not verify_mailgun_signature(MAILGUN_WEBHOOK_SIGNING_KEY, timestamp, token, signature):
        logger.warning("invalid_mailgun_signature %s", {"client_ip": client_ip})
        REJECTED_TOTAL.labels(reason="invalid_signature").inc()
        raise HTTPException(status_code=403, detail="Invalid Mailgun signature")

    # Only signature-verified requests get past this point, so the freshness
    # and replay checks below cannot be driven by an anonymous caller.
    if not timestamp_is_fresh(str(timestamp)):
        logger.warning(
            "stale_mailgun_timestamp %s",
            {"client_ip": client_ip, "timestamp": timestamp},
        )
        REJECTED_TOTAL.labels(reason="stale_timestamp").inc()
        raise HTTPException(status_code=403, detail="Stale Mailgun timestamp")

    if not reserve_token(str(token)):
        logger.warning("replayed_mailgun_token %s", {"client_ip": client_ip})
        REJECTED_TOTAL.labels(reason="replayed_token").inc()
        raise HTTPException(status_code=409, detail="Duplicate Mailgun token")

    sender = form.get("sender") or form.get("from") or "unknown@localhost"
    from_header = form.get("from") or sender
    recipient = form.get("recipient") or form.get("to") or "unknown@localhost"
    message_id = form.get("Message-Id") or form.get("message-id")

    # Prefer raw MIME if Mailgun provides it (Store and Notify)
    raw_mime = form.get("body-mime")

    if not raw_mime:
        # Fallback: reconstruct a safe message while retaining reply routing.
        subject = form.get("subject") or ""
        body_plain = form.get("body-plain") or ""
        raw_bytes = build_fallback_message(
            str(from_header),
            str(recipient),
            str(subject),
            str(body_plain),
            mailgun_message_header(form, "Reply-To"),
        )
    else:
        raw_bytes = str(raw_mime).encode("utf-8", errors="replace")

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
        release_token(str(token))
        SMTP_ERRORS.labels(reason="recipient_refused").inc()
        REQUESTS_TOTAL.labels(result="invalid_recipient").inc()
        logger.warning(
            "smtp_recipient_refused %s",
            {"error": repr(e), "recipient": recipient, "client_ip": client_ip},
        )
        raise HTTPException(status_code=422, detail="No valid recipients")
    except smtplib.SMTPDataError as e:
        release_token(str(token))
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
        release_token(str(token))
        SMTP_ERRORS.labels(reason="parse_error").inc()
        REQUESTS_TOTAL.labels(result="parse_error").inc()
        logger.warning(
            "recipient_parsing_error %s",
            {"error": repr(e), "raw_recipient": recipient},
        )
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        release_token(str(token))
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
