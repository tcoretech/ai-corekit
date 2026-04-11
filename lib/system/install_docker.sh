#!/bin/bash

set -e

# Source the utilities file
source "$(dirname "$0")/../utils/logging.sh"

# Check for sudo if not root
if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
    log_error "This script requires root privileges or sudo. Please run with sudo or as root."
    exit 1
fi

SUDO_CMD=""
if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo"
fi

# 1. Preparing the environment
export DEBIAN_FRONTEND=noninteractive
APT_OPTIONS="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y"
log_info "Preparing Docker installation..."

# Function to run apt commands with retries for lock acquisition
run_apt_with_retry() {
    local cmd_str="$*" # Capture command as a string for logging
    local retries=10
    local wait_time=10 # seconds

    for ((i=1; i<=retries; i++)); do
        # Check for dpkg locks using fuser. Redirect stderr to /dev/null
        if fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            sleep $wait_time
            continue
        fi
        # Check for apt locks using fuser
        if fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
             sleep $wait_time
             continue
        fi

        # No lock detected, attempt the command
        if $SUDO_CMD apt-get "$@"; then
            return 0 # Success
        else
            local exit_code=$?
            if [ $i -lt $retries ]; then
                 sleep $wait_time
            else
                 return $exit_code # Failed after retries
            fi
        fi
    done

    log_error "Failed to acquire lock or run command after $retries attempts: apt-get $cmd_str"
    return 1 # Failed after retries
}


# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log_info "Docker is already installed."
    docker --version
    # Check for Docker Compose plugin
    if docker compose version &> /dev/null; then
        docker compose version
    else
        log_error "Docker Compose plugin not found. Consider reinstalling or checking the installation."
        exit 1
    fi

    # Get the original user who invoked sudo
    ORIGINAL_USER=${SUDO_USER:-$(whoami)}
    # Skip user operations if we're root and SUDO_USER is not set
    if [ "$ORIGINAL_USER" != "root" ] && id "$ORIGINAL_USER" &>/dev/null; then
        # Check docker group membership
        if groups "$ORIGINAL_USER" | grep &> /dev/null '\bdocker\b'; then
            log_info "User '$ORIGINAL_USER' is already in the docker group."
        else
            log_info "Adding user '$ORIGINAL_USER' to the docker group..."
            $SUDO_CMD usermod -aG docker "$ORIGINAL_USER"
        fi
    else
        log_warning "Could not identify a non-root user. Docker will only be available for the root user."
    fi

    exit 0
fi

# 2. Updating and installing dependencies
log_info "Installing necessary dependencies..."
run_apt_with_retry update -qq
run_apt_with_retry install -qq $APT_OPTIONS \
  ca-certificates \
  curl \
  gnupg \
  lsb-release || { log_error "Failed to install dependencies."; exit 1; }

# 3. Adding Docker's GPG key
log_info "Adding Docker's GPG key..."
$SUDO_CMD install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Adding the Docker repository
log_info "Adding the official Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Installing Docker and Docker Compose
log_info "Installing Docker Engine and Compose Plugin..."
run_apt_with_retry update -qq
run_apt_with_retry install -qq $APT_OPTIONS \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin || { log_error "Failed to install Docker packages."; exit 1; }

# 6. Adding the user to the Docker group
# Use SUDO_USER to get the original user who invoked sudo
ORIGINAL_USER=${SUDO_USER:-$(whoami)}
log_info "Adding user '$ORIGINAL_USER' to the docker group..."
if id "$ORIGINAL_USER" &>/dev/null; then
    $SUDO_CMD usermod -aG docker "$ORIGINAL_USER"
fi

# 7. Verifying the installation
log_info "Verifying Docker installation..."
docker --version
docker compose version

exit 0 