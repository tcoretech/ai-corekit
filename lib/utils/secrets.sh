#!/bin/bash

# Source basic utils if not already sourced
if ! command -v log_info &> /dev/null; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

if ! command -v find_service_path &> /dev/null; then
    source "$(dirname "${BASH_SOURCE[0]}")/stack.sh"
fi

# --- Generation Functions ---

# Usage: gen_random <length> <characters>
gen_random() {
    local length="$1"
    local characters="$2"
    head /dev/urandom | tr -dc "$characters" | head -c "$length"
}

# Usage: gen_password <length>
gen_password() {
    gen_random "$1" 'A-Za-z0-9'
}

# Usage: gen_hex <length> (length = number of hex characters)
gen_hex() {
    local length="$1"
    local bytes=$(( (length + 1) / 2 ))
    openssl rand -hex "$bytes" | head -c "$length"
}

# Usage: gen_base64 <length> (length = number of base64 characters)
gen_base64() {
    local length="$1"
    local bytes=$(( (length * 3 + 3) / 4 ))
    openssl rand -base64 "$bytes" | head -c "$length"
}

# Usage: gen_openssl_hex <bytes>
gen_openssl_hex() {
    local bytes=$1
    openssl rand -hex "$bytes"
}

# Function to generate a hash using Caddy
# Usage: local HASH=$(_generate_and_get_hash "$plain_password")
generate_caddy_hash() {
    local plain_password="$1"
    local new_hash=""
    if [[ -n "$plain_password" ]]; then
        if command -v caddy &> /dev/null; then
            new_hash=$(caddy hash-password --algorithm bcrypt --plaintext "$plain_password" 2>/dev/null)
        elif command -v docker &> /dev/null; then
            # Use docker to generate hash if caddy is not installed on host
            # Suppress output from docker pull/run except the hash
            new_hash=$(docker run --rm caddy:alpine caddy hash-password --algorithm bcrypt --plaintext "$plain_password" 2>/dev/null | tail -n 1)
        else
            log_warning "Caddy and Docker not found, cannot generate hash." >&2
            return 1
        fi
    fi
    echo "$new_hash"
}

# Function to update or add a variable to a file
# Usage: update_env_var "FILE" "VAR_NAME" "VAR_VALUE"
update_env_var() {
    local file="$1"
    local var_name="$2"
    local var_value="$3"
    
    if [ ! -f "$file" ]; then
        touch "$file"
    fi
    
    # Check if var exists
    if grep -q "^${var_name}=" "$file"; then
        # Use | as delimiter for sed, escape | in value
        local safe_value="${var_value//|/\\|}"
        # Use sed -i to replace
        # We use single quotes for the value as per policy
        sed -i "s|^${var_name}=.*|${var_name}='${safe_value}'|" "$file"
    else
        echo "${var_name}='${var_value}'" >> "$file"
    fi
}

# --- Central Environment Management ---

# Global map to hold all environment variables
declare -gA ALL_ENV_VARS

get_project_root() {
    # If PROJECT_ROOT is already set, use it
    if [[ -n "$PROJECT_ROOT" ]]; then
        echo "$PROJECT_ROOT"
        return
    fi
    echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." &> /dev/null && pwd )"
}

_load_file_to_map() {
    local file="$1"
    if [[ ! -f "$file" ]]; then return; fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then continue; fi
        if [[ "$line" == *"="* ]]; then
            local key=$(echo "$line" | cut -d'=' -f1 | xargs)
            local value=$(echo "$line" | cut -d'=' -f2-)
            # Remove surrounding quotes
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'//")
            ALL_ENV_VARS["$key"]="$value"
        fi
    done < "$file"
}

