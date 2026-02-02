#!/bin/bash
set -x

REPO_URL="${GIT_REPO_URL}"
BRANCH="${GIT_BRANCH:-main}"
REPO_DIR="/app/repo"
IMAGE_NAME="${IMAGE_NAME:-custom-website:latest}"
SERVICE_NAME="${SERVICE_NAME:-website}"

# Ensure we have a repo URL
if [ -z "$REPO_URL" ]; then
    echo "Error: GIT_REPO_URL is not set."
    echo "Please set SERVICE_GIT_REPO in your .env file."
    # Sleep to prevent restart loop spam
    sleep 60
    exit 1
fi

# Inject Token if present
if [ -n "$GIT_TOKEN" ]; then
    # Simple replacement: https:// -> https://git:TOKEN@
    # Note: This might log the token if we echo REPO_URL.
    REPO_URL="${REPO_URL/https:\/\//https:\/\/git:$GIT_TOKEN@}"
fi

echo "Starting Git Auto-Deploy for ${GIT_REPO_URL} (${BRANCH})..."

# Function to build and deploy
deploy() {
    echo "Changes detected. Building image..."
    cd "$REPO_DIR"
    
    # Auto-detect project type if Dockerfile is missing
    if [ ! -f "Dockerfile" ]; then
        echo "No Dockerfile found in root."
        if [ -f "package.json" ]; then
            echo "Detected package.json. Applying default Node.js Dockerfile..."
            cp /app/templates/node.Dockerfile ./Dockerfile
        else
            echo "Error: No Dockerfile found and could not auto-detect project type."
            echo "Please add a Dockerfile to your repository."
            return 1
        fi
    fi

    echo "Preparing build environment..."
    ENV_FILE="/app/config/.env"
    BUILD_ARGS=()
    # Create or clear .env file in the repo directory
    REPO_ENV_FILE="$REPO_DIR/.env"
    : > "$REPO_ENV_FILE"

    # Append ARG instructions to Dockerfile for detected env vars
    if [ -f "$ENV_FILE" ]; then
        echo "Injecting environment variables from .env into Docker build..."
        
        # Load configurable patterns
        # BUILD_ARGS: Vars passed as --build-arg (Default: frontend prefixes)
        # RUNTIME_ENV_PASSTHROUGH: Vars added to the runtime .env (Default: * i.e., everything)
        
        B_PATTERNS="${BUILD_ARGS:-VITE_* NEXT_* PUBLIC_* REACT_* NUKS_*}"
        R_PATTERNS="${RUNTIME_ENV_PASSTHROUGH:-*}"
        
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            # 1. Runtime Config Logic
            # Check if key matches RUNTIME_ENV_PASSTHROUGH
            INCLUDE_R=false
            if [ "$R_PATTERNS" == "*" ]; then
                INCLUDE_R=true
            else
                for pattern in $R_PATTERNS; do
                    if [[ "$key" == $pattern ]]; then INCLUDE_R=true; break; fi
                done
            fi

            if [ "$INCLUDE_R" = true ]; then
                echo "$key=$value" >> "$REPO_ENV_FILE"
            fi

            # 2. Build-Time Config Logic
            # Check if key matches BUILD_ARG_PATTERNS
            INCLUDE_B=false
            if [ -n "$B_PATTERNS" ]; then
                for pattern in $B_PATTERNS; do
                    if [[ "$key" == $pattern ]]; then INCLUDE_B=true; break; fi
                done
            fi

            if [ "$INCLUDE_B" = true ]; then
                
                # Check if ARG already exists to avoid duplication (simple grep)
                if ! grep -q "ARG $key" Dockerfile; then
                    # Insert ARG passed before FROM (global ARG) or after?
                    # Placing after FROM is safer for build usage.
                    sed -i "/^FROM/a ARG $key" Dockerfile
                fi
                BUILD_ARGS+=("--build-arg" "$key=$value")
                echo " -> Added Build ARG: $key"
            fi
        done < "$ENV_FILE"
    fi
    
    # Ensure Dockerfile copies the generated .env file
    # We check if COPY .env is already there
    if ! grep -q "COPY .env" Dockerfile; then
        # Insert COPY .env ./ before COPY . . or at the end of COPY logic
        # Ideally, before the build step.
        # Find the line "COPY . ." and insert before it
        if grep -q "COPY . ." Dockerfile; then
             sed -i '/COPY . ./i COPY .env ./' Dockerfile
        else
             # Fallback: append after FROM
             sed -i '/^FROM/a COPY .env ./' Dockerfile
        fi
    fi

    # Build the image
    if docker build -t "$IMAGE_NAME" "${BUILD_ARGS[@]}" .; then
        echo "Build successful."
        
        echo "Recreating service '$SERVICE_NAME'..."
        cd /app/config
        
        # Use docker compose to recreate the service with the new image
        # We use --no-deps to avoid restarting the updater itself if possible, 
        # though updater depends on nothing.
        if docker compose up -d --no-deps "$SERVICE_NAME"; then
            echo "Service updated successfully."
        else
            echo "Failed to update service."
        fi
    else
        echo "Build failed!"
    fi
}

# Initial Clone or Update
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Cloning repository..."
    git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR"
    # Perform initial deploy after clone
    deploy
else
    echo "Repository exists. Checking for updates..."
    cd "$REPO_DIR"
    git fetch origin "$BRANCH"
    git reset --hard "origin/$BRANCH"
    # We might want to force a deploy on startup just in case the image is missing
    deploy
fi

# Loop
while true; do
    # Check every 60 seconds
    sleep 60
    
    cd "$REPO_DIR"
    echo "Checking for updates..."
    git fetch origin "$BRANCH"
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$BRANCH")
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Update detected! ($LOCAL -> $REMOTE)"
        git pull origin "$BRANCH"
        deploy
    else
        echo "No updates. ($LOCAL)"
    fi
done
