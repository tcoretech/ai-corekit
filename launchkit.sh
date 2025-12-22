#!/bin/bash

# AI LaunchKit CLI
# Usage: launchkit <command> [args]

set -e

# Resolve paths
# When run via symlink, we need to resolve the real path
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

PROJECT_ROOT="$SCRIPT_DIR"
cd "$PROJECT_ROOT"
LIB_DIR="$PROJECT_ROOT/lib"
CONFIG_DIR="$PROJECT_ROOT/config"
GLOBAL_ENV="$CONFIG_DIR/.env.global"

# Source utilities
if [ -f "$LIB_DIR/utils/logging.sh" ]; then
    source "$LIB_DIR/utils/logging.sh"
else
    echo "Error: utils.sh not found in $LIB_DIR/utils/logging.sh"
    exit 1
fi

if [ -f "$LIB_DIR/utils/stack.sh" ]; then
    source "$LIB_DIR/utils/stack.sh"
else
    echo "Error: stack.sh not found in $LIB_DIR/utils/stack.sh"
    exit 1
fi

# Helper: Load Environment
load_env() {
    if [ -f "$GLOBAL_ENV" ]; then
        set -a
        source "$GLOBAL_ENV"
        set +a
    fi
    # Also load root .env if it exists
    if [ -f "$PROJECT_ROOT/.env" ]; then
        set -a
        source "$PROJECT_ROOT/.env"
        set +a
    fi
}

# Command: Init
cmd_init() {
    log_info "Initializing AI LaunchKit System..."
    
    # Run System Prep
    if [ -f "$LIB_DIR/system/system_prep.sh" ]; then
        bash "$LIB_DIR/system/system_prep.sh"
    else
        log_error "System prep script not found."
    fi
    
    # Run Docker Install
    if [ -f "$LIB_DIR/system/install_docker.sh" ]; then
        bash "$LIB_DIR/system/install_docker.sh"
    else
        log_error "Docker install script not found."
    fi

    # Generate Secrets
    if [ -f "$LIB_DIR/services/generate_all_secrets.sh" ]; then
        bash "$LIB_DIR/services/generate_all_secrets.sh"
    else
        log_error "Secrets generation script not found."
    fi
}

# Command: Config
cmd_config() {
    log_info "Starting Configuration Wizard..."
    if [ -f "$LIB_DIR/config/wizard.sh" ]; then
        bash "$LIB_DIR/config/wizard.sh"
    else
        log_error "Wizard script not found."
    fi
}

# Command: Credentials
cmd_credentials() {
    local action="$1"
    shift
    
    case "$action" in
        download)
            if [ -f "$LIB_DIR/services/credentials/download.sh" ]; then
                bash "$LIB_DIR/services/credentials/download.sh" "$@"
            else
                log_error "Download credentials script not found."
            fi
            ;;
        export)
            if [ -f "$LIB_DIR/services/credentials/export.sh" ]; then
                bash "$LIB_DIR/services/credentials/export.sh" "$@"
            else
                log_error "Export credentials script not found."
            fi
            ;;
        *)
            echo "Usage: launchkit credentials <download|export>"
            exit 1
            ;;
    esac
}



