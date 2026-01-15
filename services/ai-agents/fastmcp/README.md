# FastMCP Gateway

A unified MCP (Model Context Protocol) gateway server that aggregates multiple MCP servers and exposes them through a single HTTP/SSE endpoint.

## Overview

FastMCP Gateway provides a centralized MCP server that:

- **Aggregates multiple MCP tools** into a single endpoint
- **Built-in tools** for filesystem, memory, time, and web fetching
- **Extensible configuration** via JSON config files
- **API key authentication** for secure access
- **Local overrides** via git-ignored config directory

## Quick Start

```bash
# Enable and start the service
launchkit enable fastmcp
launchkit up fastmcp

# View logs
launchkit logs fastmcp
```

The MCP endpoint will be available at `http://localhost:8100/mcp`

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FASTMCP_PORT` | HTTP server port | `8100` |
| `FASTMCP_SERVER_NAME` | Server display name | `FastMCP Gateway` |
| `FASTMCP_API_KEY` | API key for authentication | (auto-generated) |
| `FASTMCP_ALLOWED_PATHS` | Comma-separated paths for filesystem access | `/data/workspace` |

### Feature Flags

| Variable | Description | Default |
|----------|-------------|---------|
| `FASTMCP_ENABLE_FILESYSTEM` | Enable filesystem tools | `true` |
| `FASTMCP_ENABLE_MEMORY` | Enable memory/knowledge graph tools | `true` |
| `FASTMCP_ENABLE_TIME` | Enable time/timezone tools | `true` |
| `FASTMCP_ENABLE_FETCH` | Enable web fetch tools | `true` |
| `FASTMCP_ENABLE_BRAVE` | Enable Brave Search | `false` |
| `FASTMCP_ENABLE_GITHUB` | Enable GitHub integration | `false` |

### External API Keys

For additional features, configure these in your `.env`:

| Variable | Description |
|----------|-------------|
| `BRAVE_API_KEY` | Brave Search API key ([get one](https://brave.com/search/api/)) |
| `GITHUB_TOKEN` | GitHub Personal Access Token |
| `OPENAI_API_KEY` | OpenAI API key (for AI-powered tools) |

## Built-in Tools

### Filesystem Tools

- `read_file(path)` - Read file contents
- `write_file(path, content)` - Write content to file
- `list_directory(path)` - List directory contents
- `create_directory(path)` - Create a directory
- `delete_file(path)` - Delete a file
- `move_file(source, destination)` - Move/rename a file
- `search_files(path, pattern)` - Search files with glob pattern

### Memory Tools

- `memory_store(entity_name, entity_type, observations)` - Store entity information
- `memory_retrieve(entity_name)` - Retrieve entity information
- `memory_search(query)` - Search memory
- `memory_relate(entity1, relation, entity2)` - Create entity relations
- `memory_list_entities()` - List all entities

### Time Tools

- `get_current_time(timezone_name)` - Get current time in timezone
- `convert_time(time_str, from_timezone, to_timezone)` - Convert between timezones
- `list_timezones(region)` - List available timezones

### Fetch Tools

- `fetch_url(url)` - Fetch and extract content from URL
- `fetch_json(url)` - Fetch and parse JSON from URL

### Optional: Brave Search

- `brave_search(query, count, search_type)` - Search the web

### Optional: GitHub

- `github_search_repos(query, sort)` - Search GitHub repositories
- `github_get_file(repo, path, ref)` - Get file from repository

## Custom Configuration

### Adding Custom MCP Servers

Create or edit `config/local/servers.json`:

```json
{
  "servers": {
    "my_custom_server": {
      "enabled": true,
      "description": "My custom MCP server",
      "type": "external",
      "command": "npx",
      "args": ["-y", "@my-org/my-mcp-server"],
      "env": {
        "API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

### Overriding Default Servers

Local config takes precedence over `config/servers.json`:

```json
{
  "servers": {
    "brave_search": {
      "enabled": true
    }
  }
}
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check |
| `GET /info` | Server information and enabled features |
| `POST /mcp` | MCP protocol endpoint |

## Usage with Claude

Configure Claude Desktop or other MCP clients to use the gateway:

```json
{
  "mcpServers": {
    "fastmcp-gateway": {
      "url": "http://localhost:8100/mcp",
      "transport": "streamable-http"
    }
  }
}
```

## Directory Structure

```
fastmcp/
├── docker-compose.yml    # Container definition
├── service.json          # Service metadata
├── .env                  # Configuration (git-ignored)
├── .env.example          # Config template
├── server.py             # FastMCP server implementation
├── requirements.txt      # Python dependencies
├── secrets.sh            # API key generation
├── prepare.sh            # Service preparation
├── config/
│   ├── servers.json      # MCP servers config
│   └── local/            # User overrides (git-ignored)
│       └── servers.json  # Custom server config
├── data/
│   ├── workspace/        # Filesystem access root
│   └── memory/           # Persistent memory storage
└── README.md             # This file
```

## Troubleshooting

### Service won't start

```bash
# Check logs
launchkit logs fastmcp --tail 50

# Verify configuration
cat services/ai-agents/fastmcp/.env

# Run prepare script
cd services/ai-agents/fastmcp
bash -x prepare.sh
```

### API key issues

```bash
# Regenerate secrets
cd services/ai-agents/fastmcp
bash secrets.sh

# View generated key
grep FASTMCP_API_KEY .env
```

### Permission issues with filesystem tools

Ensure the paths you're trying to access are within `FASTMCP_ALLOWED_PATHS`:

```bash
# Check allowed paths
grep FASTMCP_ALLOWED_PATHS .env

# Default: /data/workspace (maps to ./data/workspace)
```

## Resources

- [FastMCP Documentation](https://gofastmcp.com/)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)
