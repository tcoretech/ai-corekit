# AI LaunchKit Architecture & Principles

## 1. Core Philosophy
The AI LaunchKit architecture is built on the principle of **Modular Service Units**. Instead of a monolithic `docker-compose.yml` at the root, the system is composed of independent, self-contained service directories. This approach ensures:
- **Scalability**: Adding new services does not clutter the root configuration.
- **Portability**: Each service can be run independently using native Docker tools.
- **Maintainability**: Service-specific logic (scripts, config, envs) is co-located with the service definition.

## 2. Service Structure Specification
Every service must adhere to the strict structure defined in `docs/SERVICE_STRUCTURE_SPEC.md`.

### The "Service Unit"
Located at: `services/<category>/<service-name>/`

| File/Dir | Purpose | Principle |
|----------|---------|-----------|
| `docker-compose.yml` | Container definition | Must use **relative paths** (`./`) for all internal mounts. |
| `.env` | Active configuration | **Git-ignored**. Generated from `.env.example`. |
| `.env.example` | Config template | Source of truth for variables. Must use single quotes for empty values (`=''`). |
| `data/` | Runtime persistence | **Git-ignored**. Bind mount target for database files and app state. |
| `config/` | Static configuration | Version-controlled config files (e.g., `nginx.conf`). |
| `config/local/` | Local overrides | **Git-ignored**. Place for user-specific or sensitive config files. |
| `prepare.sh` | Pre-startup hook | Runs *before* `docker compose up`. Handles `mkdir`, permissions, template rendering. |
| `startup.sh` | Post-startup hook | Runs *after* containers are up. Handles DB migrations, API initialization. |

### Data Persistence Rule
**All runtime data must reside in `./data`**.
- **Bad**: `volumes: - ${HOME}/.flowise:/root/.flowise` (Depends on host path)
- **Bad**: `volumes: - ./db:/var/lib/postgresql/data` (Pollutes service root)
- **Good**: `volumes: - ./data/db:/var/lib/postgresql/data` (Clean, ignored, self-contained)

## 3. Configuration & Secrets Management

### Hierarchy
1.  **Global Configuration** (`config/.env.global`):
    - Shared variables (Domain, Email, Timezone, PUID/PGID).
    - Loaded first by the LaunchKit CLI.
2.  **Service Configuration** (`services/.../.env`):
    - Service-specific secrets and overrides.
    - Inherits global variables at runtime.

### Secret Generation
- **Automation**: `lib/utils/secrets.sh` handles generation.
- **Quoting Rule**: All generated secrets and `.env` values must use **Single Quotes** (`'value'`).
    - **Why?** To prevent Shell and Docker Compose from attempting to interpolate special characters (like `$` in bcrypt hashes).
    - **Example**: `PASSWORD_HASH='$2a$12$...'` (Safe) vs `PASSWORD_HASH="$2a$12$..."` (Unsafe).

## 4. Execution Model (LaunchKit CLI)

The `launchkit` CLI (`launchkit.sh`) is the orchestration layer, but it respects the independence of services.

### The "Iterative Context" Strategy
Unlike a monolithic `docker-compose -f ... -f ... up`, LaunchKit iterates through selected services and executes them **in their own directory context**.

**Logic Flow (`lib/services/up.sh`):**
1.  Resolve list of services (from Stack or Arguments).
2.  Load Global Environment.
3.  For each service:
    a.  **Switch Context**: `cd services/<category>/<service>/`
    b.  **Run Hooks**: Execute `prepare.sh` if it exists.
    c.  **Execute Docker**: Run `docker compose up -d`.
    d.  **Run Hooks**: Execute `startup.sh` if it exists.

### Developer Experience (DevUX)
Because `docker-compose.yml` files use relative paths (`./data`, `./config`) and the CLI switches directories:
- **Native Compatibility**: A developer can `cd` into a service directory and run `docker compose up` manually. It just works.
- **No Magic Paths**: No reliance on `${PROJECT_ROOT}` variables inside `docker-compose.yml` for internal resources.

## 5. Stacks & Profiles
- **Stacks**: Defined in `config/stacks/*.yaml`. Group services for logical deployment (e.g., `core`, `media`, `dev`).
- **Profiles**: Docker Compose profiles are used to enable/disable optional components within a single service definition.

## 6. Pathing Principles
1.  **Internal Resources**: Use **Relative Paths** (`./`).
    - Example: `./config/Caddyfile:/etc/caddy/Caddyfile`
2.  **Shared Resources**: Use **Absolute Paths** via `${PROJECT_ROOT}` (only when necessary).
    - Example: `${PROJECT_ROOT}/services/shared/certs:/certs`
    - *Note: This is handled by the CLI exporting `PROJECT_ROOT`.*

## 7. Summary for AI Assistants
When modifying this codebase:
1.  **Never** add absolute host paths (like `~/.app`) to `docker-compose.yml`. Use `./data`.
2.  **Always** check `prepare.sh` if a directory needs to exist before startup.
3.  **Always** use single quotes in `.env` files.
4.  **Respect** the `config/local/` ignore rule for sensitive files.
5.  **Assume** the service runs from its own directory, not the project root.

## 8. Dependency Management

The system handles dependencies at two distinct levels:

### 1. Service Enablement (`service.json`)
*   **Purpose**: Defines which services must be *enabled* and *configured* for the current service to function.
*   **Mechanism**: The `launchkit` CLI checks the `dependencies` array in `service.json` when enabling a service.
*   **Example**: If `flowise` depends on `postgres`, enabling `flowise` should prompt or ensure `postgres` is also enabled.

### 2. Runtime Startup (`docker-compose.yml`)
*   **Purpose**: Defines the startup order of containers *within* a service or across services if they share a network/stack.
*   **Mechanism**: Standard Docker Compose `depends_on`.
*   **Limitation**: Since services are isolated, `depends_on` works best for containers defined within the *same* `docker-compose.yml`.
*   **Cross-Service**: For dependencies on other services (e.g., `flowise` waiting for `postgres`), use `startup.sh` scripts with wait loops (e.g., `wait-for-it` or `pg_isready`) rather than relying solely on Docker Compose, as the services might be started independently.
