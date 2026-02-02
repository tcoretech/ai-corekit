#!/bin/bash

# Stack Management Utilities

# Helper: Get Services from Stack
# Usage: get_stack_services <stack_name>
get_stack_services() {
    local stack="$1"
    local stack_file="$CONFIG_DIR/stacks/$stack.yaml"
    
    # Check custom folder if not found in root stacks folder
    if [ ! -f "$stack_file" ]; then
        if [ -f "$CONFIG_DIR/stacks/custom/$stack.yaml" ]; then
            stack_file="$CONFIG_DIR/stacks/custom/$stack.yaml"
        fi
    fi

    if [ -f "$stack_file" ]; then
        sed -n '/^services:/,$p' "$stack_file" | grep '^\s*-\s*' | sed 's/^\s*-\s*//'
    else
        return 1
    fi
}

# Helper: Get Project Name from Stack
# Usage: get_stack_project_name <stack_name>
get_stack_project_name() {
    local stack="$1"
    local stack_file="$CONFIG_DIR/stacks/$stack.yaml"
    
    # Check custom folder if not found in root stacks folder
    if [ ! -f "$stack_file" ]; then
        if [ -f "$CONFIG_DIR/stacks/custom/$stack.yaml" ]; then
            stack_file="$CONFIG_DIR/stacks/custom/$stack.yaml"
        fi
    fi

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

# Helper: Get All Stack Projects
# Usage: get_all_stack_projects
# Returns space-separated list of all unique project names defined in stacks
get_all_stack_projects() {
    local projects=("localai")
    
    if [ -d "$CONFIG_DIR/stacks" ]; then
        # Enable nullglob to handle no matches
        shopt -s nullglob
        for stack_file in "$CONFIG_DIR/stacks"/*.yaml "$CONFIG_DIR/stacks/custom"/*.yaml; do
            if [ -f "$stack_file" ]; then
                local p_name=$(grep "^\s*project_name:" "$stack_file" | cut -d':' -f2 | tr -d ' "')
                if [ -n "$p_name" ]; then
                    projects+=("$p_name")
                fi
            fi
        done
        shopt -u nullglob
    fi
    
    # Deduplicate and print
    echo "${projects[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Helper: Find Stack for Service
# Usage: find_stack_for_service <service_name>
find_stack_for_service() {
    local service="$1"
    local found_stack=""
    
    if [ -d "$CONFIG_DIR/stacks" ]; then
        shopt -s nullglob
        for stack_file in "$CONFIG_DIR/stacks"/*.yaml "$CONFIG_DIR/stacks/custom"/*.yaml; do
            if [ -f "$stack_file" ]; then
                # Check if service is listed in the services array
                # We look for "  - service_name" pattern
                if grep -q "^\s*-\s*$service\s*$" "$stack_file"; then
                    found_stack=$(basename "$stack_file" .yaml)
                    break
                fi
            fi
        done
        shopt -u nullglob
    fi
    echo "$found_stack"
}

# Helper: Find Service Path
# Usage: find_service_path <service_name> [project_root] [config_dir]
find_service_path() {
    local service="$1"
    local p_root="${2:-$PROJECT_ROOT}"
    local c_dir="${3:-$CONFIG_DIR}"
    
    # 1. Try to find path from service_categories.json
    if [ -f "$c_dir/service_categories.json" ]; then
        # Extract paths using grep/cut
        # Grep for "path": "value"
        local paths=$(grep '"path":' "$c_dir/service_categories.json" | cut -d'"' -f4)
        
        for p in $paths; do
            if [ -d "$p_root/services/$p/$service" ]; then
                echo "$p_root/services/$p/$service"
                return 0
            fi
        done
    fi
    
    # 2. Check 'custom-services' folder explicitly
    if [ -d "$p_root/services/custom-services/$service" ]; then
        echo "$p_root/services/custom-services/$service"
        return 0
    fi
    
    # 3. Fallback to global find
    local found=$(find "$p_root/services" -mindepth 2 -maxdepth 2 -name "$service" -type d 2>/dev/null | head -n 1)
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi
    
    return 1
}
