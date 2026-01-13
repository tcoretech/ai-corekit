#!/bin/bash
# Service Selection Wizard

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GLOBAL_ENV="$PROJECT_ROOT/config/.env.global"
ROOT_ENV="$PROJECT_ROOT/.env"
source "$PROJECT_ROOT/lib/utils/logging.sh"

# Check dependencies
if ! command -v whiptail &> /dev/null; then
    log_error "'whiptail' is not installed. Please install it (apt install whiptail)."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_error "'jq' is not installed. Please install it (apt install jq)."
    exit 1
fi

# Load current profiles
CURRENT_PROFILES_VALUE=""

# Try loading from .env.global first
if [ -f "$GLOBAL_ENV" ]; then
    if grep -q "COMPOSE_PROFILES" "$GLOBAL_ENV"; then
        CURRENT_PROFILES_VALUE=$(grep "^COMPOSE_PROFILES=" "$GLOBAL_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
fi

# Fallback to root .env if empty
if [ -z "$CURRENT_PROFILES_VALUE" ] && [ -f "$ROOT_ENV" ]; then
    if grep -q "COMPOSE_PROFILES" "$ROOT_ENV"; then
        CURRENT_PROFILES_VALUE=$(grep "^COMPOSE_PROFILES=" "$ROOT_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
fi

# Add commas for easier matching: ,profile1,profile2,
current_profiles_for_matching=",$CURRENT_PROFILES_VALUE,"

log_info "Scanning for services..."

# 1. Collect all services first into a temp file
SERVICES_TMP=$(mktemp)
find "$PROJECT_ROOT/services" -name "service.json" | sort | while read -r service_json; do
    name=$(jq -r '.name // empty' "$service_json")
    description=$(jq -r '.description // empty' "$service_json")
    category=$(jq -r '.category // "Other"' "$service_json")
    
    if [ -z "$name" ]; then continue; fi
    if [[ "$name" == "example-service" ]]; then continue; fi
    if [ -z "$description" ]; then description="$name"; fi
    
    # Use pipe as delimiter (assuming no pipes in names/desc)
    echo "$name|$category|$description" >> "$SERVICES_TMP"
done

if [ ! -s "$SERVICES_TMP" ]; then
    log_error "No services found in $PROJECT_ROOT/services."
    rm -f "$SERVICES_TMP"
    exit 1
fi

# 2. Calculate max name length for dynamic sizing
max_name_len=0
while IFS='|' read -r name category description; do
    len=${#name}
    if [ $len -gt $max_name_len ]; then max_name_len=$len; fi
done < "$SERVICES_TMP"

# 3. Calculate dimensions
term_height=$(stty size 2>/dev/null | awk '{print $1}' || echo 24)
term_width=$(stty size 2>/dev/null | awk '{print $2}' || echo 80)

# Whiptail checklist layout estimation:
# [ ] Name   Description
# 4 chars for checkbox "[ ] "
# Name column width = max_name_len + padding (whiptail adds some)
# Borders/Margins = ~6 chars
# Scrollbar = 1 char
# Total overhead approx: max_name_len + 16
overhead=$((max_name_len + 16))
max_desc_len=$((term_width - overhead))

# Ensure a minimum description length
if [ "$max_desc_len" -lt 20 ]; then max_desc_len=20; fi

# 4. Generate Options with calculated truncation
OPTIONS_FILE=$(mktemp)
while IFS='|' read -r name category description; do
    # Truncate description
    full_desc="[$category] $description"
    if [ ${#full_desc} -gt $max_desc_len ]; then
        full_desc="${full_desc:0:$((max_desc_len-3))}..."
    fi
    
    status="OFF"
    if [[ "$current_profiles_for_matching" == *",$name,"* ]]; then
        status="ON"
    fi
    
    echo "\"$name\" \"$full_desc\" \"$status\"" >> "$OPTIONS_FILE"
done < "$SERVICES_TMP"

rm -f "$SERVICES_TMP"

# Read options into an array
options=()
while read -r line; do
    eval "options+=($line)"
done < "$OPTIONS_FILE"

rm -f "$OPTIONS_FILE"

# Calculate item count (options array has 3 elements per item)
item_count=$((${#options[@]} / 3))

# Calculate optimal dimensions
# Max height is terminal height - 4 (top/bottom margins)
max_height=$((term_height - 4))
if [ "$max_height" -lt 10 ]; then max_height=10; fi

# Max width is terminal width - 4
max_width=$((term_width - 4))
if [ "$max_width" -lt 60 ]; then max_width=60; fi

# Calculate needed height
# List height needs to be at least item_count, but capped
# Box overhead is roughly 8 lines (title, borders, buttons, text)
needed_list_height="$item_count"
max_list_height=$((max_height - 8))

if [ "$needed_list_height" -gt "$max_list_height" ]; then
    list_height="$max_list_height"
else
    list_height="$needed_list_height"
fi

# Ensure minimum list height
if [ "$list_height" -lt 5 ]; then list_height=5; fi

# Calculate final box height
box_height=$((list_height + 8))

# Ensure box doesn't exceed terminal
if [ "$box_height" -gt "$term_height" ]; then
    box_height="$term_height"
    list_height=$((box_height - 8))
fi

# Run Whiptail
# Note: Running in foreground to ensure TTY access. 
# Dynamic resizing during execution is not supported by whiptail in this mode.
SELECTED_SERVICES=$(whiptail --title "AI CoreKit Service Selection" \
    --separate-output \
    --checklist "Select services to enable (Space to toggle, Enter to confirm):" \
    "$box_height" "$max_width" "$list_height" \
    "${options[@]}" \
    3>&1 1>&2 2>&3)

exit_status=$?

if [ $exit_status -eq 0 ]; then
    # User confirmed
    NEW_PROFILES=$(echo "$SELECTED_SERVICES" | tr '\n' ',' | sed 's/,$//')
    
    log_info "Updating configuration..."
    
    # Update .env.global
    if [ -f "$GLOBAL_ENV" ]; then
        if grep -q "^COMPOSE_PROFILES=" "$GLOBAL_ENV"; then
            TMP_ENV=$(mktemp)
            sed "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES='$NEW_PROFILES'|" "$GLOBAL_ENV" > "$TMP_ENV"
            mv "$TMP_ENV" "$GLOBAL_ENV"
        else
            echo "COMPOSE_PROFILES='$NEW_PROFILES'" >> "$GLOBAL_ENV"
        fi
    else
        echo "COMPOSE_PROFILES='$NEW_PROFILES'" > "$GLOBAL_ENV"
    fi
    
    log_success "Configuration updated in $GLOBAL_ENV"
    log_info "Enabled profiles: $NEW_PROFILES"
    log_info "Run 'corekit up' to apply changes."
else
    log_warning "Selection cancelled. No changes made."
fi
