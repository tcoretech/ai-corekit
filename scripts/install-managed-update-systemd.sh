#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this installer as root." >&2
  exit 1
fi

PROJECT_ROOT="/home/services/ai-launchkit"
UNIT_SOURCE="$PROJECT_ROOT/systemd"
STATE_ROOT="/home/services/.local/state/ai-corekit/managed-updates"
BACKUP_ROOT="/home/services/backups/ai-corekit/n8n"

id services >/dev/null 2>&1 || {
  echo "The services account does not exist." >&2
  exit 1
}

install -d -o services -g services -m 0700 "$STATE_ROOT" "$BACKUP_ROOT"
chown services:services "$STATE_ROOT" "$BACKUP_ROOT"
chmod 0700 "$STATE_ROOT" "$BACKUP_ROOT"
for unit in \
  corekit-managed-update-check.service \
  corekit-managed-update-check.timer \
  corekit-managed-update-apply.service \
  corekit-managed-update-apply.timer; do
  install -o root -g root -m 0644 "$UNIT_SOURCE/$unit" "/etc/systemd/system/$unit"
done

systemctl daemon-reload
systemctl enable --now corekit-managed-update-check.timer corekit-managed-update-apply.timer
systemctl start corekit-managed-update-check.service
systemctl --no-pager --full status corekit-managed-update-check.service
systemctl --no-pager list-timers corekit-managed-update-check.timer corekit-managed-update-apply.timer
