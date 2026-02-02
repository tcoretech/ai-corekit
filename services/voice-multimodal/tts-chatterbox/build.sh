#!/bin/bash
set -e

# Build script for tts-chatterbox

# Resolve paths
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
SERVICE_ROOT="$SCRIPT_DIR"

# Clone repository
REPO_URL="https://github.com/resemble-ai/chatterbox.git"
TARGET_DIR="$SERVICE_ROOT/build"

if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "Cloning $REPO_URL into $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo "Repository already cloned. Pulling latest changes..."
    cd "$TARGET_DIR"
    git pull
fi

# Build Docker images
echo "Building Docker images..."
cd "$SERVICE_ROOT"
docker compose build
