#!/bin/bash
# prepare.sh - Copy tracked config into the DMS data directory
# Runs on the HOST before docker compose up

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Rspamd overrides ──
RSPAMD_SRC="${SCRIPT_DIR}/config/rspamd/override.d"
RSPAMD_DST="${SCRIPT_DIR}/data/dms/config/rspamd/override.d"

if [ -d "$RSPAMD_SRC" ]; then
    mkdir -p "$RSPAMD_DST"
    cp -v "$RSPAMD_SRC"/* "$RSPAMD_DST/"
fi

# ── Fail2ban overrides ──
F2B_SRC="${SCRIPT_DIR}/config/fail2ban-jail.cf"
F2B_DST="${SCRIPT_DIR}/data/dms/config/fail2ban-jail.cf"

if [ -f "$F2B_SRC" ]; then
    cp -v "$F2B_SRC" "$F2B_DST"
fi
