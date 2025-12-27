#!/bin/bash
set -e

# n8n CLI Wrapper
# Usage: ./cli.sh {import|export}

CONTAINER_NAME="n8n"
EXPORT_DIR="./data/backups"
IMPORT_CONFIG_DIR="./config"

# Helper: Generate UUID
generate_workflow_version_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
    else
        python3 - <<'PY' || true
import uuid
print(uuid.uuid4())
PY
    fi
}

# Helper: Ensure versionId exists in workflow files
process_workflow_files() {
    local workflow_dir="$1"
    if [ -d "$workflow_dir" ]; then
        echo "Processing workflow files in $workflow_dir to ensure versionId exists..."
        find "$workflow_dir" -maxdepth 1 -type f -name "*.json" | while read -r file; do
            # Read file content
            local workflow_json
            workflow_json=$(cat "$file")
            
            # Check for versionId
            local workflow_version_id
            workflow_version_id=$(echo "$workflow_json" | jq -r '.versionId // .version.id // ""' 2>/dev/null)
            
            # Validate UUID format
            if [[ -z "$workflow_version_id" || "$workflow_version_id" == "null" || ! "$workflow_version_id" =~ ^[0-9a-fA-F-]{8}-[0-9a-fA-F-]{4}-[0-9a-fA-F-]{4}-[0-9a-fA-F-]{4}-[0-9a-fA-F-]{12}$ ]]; then
                echo "Adding missing versionId to $file"
                local new_uuid
                new_uuid=$(generate_workflow_version_id)
                
                # Add versionId to JSON using jq and overwrite file
                local tmp_file="${file}.tmp"
                echo "$workflow_json" | jq --arg uuid "$new_uuid" '. + {versionId: $uuid}' > "$tmp_file" && mv "$tmp_file" "$file"
            fi
        done
    fi
}

# Ensure export directories exist
mkdir -p "$EXPORT_DIR/credentials"
mkdir -p "$EXPORT_DIR/workflows"

case "$1" in
    import)
        echo "Starting n8n import..."
        
        # Pre-process workflow files to ensure versionId exists
        process_workflow_files "$IMPORT_CONFIG_DIR/workflows"
        
        # Import Credentials
        echo "Importing credentials from $IMPORT_CONFIG_DIR/credentials..."
        docker exec "$CONTAINER_NAME" sh -c '
            if [ -d "/import/credentials" ]; then
                find /import/credentials -maxdepth 1 -type f -not -name ".gitkeep" -print -exec sh -c "
                    echo \"Attempting to import credential file: \$0\";
                    n8n import:credentials --input=\"\$0\" || echo \"Error importing credential file: \$0\"
                " {} \;
            else
                echo "No credentials directory found at /import/credentials"
            fi
        '
        
        # Import Workflows
        echo "Importing workflows from $IMPORT_CONFIG_DIR/workflows..."
        docker exec "$CONTAINER_NAME" sh -c '
            if [ -d "/import/workflows" ]; then
                find /import/workflows -maxdepth 1 -type f -not -name ".gitkeep" -print -exec sh -c "
                    echo \"Attempting to import workflow file: \$0\";
                    n8n import:workflow --input=\"\$0\" || echo \"Error importing workflow file: \$0\"
                " {} \;
            else
                echo "No workflows directory found at /import/workflows"
            fi
        '
        
        echo "Import complete."
        ;;
        
    export)
        echo "Starting n8n export..."
        
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        # Export Credentials
        echo "Exporting credentials..."
        docker exec "$CONTAINER_NAME" n8n export:credentials --all --output="/backup/credentials/export_${TIMESTAMP}.json"
        
        # Export Workflows
        echo "Exporting workflows..."
        docker exec "$CONTAINER_NAME" n8n export:workflow --all --output="/backup/workflows/export_${TIMESTAMP}.json"
        
        echo "Export complete. Files saved to $EXPORT_DIR"
        ;;
        
    *)
        echo "Usage: $0 {import|export}"
        exit 1
        ;;
esac
