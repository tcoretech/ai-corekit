# Guide: Adding a New Service to AI LaunchKit

This document explains how to add a new service to AI LaunchKit following the modular service structure.

## Overview

AI LaunchKit uses a modular architecture where each service is self-contained in its own directory. This makes it easy to add, remove, or update services without affecting the rest of the system.

## Service Structure

Each service resides in `services/<category>/<service-name>/`.

```text
services/<category>/<service-name>/
├── docker-compose.yml      # Defines the service containers
├── service.json            # Metadata for the service registry
├── .env.example            # Template for environment variables
├── README.md               # Service-specific documentation
├── secrets.sh              # (Optional) Secret generation logic
├── build.sh                # (Optional) Custom build logic
├── prepare.sh              # (Optional) PRE-startup (host prep)
├── startup.sh              # (Optional) POST-startup (app bootstrapping)
├── cleanup.sh              # (Optional) On service down tidy up hook
├── report.sh               # (Optional) Status/Info reporting
└── config/                 # Configuration files
```

## Step-by-Step Guide

### 1. Create Service Directory

Choose an appropriate category (e.g., `ai-agents`, `databases`, `utilities`) and create a directory for your service.

```bash
mkdir -p services/my-category/my-service
cd services/my-category/my-service
```

### 2. Create `service.json`

This file registers your service with the LaunchKit system.

```json
{
  "name": "my-service",
  "description": "A short description of what this service does",
  "category": "My Category",
  "version": "1.0.0",
  "enabled": false,
  "dependencies": ["postgres"]
}
```

### 3. Create `docker-compose.yml`

Define your service container(s). Use the `${PROJECT_NAME:-localai}` variable for network names if needed, but typically you just join the default network.

```yaml
services:
  my-service:
    image: my-org/my-service:latest
    container_name: my-service
    restart: unless-stopped
    environment:
      - PORT=8080
      - DATABASE_URL=${DATABASE_URL}
    volumes:
      - ${PROJECT_NAME}_my_service_data:/data
    networks:
      - default

volumes:
  my_service_data:
```

**Note:** You do not need to define the network explicitly if you are joining the default network. The system handles network bridging.

### 4. Create `.env.example`

List all environment variables your service needs.

```dotenv
# My Service Configuration
MY_SERVICE_PORT=8080
MY_SERVICE_ADMIN_USER=admin
MY_SERVICE_ADMIN_PASSWORD=
```

### 5. Create `secrets.sh` (Optional)

If your service needs secure random passwords or keys, create a `secrets.sh` script.

```bash
#!/bin/bash
# Generate secrets for My Service

# Source secrets utility
source "$PROJECT_ROOT/lib/utils/secrets.sh"

# Generate a secure password if not set
generate_secret "MY_SERVICE_ADMIN_PASSWORD" 32
```

### 6. Create Lifecycle Scripts (Optional)

*   **`prepare.sh`**: Runs before `docker compose up`. Use this to create directories or set permissions.
*   **`startup.sh`**: Runs after `docker compose up`. Use this to run migrations or API calls to configure the running service.
*   **`build.sh`**: Runs if the service needs to be built from source.
*   **`report.sh`**: Outputs connection info after the service starts.

Example `report.sh`:
```bash
#!/bin/bash
echo "My Service is running at: http://localhost:${MY_SERVICE_PORT}"
```

### 7. Documentation

Create a `README.md` in your service directory explaining how to use it, configuration options, and any other relevant details.

## Testing Your Service

You can test your service using the `launchkit` CLI.

1.  **Enable the service:**
    ```bash
    launchkit enable my-service
    ```

2.  **Generate secrets (if applicable):**
    ```bash
    launchkit init
    ```

3.  **Start the service:**
    ```bash
    launchkit up my-service
    ```

4.  **Check logs:**
    ```bash
    launchkit logs my-service
    ```
    (Or use `docker compose logs -f my-service`)

## Best Practices

*   **Isolation:** Keep all service-specific files within the service directory.
*   **Configuration:** Use `config/` for static config files and `config/local/` for generated/sensitive config.
*   **Persistence:** Use named volumes for database data and bind mounts (`./data`) for user-accessible files.
*   **Networking:** Use the default network unless you have a specific reason not to.
*   **Environment Variables:** Prefix your variables with the service name (e.g., `MYSERVICE_`) to avoid collisions.
