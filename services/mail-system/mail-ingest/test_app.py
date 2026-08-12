import json
import unittest
from email import policy
from email.parser import BytesParser

from app import build_fallback_message, mailgun_message_header


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


if __name__ == "__main__":
    unittest.main()
