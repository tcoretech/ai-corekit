#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/secrets.sh"

# Only run if interactive
if [[ -t 0 ]]; then
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🦜 LANGFUSE INITIALIZATION"
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""

    ENV_FILE="$SCRIPT_DIR/.env"
    GLOBAL_ENV="$PROJECT_ROOT/config/.env.global"
    
    # Ensure .env exists
    if [[ ! -f "$ENV_FILE" ]]; then
        cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
    fi

    # Load Global Env for defaults
    if [ -f "$GLOBAL_ENV" ]; then
        # We use a subshell or just grep to avoid polluting current shell too much, 
        # but sourcing is easier to get the vars.
        # We'll just grep for specific ones we need to avoid overwriting everything.
        GLOBAL_EMAIL=$(grep "^PRIMARY_EMAIL=" "$GLOBAL_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi

    # Read existing values from local .env
    # We use grep to find the value, handle quotes
    get_env_val() {
        local key="$1"
        local file="$2"
        grep "^$key=" "$file" 2>/dev/null | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//' | sed "s/^'//" | sed "s/'$//"
    }

    existing_email=$(get_env_val "LANGFUSE_INIT_USER_EMAIL" "$ENV_FILE")
    existing_name=$(get_env_val "LANGFUSE_INIT_USER_NAME" "$ENV_FILE")
    existing_org=$(get_env_val "LANGFUSE_INIT_ORG_NAME" "$ENV_FILE")
    existing_proj=$(get_env_val "LANGFUSE_INIT_PROJECT_NAME" "$ENV_FILE")

    # Set Defaults
    default_email=${existing_email:-${GLOBAL_EMAIL:-admin@example.com}}
    default_name=${existing_name:-"Admin"}
    default_org=${existing_org:-"My Organization"}
    default_proj=${existing_proj:-"My Project"}

    # Update .env
    # Helper to update or append
    # update_env() { ... } # Removed in favor of lib/utils/secrets.sh update_env_var

    # Check if already configured
    # We consider it configured if Email, Org Name, and Project Name are all set (non-empty)
    if [[ -n "$existing_email" ]] && [[ -n "$existing_org" ]] && [[ -n "$existing_proj" ]]; then
        log_info "Configuration found in .env. Skipping interactive prompt."
    else
        # Resolve defaults for prompt
        # If existing_email is a variable reference like ${PRIMARY_EMAIL}, try to resolve it for display
        display_email="$default_email"
        if [[ "$default_email" == "\${PRIMARY_EMAIL}" ]]; then
             display_email="${GLOBAL_EMAIL:-$default_email}"
        fi

        read -p "Admin Email [${display_email}]: " input_email
        read -p "Admin Name [${default_name}]: " input_name
        read -p "Organization Name [${default_org}]: " input_org
        read -p "Project Name [${default_proj}]: " input_proj

        # If user accepted default and default was ${PRIMARY_EMAIL}, keep it as ${PRIMARY_EMAIL}
        # unless we want to freeze the value. Keeping the var is better for updates.
        if [[ -z "$input_email" ]] && [[ "$default_email" == "\${PRIMARY_EMAIL}" ]]; then
            final_email="\${PRIMARY_EMAIL}"
        else
            final_email=${input_email:-$default_email}
        fi
        
        final_name=${input_name:-$default_name}
        final_org=${input_org:-$default_org}
        final_proj=${input_proj:-$default_proj}

        update_env_var "$ENV_FILE" "LANGFUSE_INIT_USER_EMAIL" "$final_email"
        update_env_var "$ENV_FILE" "LANGFUSE_INIT_USER_NAME" "$final_name"
        update_env_var "$ENV_FILE" "LANGFUSE_INIT_ORG_NAME" "$final_org"
        update_env_var "$ENV_FILE" "LANGFUSE_INIT_PROJECT_NAME" "$final_proj"

        echo ""
        log_success "✅ Langfuse configuration saved."
        echo ""
    fi
fi