# Command: Enable
cmd_enable() {
    local services_to_enable=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--stack)
                shift
                if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
                local stack_services=$(get_stack_services "$1")
                if [ $? -eq 0 ]; then
                    for s in $stack_services; do services_to_enable+=("$s"); done
                fi
                shift
                ;;
            *)
                services_to_enable+=("$1")
                shift
                ;;
        esac
    done
    
    if [ ${#services_to_enable[@]} -eq 0 ]; then
        log_error "No services specified to enable."
        exit 1
    fi
    
    load_env
    local current_profiles="${COMPOSE_PROFILES:-}"
    local new_profiles="$current_profiles"
    
    for s in "${services_to_enable[@]}"; do
        # Only add if not already present
        if [[ ",$new_profiles," != *",$s,"* ]]; then
            if [ -z "$new_profiles" ]; then
                new_profiles="$s"
            else
                new_profiles="$new_profiles,$s"
            fi
        fi
    done
    
    # Update .env.global
    if [ -f "$GLOBAL_ENV" ]; then
        if grep -q "^COMPOSE_PROFILES=" "$GLOBAL_ENV"; then
            local tmp_env=$(mktemp)
            sed "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=\"$new_profiles\"|" "$GLOBAL_ENV" > "$tmp_env"
            mv "$tmp_env" "$GLOBAL_ENV"
        else
            echo "COMPOSE_PROFILES=\"$new_profiles\"" >> "$GLOBAL_ENV"
        fi
    else
        echo "COMPOSE_PROFILES=\"$new_profiles\"" > "$GLOBAL_ENV"
    fi
    
    log_success "Enabled services: ${services_to_enable[*]}"
    log_info "Current profiles: $new_profiles"
}

# Command: Disable
cmd_disable() {
    local services_to_disable=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--stack)
                shift
                if [ -z "$1" ]; then log_error "Stack name required"; exit 1; fi
                local stack_services=$(get_stack_services "$1")
                if [ $? -eq 0 ]; then
                    for s in $stack_services; do services_to_disable+=("$s"); done
                fi
                shift
                ;;
            *)
                services_to_disable+=("$1")
                shift
                ;;
        esac
    done
    
    if [ ${#services_to_disable[@]} -eq 0 ]; then
        log_error "No services specified to disable."
        exit 1
    fi
    
    load_env
    local current_profiles="${COMPOSE_PROFILES:-}"
    local new_profiles=""
    
    # Convert comma-separated string to array
    IFS=',' read -ra profile_array <<< "$current_profiles"
    
    for p in "${profile_array[@]}"; do
        local keep=true
        for s in "${services_to_disable[@]}"; do
            if [ "$p" == "$s" ]; then
                keep=false
                break
            fi
        done
        
        if [ "$keep" = true ]; then
            if [ -z "$new_profiles" ]; then
                new_profiles="$p"
            else
                new_profiles="$new_profiles,$p"
            fi
        fi
    done
    
    # Update .env.global
    if [ -f "$GLOBAL_ENV" ]; then
        if grep -q "^COMPOSE_PROFILES=" "$GLOBAL_ENV"; then
            local tmp_env=$(mktemp)
            sed "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=\"$new_profiles\"|" "$GLOBAL_ENV" > "$tmp_env"
            mv "$tmp_env" "$GLOBAL_ENV"
        else
            echo "COMPOSE_PROFILES=\"$new_profiles\"" >> "$GLOBAL_ENV"
        fi
    else
        echo "COMPOSE_PROFILES=\"$new_profiles\"" > "$GLOBAL_ENV"
    fi
    
    log_success "Disabled services: ${services_to_disable[*]}"
    log_info "Current profiles: $new_profiles"
}

# Command: Run
cmd_run() {
    local service_name="$1"
    if [ -n "$1" ]; then
        shift
    fi
    
    if [ -z "$service_name" ]; then
        log_error "Service name required."
        exit 1
    fi
    
    # Search for a service with this name
    local found_service=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -type d -name "$service_name" | head -n 1)
    
    if [ -n "$found_service" ] && [ -f "$found_service/cli.sh" ]; then
        log_info "Delegating to service CLI: $service_name"
        (cd "$found_service" && bash "cli.sh" "$@")
    else
        log_error "Service '$service_name' not found or does not have a CLI."
        exit 1
    fi
}

# Command: Up
cmd_up() {
    if [ -f "$LIB_DIR/services/up.sh" ]; then
        bash "$LIB_DIR/services/up.sh" "$@"
    else
        log_error "Up script not found."
    fi
}

# Command: Update
cmd_update() {
    if [ -f "$LIB_DIR/services/update.sh" ]; then
        bash "$LIB_DIR/services/update.sh" "$@"
    else
        log_error "Update script not found."
    fi
}

# Command: Down
cmd_down() {
    if [ -f "$LIB_DIR/services/down.sh" ]; then
        bash "$LIB_DIR/services/down.sh" "$@"
    else
        log_error "Down script not found."
    fi
}

