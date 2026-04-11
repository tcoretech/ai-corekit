#!/bin/bash
command="$1"
shift

case "$command" in
  onboard)
    echo "Starting OpenClaw Onboarding..."
    # Ensure variables are loaded
    source "$PROJECT_ROOT/lib/utils/stack.sh"
    
    # We need to run docker compose from the service directory context
    # But corekit handles execution.
    # We assume we are in the service directory or setup context.
    
    # Run the onboarding command
    docker compose run --rm openclaw-cli onboard --no-install-daemon
    ;;
  *)
    echo "Unknown command: $command"
    echo "Available commands: onboard"
    exit 1
    ;;
esac
