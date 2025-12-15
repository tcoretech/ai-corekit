#!/bin/bash
# Report for monitoring

echo
echo "================================= Grafana ============================="
echo
echo "Host: ${GRAFANA_HOSTNAME:-<hostname_not_set>}"
echo "User: admin"
echo "Password: ${GRAFANA_ADMIN_PASSWORD:-<not_set_in_env>}"
echo
echo "================================= Prometheus =========================="
echo
echo "Host: ${PROMETHEUS_HOSTNAME:-<hostname_not_set>}"
echo "User: ${PROMETHEUS_USERNAME:-<not_set_in_env>}"
echo "Password: ${PROMETHEUS_PASSWORD:-<not_set_in_env>}"
