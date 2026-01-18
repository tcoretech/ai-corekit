#!/bin/bash
set -e

echo "Setting up Vexa repository..."

# Clone Vexa repository if it doesn't exist
mkdir -p build
if [ ! -d "build/repo" ]; then
    echo "Cloning Vexa repository..."
    git clone https://github.com/Vexa-ai/vexa.git build/repo || {
        echo "Failed to clone Vexa repository"
        exit 1
    }
    cd build/repo
    echo "Initializing git submodules..."
    git submodule update --init --recursive || {
        echo "Failed to initialize submodules"
        exit 1
    }
else
    echo "Vexa repository already exists"
    cd build/repo
fi

# Patch WHISPER_LIVE_URL to use whisperlive-cpu
echo "Patching WHISPER_LIVE_URL for CPU deployment..."
if grep -q "ws://traefik:8081/ws" docker-compose.yml; then
    sed -i 's|ws://traefik:8081/ws|ws://whisperlive-cpu:9090|g' docker-compose.yml
    echo "WHISPER_LIVE_URL patched"
else
    echo "WHISPER_LIVE_URL already configured"
fi

# Fix Playwright version mismatch - use latest stable
echo "Fixing Playwright Docker image version to v1.56.0..."
sed -i 's|mcr.microsoft.com/playwright:v[0-9.]*-jammy|mcr.microsoft.com/playwright:v1.56.0-jammy|g' \
    services/vexa-bot/core/Dockerfile
echo "Playwright version set to v1.56.0"

# Fix transcription-collector SQL type mismatch bug
echo "Patching transcription-collector SQL type mismatch..."
if grep -q "Meeting.platform_specific_id == native_meeting_id" services/transcription-collector/streaming/processors.py 2>/dev/null; then
    sed -i 's|Meeting.platform_specific_id == native_meeting_id|Meeting.id == native_meeting_id|g' \
        services/transcription-collector/streaming/processors.py
    echo "Transcription-collector SQL fix applied"
else
    echo "Transcription-collector SQL fix already applied or not needed"
fi
