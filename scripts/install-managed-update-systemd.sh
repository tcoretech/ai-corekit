#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${COREKIT_PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SERVICE_USER="${COREKIT_SYSTEMD_USER:-}"
SERVICE_GROUP="${COREKIT_SYSTEMD_GROUP:-}"
STATE_ROOT="${COREKIT_MANAGED_STATE_ROOT:-}"
BACKUP_ROOT="${COREKIT_N8N_BACKUP_ROOT:-}"
RENDER_ONLY_DIR=""

usage() {
  cat <<'EOF'
Usage: install-managed-update-systemd.sh [options]

Options:
  --user USER          Unprivileged account that owns the CoreKit runtime
  --group GROUP        Runtime group (defaults to USER's primary group)
  --project-root PATH  CoreKit checkout (defaults to the installer's parent)
  --state-root PATH    Protected updater state directory
  --backup-root PATH   Protected n8n recovery-set directory
  --render-only PATH   Render and verify units into PATH without installing them
  -h, --help           Show this help

The installer never selects root as the runtime account implicitly. When --user
is omitted it uses the non-root sudo caller, then the non-root checkout owner.
EOF
}

fail() {
  echo "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      SERVICE_USER="$2"
      shift 2
      ;;
    --group)
      SERVICE_GROUP="$2"
      shift 2
      ;;
    --project-root)
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --state-root)
      STATE_ROOT="$2"
      shift 2
      ;;
    --backup-root)
      BACKUP_ROOT="$2"
      shift 2
      ;;
    --render-only)
      RENDER_ONLY_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown installer option: $1"
      ;;
  esac
done

PROJECT_ROOT="$(realpath -e "$PROJECT_ROOT")"
[[ -x "$PROJECT_ROOT/corekit.sh" ]] || fail "CoreKit executable not found under project root: $PROJECT_ROOT"

if [[ -z "$SERVICE_USER" && -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]]; then
  SERVICE_USER="$SUDO_USER"
fi
if [[ -z "$SERVICE_USER" ]]; then
  PROJECT_OWNER="$(stat -c '%U' "$PROJECT_ROOT")"
  if [[ "$PROJECT_OWNER" != "root" ]]; then
    SERVICE_USER="$PROJECT_OWNER"
  fi
fi
[[ -n "$SERVICE_USER" ]] || fail "Specify --user; the installer will not run scheduled updates as root implicitly."
[[ "$SERVICE_USER" != "root" ]] || fail "Choose an unprivileged runtime account instead of root."
id "$SERVICE_USER" >/dev/null 2>&1 || fail "Runtime account does not exist: $SERVICE_USER"

if [[ -z "$SERVICE_GROUP" ]]; then
  SERVICE_GROUP="$(id -gn "$SERVICE_USER")"
fi
getent group "$SERVICE_GROUP" >/dev/null 2>&1 || fail "Runtime group does not exist: $SERVICE_GROUP"

SERVICE_HOME="$(getent passwd "$SERVICE_USER" | awk -F: 'NR == 1 {print $6}')"
[[ -n "$SERVICE_HOME" ]] || fail "Runtime account has no home directory: $SERVICE_USER"
STATE_ROOT="${STATE_ROOT:-$SERVICE_HOME/.local/state/ai-corekit/managed-updates}"
BACKUP_ROOT="${BACKUP_ROOT:-$SERVICE_HOME/.local/share/ai-corekit/backups/n8n}"
STATE_ROOT="$(realpath -m "$STATE_ROOT")"
BACKUP_ROOT="$(realpath -m "$BACKUP_ROOT")"

for path_value in "$PROJECT_ROOT" "$STATE_ROOT" "$BACKUP_ROOT"; do
  [[ "$path_value" =~ ^/[A-Za-z0-9._/+:,-]+$ ]] || {
    fail "Configured paths must be absolute and contain no whitespace, percent signs, or shell metacharacters: $path_value"
  }
done
[[ "$SERVICE_USER" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]] || fail "Unsupported runtime account name: $SERVICE_USER"
[[ "$SERVICE_GROUP" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]] || fail "Unsupported runtime group name: $SERVICE_GROUP"

UNIT_SOURCE="$PROJECT_ROOT/systemd"
UNIT_DIR="/etc/systemd/system"
RENDER_ROOT="$(mktemp -d /tmp/corekit-managed-systemd.XXXXXX)"
trap 'rm -rf -- "$RENDER_ROOT"' EXIT

render_service() {
  local template="$1"
  local output="$2"
  local rendered

  [[ -f "$template" ]] || fail "Unit template is missing: $template"
  rendered="$(<"$template")"
  rendered="${rendered//@COREKIT_USER@/$SERVICE_USER}"
  rendered="${rendered//@COREKIT_GROUP@/$SERVICE_GROUP}"
  rendered="${rendered//@PROJECT_ROOT@/$PROJECT_ROOT}"
  rendered="${rendered//@STATE_ROOT@/$STATE_ROOT}"
  rendered="${rendered//@BACKUP_ROOT@/$BACKUP_ROOT}"
  [[ "$rendered" != *"@COREKIT_"* && "$rendered" != *"@PROJECT_ROOT@"* \
    && "$rendered" != *"@STATE_ROOT@"* && "$rendered" != *"@BACKUP_ROOT@"* ]] \
    || fail "Unresolved placeholder in unit template: $template"
  printf '%s\n' "$rendered" >"$output"
  chmod 0644 "$output"
}

for service_name in corekit-managed-update-check corekit-managed-update-apply; do
  render_service "$UNIT_SOURCE/$service_name.service.in" "$RENDER_ROOT/$service_name.service"
done
for timer_name in corekit-managed-update-check corekit-managed-update-apply; do
  install -m 0644 "$UNIT_SOURCE/$timer_name.timer" "$RENDER_ROOT/$timer_name.timer"
done

systemd-analyze verify \
  "$RENDER_ROOT/corekit-managed-update-check.service" \
  "$RENDER_ROOT/corekit-managed-update-check.timer" \
  "$RENDER_ROOT/corekit-managed-update-apply.service" \
  "$RENDER_ROOT/corekit-managed-update-apply.timer"

if [[ -n "$RENDER_ONLY_DIR" ]]; then
  install -d -m 0755 "$RENDER_ONLY_DIR"
  install -m 0644 "$RENDER_ROOT"/* "$RENDER_ONLY_DIR/"
  echo "Rendered verified units in $RENDER_ONLY_DIR"
  exit 0
fi

[[ "$(id -u)" -eq 0 ]] || fail "Run installation as root, or use --render-only."

install -d -o "$SERVICE_USER" -g "$SERVICE_GROUP" -m 0700 "$STATE_ROOT" "$BACKUP_ROOT"
chown "$SERVICE_USER:$SERVICE_GROUP" "$STATE_ROOT" "$BACKUP_ROOT"
chmod 0700 "$STATE_ROOT" "$BACKUP_ROOT"
for unit in \
  corekit-managed-update-check.service \
  corekit-managed-update-check.timer \
  corekit-managed-update-apply.service \
  corekit-managed-update-apply.timer; do
  install -o root -g root -m 0644 "$RENDER_ROOT/$unit" "$UNIT_DIR/$unit"
done

systemctl daemon-reload
systemctl enable --now corekit-managed-update-check.timer corekit-managed-update-apply.timer
systemctl start corekit-managed-update-check.service
systemctl show corekit-managed-update-check.service \
  -p Result -p ExecMainCode -p ExecMainStatus -p ActiveState -p SubState
systemctl --no-pager list-timers corekit-managed-update-check.timer corekit-managed-update-apply.timer