# Helper: Get Compose Files for Stack
# Usage: get_stack_compose_files <stack_name>
# Returns array of -f flags in global COMPOSE_FLAGS variable
get_stack_compose_files() {
    local stack="$1"
    local services=$(get_stack_services "$stack")
    
    COMPOSE_FLAGS=()
    
    for service in $services; do
        # Optimization: assume structure services/category/service
        # Or use find. Find is safer.
        local service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service" -type d | head -n 1)
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
            COMPOSE_FLAGS+=("-f" "$service_dir/docker-compose.yml")
        fi
    done
}

# Generic Docker Compose Wrapper
# Usage: run_compose_cmd <command> [args...]
run_compose_cmd() {
    local cmd="$1"
    shift
    
    local stack="core"
    local project=""
    local compose_args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--stack)
                shift
                if [ -n "$1" ]; then
                    stack="$1"
                    shift
                fi
                ;;
            -p|--project)
                shift
                if [ -n "$1" ]; then
                    project="$1"
                    shift
                fi
                ;;
            *)
                compose_args+=("$1")
                shift
                ;;
        esac
    done
    
    if [ -n "$project" ]; then
        PROJECT_NAME="$project"
    else
        load_stack_config "$stack"
    fi
    
    load_env

    # Gather compose files if we are using a stack
    # If project is manually specified, we might not know the stack, so we default to core or just root compose?
    # If we don't provide -f, docker compose might fail to find services.
    # We'll try to load files from the stack if project is not manually overridden OR if stack is explicitly provided.
    
    get_stack_compose_files "$stack"
    
    docker compose -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" "${COMPOSE_FLAGS[@]}" "$cmd" "${compose_args[@]}"
}

# Command: Logs
cmd_logs() {
    run_compose_cmd logs "$@"
}

