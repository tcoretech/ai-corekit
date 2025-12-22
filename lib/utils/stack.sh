#!/bin/bash

# Stack Management Utilities

# Helper: Get Services from Stack
# Usage: get_stack_services <stack_name>
get_stack_services() {
    local stack="$1"
    local stack_file="$CONFIG_DIR/stacks/$stack.yaml"
    if [ -f "$stack_file" ]; then
        sed -n '/^services:/,$p' "$stack_file" | grep '^\s*-\s*' | sed 's/^\s*-\s*//'
    else
        # If stack file doesn't exist, return empty or error?
        # For now, just return empty so we don't break things if stack is invalid
        return 1
    fi
}

# Helper: Get Project Name from Stack
# Usage: get_stack_project_name <stack_name>
get_stack_project_name() {
    local stack="$1"
    local stack_file="$CONFIG_DIR/stacks/$stack.yaml"
    local project_name="localai" # Default
    
    if [ -f "$stack_file" ]; then
        local extracted=$(grep "^project_name:" "$stack_file" | cut -d':' -f2 | tr -d ' "')
        if [ -n "$extracted" ]; then
            project_name="$extracted"
        fi
    fi
    echo "$project_name"
}

# Helper: Load Stack Config (sets PROJECT_NAME)
# Usage: load_stack_config <stack_name>
load_stack_config() {
    local stack="$1"
    PROJECT_NAME=$(get_stack_project_name "$stack")
}

# Helper: Enable Service Profile
# Usage: enable_service_profile <service_name>
enable_service_profile() {
    local service="$1"
    local global_env="$CONFIG_DIR/.env.global"
    
    # Load current profiles
    local current_profiles=""
    if [ -f "$global_env" ]; then
        current_profiles=$(grep "^COMPOSE_PROFILES=" "$global_env" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
    
    # Check if already enabled
    if [[ ",$current_profiles," == *",$service,"* ]]; then
        return 0
    fi
    
    # Add to profiles
    local new_profiles=""
    if [ -z "$current_profiles" ]; then
        new_profiles="$service"
    else
        new_profiles="$current_profiles,$service"
    fi
    
    # Update .env.global
    if command -v update_env_var &> /dev/null; then
        update_env_var "$global_env" "COMPOSE_PROFILES" "$new_profiles"
        log_info "Enabled profile: $service"
    else
        log_warning "Cannot update profiles: update_env_var not found"
    fi
}

# Helper: Disable Service Profile
# Usage: disable_service_profile <service_name>
disable_service_profile() {
    local service="$1"
    local global_env="$CONFIG_DIR/.env.global"
    
    # Load current profiles
    local current_profiles=""
    if [ -f "$global_env" ]; then
        current_profiles=$(grep "^COMPOSE_PROFILES=" "$global_env" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
    
    # Check if present
    if [[ ",$current_profiles," != *",$service,"* ]]; then
        return 0
    fi
    
    # Remove from profiles
    local new_profiles=$(echo "$current_profiles" | sed "s/^$service,//" | sed "s/,$service$//" | sed "s/,$service,/,/g" | sed "s/^$service$//")
    
    # Update .env.global
    if command -v update_env_var &> /dev/null; then
        update_env_var "$global_env" "COMPOSE_PROFILES" "$new_profiles"
        log_info "Disabled profile: $service"
    else
        log_warning "Cannot update profiles: update_env_var not found"
    fi
}
