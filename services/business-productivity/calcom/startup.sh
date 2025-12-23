#!/bin/bash
set -e

# Source utilities
source "$PROJECT_ROOT/lib/utils/logging.sh"

log_info "Running Cal.com startup tasks..."

# 1. Ensure Database Exists
# We assume the postgres container is named 'postgres' as per the core stack.
if docker ps | grep -q "postgres"; then
    log_info "Checking for 'calcom' database..."
    if ! docker exec postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw calcom; then
        log_info "Database 'calcom' not found. Creating it..."
        docker exec postgres createdb -U postgres calcom
        log_success "Database 'calcom' created."
    else
        log_info "Database 'calcom' already exists."
    fi
else
    log_warn "Postgres container not found. Skipping database creation check."
fi

# 2. Run Prisma Migrations
# The calcom container must be running for this.
log_info "Waiting for calcom container to be ready for migrations..."
sleep 5 # Give it a moment to start

if docker ps | grep -q "calcom"; then
    log_info "Running Prisma migrations..."
    # We use 'npx prisma migrate deploy' to apply pending migrations
    if docker exec calcom npx prisma migrate deploy; then
        log_success "Prisma migrations applied successfully."
    else
        log_error "Failed to apply Prisma migrations."
        # We don't exit 1 here to avoid breaking the whole launch process, 
        # but we log the error.
    fi
else
    log_warn "Cal.com container not running. Skipping migrations."
fi

log_success "Cal.com startup completed."
