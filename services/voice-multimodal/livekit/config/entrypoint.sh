#!/bin/sh
set -e
cat > /etc/livekit.yaml << YAML
port: 7880
rtc:
  tcp_port: 7882
  port_range_start: 50000
  port_range_end: 50100
  use_external_ip: true
keys:
  ${LIVEKIT_API_KEY}: ${LIVEKIT_API_SECRET}
redis:
  address: redis:6379
logging:
  level: info
  json: false
YAML
exec /livekit-server --config /etc/livekit.yaml --bind 0.0.0.0
