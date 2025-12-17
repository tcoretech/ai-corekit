#!/bin/bash
set -e

# Ensure build directory exists
mkdir -p build

# Clone Dify repository if it doesn't exist
if [ ! -d "build/repo" ]; then
    echo "Cloning Dify repository..."
    git clone https://github.com/langgenius/dify.git build/repo
else
    echo "Dify repository already exists."
fi

# Ensure data directories exist
mkdir -p data/app/storage
mkdir -p data/db/data
mkdir -p data/redis/data
mkdir -p data/weaviate
mkdir -p data/sandbox/dependencies
mkdir -p data/sandbox/conf
