import hashlib
import hmac
import json
import smtplib
import ssl
import time
import unittest
from unittest import mock
from email import policy
from email.parser import BytesParser

from fastapi.testclient import TestClient

import app as app_module
from app import (
    MAX_BODY_BYTES,
    app,
    build_fallback_message,
    mailgun_message_header,
    release_token,
    reserve_token,
    timestamp_is_fresh,
)

SIGNING_KEY = "test-signing-key"


def signed_form(timestamp=None, token="token-0001"):
    """Build the signed fields Mailgun sends, using the key the tests install."""

    timestamp = str(int(time.time())) if timestamp is None else str(timestamp)
    signature = hmac.new(
        key=SIGNING_KEY.encode("utf-8"),
        msg=f"{timestamp}{token}".encode("utf-8"),
        digestmod=hashlib.sha256,
    ).hexdigest()
    return {
        "timestamp": timestamp,
        "token": token,
        "signature": signature,
        "sender": "visitor@gmail.com",
        "recipient": "info@example.com",
        "subject": "hello",
        "body-plain": "hello",
    }


class MailgunHeaderTests(unittest.TestCase):
    def test_reads_reply_to_from_message_headers_case_insensitively(self):
        form = {
            "message-headers": json.dumps(
                [["From", "TCoreTech <updates@example.com>"], ["reply-to", "reader@example.com"]]
            )
        }

        self.assertEqual(mailgun_message_header(form, "Reply-To"), "reader@example.com")

    def test_direct_header_wins_and_cannot_inject_another_header(self):
        form = {
            "Reply-To": "reader@example.com\r\nBcc: hidden@example.com",
            "message-headers": json.dumps([["Reply-To", "other@example.com"]]),
        }

        self.assertEqual(
            mailgun_message_header(form, "Reply-To"),
            "reader@example.com Bcc: hidden@example.com",
        )

    def test_fallback_message_preserves_reply_to_and_display_from(self):
        raw = build_fallback_message(
            "TCoreTech <updates@example.com>",
            "info@example.com",
            "Website enquiry",
            "Please reply to the visitor.",
            "reader@example.com",
        )
        message = BytesParser(policy=policy.default).parsebytes(raw)

        self.assertEqual(message["From"], "TCoreTech <updates@example.com>")
        self.assertEqual(message["To"], "info@example.com")
        self.assertEqual(message["Reply-To"], "reader@example.com")
        self.assertEqual(message.get_content().strip(), "Please reply to the visitor.")


