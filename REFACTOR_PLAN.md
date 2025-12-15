# AI LaunchKit Refactor Plan

This document outlines the step-by-step plan to refactor the AI LaunchKit codebase from a monolithic Docker Compose setup to a modular, service-based architecture.

## 🎯 Objectives

1.  **Granular Control:** Split the "mega" `docker-compose.yml` into per-service `docker-compose.yml` files.
2.  **Modular Configuration:** Move service-specific `.env` variables into service folders, keeping only global variables in `config/global.env`.
3.  **Targeted Operations:** Enable/disable/update specific services without affecting the whole stack.
4.  **Explicit Stacks:** Formalize `core`, `host-dns`, and `host-ssh` stacks.
5.  **Configurable Project Name:** Allow variable project names (defaulting to `localai` for backward compatibility).

## 📂 Target Structure

```text
ai-launchkit/
├── config/
│   ├── global.env              # Global variables (Domain, Secrets, Hostnames)
│   └── services-enabled.json   # Source of truth for enabled services
├── services/
│   ├── workflow-automation/
│   │   ├── n8n/
│   │   │   ├── docker-compose.yml
│   │   │   ├── .env
│   │   │   ├── .env.example
│   │   │   └── service.json    # Metadata (dependencies, category)
│   │   └── ...
│   ├── system-management/
│   │   ├── caddy/
│   │   └── ...
│   └── ...
├── stacks/
│   ├── core.yaml               # Defines services included in "core"
│   ├── host-dns.yaml
│   └── host-ssh.yaml
├── scripts/
│   ├── launchkit.py            # New CLI orchestrator
│   └── ...
└── ...
```

---

## 📝 Task List

### Phase 1: Preparation & Safety

- [x] **Snapshot Current State**
    - Run `docker ps --format "table {{.Names}}\t{{.Image}}"` and save to `current_running_services.txt`.
    - Run `docker volume ls` and save to `current_volumes.txt`.
    - Backup the current `.env` file to `.env.backup`.

- [x] **Create Directory Structure**
    - Create `config/`, `services/`, and `stacks/` directories.
    - Create subdirectories in `services/` matching the categories in `README.md` (e.g., `workflow-automation`, `system-management`, `ai-agents`, etc.).

### Phase 2: Configuration Migration

- [x] **Create Global Environment File**
    - Copy `.env` to `config/global.env`.
    - **Action:** Audit `config/global.env` and remove service-specific variables that will be moved to service folders (e.g., `FLOWISE_USERNAME` can move, but `DOMAIN` must stay). *Note: For the first pass, it is safe to keep a "fat" global env and prune later.*

- [x] **Create Services Registry (JSON)**
    - Create `config/services-enabled.json`.
    - **Scripting:** Write a temporary script to parse the current `COMPOSE_PROFILES` from `.env` and populate this JSON file.
    - Format:
      ```json
      {
        "n8n": { "enabled": true, "category": "workflow-automation" },
        ...
      }
      ```

### Phase 3: Service Decomposition (The Big Split)

*Repeat the following sub-tasks for EVERY service in `docker-compose.yml`.*

- [x] **Extract Services**
    - Systematically go through the rest of the `docker-compose.yml` and move services to their respective folders.
    - **Note:** For services like `supabase` and `dify` that currently live in their own subfolders, just create a `service.json` in their existing folder or move them into the new structure for consistency.

### Phase 4: The LaunchKit CLI (`scripts/launchkit.py`)

- [x] **Develop CLI Skeleton**
    - Create `scripts/launchkit.py` using Python `argparse` or `click`.
    - Implement `load_config()` to read `config/global.env` and `config/services-enabled.json`.

- [x] **Implement `compose` Command Generator**
    - The core logic: Given a stack (e.g., `core`) and enabled services, generate the `docker compose` command.
    - Logic: `docker compose -p ${PROJECT_NAME} -f services/system/caddy/docker-compose.yml -f services/workflow/n8n/docker-compose.yml ... up -d`
    - **Important:** Support merging global env vars into the process environment so compose files can substitute `${DOMAIN}` etc.

- [x] **Implement CLI Commands**
    - `launchkit status`: Show enabled services and their running state.
    - `launchkit enable <service>`: Update `services-enabled.json`.
    - `launchkit disable <service>`: Update `services-enabled.json`.
    - `launchkit up [stack]`: Run `docker compose up -d` for the generated file list.
    - `launchkit pull [stack]`: Run `docker compose pull` for the generated file list.
    - `launchkit update [stack]`: `pull` then `up -d`.

### Phase 5: Refinement & Grouping

- [x] **Simplify Configuration**
    - Refactor `services-enabled.json` to be a simple map of `service: boolean`.
    - Create `config/service-catalog.json` to map service IDs to paths and categories.
    - Update `launchkit.py` to use the new config structure.

- [x] **Group Related Services**
    - Merge "helper" services (e.g., `kimai_db`, `n8n-worker`) into their main service folder (e.g., `kimai`, `n8n`).
    - Ensure `docker-compose.yml` files in service folders are self-contained for that service stack.
    - Rename folders for clarity (e.g., `mautic_redis` -> `mautic`).

### Phase 6: Switchover & Verification


### Phase 5: Stack Definitions

- [ ] **Define `stacks/core.yaml`**
    - List all services that belong to the main "localai" project.
    - Include `mailserver` here as requested.

- [ ] **Define `stacks/host-dns.yaml` & `stacks/host-ssh.yaml`**
    - Point to the existing (or moved) compose files for these host services.

### Phase 6: Validation & Switchover

- [ ] **Dry Run**
    - Run `python3 scripts/launchkit.py up core --dry-run`.
    - Verify the generated `docker compose` command includes all expected files and environment variables.

- [ ] **Volume Mapping Check**
    - Verify that the new compose files map to the *exact same volume names* as the old monolithic file.
    - Example: If old was `volumes: n8n_storage:`, new must be `volumes: n8n_storage:` and project name must be `localai`.

- [ ] **Stop Old Stack**
    - `docker compose -p localai down --remove-orphans` (WARNING: This stops everything. Schedule downtime).

- [ ] **Start New Stack**
    - `python3 scripts/launchkit.py up core`.

### Phase 7: Cleanup & Documentation

- [ ] **Archive Old Files**
    - Move `docker-compose.yml` to `archive/`.
    - Move old scripts to `archive/`.

- [ ] **Update Documentation**
    - Update `README.md` to reflect the new folder structure and `launchkit` CLI usage.

- [ ] **Update Update Script**
    - Rewrite `scripts/update.sh` to simply call `launchkit update core`.

## ⚠️ Critical Considerations

1.  **Volume Names:** The project name MUST default to `localai` initially to prevent losing access to existing volumes (`localai_n8n_storage`).
2.  **Network:** Ensure all service fragments define the shared network (e.g., `default` or `ai-launchkit_default`) as `external: true` or define it in a "base" compose file included first.
3.  **Dependencies:** `service.json` must track dependencies (e.g., `n8n` depends on `postgres`). The CLI should ensure dependencies are included in the compose command or started first.
