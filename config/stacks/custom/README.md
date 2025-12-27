# Custom Stacks

This directory allows you to define custom stacks or override existing ones.

## How it works

1.  **New Stacks:** Create a YAML file (e.g., `my-stack.yaml`) to define a new stack.
    ```yaml
    name: my-stack
    project_name: localai
    services:
      - n8n
      - postgres
    ```
    Run it with: `launchkit up my-stack`

2.  **Additive Overrides:** If you create a file with the **same name** as a base stack (e.g., `core.yaml`), it will be **merged** with the base stack.
    *   **Services:** The list of services will be *added* to the base list.
    *   **Project Name:** If specified, it will *override* the base project name.

    **Example: `config/stacks/custom/core.yaml`**
    ```yaml
    # This adds 'my-custom-service' to the core stack
    services:
      - my-custom-service
    ```

## Rules
*   Files in this directory are ignored by git (except this README).
*   You can use this to create personal development stacks or add private services without modifying the main codebase.
