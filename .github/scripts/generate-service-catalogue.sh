#!/bin/bash
# Generate Services Catalogue in docs folder
# Usage: ./scripts/generate-service-catalogue.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/service_categories.json"
OUTPUT_FILE="$PROJECT_ROOT/docs/SERVICES_CATALOGUE.md"

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
        .source // "",
        (.depends_on | if . == null then [] else . end | join(", "))
    ] | @tsv' "$json_file")

    IFS=$'\t' read -r category name display_name rank description interface source depends_on <<< "$match"

    # Skip services with empty required fields
    [[ -z "$name" || -z "$category" ]] && continue

    # Only include example-service from Custom Services category
    if [[ "$category" == "Custom Services" && "$name" != "example-service" ]]; then
        continue
    fi

    # Get relative path to service directory
    dir_path=$(dirname "$json_file")
    rel_path="${dir_path#$PROJECT_ROOT/}"

    echo "${rank}|${category}|${name}|${display_name}|${description}|${interface}|${source}|${rel_path}|${depends_on}" >> "$SERVICES_DATA"
done

# Count total services
total_services=$(wc -l < "$SERVICES_DATA" | tr -d ' ')

# Start generating output
{
    echo "# AI LaunchKit Services Catalogue"
    echo ""
    echo "This document provides a complete catalogue of the **${total_services}+ self-hosted services** included in AI LaunchKit."
    echo ""
    echo "## Table of Contents"
    echo ""
    
    # Generate TOC
    jq -c '.[]' "$CONFIG_FILE" | while read -r cat_json; do
        category=$(echo "$cat_json" | jq -r '.name')
        icon=$(echo "$cat_json" | jq -r '.icon')
        
        # Check if category has services. Data format: rank|category|...
        if grep -q "|${category}|" "$SERVICES_DATA"; then
            # Generate anchor: remove ampersands, lowercase, replace non-alphanumeric with hyphens
            anchor=$(echo "$category" | sed 's/&//g' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
            
            # Check for VS16 (Variation Selector-16) in icon using hex sequence
            vs16=$(printf '\xef\xb8\x8f')
            if [[ "$icon" == *"$vs16"* ]]; then
                # Multi-code point emoji: Start with encoded VS16
                echo "- [${icon} ${category}](#%EF%B8%8F-${anchor})"
            else
                # Standard emoji: Start with leading hyphen
                echo "- [${icon} ${category}](#-${anchor})"
            fi
        fi
    done
    echo ""
    echo "---"
    echo ""

    # Generate Categories
    jq -c '.[]' "$CONFIG_FILE" | while read -r cat_json; do
        category=$(echo "$cat_json" | jq -r '.name')
        icon=$(echo "$cat_json" | jq -r '.icon')
        description=$(echo "$cat_json" | jq -r '.description')

        # Get services in this category
        # Format: rank|category|name|display_name|description|interface|source|rel_path|depends_on
        # Grep for category in second field
        category_services=$(grep "^[^|]*|${category}|" "$SERVICES_DATA" | sort -t'|' -k1n -k4)

        # Skip empty categories
        [[ -z "$category_services" ]] && continue

        # Calculate exact anchor to match TOC
        anchor=$(echo "$category" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')

        echo "## ${icon} ${category}"
        if [[ -n "$description" ]]; then
            echo "$description"
        fi
        echo ""
        echo "| Service | Description | Interface | Dependencies |"
        echo "|---------|-------------|-----------|--------------|"

        while IFS='|' read -r rank cat name display_name desc interface source_url rel_path depends_on; do
            # Service Name (linked to folder)
            service_col="[**${display_name}**](../${rel_path})"
            
            # Technical name
            service_col="${service_col} <br> [\`${name}\`]"

            # Description
            desc_col="${desc}"
            # Add External Link to description if available
            if [[ -n "$source_url" && "$source_url" != "Local" && "$source_url" =~ ^https?:// ]]; then
                 desc_col="${desc_col} [[↗](${source_url})]"
            fi

            # Interface
            if [[ -z "$interface" || "$interface" == "Internal only" || "$interface" == "Internal API" ]]; then
                interface_col="Internal"
            elif [[ "$interface" =~ \<yourdomain\> ]]; then
                interface_col="\`${interface}\`"
            else
                interface_col="$interface"
            fi

            # Dependencies
            if [[ -z "$depends_on" ]]; then
                deps_col="-"
            else
                deps_col="$depends_on"
            fi

            echo "| ${service_col} | ${desc_col} | ${interface_col} | ${deps_col} |"
        done <<< "$category_services"

        echo ""
        echo "[Back to Top](#table-of-contents)"
        echo ""
    done


} > "$OUTPUT_FILE"

echo "Generated service catalogue at $OUTPUT_FILE"
