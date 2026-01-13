#!/bin/bash
# Generate Services Section for README.md
# This script reads all service.json files and generates the "What's Included" section
#
# Usage: ./scripts/generate-services-readme.sh > services-section.md
#        ./scripts/generate-services-readme.sh --update  # Updates README.md in place

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Category display order and icons
declare -A CATEGORY_ICONS=(
    ["Workflow Automation"]="🔧"
    ["User Interfaces"]="🎯"
    ["Mail System"]="📧"
    ["Video Conferencing"]="📹"
    ["File & Document Management"]="📁"
    ["Business Productivity"]="💼"
    ["AI Content Generation"]="🎨"
    ["AI-Powered Development"]="💻"
    ["AI Agents"]="🤖"
    ["RAG Systems"]="📚"
    ["Speech, Language & Text"]="🎙️"
    ["Search & Web Data"]="🔍"
    ["Knowledge Graphs"]="🧠"
    ["Data Infrastructure"]="🗄️"
    ["System Management"]="⚙️"
    ["AI Support Tools"]="🧰"
    ["AI Security & Compliance"]="🛡️"
    ["Python"]="🐍"
    ["Host Services"]="🖥️"
)

# Category display order (controls section order in output)
CATEGORY_ORDER=(
    "Workflow Automation"
    "User Interfaces"
    "Mail System"
    "Video Conferencing"
    "File & Document Management"
    "Business Productivity"
    "AI Content Generation"
    "AI-Powered Development"
    "AI Agents"
    "RAG Systems"
    "Speech, Language & Text"
    "Search & Web Data"
    "Knowledge Graphs"
    "Data Infrastructure"
    "System Management"
    "AI Support Tools"
    "AI Security & Compliance"
    "Python"
    "Host Services"
)

# Temp file for collecting services
SERVICES_DATA=$(mktemp)
trap "rm -f $SERVICES_DATA" EXIT

# Collect all service data
find "$PROJECT_ROOT/services" -name "service.json" -not -path "*/custom/*" | while read -r json_file; do
    # Skip if file doesn't exist or is empty
    [[ ! -s "$json_file" ]] && continue

    # Extract fields using grep/sed (portable, no jq dependency)
    name=$(grep -o '"name": *"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/"name": *"//;s/"$//')
    category=$(grep -o '"category": *"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/"category": *"//;s/"$//')
    description=$(grep -o '"description": *"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/"description": *"//;s/"$//')
    use_cases=$(grep -o '"use_cases": *"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/"use_cases": *"//;s/"$//')
    interface=$(grep -o '"interface": *"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/"interface": *"//;s/"$//')
    source=$(grep -o '"source": *"[^"]*"' "$json_file" 2>/dev/null | head -1 | sed 's/"source": *"//;s/"$//')

    # Skip services with empty required fields
    [[ -z "$name" || -z "$category" ]] && continue

    # Skip example service
    [[ "$name" == "example-service" ]] && continue

    # Use pipe delimiter (assuming no pipes in data)
    echo "${category}|${name}|${description}|${use_cases}|${interface}|${source}" >> "$SERVICES_DATA"
done

# Count total services
total_services=$(wc -l < "$SERVICES_DATA" | tr -d ' ')

# Generate output
generate_services_section() {
    echo "## ✨ What's Included"
    echo ""
    echo "> **${total_services}+ self-hosted services** organized into ${#CATEGORY_ORDER[@]} categories."
    echo "> Each service includes its own README with detailed setup instructions, n8n integration examples, and troubleshooting guides."
    echo ""

    for category in "${CATEGORY_ORDER[@]}"; do
        # Get services in this category
        category_services=$(grep "^${category}|" "$SERVICES_DATA" | sort -t'|' -k2)

        # Skip empty categories
        [[ -z "$category_services" ]] && continue

        # Get icon
        icon="${CATEGORY_ICONS[$category]:-📦}"

        echo "### ${icon} ${category}"
        echo ""
        echo "| Service | Description | Access |"
        echo "|---------|-------------|--------|"

        while IFS='|' read -r cat name desc use_cases interface source_url; do
            # Clean up description - extract tool name if in format "ToolName (description)"
            if [[ "$desc" =~ ^([^(]+)\(([^)]+)\)$ ]]; then
                tool_name="${BASH_REMATCH[1]}"
                tool_desc="${BASH_REMATCH[2]}"
            else
                tool_name="$name"
                tool_desc="$desc"
            fi

            # Format tool name with link if source available
            if [[ -n "$source_url" && "$source_url" != "Local" && "$source_url" =~ ^https?:// ]]; then
                tool_display="[**${tool_name}**](${source_url})"
            else
                tool_display="**${tool_name}**"
            fi

            # Format interface/access
            if [[ -z "$interface" || "$interface" == "Internal only" || "$interface" == "Internal API" ]]; then
                access="Internal"
            elif [[ "$interface" =~ \<yourdomain\> ]]; then
                access="\`${interface}\`"
            else
                access="$interface"
            fi

            # Use use_cases as description if desc is empty, otherwise combine
            if [[ -z "$tool_desc" && -n "$use_cases" ]]; then
                final_desc="$use_cases"
            elif [[ -n "$tool_desc" ]]; then
                final_desc="$tool_desc"
            else
                final_desc="$name service"
            fi

            echo "| ${tool_display} | ${final_desc} | ${access} |"
        done <<< "$category_services"

        echo ""
    done

    echo "---"
    echo ""
    echo "> 📖 **For detailed documentation**, see each service's README in \`services/<category>/<service>/README.md\`"
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
