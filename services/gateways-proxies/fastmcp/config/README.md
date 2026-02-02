# FastMCP Configuration

FastMCP is configured through JSON files. The system loads configuration in the following order, merging them together:

1.  `config/servers.json`: The base configuration file (committed to git).
2.  `config/local/servers.json`: Personal overrides (git-ignored).
3.  `config/local/servers/*.json`: Modular server definition files (git-ignored).

## Adding New MCP Servers

You can add new MCP servers in two ways:

### 1. Modular Configuration (Recommended)

Create a new JSON file in `config/local/servers/` (e.g., `postgres.json`, `tools.json`). This is the best way to manage custom tools without modifying the main configuration.

**Example: `config/local/servers/postgres.json`**
```json
{
  "postgres": {
    "enabled": true,
    "description": "PostgreSQL Database Inspector",
    "type": "external",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@localhost/db"],
    "env": {
      "PGPASSWORD": "${PGPASSWORD}" // Uses environment variable from .env
    }
  }
}
```

### 2. Single Local Config

Edit `config/local/servers.json` to add your servers directly:

```json
{
  "servers": {
    "my-tool": {
      "enabled": true,
      "type": "external",
      "command": "python",
      "args": ["/path/to/server.py"]
    }
  }
}
```

## Configuration Structure

Each server definition supports the following fields:

*   **`enabled`** (boolean): Whether the server is active.
*   **`description`** (string): Description of the server's capabilities.
*   **`type`** (string): 
    *   `"builtin"`: For servers built into the FastMCP gateway (e.g., `filesystem`, `memory`).
    *   `"external"`: For running third-party MCP servers (node, python, binary).
*   **`config`** (object): Configuration for `"builtin"` servers.
*   **`command`** (string): Executable to run (only for `"external"`).
*   **`args`** (array): Arguments passed to the command (only for `"external"`).
*   **`env`** (object): Environment variables to pass to the server process. Values like `${VAR_NAME}` are expanded from the main service `.env`.

## Built-in Servers

The gateway comes with several built-in servers that can be configured in `config/servers.json`:

*   **Filesystem**: Secure file access.
*   **Memory**: Knowledge graph persistence.
*   **Time**: Timezone and date utilities.
*   **Fetch**: Web content fetching.
