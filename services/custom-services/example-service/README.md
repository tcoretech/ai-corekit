# Example Custom Service

This is a **template** for adding your own custom services to AI CoreKit. It includes an **auto-updater** sidecar that monitors a Git repository, rebuilds the Docker image on changes, and redeploys the service automatically.

## How to Use This Template

1.  **Duplicate this directory**:
    ```bash
    cp -r services/custom-services/example-service services/custom-services/my-cool-app
    ```

2.  **Update Metadata**:
    Edit `services/custom-services/my-cool-app/service.json`:
    ```json
    {
      "name": "my-cool-app",
      "description": "My Cool App",
      ...
    }
    ```

3.  **Configure Environment**:
    Copy `.env.example` to `.env` and configure your repository:
    ```bash
    cd services/custom-services/my-cool-app
    cp .env.example .env
    nano .env
    ```
    
    *   Set `SERVICE_GIT_REPO` to your Git repository URL.
    *   Set `SERVICE_HOST_PORT` to a unique port.

4.  **Enable and Start**:
    ```bash
    corekit up my-cool-app
    ```

## Features

### 1. Auto-Deployment (GitOps)
The service hosts a sidecar container (`*-updater`) which:
*   Clones your Git repository.
*   Watches for new commits on the specified branch.
*   Automatically rebuilds and restarts the service when changes are found.

### 2. Environment Variable Control
For security and flexibility, you can precisely control which variables from your `.env` are injected into the application.

*   **Runtime Variables** (`RUNTIME_ENV_PASSTHROUGH`)
    *   Controls which variables are available to the running container (and written to the internal `.env` file).
    *   **Default:** `*` (All variables from `.env`).
    *   **Secure Usage:** Set `RUNTIME_ENV_PASSTHROUGH='MYAPP_* DATABASE_*'` to valid excluding system vars like `SERVICE_GIT_TOKEN`.

*   **Build Variables** (`BUILD_ARGS`)
    *   Controls which variables are passed as `--build-arg` during `docker build`.
    *   **Default:** `VITE_* NEXT_* PUBLIC_* REACT_* NUKS_*`.
    *   **Usage:** Set `BUILD_ARGS='MY_BUILD_*'` to inject specific build-time secrets.

The updater automatically attempts to patch your `Dockerfile` to add `ARG` instructions for any matching build variables if they are missing.

### 3. Auto-Build
If your repo has a `Dockerfile`, it is used. If not, the system attempts to auto-detect the project type (e.g., Node.js) and use a default template.

## Directory Structure
*   `updater/`: Contains the logic for the sidecar updater.
*   `data/`: Persisted data (git-ignored).
*   `config/`: Configuration files.

## Troubleshooting
*   **Logs**: `corekit logs my-cool-app`
*   **Updater Logs**: `corekit logs my-cool-app-updater`
