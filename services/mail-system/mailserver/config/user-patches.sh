#!/bin/bash
# user-patches.sh - Run by docker-mailserver inside the container at startup,
# after its own configuration and before Postfix starts.
# prepare.sh copies this file into data/dms/config/. A container restart runs
# it again over the already-patched files, so every step must be idempotent.

set -euo pipefail

# ── mail-ingest listener ──
# mail-ingest relays mail that Mailgun has already accepted, after Mailgun's
# own SPF/DKIM checks at the edge. On port 25 Postfix re-checks the original
# sender's SPF against mail-ingest's Docker address, which fails for every
# sender publishing -all.
#
# This listener is for mail-ingest alone:
#   - requires STARTTLS and a SASL login as MAIL_INGEST_SMTP_USER, nobody else
#   - accepts local recipients only, so it cannot relay even when authenticated
#   - skips the SPF policy service
#   - withholds the login from milters, so Rspamd, OpenDKIM and OpenDMARC
#     treat the message as inbound rather than as mail sent by a local user
# The port is not published on the host.
# MAIL_INGEST_SMTP_USER is also barred from submission (587/465), so its
# credential cannot be used to send mail out.

INGEST_PORT="${MAIL_INGEST_SMTP_PORT:-10587}"
INGEST_USER="${MAIL_INGEST_SMTP_USER:-}"

if [[ -z "$INGEST_USER" ]]; then
  echo "user-patches: MAIL_INGEST_SMTP_USER is unset; mail-ingest listener not configured"
  exit 0
fi

printf '%s OK\n' "$INGEST_USER" > /etc/postfix/mail-ingest-login
printf '%s REJECT this account only delivers inbound mail\n' "$INGEST_USER" > /etc/postfix/mail-ingest-deny

# Keep the mailbox quota check that port 25 applies, when quotas are enabled.
recipient_restrictions="reject_unauth_destination"
if postconf -h smtpd_recipient_restrictions | grep -q 'inet:localhost:65265'; then
  recipient_restrictions+=", check_policy_service inet:localhost:65265"
fi

postconf -e \
  "mail_ingest_client_restrictions = check_sasl_access texthash:/etc/postfix/mail-ingest-login, reject" \
  "mail_ingest_relay_restrictions = reject_unauth_destination, permit" \
  "mail_ingest_recipient_restrictions = ${recipient_restrictions}" \
  "mail_ingest_milter_mail_macros = i {mail_addr} {mail_host} {mail_mailer}"

postconf -M "${INGEST_PORT}/inet=${INGEST_PORT} inet n - n - - smtpd"
postconf -P \
  "${INGEST_PORT}/inet/syslog_name=postfix/mail-ingest" \
  "${INGEST_PORT}/inet/smtpd_tls_security_level=encrypt" \
  "${INGEST_PORT}/inet/smtpd_tls_auth_only=yes" \
  "${INGEST_PORT}/inet/smtpd_sasl_auth_enable=yes" \
  "${INGEST_PORT}/inet/smtpd_sasl_type=dovecot" \
  "${INGEST_PORT}/inet/smtpd_sasl_authenticated_header=no" \
  "${INGEST_PORT}/inet/smtpd_client_restrictions=\$mail_ingest_client_restrictions" \
  "${INGEST_PORT}/inet/smtpd_relay_restrictions=\$mail_ingest_relay_restrictions" \
  "${INGEST_PORT}/inet/smtpd_recipient_restrictions=\$mail_ingest_recipient_restrictions" \
  "${INGEST_PORT}/inet/milter_mail_macros=\$mail_ingest_milter_mail_macros"

mua_sender="$(postconf -h mua_sender_restrictions)"
if [[ "$mua_sender" != *mail-ingest-deny* ]]; then
  postconf -e "mua_sender_restrictions = check_sasl_access texthash:/etc/postfix/mail-ingest-deny, ${mua_sender}"
fi

echo "user-patches: mail-ingest listener on ${INGEST_PORT} for ${INGEST_USER}"
