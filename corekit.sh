#!/bin/bash

# AI CoreKit CLI
# Usage: corekit <command> [args]

VERSION="1.0.0"

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
export PROJECT_ROOT
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
    log_info "Initializing AI CoreKit System..."
    
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

# Command: System
cmd_system() {
    local action="$1"
    shift || true
    
    case "$action" in
        --close-ports)
            if [ -f "$LIB_DIR/system/firewall_config.sh" ]; then
                bash "$LIB_DIR/system/firewall_config.sh" "$@"
            else
                log_error "Firewall configuration script not found."
                exit 1
            fi
            ;;
        *)
            echo "Usage: corekit system --close-ports"
            echo ""
            echo "System commands:"
            echo "  --close-ports    Configure firewall to close most ports (keeps SSH, HTTP, HTTPS)"
            echo ""
            echo "⚠️  WARNING: --close-ports will enable UFW firewall and close most ports."
            echo "    SSH, HTTP, and HTTPS will remain open, but other services may become"
            echo "    inaccessible. Only use this if you understand the implications."
            exit 1
            ;;
    esac
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
            echo "Usage: corekit credentials <download|export>"
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
    
    # Validate services exist
    for s in "${services_to_enable[@]}"; do
        service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$s" -type d | head -n 1)
        if [ -z "$service_dir" ]; then
            log_error "Service '$s' not found. Please check the service name."
            exit 1
        fi
    done
    
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
    
    if [ "$cmd" == "logs" ]; then
        docker compose -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" "${COMPOSE_FLAGS[@]}" "$cmd" "${compose_args[@]}" 2> >(grep -v "variable is not set" >&2)
    else
        docker compose -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" "${COMPOSE_FLAGS[@]}" "$cmd" "${compose_args[@]}"
    fi
}

