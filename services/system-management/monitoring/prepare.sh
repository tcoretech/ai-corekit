#!/bin/bash
set -e

# Create directories
mkdir -p ./grafana/data
mkdir -p ./grafana/provisioning
mkdir -p ./grafana/dashboards
mkdir -p ./prometheus/data

# Set permissions for Grafana (UID 472)
chown -R 472:472 ./grafana/data
chown -R 472:472 ./grafana/provisioning
chown -R 472:472 ./grafana/dashboards

# Set permissions for Prometheus (UID 65534)
chown -R 65534:65534 ./prometheus/data