class RejectionTests(unittest.TestCase):
    """The three rejections added on 2026-09-26: stale timestamp, replayed token, oversized body."""

    def setUp(self):
        self.client = TestClient(app)
        self._old_key = app_module.MAILGUN_WEBHOOK_SIGNING_KEY
        app_module.MAILGUN_WEBHOOK_SIGNING_KEY = SIGNING_KEY
        app_module._seen_tokens.clear()
        # Fail loudly rather than reaching the real mailserver from a test.
        self._forwarded = []
        self._old_forward = app_module.smtp_forward
        app_module.smtp_forward = lambda *a, **kw: self._forwarded.append(a)

    def tearDown(self):
        app_module.MAILGUN_WEBHOOK_SIGNING_KEY = self._old_key
        app_module.smtp_forward = self._old_forward
        app_module._seen_tokens.clear()

    def test_a_correctly_signed_fresh_request_is_forwarded(self):
        response = self.client.post("/mailgun/incoming", data=signed_form())

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(self._forwarded), 1)

    def test_raw_mime_from_a_forward_route_is_relayed_unchanged(self):
        raw = (
            "From: Visitor <visitor@gmail.com>\r\n"
            "To: info@example.com\r\n"
            "Subject: hello\r\n"
            "Content-Type: text/html; charset=utf-8\r\n"
            "\r\n"
            "<p>hello</p>\r\n"
        )
        form = signed_form()
        form["body-mime"] = raw

        response = self.client.post("/mailgun/incoming-mime", data=form)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(self._forwarded, [("visitor@gmail.com", "info@example.com", raw.encode())])

    def test_raw_mime_sent_as_a_file_part_is_relayed_unchanged(self):
        raw = b"From: visitor@gmail.com\r\nSubject: hello\r\n\r\nhello\r\n"

        response = self.client.post(
            "/mailgun/incoming-mime",
            data=signed_form(),
            files={"body-mime": ("message.mime", raw, "message/rfc822")},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(self._forwarded[0][2], raw)

    def test_timestamp_older_than_five_minutes_is_rejected(self):
        stale = int(time.time()) - 301
        response = self.client.post("/mailgun/incoming", data=signed_form(timestamp=stale))

        self.assertEqual(response.status_code, 403)
        self.assertIn("Stale", response.json()["detail"])
        self.assertEqual(self._forwarded, [])

    def test_timestamp_more_than_five_minutes_in_the_future_is_rejected(self):
        ahead = int(time.time()) + 301
        response = self.client.post("/mailgun/incoming", data=signed_form(timestamp=ahead))

        self.assertEqual(response.status_code, 403)
        self.assertEqual(self._forwarded, [])

    def test_timestamp_just_inside_the_window_is_accepted(self):
        response = self.client.post(
            "/mailgun/incoming", data=signed_form(timestamp=int(time.time()) - 299)
        )

        self.assertEqual(response.status_code, 200)

    def test_token_replayed_within_the_window_is_rejected(self):
        form = signed_form(token="replay-me")

        first = self.client.post("/mailgun/incoming", data=form)
        second = self.client.post("/mailgun/incoming", data=form)

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 409)
        self.assertIn("Duplicate", second.json()["detail"])
        self.assertEqual(len(self._forwarded), 1)

    def test_token_is_released_so_mailgun_may_retry_a_failed_delivery(self):
        def boom(*a, **kw):
            raise RuntimeError("mailserver unreachable")

        app_module.smtp_forward = boom
        form = signed_form(token="retry-me")

        failed = self.client.post("/mailgun/incoming", data=form)
        self.assertEqual(failed.status_code, 500)

        app_module.smtp_forward = lambda *a, **kw: self._forwarded.append(a)
        retried = self.client.post("/mailgun/incoming", data=form)

        self.assertEqual(retried.status_code, 200)
        self.assertEqual(len(self._forwarded), 1)

    def test_body_over_thirty_megabytes_is_rejected_before_parsing(self):
        oversized = b"x" * (MAX_BODY_BYTES + 1)

        response = self.client.post(
            "/mailgun/incoming",
            content=oversized,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

        self.assertEqual(response.status_code, 413)
        self.assertIn("too large", response.json()["detail"])
        self.assertEqual(self._forwarded, [])

    def test_oversized_body_is_rejected_on_a_lying_content_length(self):
        """A chunked body with no Content-Length is still counted as it streams."""

        def chunks():
            sent = 0
            while sent <= MAX_BODY_BYTES:
                block = b"x" * (1024 * 1024)
                sent += len(block)
                yield block

        response = self.client.post(
            "/mailgun/incoming",
            content=chunks(),
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

        self.assertEqual(response.status_code, 413)
        self.assertEqual(self._forwarded, [])

    def test_a_body_under_the_limit_still_parses(self):
        form = signed_form()
        form["body-plain"] = "y" * 1024

        response = self.client.post("/mailgun/incoming", data=form)

        self.assertEqual(response.status_code, 200)

    def test_an_unsigned_request_is_rejected_before_the_replay_cache_is_touched(self):
        form = signed_form(token="never-reserve-me")
        form["signature"] = "0" * 64

        response = self.client.post("/mailgun/incoming", data=form)

        self.assertEqual(response.status_code, 403)
        self.assertNotIn("never-reserve-me", app_module._seen_tokens)


class ReplayCacheUnitTests(unittest.TestCase):
    def setUp(self):
        app_module._seen_tokens.clear()

    def tearDown(self):
        app_module._seen_tokens.clear()

    def test_reserve_then_replay(self):
        self.assertTrue(reserve_token("t1"))
        self.assertFalse(reserve_token("t1"))

    def test_reservation_expires_after_the_window(self):
        now = time.time()
        self.assertTrue(reserve_token("t2", now=now))
        self.assertFalse(reserve_token("t2", now=now + 899))
        self.assertTrue(reserve_token("t2", now=now + 901))

    def test_release_allows_immediate_retry(self):
        self.assertTrue(reserve_token("t3"))
        release_token("t3")
        self.assertTrue(reserve_token("t3"))


class TimestampFreshnessUnitTests(unittest.TestCase):
    def test_boundaries(self):
        now = 1_000_000.0
        self.assertTrue(timestamp_is_fresh(str(int(now)), now=now))
        self.assertTrue(timestamp_is_fresh(str(int(now - 300)), now=now))
        self.assertFalse(timestamp_is_fresh(str(int(now - 301)), now=now))
        self.assertTrue(timestamp_is_fresh(str(int(now + 300)), now=now))
        self.assertFalse(timestamp_is_fresh(str(int(now + 301)), now=now))

    def test_non_numeric_timestamp_is_not_fresh(self):
        self.assertFalse(timestamp_is_fresh("not-a-number"))
        self.assertFalse(timestamp_is_fresh(""))


if __name__ == "__main__":
    unittest.main()


class FakeSMTP:
    """Records what smtp_forward does to the mailserver connection."""

    instances: list["FakeSMTP"] = []
    rcpt_codes: dict[str, int] = {}
    starttls_error: Exception | None = None
    peer_cert = b"mailserver-cert-der"

    def __init__(self, host, port, timeout=None):
        self._host = host
        self.calls: list[tuple] = []
        FakeSMTP.instances.append(self)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def ehlo(self, name):
        self.calls.append(("ehlo", name))

    def starttls(self, context=None):
        if FakeSMTP.starttls_error:
            raise FakeSMTP.starttls_error
        self.calls.append(("starttls", self._host, context.check_hostname))
        self.sock = mock.Mock(getpeercert=lambda binary_form=False: FakeSMTP.peer_cert)

    def login(self, user, password):
        self.calls.append(("login", user))

    def mail(self, sender):
        self.calls.append(("mail", sender))

    def rcpt(self, rcpt):
        code = FakeSMTP.rcpt_codes.get(rcpt, 250)
        self.calls.append(("rcpt", rcpt))
        return code, b"5.7.1 refused" if code >= 400 else b"2.1.5 Ok"

    def data(self, raw):
        self.calls.append(("data",))


class SmtpForwardTests(unittest.TestCase):
    def setUp(self):
        FakeSMTP.instances = []
        FakeSMTP.rcpt_codes = {}
        FakeSMTP.starttls_error = None
        patches = [
            mock.patch.object(app_module.smtplib, "SMTP", FakeSMTP),
            mock.patch.object(app_module, "SMTP_RETRY_ATTEMPTS", 1),
            mock.patch.object(app_module, "MAILSERVER_SMTP_USER", "mail-ingest@example.com"),
            mock.patch.object(app_module, "MAILSERVER_SMTP_PASSWORD", "pw"),
            mock.patch.object(app_module, "MAILSERVER_TLS_SERVER_NAME", "mail.example.com"),
        ]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)

    def calls(self):
        return [c[0] for c in FakeSMTP.instances[-1].calls]

    def test_logs_in_after_starttls_verified_against_the_public_name(self):
        app_module.smtp_forward("a@hotmail.com", "tom@example.com", b"raw")
        self.assertEqual(
            self.calls(), ["ehlo", "starttls", "ehlo", "login", "mail", "rcpt", "data"]
        )
        self.assertEqual(
            FakeSMTP.instances[-1].calls[1], ("starttls", "mail.example.com", True)
        )

    def test_never_logs_in_when_starttls_is_unavailable(self):
        FakeSMTP.starttls_error = smtplib.SMTPNotSupportedError("no STARTTLS")
        with self.assertRaises(smtplib.SMTPNotSupportedError):
            app_module.smtp_forward("a@hotmail.com", "tom@example.com", b"raw")
        self.assertNotIn("login", self.calls())

    def test_without_a_login_configured_it_relays_unauthenticated(self):
        with mock.patch.object(app_module, "MAILSERVER_SMTP_USER", ""):
            app_module.smtp_forward("a@hotmail.com", "tom@example.com", b"raw")
        self.assertEqual(self.calls(), ["ehlo", "mail", "rcpt", "data"])

    def test_refused_recipient_raises_instead_of_reaching_data(self):
        FakeSMTP.rcpt_codes = {"tom@example.com": 550}
        with self.assertRaises(smtplib.SMTPRecipientsRefused):
            app_module.smtp_forward("a@hotmail.com", "tom@example.com", b"raw")
        self.assertNotIn("data", self.calls())

    def test_partly_refused_recipients_still_deliver_to_the_rest(self):
        FakeSMTP.rcpt_codes = {"bad@example.com": 550}
        with self.assertLogs("mail-ingest", level="ERROR"):
            app_module.smtp_forward("a@hotmail.com", "tom@example.com, bad@example.com", b"raw")
        self.assertIn("data", self.calls())

    def test_refused_recipient_is_reported_to_mailgun_as_422(self):
        FakeSMTP.rcpt_codes = {"info@example.com": 550}
        with mock.patch.object(app_module, "MAILGUN_WEBHOOK_SIGNING_KEY", SIGNING_KEY):
            response = TestClient(app).post("/mailgun/incoming", data=signed_form(token="token-rcpt"))
        self.assertEqual(response.status_code, 422)

    def test_pinned_certificate_that_matches_is_trusted(self):
        pin = hashlib.sha256(FakeSMTP.peer_cert).hexdigest()
        with mock.patch.object(app_module, "MAILSERVER_TLS_FINGERPRINT", pin):
            app_module.smtp_forward("a@hotmail.com", "tom@example.com", b"raw")
        self.assertIn("login", self.calls())

    def test_pinned_certificate_that_differs_is_refused_before_login(self):
        with mock.patch.object(app_module, "MAILSERVER_TLS_FINGERPRINT", "00" * 32):
            with self.assertRaises(ssl.SSLError):
                app_module.smtp_forward("a@hotmail.com", "tom@example.com", b"raw")
        self.assertNotIn("login", self.calls())