load_all_envs() {
    local project_root=$(get_project_root)
    local specific_services=("${@}")
    
    log_info "Loading environment variables..."

    # 0. Load Legacy Root .env (Lowest Priority)
    if [[ -f "$project_root/.env" ]]; then
        _load_file_to_map "$project_root/.env"
    fi

    # 1. Load Global Environment (Overwrites Legacy)
    if [[ -f "$project_root/config/.env.global" ]]; then
        _load_file_to_map "$project_root/config/.env.global"
    fi
    
    # Ensure PRIMARY_EMAIL is set if LETSENCRYPT_EMAIL is present (Backward Compatibility)
    if [[ -z "${ALL_ENV_VARS[PRIMARY_EMAIL]}" && -n "${ALL_ENV_VARS[LETSENCRYPT_EMAIL]}" ]]; then
        ALL_ENV_VARS["PRIMARY_EMAIL"]="${ALL_ENV_VARS[LETSENCRYPT_EMAIL]}"
    fi
    
    # 2. Load service environments
    if [[ ${#specific_services[@]} -gt 0 ]]; then
        # Load only specific services
        for service in "${specific_services[@]}"; do
            # Find service directory (maxdepth 2)
            local s_dir=$(find_service_path "$service" "$project_root" "$project_root/config")
            if [[ -n "$s_dir" && -f "$s_dir/.env" ]]; then
                _load_file_to_map "$s_dir/.env"
            fi
        done
    else
        # Load all service environments (Legacy behavior)
        # Optimized find: Limit depth to avoid scanning node_modules or build artifacts
        # Structure is services/<category>/<service>/.env (depth 3 from services/)
        while IFS= read -r env_file; do
            _load_file_to_map "$env_file"
        done < <(find "$project_root/services" -mindepth 3 -maxdepth 3 -name ".env" -type f)
    fi
    
    # Ensure PROJECT_ROOT is set in map
    ALL_ENV_VARS["PROJECT_ROOT"]="$project_root"
}

generate_value() {
    local type="$1"
    local length="$2"
    case "$type" in
        password|alphanum) gen_password "$length" ;;
        secret|base64) gen_base64 "$length" ;;
        hex) gen_hex "$length" ;;
        apikey) gen_hex "$length" ;;
        fixed) echo "$length" ;;
        *) echo "" ;;
    esac
}

# Global map to hold service-specific environment variables during processing
declare -gA SERVICE_ENV_VARS

