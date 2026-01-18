#!/bin/bash
# Report for jitsi

echo
echo "================================= Jitsi Meet =========================="
echo
echo "Host: ${JITSI_HOSTNAME:-<hostname_not_set>}"
echo
echo "Access:"
echo "  Video Conferencing: https://${JITSI_HOSTNAME:-<hostname_not_set>}"
echo "  Meeting Rooms: https://${JITSI_HOSTNAME:-<hostname_not_set>}/YourRoomName"
echo
echo "⚠️  CRITICAL NETWORK REQUIREMENTS:"
echo "  - UDP Port 10000 MUST be open for WebRTC media"
echo "  - Without UDP 10000: Audio/Video will NOT work!"
echo "  - Current VPS may have UDP issues - test required"
echo
echo "Network Configuration:"
echo "  JVB Host Address: ${JVB_DOCKER_HOST_ADDRESS:-<not_set>}"
echo "  WebRTC Media Port: 10000/udp"
echo "  XMPP Domain: ${JITSI_XMPP_DOMAIN:-meet.jitsi}"
echo
echo "Security Features (NO Basic Auth):"
echo "  - Lobby mode for meeting security"
echo "  - Guest access (no accounts required)"
echo "  - Optional meeting passwords"
echo "  - Room-level security instead of site-level auth"
echo
echo "Testing:"
echo "  1. Create test meeting: https://${JITSI_HOSTNAME:-<hostname_not_set>}/test123"
echo "  2. Join from different devices/networks"
echo "  3. Verify audio/video works"
echo
echo "Cal.com Integration:"
echo "  1. In Cal.com: Settings → Apps → Jitsi Video"
echo "  2. Server URL: https://${JITSI_HOSTNAME:-<hostname_not_set>}"
echo "  3. Meeting links auto-generated for bookings"
echo
echo "Documentation: https://jitsi.github.io/handbook/"
