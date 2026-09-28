#!/usr/bin/env bash
# Service CLI for the production n8n instance.
#
#   corekit run n8n-prod promote [options]
#
# Promotion is n8n-specific -- it drives n8n-git and the n8n CLI inside the
# container -- so both the command and its implementation live with the service
# rather than in lib/. See docs/PROMOTION.md for the design and configuration.
set -Eeuo pipefail

SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="$(basename "$SERVICE_DIR")"
PROMOTE_LIB="$SERVICE_DIR/managed/promote.sh"

usage() {
  cat <<USAGE
Usage: corekit run $SERVICE_NAME <command> [options]

Commands:
  promote [options]   Import reviewed workflow definitions from a commit that is
                      already merged into the protected branch.
  status              Show the last recorded promotion.
  rollback-plan       Print the recovery procedure.

promote options:
  --commit <sha>      Promote this exact commit. Full 40-character SHA.
                      Defaults to the current tip of the protected branch.
  --plan              Show what would be promoted and exit. Changes nothing.
  --dry-run           Run the import in the tool's dry-run mode.

Configuration: policy in service.json under "promotion"; repository and token in
this service's .env as PROMOTION_REPOSITORY and PROMOTION_TOKEN. The token needs
read access only. See docs/PROMOTION.md.
USAGE
}

require_lib() {
  [[ -f "$PROMOTE_LIB" ]] || { echo "Promotion library not found at $PROMOTE_LIB" >&2; exit 1; }
}

case "${1:-}" in
  promote)
    shift
    require_lib
    exec bash "$PROMOTE_LIB" "$SERVICE_NAME" "$@"
    ;;
  status)
    shift
    require_lib
    exec bash "$PROMOTE_LIB" "$SERVICE_NAME" --status "$@"
    ;;
  rollback-plan)
    shift
    require_lib
    exec bash "$PROMOTE_LIB" "$SERVICE_NAME" --rollback-plan "$@"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    echo >&2
    usage >&2
    exit 1
    ;;
esac
