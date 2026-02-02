#!/bin/bash
set -e

# Create config directories
mkdir -p ./config/local/jitsi-jvb
mkdir -p ./config/local/jitsi-web
mkdir -p ./config/local/jitsi-prosody-config
mkdir -p ./config/local/jitsi-prosody-plugins
mkdir -p ./config/local/jitsi-jicofo
mkdir -p ./data/transcripts

# Set permissions if needed (Jitsi runs as root usually, but good practice)
# chmod 755 ./config/local/jitsi-jvb
