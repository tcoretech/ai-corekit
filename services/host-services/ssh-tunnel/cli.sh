#!/bin/bash

# SSH Tunnel Management Script
# Handles starting, stopping, and restarting the isolated SSH tunnel service

set -e

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SSH_TUNNEL_DIR="$SCRIPT_DIR"

# Source the utilities file
# Assuming we are in services/host-services/ssh-tunnel/
if [ -f "$SSH_TUNNEL_DIR/../../../lib/utils/logging.sh" ]; then
    source "$SSH_TUNNEL_DIR/../../../lib/utils/logging.sh"
else
    echo "Error: utils.sh not found."
    exit 1
fi

# SSH Tunnel Management Functions
stop_ssh_tunnel() {
    if [ -f "$SSH_TUNNEL_DIR/docker-compose.yml" ]; then
        log_info "Stopping SSH tunnel..."
        cd "$SSH_TUNNEL_DIR"
        sudo docker compose -p ssh-tunnel down || true
        log_success "SSH tunnel stopped"
    else
        log_info "No SSH tunnel configuration found in $SSH_TUNNEL_DIR - skipping stop"
    fi
}

start_ssh_tunnel() {
    local pull_image="${1:-false}"  # Optional parameter to pull image
    local ssh_tunnel_env="$SSH_TUNNEL_DIR/.env"
    
    if [ -f "$SSH_TUNNEL_DIR/docker-compose.yml" ]; then
        # Check if SSH tunnel .env file exists and has token
        if [ ! -f "$ssh_tunnel_env" ]; then
            log_warning "SSH tunnel .env file not found at $ssh_tunnel_env - SSH tunnel will not start"
            return
        fi
        
        # Check if CLOUDFLARE_SSH_TUNNEL_TOKEN is set in host-services/ssh-tunnel/.env
        if ! grep -q "^CLOUDFLARE_SSH_TUNNEL_TOKEN=" "$ssh_tunnel_env" || \
           [ -z "$(grep "^CLOUDFLARE_SSH_TUNNEL_TOKEN=" "$ssh_tunnel_env" | cut -d'=' -f2- | sed 's/^\"//' | sed 's/\"$//')" ]; then
            log_warning "CLOUDFLARE_SSH_TUNNEL_TOKEN not set in $ssh_tunnel_env - SSH tunnel will not start"
            return
        fi
        
        cd "$SSH_TUNNEL_DIR"
        
        # Pull image if requested
        if [ "$pull_image" = "true" ]; then
            log_info "Pulling latest SSH tunnel image..."
            sudo docker compose -p ssh-tunnel pull || {
                log_warning "Failed to pull SSH tunnel image - continuing with existing image"
            }
        fi
        
        log_info "Starting SSH tunnel..."
        sudo docker compose -p ssh-tunnel up -d || {
            log_error "Failed to start SSH tunnel"
            return 1
        }
        log_success "SSH tunnel started"
    else
        log_info "No SSH tunnel configuration found in $SSH_TUNNEL_DIR - skipping start"
    fi
}

restart_ssh_tunnel() {
    if [ -f "$SSH_TUNNEL_DIR/docker-compose.yml" ]; then
        log_info "Restarting SSH tunnel with latest image..."
        
        # Brief pause before stop
        sleep 2

        # Stop the tunnel
        stop_ssh_tunnel
        
        # Pull latest image
        log_info "Pulling latest cloudflared image..."
        cd "$SSH_TUNNEL_DIR"
        sudo docker compose -p ssh-tunnel pull || {
            log_warning "Failed to pull SSH tunnel image - continuing with existing image"
        }
        
        # Brief pause before restart
        sleep 2
        
        # Start with updated image
        start_ssh_tunnel
    else
        log_info "No SSH tunnel configuration found - skipping restart"
    fi
}

status_ssh_tunnel() {
    if [ -f "$SSH_TUNNEL_DIR/docker-compose.yml" ]; then
        log_info "SSH tunnel status:"
        cd "$SSH_TUNNEL_DIR"
        sudo docker compose -p ssh-tunnel ps || true
    else
        log_info "No SSH tunnel configuration found"
    fi
}

# Command line interface
case "${1:-}" in
    "start")
        start_ssh_tunnel "${2:-false}"
        ;;
    "stop")
        stop_ssh_tunnel
        ;;
    "restart")
        restart_ssh_tunnel
        ;;
    "status")
        status_ssh_tunnel
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status} [pull_image]"
        echo ""
        echo "Commands:"
        echo "  start    - Start SSH tunnel (optionally pull image first)"
        echo "  stop     - Stop SSH tunnel"
        echo "  restart  - Restart SSH tunnel with image pull"
        echo "  status   - Show SSH tunnel status"
        echo ""
        echo "Parameters:"
        echo "  pull_image   - true/false to pull image before start (default: false)"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 start true"
        echo "  $0 restart"
        echo "  $0 status"
        exit 1
        ;;
esac
