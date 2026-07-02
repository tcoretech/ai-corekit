#!/bin/bash
set -e

# Create directories
mkdir -p ./grafana/data
mkdir -p ./grafana/provisioning
mkdir -p ./grafana/dashboards
mkdir -p ./prometheus/data

ensure_owner() {
    local path="$1"
    local owner="$2"
    local group="$3"

    if [ "$(stat -c '%u:%g' "$path")" != "$owner:$group" ]; then
        echo "Cannot set ownership for $path when running as non-root." >&2
        echo "Run this prepare hook as root once, or set $path to $owner:$group." >&2
        exit 1
    fi
}

if [ "$(id -u)" -eq 0 ]; then
    # Set permissions for Grafana (UID 472)
    chown -R 472:472 ./grafana/data
    chown -R 472:472 ./grafana/provisioning
    chown -R 472:472 ./grafana/dashboards

    # Set permissions for Prometheus (UID 65534)
    chown -R 65534:65534 ./prometheus/data
else
    ensure_owner ./grafana/data 472 472
    ensure_owner ./grafana/provisioning 472 472
    ensure_owner ./grafana/dashboards 472 472
    ensure_owner ./prometheus/data 65534 65534
fi
