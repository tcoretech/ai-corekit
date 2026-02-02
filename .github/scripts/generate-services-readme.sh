#!/bin/bash
# Generate Services Section for README.md
# This script reads all service.json files and generates the "What's Included" section
#
# Usage: ./scripts/generate-services-readme.sh > services-section.md
#        ./scripts/generate-services-readme.sh --update  # Updates README.md in place

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/service_categories.json"

# Check requirements
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for this script" >&2
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

# Temp file for collecting services
SERVICES_DATA=$(mktemp)
trap "rm -f $SERVICES_DATA" EXIT

# Collect all service data
find "$PROJECT_ROOT/services" -name "service.json" | while read -r json_file; do
    # Skip if file doesn't exist or is empty
    [[ ! -s "$json_file" ]] && continue

    # Extract fields using jq
    match=$(jq -r '[
        .category // "",
        .name // "",
        .display_name // .name,
        .rank // 100,
        .description // "",
        .interface // "",
        .source // ""
    ] | @tsv' "$json_file")

    IFS=$'\t' read -r category name display_name rank description interface source <<< "$match"

    # Skip services with empty required fields
    [[ -z "$name" || -z "$category" ]] && continue

    # Only include example-service from Custom Services category
    if [[ "$category" == "Custom Services" && "$name" != "example-service" ]]; then
        continue
    fi

    # Get relative path to service directory
    service_dir=$(dirname "$json_file")
    rel_path=${service_dir#"$PROJECT_ROOT/"}

    # Use pipe delimiter (assuming no pipes in data)
    echo "${rank}|${category}|${name}|${display_name}|${description}|${interface}|${source}|${rel_path}" >> "$SERVICES_DATA"
done

# Count total services
total_services=$(wc -l < "$SERVICES_DATA" | tr -d ' ')

# Generate output
generate_services_section() {
    echo "## ✨ What's Included"
    echo ""
    echo "**${total_services}+ self-hosted services** pre-configured and wrapped for easy deployment."
    echo ""
    echo "Each service includes its own config, secrets handling and detailed setup instructions. Navigate to each modular service definition below."
    echo ""

    # Read categories from config and iterate
    jq -c '.[]' "$CONFIG_FILE" | while read -r cat_json; do
        category=$(echo "$cat_json" | jq -r '.name')
        icon=$(echo "$cat_json" | jq -r '.icon')
        description=$(echo "$cat_json" | jq -r '.description')

        # Get services in this category
        # Format: rank|category|name|display_name|description|interface|source
        category_services=$(grep "^[^|]*|${category}|" "$SERVICES_DATA" | sort -t'|' -k1n -k4)

        # Skip empty categories
        [[ -z "$category_services" ]] && continue

        echo "### ${icon} ${category}"
        if [[ -n "$description" ]]; then
            echo "$description"
        fi
        echo ""
        echo "| Service | Name | Description |"
        echo "| --- | --- | ------ |"

        while IFS='|' read -r rank cat name display_name desc interface source_url rel_path; do
            # Clean up description - extract tool name if in format "ToolName (description)"
            if [[ "$desc" =~ ^([^(]+)\(([^)]+)\)$ ]]; then
                tool_desc="${BASH_REMATCH[2]}"
            else
                tool_desc="$desc"
            fi

            # Format tool name with link to local service directory
            # rel_path is already correct from the data collection phase
            tool_display="[**${display_name}**](${rel_path})"

            
            # Name column
            name_display="\`${name}\`"

            # Description handling
            if [[ -n "$tool_desc" ]]; then
                final_desc="$tool_desc"
            else
                final_desc="$name service"
            fi

            # Add source link if available
            if [[ -n "$source_url" && "$source_url" != "Local" && "$source_url" =~ ^https?:// ]]; then
                final_desc="${final_desc} [[↗](${source_url})]"
            fi

            echo "| ${tool_display} | ${name_display} | ${final_desc} |"
        done <<< "$category_services"

        echo ""
    done


    echo "---"
    echo ""
    echo "### 🛠️ Creating Custom Services"
    echo ""
    echo "You can easily add your own services to AI LaunchKit using the custom services directory. This allows you to integrate your own tools or proprietary software while keeping them separate from the core repository."
    echo ""
    echo "👉 **[Learn how to add custom services](services/custom-services/README.md)**"
    echo ""
}

# Main execution
if [[ "$1" == "--update" ]]; then
    # Update README.md in place
    README_FILE="$PROJECT_ROOT/README.md"

    if [[ ! -f "$README_FILE" ]]; then
        echo "Error: README.md not found at $README_FILE" >&2
        exit 1
    fi

    # Generate new services section
    NEW_SECTION=$(generate_services_section)

    # Create temp file for new README
    NEW_README=$(mktemp)

    # Find markers and replace content between them
    START_MARKER="<!-- SERVICES_SECTION_START -->"
    END_MARKER="<!-- SERVICES_SECTION_END -->"

    # Check if markers exist
    if ! grep -q "$START_MARKER" "$README_FILE"; then
        echo "Error: Start marker '$START_MARKER' not found in README.md" >&2
        echo "Add these markers to README.md where you want the services section:" >&2
        echo "  $START_MARKER" >&2
        echo "  ... services content ..." >&2
        echo "  $END_MARKER" >&2
        rm -f "$NEW_README"
        exit 1
    fi

    # Replace content between markers
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v content="$NEW_SECTION" '
        $0 ~ start { print; print content; skip=1; next }
        $0 ~ end { skip=0 }
        !skip { print }
    ' "$README_FILE" > "$NEW_README"

    # Verify new file is not empty
    if [[ ! -s "$NEW_README" ]]; then
        echo "Error: Generated README is empty" >&2
        rm -f "$NEW_README"
        exit 1
    fi

    # Replace original
    mv "$NEW_README" "$README_FILE"
    echo "✅ README.md updated successfully with ${total_services} services"
else
    # Just output to stdout
    generate_services_section
fi
