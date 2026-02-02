# OpenClaw for AI CoreKit

OpenClaw is a versatile agentic framework that connects LLMs to the real world securely.

## Setup

1.  Enable the service:
    ```bash
    ./corekit.sh enable openclaw
    ```

2.  Initialize configuration (generates secrets):
    ```bash
    ./corekit.sh init
    ```

3.  Build and Start:
    ```bash
    ./corekit.sh up openclaw
    ```

## Onboarding

To configure the gateway securely (bind to LAN, generate token, etc.), run the onboarding wizard:

```bash
./corekit.sh run openclaw onboard
```

Follow the interactive prompts.

## Configuration

Configuration is stored in the `openclaw_config` and `openclaw_workspace` volumes.

Environment variables can be customized in `.env`.

## Architecture

*   **openclaw-gateway**: The main gateway service running on port 18789.
*   **openclaw-cli**: A CLI tool for management and onboarding.