# Command: Logs
cmd_logs() {
    local project=""
    local other_args=()
    
    # Parse args manually to extract -p/--project
    local i=1
    while [ $i -le $# ]; do
        local arg="${!i}"
        case "$arg" in
            -p|--project)
                ((i++))
                if [ $i -le $# ]; then
                    project="${!i}"
                fi
                ;;
            *)
                other_args+=("$arg")
                ;;
        esac
        ((i++))
    done
    
    # Reset positional parameters to other_args
    set -- "${other_args[@]}"

    # If no service specified (or first arg is a flag), show interactive menu of running services
    if [ -z "$1" ] || [[ "$1" == -* ]]; then
        # Only show menu if we are in a TTY or if we can read from /dev/tty
        if [ -t 0 ] || [ -c /dev/tty ]; then
            
            # Get running services from cmd_ps
            # cmd_ps output format: PROJECT SERVICE ...
            # We skip the header (first line)
            local ps_out=$(cmd_ps | tail -n +2)
            
            if [ -z "$ps_out" ]; then
                log_error "No running services found."
                return 1
            fi

            # Parse into unique "SERVICE PROJECT" lines
            local services_list=$(echo "$ps_out" | awk '{print $2, $1}' | sort | uniq)
            
            if [ -z "$services_list" ]; then
                log_error "No running services found."
                return 1
            fi

            # Read into array
            local menu_items=()
            while read -r line; do
                if [ -n "$line" ]; then
                    menu_items+=("$line")
                fi
            done <<< "$services_list"

            # Print menu to stderr
            {
                echo "Select a running service to view logs:"
                local j=1
                for item in "${menu_items[@]}"; do
                    local svc=$(echo "$item" | awk '{print $1}')
                    local proj=$(echo "$item" | awk '{print $2}')
                    echo "$j) $svc ($proj)"
                    ((j++))
                done
                echo "$j) All (via docker compose)"
            } >&2

            local selection
            if [ -t 0 ]; then
                read -p "Select service (default 1): " selection
            else
                echo -n "Select service (default 1): " >&2
                read selection < /dev/tty
            fi

            if [ -z "$selection" ]; then selection=1; fi

            if [ "$selection" -eq "$j" ]; then
                # All selected - fall through to run_compose_cmd
                if [ -n "$project" ]; then
                    run_compose_cmd logs -p "$project" "$@"
                else
                    run_compose_cmd logs "$@"
                fi
                return
            elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$j" ]; then
                local selected_item="${menu_items[$((selection-1))]}"
                local svc=$(echo "$selected_item" | awk '{print $1}')
                local proj=$(echo "$selected_item" | awk '{print $2}')
                
                # Recursively call cmd_logs with the selected service and project
                cmd_logs -p "$proj" "$svc" "$@"
                return
            else
                log_error "Invalid selection"
                return 1
            fi
        fi
    fi

    # Optimization: If a specific service is requested, only load that service's compose file
    # This prevents "variable not set" warnings from unrelated services
    if [[ "$1" != -* ]] && [ -n "$1" ]; then
        local service_name="$1"
        
        # Find the service directory
        local service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service_name" -type d | head -n 1)
        
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
            shift # Remove service name from args
            
            # Load environment
            load_env
            
            # Determine project name
            if [ -n "$project" ]; then
                PROJECT_NAME="$project"
            else
                load_stack_config "core" # Default to core stack if no project specified
            fi

            # Load service-specific .env to prevent warnings
            local env_file_args=()
            if [ -f "$service_dir/.env" ]; then
                set -a
                source "$service_dir/.env"
                set +a
                env_file_args+=(--env-file "$service_dir/.env")
            fi
            
            # Suppress warnings by filtering stderr
            # We use process substitution to filter out the specific warning pattern from stderr
            # while keeping other stderr output (like container logs) intact.

            
            # Check if --all flag is present
            local show_all=false
            local args=()
            for arg in "$@"; do
                if [ "$arg" == "--all" ]; then
                    show_all=true
                else
                    args+=("$arg")
                fi
            done
            
            if [ "$show_all" = true ]; then
                # Show logs for all containers in this service
                docker compose "${env_file_args[@]}" -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" -f "$service_dir/docker-compose.yml" logs "${args[@]}" 2> >(grep -v "variable is not set" >&2)
            else
                # Try to find the main service name from docker-compose.yml
                # Heuristic: Look for service name matching directory name, or first service
                local main_service=""
                
                # Get list of services in this compose file
                # Ensure profiles are active for config command
                export COMPOSE_PROFILES
                local services=$(docker compose "${env_file_args[@]}" -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" -f "$service_dir/docker-compose.yml" config --services 2>/dev/null)
                
                # Fallback to grep if config returns nothing (e.g. profiles issue or invalid config)
                if [ -z "$services" ]; then
                    services=$(grep "^  [a-zA-Z0-9_-]\+:" "$service_dir/docker-compose.yml" | sed 's/^  //;s/://')
                fi
                
                if [ -z "$services" ]; then
                    log_error "No services found in $service_dir/docker-compose.yml"
                    return 1
                fi

                local service_count=$(echo "$services" | wc -l)
                
                if [ "$service_count" -eq 1 ]; then
                    main_service=$(echo "$services" | head -n 1)
                else
                    # Sort services: exact match first, then others
                    local sorted_services=""
                    if echo "$services" | grep -q "^$service_name$"; then
                        sorted_services="$service_name"
                        sorted_services+=$'\n'
                        sorted_services+=$(echo "$services" | grep -v "^$service_name$")
                    else
                        sorted_services="$services"
                    fi

                    # Parse services into array
                    local i=1
                    local service_array=()
                    while read -r s; do
                        if [ -n "$s" ]; then
                            service_array+=("$s")
                            ((i++))
                        fi
                    done <<< "$sorted_services"

                    # Interactive selection
                    # Print menu to stderr so it is visible even if stdout is piped (e.g. | tail)
                    {
                        echo "Multiple containers found for service '$service_name':"
                        local j=1
                        for s in "${service_array[@]}"; do
                            echo "$j) $s"
                            ((j++))
                        done
                        echo "$j) All"
                    } >&2
                    
                    if [ -t 0 ]; then
                        # Input is a TTY (interactive)
                        read -p "Select container (default 1): " selection
                    else
                        # Input is not a TTY (automated/piped input)
                        # Still try to read from /dev/tty if available to support piping
                        if [ -c /dev/tty ]; then
                            # Prompt to stderr
                            echo -n "Select container (default 1): " >&2
                            read selection < /dev/tty
                        else
                            read selection
                        fi
                    fi

                    if [ -z "$selection" ]; then selection=1; fi
                    
                    if [ "$selection" -eq "$i" ]; then
                        # All selected
                        docker compose "${env_file_args[@]}" -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" -f "$service_dir/docker-compose.yml" logs "${args[@]}" 2> >(grep -v "variable is not set" >&2)
                        return
                    elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$i" ]; then
                        main_service="${service_array[$((selection-1))]}"
                    else
                        log_error "Invalid selection"
                        return 1
                    fi
                fi
                
                if [ -n "$main_service" ]; then
                    docker compose "${env_file_args[@]}" -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" -f "$service_dir/docker-compose.yml" logs "$main_service" "${args[@]}" 2> >(grep -v "variable is not set" >&2)
                else
                     # Fallback to all
                    docker compose "${env_file_args[@]}" -p "$PROJECT_NAME" --project-directory "$PROJECT_ROOT" -f "$service_dir/docker-compose.yml" logs "${args[@]}" 2> >(grep -v "variable is not set" >&2)
                fi
            fi
            return
        fi
    fi

    run_compose_cmd logs "$@"
}

# Command: PS
cmd_ps() {
    local stack=""
    local project=""
    local filter_service=""
    
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
                if [ -z "$filter_service" ]; then
                    filter_service="$1"
                fi
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
                corekit_service = parts[i+2];
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
            corekit_service = json_name;
        }

        if (corekit_service == service_name) {
            best_map[service_name] = corekit_service;
        } else {
            if (!(service_name in best_map)) {
                best_map[service_name] = corekit_service;
            }
            # If we have a json name, it should probably override?
            if (json_name != "") {
                 best_map[service_name] = corekit_service;
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
        awk -F'\t' -v map_file="$map_file" -v filter="$filter_service" '
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
            
            # Filter if requested
            if (filter != "" && $2 != filter) {
                next;
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
    local project=""
    local service_name=""
    local other_args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--project)
                shift
                if [ -n "$1" ]; then project="$1"; fi
                shift
                ;;
            -*)
                other_args+=("$1")
                shift
                ;;
            *)
                if [ -z "$service_name" ]; then
                    service_name="$1"
                else
                    other_args+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    if [ -n "$service_name" ]; then
        local service_dir=$(find "$PROJECT_ROOT/services" -mindepth 2 -maxdepth 2 -name "$service_name" -type d | head -n 1)
        
        if [ -n "$service_dir" ] && [ -f "$service_dir/docker-compose.yml" ]; then
            load_env
            if [ -n "$project" ]; then
                PROJECT_NAME="$project"
            else
                load_stack_config "core"
            fi
            
            local env_file_args=()
            if [ -f "$service_dir/.env" ]; then
                set -a
                source "$service_dir/.env"
                set +a
                env_file_args+=(--env-file "$service_dir/.env")
            fi
            
            log_info "Restarting service: $service_name"
            docker compose "${env_file_args[@]}" -p "$PROJECT_NAME" --project-directory "$service_dir" -f "$service_dir/docker-compose.yml" restart "${other_args[@]}"
            return
        fi
    fi
    
    # Reconstruct args
    local args=()
    if [ -n "$project" ]; then args+=("-p" "$project"); fi
    if [ -n "$service_name" ]; then args+=("$service_name"); fi
    args+=("${other_args[@]}")
    
    run_compose_cmd restart "${args[@]}"
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
    if [ -f "$LIB_DIR/services/build.sh" ]; then
        bash "$LIB_DIR/services/build.sh" "$@"
    else
        log_error "Build script not found."
    fi
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

# Command: List
cmd_list() {
    echo "Available Services:"
    echo "-------------------"
    printf "%-20s %-20s %-40s\n" "SERVICE" "CATEGORY" "DESCRIPTION"
    echo "--------------------------------------------------------------------------------"
    
    find "$PROJECT_ROOT/services" -mindepth 3 -maxdepth 3 -name "service.json" | while read -r json_file; do
        # Extract fields using grep/sed since jq might not be available
        local name=$(grep -o '"name": *"[^"]*"' "$json_file" | cut -d'"' -f4)
        local category=$(grep -o '"category": *"[^"]*"' "$json_file" | cut -d'"' -f4)
        local desc=$(grep -o '"description": *"[^"]*"' "$json_file" | cut -d'"' -f4)
        
        # Fallback if name is missing (use directory name)
        if [ -z "$name" ]; then
            name=$(basename "$(dirname "$json_file")")
        fi
        
        printf "%-20s %-20s %-40s\n" "$name" "${category:0:20}" "${desc:0:40}..."
    done | sort
}

# Command: Help
cmd_help() {
    echo "AI CoreKit CLI"
    echo "Usage: corekit <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init          Initialize the system (install dependencies)"
    echo "  config        Run configuration wizard"
    echo "  system        System management commands (e.g., system --close-ports)"
    echo "  enable        Enable services or stacks (e.g. enable service1 -s stack1)"
    echo "  disable       Disable services or stacks"
    echo "  up            Start services"
    echo "  down          Stop services (use --prune to stop disabled services)"
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
    echo "  run <service> Run a service-specific command (e.g., corekit run ssh ...)"
    echo "  list          List all available services"
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
    system)
        cmd_system "$@"
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
    list)
        cmd_list "$@"
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