# Load service environment context
# Usage: load_all_env "SCRIPT_DIR"
load_all_env() {
    local service_dir="$1"
    local template_file="$service_dir/.env.example"
    local output_file="$service_dir/.env"
    
    if [[ ! -f "$template_file" ]]; then
        log_warning "No .env.example found in $service_dir"
        return 0
    fi
    
    log_info "Loading environment for $(basename "$service_dir")..."

    # Load all environment context if not already loaded
    # Optimization: If COREKIT_ENV_LOADED is true, we assume variables are already in the environment
    # and we skip the expensive file scan.
    if [[ ${#ALL_ENV_VARS[@]} -eq 0 && "$COREKIT_ENV_LOADED" != "true" ]]; then
        load_all_envs
    fi
    
    # Clear global map first
    SERVICE_ENV_VARS=()
    
    # Load local existing variables to preserve them
    if [[ -f "$output_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then continue; fi
            if [[ "$line" == *"="* ]]; then
                local key=$(echo "$line" | cut -d'=' -f1 | xargs)
                local value=$(echo "$line" | cut -d'=' -f2-)
                value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'//")
                SERVICE_ENV_VARS["$key"]="$value"
            fi
        done < "$output_file"
    fi

    # Pre-populate defaults from template if not set
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then continue; fi
        if [[ "$line" == *"="* ]]; then
            local key=$(echo "$line" | cut -d'=' -f1 | xargs)
            local default_val_raw=$(echo "$line" | cut -d'=' -f2-)
            local default_val=$(echo "$default_val_raw" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'//")
            
            if [[ -z "${SERVICE_ENV_VARS[$key]}" ]]; then
                 # Try inheritance first
                 # Check ALL_ENV_VARS map OR current environment variable (indirect reference)
                 if [[ -n "${ALL_ENV_VARS[$key]}" ]]; then
                     SERVICE_ENV_VARS["$key"]="${ALL_ENV_VARS[$key]}"
                 elif [[ -n "${!key}" ]]; then
                     SERVICE_ENV_VARS["$key"]="${!key}"
                 else
                     SERVICE_ENV_VARS["$key"]="$default_val"
                 fi
            fi
        fi
    done < "$template_file"
}

# Generate secrets for the service
# Usage: generate_secrets "VARS_TO_GENERATE_REF"
generate_secrets() {
    local -n vars_gen_ref="$1"
    
    for key in "${!vars_gen_ref[@]}"; do
        # Only generate if empty or missing
        if [[ -z "${SERVICE_ENV_VARS[$key]}" ]]; then
            IFS=':' read -r type length <<< "${vars_gen_ref[$key]}"
            local final_val=$(generate_value "$type" "$length")
            SERVICE_ENV_VARS["$key"]="$final_val"
            ALL_ENV_VARS["$key"]="$final_val" # Update global context too
        fi
    done
}

# Generic function to write env file from template
# Usage: write_env_file "TEMPLATE_FILE" "OUTPUT_FILE"
write_env_file() {
    local template_file="$1"
    local output_file="$2"
    local temp_file=$(mktemp)
    
    # Perform substitution using shell expansion to support ${VAR} and ${VAR%%.*}
    # We run this in a subshell to avoid polluting the current environment
    (
        # Export global vars
        for k in "${!ALL_ENV_VARS[@]}"; do
            export "$k"="${ALL_ENV_VARS[$k]}"
        done

        # Export service vars (initial state)
        for k in "${!SERVICE_ENV_VARS[@]}"; do
            export "$k"="${SERVICE_ENV_VARS[$k]}"
        done

        # Resolve variables (Multiple passes for dependencies)
        for pass in {1..3}; do
            local changed=false
            for key in "${!SERVICE_ENV_VARS[@]}"; do
                local val="${SERVICE_ENV_VARS[$key]}"
                if [[ "$val" == *"\${"* ]]; then
                    # Escape double quotes to prevent breaking eval
                    local escaped_val="${val//\"/\\\"}"
                    # Use eval echo to expand variables
                    local resolved_val
                    if resolved_val=$(eval echo "\"$escaped_val\"" 2>/dev/null); then
                        if [[ "$resolved_val" != "$val" ]]; then
                            SERVICE_ENV_VARS["$key"]="$resolved_val"
                            export "$key"="$resolved_val"
                            changed=true
                        fi
                    fi
                fi
            done
            if [ "$changed" = false ]; then break; fi
        done

        # Track written keys
        declare -A WRITTEN_KEYS

        # Write to temp file
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Pass comments and empty lines
            if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then
                echo "$line" >> "$temp_file"
                continue
            fi
            
            if [[ "$line" == *"="* ]]; then
                local key=$(echo "$line" | cut -d'=' -f1 | xargs)
                local final_val="${SERVICE_ENV_VARS[$key]}"
                echo "${key}='${final_val}'" >> "$temp_file"
                WRITTEN_KEYS["$key"]=1
            else
                echo "$line" >> "$temp_file"
            fi
        done < "$template_file"

        # Append User Defined Variables
        local header_written=false
        for key in "${!SERVICE_ENV_VARS[@]}"; do
            if [[ -z "${WRITTEN_KEYS[$key]}" ]]; then
                if [ "$header_written" = false ]; then
                    echo "" >> "$temp_file"
                    echo "# --- User Defined Variables ---" >> "$temp_file"
                    header_written=true
                fi
                echo "${key}='${SERVICE_ENV_VARS[$key]}'" >> "$temp_file"
            fi
        done
    )
    
    mv "$temp_file" "$output_file"
}

# Write the service environment file using SERVICE_ENV_VARS
# Usage: write_service_env "SCRIPT_DIR"
write_service_env() {
    local service_dir="$1"
    local template_file="$service_dir/.env.example"
    local output_file="$service_dir/.env"
    
    write_env_file "$template_file" "$output_file"
    log_success "Updated secrets in $(basename "$service_dir")/.env"
}
