#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." &> /dev/null && pwd )"
CONFIG_DIR="$SCRIPT_DIR/config/local"
CONFIG_CATEGORIES="$PROJECT_ROOT/config/service_categories.json"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Load environment variables
if [ -f "$PROJECT_ROOT/config/.env.global" ]; then
    set -a
    source "$PROJECT_ROOT/config/.env.global"
    set +a
fi

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Determine Domain
DOMAIN="${USER_DOMAIN_NAME:-$DOMAIN_NAME}"
DOMAIN="${DOMAIN:-$DOMAIN}" # Fallback to DOMAIN if others empty

if [[ -z "$DOMAIN" ]]; then
    # Fallback for testing or if variables not set
    echo "Warning: No domain variable found (USER_DOMAIN_NAME, DOMAIN_NAME, or DOMAIN). Using 'localhost'"
    DOMAIN="localhost"
fi

echo "Generating Homepage services configuration for domain: $DOMAIN"

# Temp file for yaml generation
YAML_TEMP=$(mktemp)
trap "rm -f $YAML_TEMP" EXIT

# Check requirements
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for this script" >&2
    exit 1
fi

# Iterate Categories
jq -c '.[]' "$CONFIG_CATEGORIES" | while read -r cat_json; do
    category=$(echo "$cat_json" | jq -r '.name')
    icon=$(echo "$cat_json" | jq -r '.icon')
    
    # We will accumulate services for this category in a temporary buffer
    CAT_BUFFER=$(mktemp)
    
    # Get category path to find services efficiently
    cat_path=$(echo "$cat_json" | jq -r '.path')
    cat_dir="$PROJECT_ROOT/services/$cat_path"
    
    if [[ -d "$cat_dir" ]]; then
        # Look for service.json files in this category folder
        find "$cat_dir" -name "service.json" | sort | while read -r json_file; do
             # Read data
             match=$(jq -r '[
                .name // "",
                .display_name // .name,
                .description // "",
                .interface // ""
            ] | @tsv' "$json_file")
            
            IFS=$'\t' read -r name display_name description interface <<< "$match"
            
            [[ -z "$name" ]] && continue
            
            # Process URL
            # Only include if interface defines a domain pattern
            regex="^([a-zA-Z0-9-]+)\.<yourdomain>\.com"
            if [[ "$interface" =~ $regex ]]; then
                subdomain="${BASH_REMATCH[1]}"
                url="https://${subdomain}.${DOMAIN}"
                
                echo "    - ${display_name}:" >> "$CAT_BUFFER"
                # Use name for icon - Homepage will try to match name.png, name.svg, etc.
                echo "        icon: ${name}.png" >> "$CAT_BUFFER"
                echo "        href: ${url}" >> "$CAT_BUFFER"
                echo "        description: ${description}" >> "$CAT_BUFFER"
            fi
        done
    fi
    
    if [[ -s "$CAT_BUFFER" ]]; then
        echo "- ${icon} ${category}:" >> "$YAML_TEMP"
        cat "$CAT_BUFFER" >> "$YAML_TEMP"
    fi
    rm -f "$CAT_BUFFER"
done

# Write final file
cp "$YAML_TEMP" "$CONFIG_DIR/services.yaml"

# Permissions (try to set if possible, ignore error if not root or different user mapping)
chown -R 1000:1000 "$CONFIG_DIR/" 2>/dev/null || true

echo "Homepage configuration generated successfully at $CONFIG_DIR/services.yaml"
