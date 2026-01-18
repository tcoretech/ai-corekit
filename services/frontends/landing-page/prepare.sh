#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." &> /dev/null && pwd )"
CONFIG_FILE="$PROJECT_ROOT/config/service_categories.json"
TEMPLATE_FILE="$SCRIPT_DIR/website/index.html.template"
OUTPUT_FILE="$SCRIPT_DIR/website/index.html"
SERVICES_DATA=$(mktemp)
JSON_OUTPUT=$(mktemp)

trap "rm -f $SERVICES_DATA $JSON_OUTPUT" EXIT

# Check requirements
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for this script" >&2
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file not found at $TEMPLATE_FILE" >&2
    exit 1
fi

echo "Scanning services..."
# Collect all service data
find "$PROJECT_ROOT/services" -name "service.json" | while read -r json_file; do
    [[ ! -s "$json_file" ]] && continue

    match=$(jq -r '[
        .category // "",
        .name // "",
        .display_name // .name,
        .description // "",
        .interface // ""
    ] | @tsv' "$json_file")

    IFS=$'\t' read -r category name display_name description interface <<< "$match"
    
    [[ -z "$name" || -z "$category" ]] && continue
    
    # Check if interface has a subdomain pattern
    # Regex for "subdomain.<yourdomain>.com"
    regex="^([a-zA-Z0-9-]+)\.<yourdomain>\.com"
    if [[ "$interface" =~ $regex ]]; then
        subdomain="${BASH_REMATCH[1]}"
        # Store: category|subdomain|name|desc
        echo "${category}|${subdomain}|${display_name}|${description}" >> "$SERVICES_DATA"
    fi
done

echo "Generating index.html..."

# Start JSON array
echo "[" > "$JSON_OUTPUT"

first_cat=true
# Read categories from config to maintain order
jq -c '.[]' "$CONFIG_FILE" | while read -r cat_json; do
    category=$(echo "$cat_json" | jq -r '.name')
    icon=$(echo "$cat_json" | jq -r '.icon')
    
    # Check if we have services for this category
    if grep -q "^${category}|" "$SERVICES_DATA"; then
        if [ "$first_cat" = true ]; then
            first_cat=false
        else
            echo "," >> "$JSON_OUTPUT"
        fi
        
        echo "    {" >> "$JSON_OUTPUT"
        echo "        name: \"${icon} ${category}\"," >> "$JSON_OUTPUT"
        echo "        services: [" >> "$JSON_OUTPUT"
        
        first_svc=true
        grep "^${category}|" "$SERVICES_DATA" | sort -t'|' -k3 | while IFS='|' read -r cat sub name desc; do
            if [ "$first_svc" = true ]; then
                first_svc=false
            else
                echo "," >> "$JSON_OUTPUT"
            fi
            # Escape quotes in description just in case
            safe_desc=$(echo "$desc" | sed 's/"/\\"/g')
            echo "            { subdomain: \"${sub}\", name: \"${name}\", desc: \"${safe_desc}\" }" >> "$JSON_OUTPUT"
        done
        
        echo "        ]" >> "$JSON_OUTPUT"
        echo "    }" >> "$JSON_OUTPUT"
    fi
done

echo "]" >> "$JSON_OUTPUT"

# Read JSON content
JS_CONTENT=$(cat "$JSON_OUTPUT")

# Use awk to insert the content because it handles multi-line string replacement better than sed
awk -v content="$JS_CONTENT" '
    /\/\* SERVICE_CATEGORIES_PLACEHOLDER \*\// {
        print content
        next
    }
    { print }
' "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Landing page generated at $OUTPUT_FILE"
