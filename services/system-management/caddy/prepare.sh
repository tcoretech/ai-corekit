#!/bin/bash
set -e

# Ensure website directory exists
mkdir -p ./data/website

# Check if index.html exists, if not copy from templates
if [ ! -f "./data/website/index.html" ]; then
    if [ -f "./templates/landing-page.html" ]; then
        echo "Initializing website/index.html from template..."
        cp "./templates/landing-page.html" "./data/website/index.html"
    else
        echo "Warning: Template not found at ./templates/landing-page.html"
    fi
fi
