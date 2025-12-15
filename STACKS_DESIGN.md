# Stack Design & Architecture

## Overview
This document defines how "Stacks" work in the refactored AI LaunchKit. A Stack is a named collection of services that can be managed together.

## Core Concepts

1.  **Stack Definition (`config/stacks/*.yaml`)**
    - Defines the *potential* members of a stack.
    - Defines the Docker Compose `project_name`.
    - Defines the set of services included.

2.  **Service Registry (`config/services.json`)**
    - Defines the *available* services.
    - Controls the *enabled/disabled* state.
    - Contains metadata (path, description).

3.  **Runtime Logic**
    - `Active Stack Services` = `Stack.services` ∩ `Services.enabled=true`

## Stack File Schema
File: `config/stacks/<stack_name>.yaml`

```yaml
name: core
description: "Main application stack"
project_name: localai  # Determines the Docker network and volume namespace
services:
  - n8n
  - caddy
  - postgres
  # ...
```

## Operations

### `launchkit up <stack>`
1.  Load `<stack>.yaml`.
2.  Identify enabled services from `services.json` that are also in this stack.
3.  Construct `docker compose` command:
    ```bash
    docker compose -p <project_name> \
      -f services/path/to/service1.yml \
      -f services/path/to/service2.yml \
      up -d
    ```
    *Note: We must be careful with `--remove-orphans` if multiple stacks share the same project name. It should probably be omitted for subset stacks.*

### `launchkit down <stack>`
1.  Load `<stack>.yaml`.
2.  Identify enabled services in this stack.
3.  Construct command to stop/remove ONLY these services.
    - `docker compose -p <project_name> -f ... down` might remove the whole network if it's the last service.
    - Alternatively: `docker compose -p ... stop` and `rm`.

## Common Stacks

| Stack | Project Name | Purpose |
| :--- | :--- | :--- |
| `core` | `localai` | The main application platform (n8n, DBs, etc.) |
| `monitoring` | `localai` | Grafana, Prometheus (runs in same network as core) |
| `host-dns` | `host-dns` | DNS services (runs separately, maybe host network) |

## Network Strategy
- Stacks sharing the same `project_name` automatically share the `default` network.
- No need to explicitly define a "network" service unless specific configuration (subnets, drivers) is required.
- If `host-dns` needs to talk to `core`, it should use the external network name `localai_default`.

## Implementation Plan
1.  Update `launchkit.py` to support `up <stack>` and `down <stack>`.
2.  Update `core.yaml` to include `project_name: localai`.
3.  Ensure `services.json` is the single source of truth for "enabled".
