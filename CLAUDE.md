# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AI CoreKit** is a modular, service-based Docker Compose orchestration system that deploys 50+ self-hosted AI and productivity tools. Unlike monolithic Docker Compose setups, it uses an **iterative context strategy** where each service is self-contained in its own directory with independent `docker-compose.yml` files, and the `corekit` CLI orchestrates them by switching into each service's directory context.

## Essential Commands

### Installation & Setup
```bash
# Install CLI globally
sudo make install

# Initialize system (Docker, secrets)
corekit init

# Configure services (interactive wizard)
corekit config

# Start all enabled services
corekit up

# Update system and services
corekit update
```

### Service Management
```bash
# Enable/disable services
corekit enable <service-name>
corekit disable <service-name>

# Enable a stack of services
corekit enable -s <stack-name>

# Start specific services (auto-enables)
corekit up <service1> <service2>

# Start all services in a stack
corekit up -s <stack-name>

# Stop services (keeps enabled)
corekit down

# Stop and disable services
corekit down --prune

# Remove stopped containers
corekit rm
```

### Monitoring & Debugging
```bash
# View running services
corekit ps

# View logs (interactive menu if no service specified)
corekit logs [service-name]

# View logs with options
corekit logs <service-name> -f --tail 100

# Restart services
corekit restart [service-name]

# Execute command in container
corekit exec <service-name> <command>

# Access service-specific CLI (if available)
corekit run <service-name> <args>
```

### Credentials Management
```bash
# Export credentials to JSON
corekit credentials export

# Download credentials for Vaultwarden import
corekit credentials download
```

### System Management
```bash
# Configure firewall (with safety checks)
corekit system --close-ports
```

**⚠️ Firewall Configuration:**
- NOT run during `corekit init` to prevent SSH lockouts
- Requires multiple confirmations before proceeding
- Auto-detects SSH port from running processes and `/etc/ssh/sshd_config`
- Preserves SSH, HTTP (80), and HTTPS (443) access
- Sets default deny for all other incoming connections
- Use only if you understand the implications and have console access

## Critical Architecture Principles

### 1. Modular Service Units

**DO NOT create monolithic `docker-compose.yml` at project root.** Each service is self-contained:

```
services/<category>/<service-name>/
├── docker-compose.yml      # Container definition
├── service.json            # Metadata (name, category, dependencies)
├── .env.example            # Config template
├── .env                    # Generated config (git-ignored)
├── data/                   # Runtime data (git-ignored)
├── config/                 # Static config (tracked)
├── config/local/           # User overrides (git-ignored)
├── prepare.sh              # Pre-startup hook
├── entrypoint.sh           # Container internal setup
├── startup.sh              # Post-startup hook
├── secrets.sh              # Secret generation
├── build.sh                # Custom build logic
├── healthcheck.sh          # Health verification
└── README.md               # Service documentation
```

### 2. Iterative Context Execution

The `corekit up` command works by:

1. Resolving service dependencies from `service.json`
2. For each service in order:
   - **Switch directory**: `cd services/<category>/<service>/`
   - **Load environment**: Source `.env` (inherits globals)
   - **Run secrets.sh**: Generate missing passwords/keys
   - **Run prepare.sh**: Create directories, set permissions
   - **Run build.sh**: Build custom images if needed
   - **Execute Docker Compose**: `docker compose up -d` (in service directory)
   - **Run startup.sh**: Database migrations, API initialization
   - **Run healthcheck.sh**: Verify service is healthy

This means services use **relative paths** internally (`./data`, `./config`) and work when run directly with `docker compose up` from their own directory.

### 3. Path Rules

**Internal Resources (within service directory):**
- ✅ Use relative paths: `./data/db:/var/lib/postgresql/data`
- ✅ Use relative paths: `./config/nginx.conf:/etc/nginx/nginx.conf`
- ❌ Never use absolute host paths: `~/myservice/data` or `/home/user/data`

