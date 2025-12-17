# Service Structure Specification

## Overview
This document outlines the standardized folder structure and principles for all services within the AI LaunchKit. Adhering to this structure ensures consistency, simplifies automation, and enforces security best practices.

## Folder Structure
Each service resides in `services/<category>/<service-name>/`.

```text
services/<category>/<service-name>/
├── docker-compose.yml      # Defines the service containers
├── service.json            # Metadata for the service registry
├── .env.example            # Template for environment variables
├── .env                    # (Ignored) Active environment variables
├── README.md               # Service-specific documentation
├── prepare.sh              # (Optional) PRE-startup (host prep)
├── startup.sh              # (Optional) POST-startup (app bootstrapping)
├── secrets.sh              # (Optional) Secret generation logic
├── build.sh                # (Optional) Custom build logic
├── report.sh               # (Optional) Status/Info reporting
├── scripts/                # (Optional) Any service specific helper scripts
├── data/                   # (Ignored) Runtime data persistence
│   └── ...                 # Runtime Database files, Application state
├── config/                 # Configuration files
│   ├── ...                 # Static/Repo-tracked config (flexible)
│   └── local/              # (Ignored) User-specific/Sensitive config
├── build/                  # (Ignored) Build artifacts/repos
└── logs/                   # (Ignored) Application logs
```

## Core Principles

### 1. Data Persistence (`/data`)
*   **Principle**: The `data/` directory is a flexible container for runtime data.
*   **Git Ignore**: The global `.gitignore` excludes `**/data/`.
*   **Volumes vs. Mounts**:
    *   **Bind Mounts (`./data/...`)**: Preferred for data you want to easily access, backup, or inspect (e.g., config files, logs, import/export folders).
    *   **Named Volumes**: Permitted for internal container state that doesn't need to be exposed to the host (e.g., complex database storage formats), provided they are documented.
*   **Goal**: Ensure all persistent data is either in a named volume (managed by Docker) or in the ignored `data/` folder (managed by us). Do not mount files from the root of the service directory unless they are static config.

### 2. Configuration (`/config`)
*   **Principle**: Flexible storage for configuration files.
*   **Root (`config/`)**: Contains static, version-controlled configuration files (e.g., `nginx.conf`, `prometheus.yml`).
*   **Local (`config/local/`)**: **Strictly Ignored**. Use this folder for:
    *   User-specific overrides.
    *   Files containing secrets (if not using env vars).
    *   Generated config files.

### 3. Build Artifacts (`/build`)
*   **Principle**: Temporary files required for building images (e.g., cloned repositories) must be isolated.
*   **Git Ignore**: The global `.gitignore` excludes `**/build/`.
*   **Usage**: If a service requires building from source, the `build.sh` script should clone repositories into `build/`.

### 4. Lifecycle Scripts
To avoid confusion about *when* a script runs, we use distinct names:

*   **`prepare.sh` (Pre-Up)**:
    *   **When**: Runs **BEFORE** `docker compose up`.
    *   **Purpose**: Host preparation.
    *   **Tasks**: Creating directories (`mkdir -p data/db`), setting permissions (`chown`), generating initial config files from templates.
*   **`startup.sh` (Post-Up)**:
    *   **When**: Runs **AFTER** `docker compose up` (and potentially waits for healthchecks).
    *   **Purpose**: Application bootstrapping.
    *   **Tasks**: Running database migrations, creating initial admin users via API, seeding data.
*   **`secrets.sh`**:
    *   **Purpose**: Generates secure random values for `.env`.
    *   **Tasks**: Updates `.env` without overwriting existing values.
*   **`build.sh`**:
    *   **Purpose**: Compiles code or builds Docker images.
    *   **Tasks**: Cloning repos, running `docker build`.
*   **`report.sh`**:
    *   **Purpose**: Reporting.
    *   **Tasks**: Outputs URLs, credentials, and status to the user.

### 5. Environment Variables
*   **`.env`**: The source of truth for secrets and instance-specific configuration.
*   **`.env.example`**: Must exist and list all required variables with dummy values.
*   **Inheritance**: Services should inherit global settings (like `BASE_DOMAIN`) from the root `.env` or any other enabled service `.env`, they are all available at runtime.

## Migration Checklist
When refactoring a service to this standard:
1.  [ ] Check if data persistence should be a bind mount (`./data`) or named volume.
2.  [ ] Ensure sensitive config is in `config/local/` or `.env`.
3.  [ ] Rename or distribute scripts to `prepare.sh` (host prep) or `startup.sh` (app bootstrapping).
4.  [ ] Verify `.gitignore` coverage.
5.  [ ] Create `service.json` if missing.
