#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source basic utils if not already sourced
if ! command -v log_info &> /dev/null; then
    # Assuming utils.sh is in the project root scripts folder
    # Adjust path if necessary based on where prepare.sh is located relative to project root
    PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." &> /dev/null && pwd )"
    if [ -f "$PROJECT_ROOT/scripts/utils.sh" ]; then
        source "$PROJECT_ROOT/scripts/utils.sh"
    fi
fi

log_info "Preparing SearXNG..."

# Ensure config/local exists
mkdir -p "$SCRIPT_DIR/config/local"

# Read SEARXNG_SECRET from .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    SEARXNG_SECRET=$(grep "^SEARXNG_SECRET=" "$SCRIPT_DIR/.env" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
else
    log_warning "No .env file found in $SCRIPT_DIR. Using default/empty secret."
    SEARXNG_SECRET=""
fi

# Generate settings.yml from template
TEMPLATE_FILE="$SCRIPT_DIR/config/settings.yml"
OUTPUT_FILE="$SCRIPT_DIR/config/local/settings.yml"

if [ -f "$TEMPLATE_FILE" ]; then
    log_info "Generating $OUTPUT_FILE from template..."
    # Use sed to replace the placeholder
    # We use a different delimiter for sed in case the secret contains slashes
    sed "s|\${SEARXNG_SECRET}|$SEARXNG_SECRET|g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"
else
    log_error "Template file $TEMPLATE_FILE not found!"
    exit 1
fi

# Set permissions (optional, but good practice)
chmod 600 "$OUTPUT_FILE"

log_success "SearXNG preparation complete."