**Shared Resources (cross-service):**
- ✅ Use `${PROJECT_ROOT}/shared`: For truly shared files
- ✅ Handled by CLI exporting `PROJECT_ROOT` before execution

**Data Persistence:**
- ✅ All runtime data goes in `./data/` (git-ignored)
- ❌ Never pollute service root: `./db:/var/lib/postgresql/data` is wrong
- ✅ Correct structure: `./data/db:/var/lib/postgresql/data`

### 4. Environment Variable Hierarchy

```
1. config/.env.global          # Global settings (domain, email, timezone)
2. services/<cat>/<svc>/.env   # Service-specific (passwords, ports)
3. Runtime exports              # CLI sets PROJECT_ROOT, PROJECT_NAME
```

**Critical Quoting Rule:**
- All `.env` values MUST use **single quotes** to prevent shell interpolation
- Example: `PASSWORD='$2a$12$hash'` (safe) vs `PASSWORD="$2a$12$hash"` (breaks)
- Why: Dollar signs in bcrypt hashes, special characters in passwords

### 5. Stack System

**Stacks** (`config/stacks/*.yaml`) define logical service groups:

```yaml
name: core
project_name: localai  # Docker Compose project name

services:
  - postgres
  - redis
  - n8n
  - caddy
```

**Usage:**
- Services enabled via `COMPOSE_PROFILES` in `config/.env.global`
- CLI commands: `corekit up -s core`, `corekit enable -s core`
- Auto-detection: Starting a service auto-enables its profile

### 6. Dependency Management

**Two levels of dependencies:**

1. **Enablement Dependencies** (`service.json`):
   ```json
   {
     "name": "flowise",
     "depends_on": ["postgres", "redis"]
   }
   ```
   - Ensures required services are enabled when enabling this one
   - Resolved by `corekit up` before startup

2. **Runtime Dependencies** (Docker Compose):
   ```yaml
   depends_on:
     postgres:
       condition: service_healthy
   ```
   - Controls startup order within a service's containers
   - For cross-service deps, use `startup.sh` with wait loops

## Critical Implementation Notes

### When Adding a New Service

