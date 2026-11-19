import hashlib
import hmac
import json
import time
import unittest
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
