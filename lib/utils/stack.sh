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
