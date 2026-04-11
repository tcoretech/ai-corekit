#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="/usr/local/bin/corekit"

usage() {
    echo "Usage: $0 [install|uninstall]"
    echo "  install    Symlink corekit to $TARGET (default)"
    echo "  uninstall  Remove corekit from $TARGET"
    exit 1
}

cmd="${1:-install}"

case "$cmd" in
    install)
        echo "Installing corekit to $TARGET..."
        ln -sf "$SCRIPT_DIR/corekit.sh" "$TARGET"
        chmod +x "$SCRIPT_DIR/corekit.sh"
        echo "Done. You can now run 'corekit <command>'."
        ;;
    uninstall)
        echo "Removing corekit from $TARGET..."
        rm -f "$TARGET"
        echo "Done."
        ;;
    *)
        usage
        ;;
esac