**NEVER:**
- Add to a root `docker-compose.yml` (doesn't exist)
- Use absolute host paths in volume mounts
- Use double quotes for `.env` values with special chars
- Put runtime data outside `./data/`

**ALWAYS:**
1. Create directory: `services/<category>/<service-name>/`
2. Follow structure from `docs/SERVICE_STRUCTURE_SPEC.md`
3. Create `service.json` with metadata and dependencies
4. Use relative paths in `docker-compose.yml`
5. Put all persistent data in `./data/`
6. Put sensitive config in `config/local/` (git-ignored)
7. Add to a stack in `config/stacks/*.yaml`
8. Test by running `docker compose up` from the service directory

**See:** `docs/ADDING_NEW_SERVICE.md` for step-by-step guide

### Lifecycle Script Execution Order

```
corekit up <service>
├─ 1. Find service directory
├─ 2. Load .env (inherits globals)
├─ 3. Run secrets.sh (generate missing secrets)
├─ 4. Re-load .env (pick up new secrets)
├─ 5. Run prepare.sh (mkdir, chown, template rendering)
├─ 6. Run build.sh (if custom image needed)
├─ 7. Docker Compose up -d (start containers)
├─ 8. Run startup.sh (migrations, API calls)
└─ 9. Run healthcheck.sh (verify from host)
```

**Script Purposes:**
- `secrets.sh`: Generate passwords/keys, update `.env`
- `prepare.sh`: Host preparation (directories, permissions, config from templates)
- `build.sh`: Build Docker images from source (e.g., clone repo, `docker build`)
- `startup.sh`: Application bootstrapping (DB migrations, seed data, API initialization)
- `healthcheck.sh`: Host-side health verification (curl, ping). Runs on HOST. Use `docker exec` for internal checks.

### Environment Variable Management

**Utilities available (`lib/utils/secrets.sh`):**

```bash
# Generate a secret if not already set
generate_secret "MY_SERVICE_PASSWORD" 32

# Update or add env var
update_env_var "/path/to/.env" "KEY" "value"

# Load all environments (global + all services)
load_all_envs
# Creates associative array: ALL_ENV_VARS[KEY]=value
```

**Example `secrets.sh`:**
```bash
#!/bin/bash
source "$PROJECT_ROOT/lib/utils/secrets.sh"

# Generate if missing
generate_secret "FLOWISE_PASSWORD" 32
generate_secret "FLOWISE_API_KEY" 64
```

### Logging Functions

**Available utilities (`lib/utils/logging.sh`):**

```bash
log_info "Starting service..."
log_success "Service started successfully"
log_warning "Port conflict detected"
log_error "Failed to connect to database"
```

Logs are framed with borders and include timestamps.

### Stack Management

**Utilities available (`lib/utils/stack.sh`):**

```bash
# Get services in a stack
get_stack_services "core"

# Get project name for a stack
get_stack_project_name "core"

# Find which stack a service belongs to
find_stack_for_service "n8n"

# Enable/disable a service profile
enable_service_profile "flowise"
disable_service_profile "flowise"

# Get all project names across all stacks
get_all_stack_projects
```

## Common Development Tasks

### Testing a Single Service

```bash
# Navigate to service directory
cd services/ai-agents/flowise

# Check environment
cat .env.example

# Run preparation
bash prepare.sh

# Start with Docker Compose directly
docker compose up

# Or use corekit CLI
cd /root/ai-corekit
corekit up flowise
```

### Debugging Service Startup Issues

```bash
# Check if service directory exists
ls -la services/ai-agents/flowise/

# Check service.json metadata
cat services/ai-agents/flowise/service.json

# Check if enabled
grep COMPOSE_PROFILES config/.env.global

# Enable manually
corekit enable flowise

# Check logs
corekit logs flowise --tail 100

# Check hooks execution
bash -x services/ai-agents/flowise/prepare.sh
bash -x services/ai-agents/flowise/startup.sh
```

### Modifying Service Configuration

```bash
# Edit service environment
nano services/<category>/<service>/.env

# Edit Docker Compose definition
nano services/<category>/<service>/docker-compose.yml

# Recreate containers with new config
cd services/<category>/<service>
docker compose up -d --force-recreate

# Or via CLI
corekit up <service> --force-recreate
```

### Adding a Service to a Stack

```bash
# Edit stack file
nano config/stacks/core.yaml

# Add service to list:
services:
  - my-new-service

# Enable and start
corekit enable -s core
corekit up -s core
```

## Service Discovery & Networking

- All services join the default Docker network (named `<project>_default`)
- Services communicate using container names as hostnames
- Example: `n8n` connects to `postgres:5432`, not `localhost:5432`
- DNS resolution handled by Docker's internal DNS
- No need to define networks explicitly unless isolating services

## CLI Implementation Details

**Entry Point:** `corekit.sh`

**Command Structure:**
```bash
corekit <command> [options] [arguments]
```

**Key Commands Mapping:**
- `init` → `lib/system/system_prep.sh`, `lib/system/install_docker.sh`, `lib/services/generate_all_secrets.sh`
- `config` → `lib/config/wizard.sh`
- `up` → `lib/services/up.sh`
- `down` → `lib/services/down.sh`
- `update` → `lib/services/update.sh`
- `logs` → Direct `docker compose logs` with smart service selection
- `ps` → Custom Docker PS with service name mapping from `service.json`

**Important Behaviors:**

1. **Interactive Logs:** `corekit logs` without a service shows menu of running services
2. **Multi-Container Services:** `corekit logs <service>` shows menu if service has multiple containers
3. **Service Name Mapping:** `corekit ps` shows service names from `service.json`, not container names
4. **Auto-Enable:** `corekit up <service>` automatically enables the service profile

## Security & Secrets

**Secret Generation:**
- Automated via `lib/services/generate_all_secrets.sh` during `corekit init`
- Per-service via `secrets.sh` in each service directory
- Uses `openssl rand -hex` for random generation
- Stored in `.env` files (git-ignored)

**Critical Security Rules:**
- `.env` files are NEVER committed to git
- All passwords/keys in single quotes to prevent interpolation
- Secrets utility checks if value exists before overwriting
- `config/local/` is git-ignored for user-specific sensitive configs

## Troubleshooting

### Service Won't Start

```bash
# 1. Check if directory exists
ls -la services/<category>/<service>/

# 2. Check service.json
cat services/<category>/<service>/service.json

# 3. Check if docker-compose.yml is valid
cd services/<category>/<service>
docker compose config

# 4. Check environment
cat .env

# 5. Check logs
docker compose logs --tail 50

# 6. Run hooks manually
bash -x prepare.sh
bash -x startup.sh
```

### Environment Variables Not Loading

```bash
# Check global config
cat config/.env.global

# Check service config
cat services/<category>/<service>/.env

# Verify quoting (single quotes for special chars)
grep PASSWORD services/<category>/<service>/.env

# Test loading
source config/.env.global
source services/<category>/<service>/.env
echo $MY_VARIABLE
```

### Path Issues

```bash
# Check if paths are relative in docker-compose.yml
grep "volumes:" services/<category>/<service>/docker-compose.yml

# Should see:
#   - ./data/db:/var/lib/postgresql/data
#
# NOT:
#   - /home/user/data:/var/lib/postgresql/data
```

### Dependency Issues

```bash
# Check service dependencies
cat services/<category>/<service>/service.json | grep depends_on

# Check if dependencies are enabled
grep COMPOSE_PROFILES config/.env.global

# Enable dependencies
corekit enable <dependency>

# Restart with dependencies
corekit up <service>
```

## Project Structure

```
ai-corekit/
├── corekit.sh              # Main CLI entrypoint
├── Makefile                  # Install CLI globally
├── config/
│   ├── .env.global           # Global configuration
│   └── stacks/               # Service group definitions
│       ├── core.yaml
│       └── custom/           # User-defined stacks
├── docs/
│   ├── ARCHITECTURE.md       # Detailed architecture
│   ├── SERVICE_STRUCTURE_SPEC.md
│   └── ADDING_NEW_SERVICE.md
├── lib/
│   ├── config/
│   │   └── wizard.sh         # Interactive service selection
│   ├── services/
│   │   ├── up.sh             # Service startup orchestration
│   │   ├── down.sh           # Service shutdown
│   │   ├── update.sh         # System update
│   │   └── generate_all_secrets.sh
│   ├── system/
│   │   ├── system_prep.sh    # OS updates, firewall
│   │   └── install_docker.sh # Docker installation
│   └── utils/
│       ├── logging.sh        # Log functions
│       ├── secrets.sh        # Secret generation
│       └── stack.sh          # Stack management
└── services/
    ├── <category>/
    │   └── <service-name>/
    │       ├── docker-compose.yml
    │       ├── service.json
    │       ├── .env.example
    │       ├── data/         # Runtime data
    │       ├── config/       # Static config
    │       └── *.sh          # Lifecycle hooks
    └── custom-services/      # User services
```

## Key Files

- `corekit.sh:56-89` - Command dispatch and help
- `lib/services/up.sh:47-160` - Service startup logic with dependency resolution
- `lib/services/up.sh:179-229` - Hook execution (prepare, build, secrets)
- `lib/services/up.sh:232-248` - Docker Compose execution in service context
- `lib/utils/stack.sh:57-88` - Service profile enabling
- `docs/ARCHITECTURE.md` - Complete architecture documentation
- `docs/SERVICE_STRUCTURE_SPEC.md` - Service structure rules

### Healthcheck Utilities

**Available in `lib/utils/healthcheck.sh`:**

```bash
# Check internal service via sidecar or container exec
check_internal_service_http <service-name> <port> [sidecar-name]
```
