#!/bin/bash
# Library for service health verification

# Check a service that is NOT exposed to the host by using a sidecar or internal exec.
# Usage: check_internal_service_http <service_container_name> <internal_port> <sidecar_container_name> [max_retries]
# Returns: 0 if success, 1 if failure
check_internal_service_http() {
    local target_service="$1"
    local port="$2"
    local sidecar="$3"
    local max_retries="${4:-12}" # Default to 12 attempts (approx 60s)
    local attempt=1
    
    # Validation
    if [ -z "$target_service" ] || [ -z "$port" ]; then
        echo "Error: Usage check_internal_service_http <target> <port> [sidecar] [max_retries]"
        return 1
    fi

    echo "Checking health for ${target_service}:${port} (Max retries: ${max_retries})..."

    while [ $attempt -le $max_retries ]; do
        # Strategy 1: Use Sidecar (Preferred if provided, as it guarantees 'curl' availability)
        if [ -n "$sidecar" ]; then
            if ! docker ps --format '{{.Names}}' | grep -q "^${sidecar}$"; then
                echo "Healthcheck Warning: Sidecar '$sidecar' is not running."

                return 1
            fi
            
            # Check connection from sidecar to target
            if docker exec "$sidecar" curl -s -f -o /dev/null --connect-timeout 2 "http://${target_service}:${port}"; then
                echo "Host: Connection via Sidecar -> ${target_service}:${port} [OK]"
                return 0
            fi
        else
            # Strategy 2: Exec into Target (Fallback)
            # This works only if the target container has 'curl' or 'wget' installed.
            if docker exec "$target_service" curl -s -f -o /dev/null "http://localhost:${port}" 2>/dev/null; then
                 echo "Host: Exec Curl -> ${target_service}:${port} [OK]"
                 return 0
            fi
            
            if docker exec "$target_service" wget -q --spider "http://localhost:${port}" 2>/dev/null; then
                 echo "Host: Exec Wget -> ${target_service}:${port} [OK]"
                 return 0
            fi
        fi

        # If we are here, the check failed.
        if [ $attempt -lt $max_retries ]; then
            echo "Waiting for service... (Attempt $attempt/$max_retries)"
            sleep 5
        fi
        attempt=$((attempt + 1))
    done

    echo "Healthcheck Failed: Could not verify http://${target_service}:${port} after $max_retries attempts."
    return 1
}
