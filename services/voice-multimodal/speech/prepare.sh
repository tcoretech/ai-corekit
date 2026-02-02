#!/bin/bash
set -e

# Create directories
mkdir -p ./data/voices
mkdir -p ./config/local/openedai-config

# Copy default config if it doesn't exist in local
if [ ! -f "./config/local/openedai-config/voice_to_speaker.yaml" ] && [ -f "./config/openedai-config/voice_to_speaker.yaml" ]; then
    cp "./config/openedai-config/voice_to_speaker.yaml" "./config/local/openedai-config/voice_to_speaker.yaml"
fi
