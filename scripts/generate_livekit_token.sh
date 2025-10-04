#!/bin/bash

# LiveKit Token Generator
# Usage: bash scripts/generate_livekit_token.sh [room-name] [user-id]

set -e

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

source .env

# Default values
ROOM_NAME="${1:-voice-test}"
USER_ID="${2:-user-$(date +%s)}"

# Check if credentials exist
if [ -z "$LIVEKIT_API_KEY" ] || [ -z "$LIVEKIT_API_SECRET" ]; then
    echo "Error: LIVEKIT_API_KEY or LIVEKIT_API_SECRET not found in .env"
    exit 1
fi

echo "Generating LiveKit access token..."
echo "Room: $ROOM_NAME"
echo "User: $USER_ID"
echo ""

# Generate token
TOKEN=$(docker run --rm \
  -e LIVEKIT_API_KEY=$LIVEKIT_API_KEY \
  -e LIVEKIT_API_SECRET=$LIVEKIT_API_SECRET \
  livekit/livekit-cli create-token \
  --identity "$USER_ID" \
  --room "$ROOM_NAME" \
  --join)

echo "Token generated successfully!"
echo ""
echo "$TOKEN"
echo ""
echo "Use this token in LiveKit Playground:"
echo "https://agents-playground.livekit.io"