# Command: PS
cmd_ps() {
    local stack=""
    local project=""
    
    # Parse args to find project/stack
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--stack)
                shift
                if [ -n "$1" ]; then stack="$1"; fi
                shift
                ;;
            -p|--project)
                shift
                if [ -n "$1" ]; then project="$1"; fi
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    load_env
    
    # Generate Service Map
    local map_file=$(mktemp)
    find "$PROJECT_ROOT/services" -mindepth 3 -maxdepth 3 -name docker-compose.yml -exec grep -H "^  [a-zA-Z0-9_-]\+:" {} + | \
    awk -F: '{ 
        split($1, parts, "/"); 
        for (i=1; i<=length(parts); i++) {
            if (parts[i] == "services") {
                launchkit_service = parts[i+2];
                break;
            }
        }
        service_name = $2; 
        gsub(/^[ \t]+/, "", service_name); 
        gsub(/:$/, "", service_name); 
        
        # Check for service.json to get a better name
        service_json_path = "";
        for (j=1; j<=length(parts)-1; j++) {
            service_json_path = service_json_path parts[j] "/";
        }
        service_json_path = service_json_path "service.json";
        
        json_name = "";
        if ((getline json_line < service_json_path) > 0) {
             # Very simple JSON parsing for "name": "value"
             # Read whole file
             close(service_json_path);
             while ((getline json_line < service_json_path) > 0) {
                 if (match(json_line, /"name"[ \t]*:[ \t]*"([^"]+)"/, groups)) {
                     json_name = groups[1];
                     break;
                 }
             }
             close(service_json_path);
        }

        if (json_name != "") {
            launchkit_service = json_name;
        }

        if (launchkit_service == service_name) {
            best_map[service_name] = launchkit_service;
        } else {
            if (!(service_name in best_map)) {
                best_map[service_name] = launchkit_service;
            }
            # If we have a json name, it should probably override?
            if (json_name != "") {
                 best_map[service_name] = launchkit_service;
            }
        }
    }
    END {
        for (s in best_map) {
            print s "=" best_map[s];
        }
    }' > "$map_file"

    # Define processing function to avoid code duplication
    process_ps_output() {
        awk -F'\t' -v map_file="$map_file" '
        BEGIN {
            OFS="\t";
            while ((getline line < map_file) > 0) {
                split(line, kv, "=");
                service_map[kv[1]] = kv[2];
            }
            close(map_file);
        }
        NR==1 { print; next }
        {
            if ($2 in service_map) {
                $2 = service_map[$2];
            }
            print $1, $2, $3, $4, $5, $6
        }' | column -t -s $'\t'
    }

    if [ -n "$project" ]; then
        # Specific project requested
        {
            printf "PROJECT\tSERVICE\tCONTAINER\tIMAGE\tSTATUS\tPORTS\n"
            docker ps --filter "label=com.docker.compose.project=$project" --format "{{.Label \"com.docker.compose.project\"}}\t{{.Label \"com.docker.compose.service\"}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        } | process_ps_output
    elif [ -n "$stack" ]; then
        # Specific stack requested
        load_stack_config "$stack"
        {
            printf "PROJECT\tSERVICE\tCONTAINER\tIMAGE\tSTATUS\tPORTS\n"
            docker ps --filter "label=com.docker.compose.project=$PROJECT_NAME" --format "{{.Label \"com.docker.compose.project\"}}\t{{.Label \"com.docker.compose.service\"}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        } | process_ps_output
    else
        # No specific project/stack, find all configured projects
        local unique_projects=($(get_all_stack_projects))
        local pattern=$(IFS="|"; echo "${unique_projects[*]}")
        
        # Use docker ps to list all running containers for the project(s)
        {
            printf "PROJECT\tSERVICE\tCONTAINER\tIMAGE\tSTATUS\tPORTS\n"
            docker ps --filter "label=com.docker.compose.project" --format "{{.Label \"com.docker.compose.project\"}}\t{{.Label \"com.docker.compose.service\"}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        } | process_ps_output | grep -E "^(PROJECT|${pattern})\s"
    fi
    
    rm "$map_file"
}

# Command: Restart
cmd_restart() {
    run_compose_cmd restart "$@"
}

# Command: Exec
cmd_exec() {
    run_compose_cmd exec "$@"
}

# Command: Pull
cmd_pull() {
    run_compose_cmd pull "$@"
}

# Command: Build
cmd_build() {
    run_compose_cmd build "$@"
}

# Command: Stop
cmd_stop() {
    run_compose_cmd stop "$@"
}

# Command: Rm
cmd_rm() {
    if [ -f "$LIB_DIR/services/rm.sh" ]; then
        bash "$LIB_DIR/services/rm.sh" "$@"
    else
        log_error "Rm script not found."
    fi
}

# Command: Help
cmd_help() {
    echo "AI LaunchKit CLI"
    echo "Usage: launchkit <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init          Initialize the system (install dependencies)"
    echo "  config        Run configuration wizard"
    echo "  enable        Enable services or stacks (e.g. enable service1 -s stack1)"
    echo "  disable       Disable services or stacks"
    echo "  up            Start services"
    echo "  down          Stop services"
    echo "  restart       Restart services"
    echo "  stop          Stop services (without removing)"
    echo "  build         Build services"
    echo "  rm            Remove stopped containers"
    echo "  logs          View service logs"
    echo "  ps            List running services"
    echo "  exec          Execute command in container"
    echo "  pull          Pull service images"
    echo "  update        Update the system"
    echo "  credentials   Manage credentials (download|export)"
    echo "  run <service> Run a service-specific command (e.g., launchkit run ssh ...)"
    echo "  help          Show this help message"
}

# Main Dispatch
COMMAND="$1"
shift || true

case "$COMMAND" in
    init)
        cmd_init "$@"
        ;;
    config)
        cmd_config "$@"
        ;;
    enable)
        cmd_enable "$@"
        ;;
    disable)
        cmd_disable "$@"
        ;;
    up)
        cmd_up "$@"
        ;;
    down)
        cmd_down "$@"
        ;;
    restart)
        cmd_restart "$@"
        ;;
    stop)
        cmd_stop "$@"
        ;;
    build)
        cmd_build "$@"
        ;;
    rm)
        cmd_rm "$@"
        ;;
    logs)
        cmd_logs "$@"
        ;;
    ps)
        cmd_ps "$@"
        ;;
    exec)
        cmd_exec "$@"
        ;;
    pull)
        cmd_pull "$@"
        ;;
    update)
        cmd_update "$@"
        ;;
    credentials)
        cmd_credentials "$@"
        ;;
    run)
        cmd_run "$@"
        ;;
    help|--help|-h)
        cmd_help
        ;;
    "")
        cmd_help
        exit 1
        ;;
    *)
        echo "Unknown command: $COMMAND"
        cmd_help
        exit 1
        ;;
esac
