#!/bin/bash
set -e

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Ensure build directory exists
mkdir -p build

# Clone Supabase repository if it doesn't exist
if [ ! -d "build/repo" ]; then
    echo "Cloning Supabase repository..."
    git clone https://github.com/supabase/supabase.git build/repo
else
    echo "Supabase repository already exists."
fi

# Ensure data directories exist
mkdir -p data/db
mkdir -p data/storage
mkdir -p config/kong
mkdir -p config/db
mkdir -p config/logs
mkdir -p config/pooler
mkdir -p config/functions

# Copy initial config if missing (optional, depends on if we want to seed from upstream)
# For now, we assume the config/ folder is populated by the user or previous runs
