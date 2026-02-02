#!/usr/bin/env python3
"""
FastMCP Gateway Server

A unified MCP gateway that aggregates multiple MCP servers and exposes them
through a single HTTP/SSE endpoint. Supports both built-in tools and external
MCP server proxying.
"""

import os
import json
import asyncio
import logging
from pathlib import Path
from datetime import datetime, timezone
from typing import Any, Optional
from contextlib import asynccontextmanager

import httpx
from fastmcp import FastMCP
from fastmcp.client.transports import StdioTransport
from starlette.applications import Starlette
from starlette.routing import Route, Mount
from starlette.responses import JSONResponse, Response
from starlette.requests import Request
from starlette.middleware import Middleware
from starlette.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("fastmcp-gateway")

# Configuration
PORT = int(os.environ.get("FASTMCP_PORT", 8100))
HOST = os.environ.get("FASTMCP_HOST", "0.0.0.0")
SERVER_NAME = os.environ.get("FASTMCP_SERVER_NAME", "FastMCP Gateway")
API_KEY = os.environ.get("FASTMCP_API_KEY", "")
SERVERS_CONFIG = os.environ.get("FASTMCP_SERVERS_CONFIG", "config/servers.json")
SERVERS_LOCAL_CONFIG = os.environ.get("FASTMCP_SERVERS_LOCAL_CONFIG", "config/local/servers.json")
SERVERS_LOCAL_DIR = os.environ.get("FASTMCP_SERVERS_LOCAL_DIR", "config/local/servers")

# Feature flags
ENABLE_FILESYSTEM = os.environ.get("FASTMCP_ENABLE_FILESYSTEM", "true").lower() == "true"
ENABLE_MEMORY = os.environ.get("FASTMCP_ENABLE_MEMORY", "true").lower() == "true"
ENABLE_TIME = os.environ.get("FASTMCP_ENABLE_TIME", "true").lower() == "true"
ENABLE_FETCH = os.environ.get("FASTMCP_ENABLE_FETCH", "true").lower() == "true"
ENABLE_BRAVE = os.environ.get("FASTMCP_ENABLE_BRAVE", "false").lower() == "true"
ENABLE_GITHUB = os.environ.get("FASTMCP_ENABLE_GITHUB", "false").lower() == "true"

# Initialize FastMCP
mcp = FastMCP(SERVER_NAME)


# ============================================================================
# Authentication Middleware
# ============================================================================

class APIKeyAuthMiddleware(BaseHTTPMiddleware):
    """Middleware to enforce API key authentication."""

    # Paths that don't require authentication
    PUBLIC_PATHS = {"/health"}

    async def dispatch(self, request: Request, call_next):
        # Skip auth for public paths
        if request.url.path in self.PUBLIC_PATHS:
            return await call_next(request)

        # Skip auth if no API key is configured
        if not API_KEY:
            return await call_next(request)

        # Check for API key in headers
        auth_header = request.headers.get("Authorization", "")
        api_key_header = request.headers.get("X-API-Key", "")

        # Extract Bearer token if present
        bearer_token = ""
        if auth_header.startswith("Bearer "):
            bearer_token = auth_header[7:]

        # Validate API key
        if bearer_token == API_KEY or api_key_header == API_KEY:
            return await call_next(request)

        # Authentication failed
        logger.warning(f"Unauthorized request to {request.url.path} from {request.client.host}")
        return JSONResponse(
            {"error": "Unauthorized", "message": "Valid API key required"},
            status_code=401,
            headers={"WWW-Authenticate": "Bearer"}
        )


def load_servers_config() -> dict:
    """Load servers configuration from JSON files."""
    config = {"servers": {}, "defaults": {}}

    # Load base config
    base_path = Path(SERVERS_CONFIG)
    if base_path.exists():
        with open(base_path) as f:
            config = json.load(f)
        logger.info(f"Loaded base config from {SERVERS_CONFIG}")

    # Load separate server files from local directory
    local_dir = Path(SERVERS_LOCAL_DIR)
    if local_dir.exists() and local_dir.is_dir():
        for file_path in local_dir.glob("*.json"):
            try:
                with open(file_path) as f:
                    file_content = json.load(f)
                    
                # Handle structure: {"servers": {...}}
                servers_to_add = {}
                if "servers" in file_content:
                    servers_to_add = file_content["servers"]
                # Handle structure: {"server_name": {...}} (direct map)
                elif isinstance(file_content, dict):
                    # Filter out non-server keys like 'defaults' if present at root
                    servers_to_add = {k: v for k, v in file_content.items() 
                                    if k != "defaults" and not k.startswith("_")}
                
                for server_name, server_config in servers_to_add.items():
                    if server_name.startswith("_"):
                        continue
                        
                    # Basic validation - must be dict
                    if not isinstance(server_config, dict):
                        logger.warning(f"Skipping invalid config for {server_name} in {file_path.name}")
                        continue
                        
                    config["servers"][server_name] = {
                        **config["servers"].get(server_name, {}),
                        **server_config
                    }
                logger.info(f"Loaded local server config from {file_path}")
            except Exception as e:
                logger.error(f"Failed to load local config {file_path}: {e}")

    # Load local overrides
    local_path = Path(SERVERS_LOCAL_CONFIG)
    if local_path.exists():
        with open(local_path) as f:
            local_config = json.load(f)
        # Merge local config (local takes precedence)
        if "servers" in local_config:
            for server_name, server_config in local_config["servers"].items():
                if server_name.startswith("_"):
                    continue
                config["servers"][server_name] = {
                    **config["servers"].get(server_name, {}),
                    **server_config
                }
        logger.info(f"Loaded local overrides from {SERVERS_LOCAL_CONFIG}")

    return config


def expand_env_vars(value: Any) -> Any:
    """Recursively expand environment variables in configuration values."""
    if isinstance(value, str):
        # Handle ${VAR} and ${VAR:-default} syntax
        import re
        def replacer(match):
            var_name = match.group(1)
            default = match.group(3) if match.group(3) else ""
            return os.environ.get(var_name, default)
        return re.sub(r'\$\{([^}:-]+)(?::-([^}]*))?\}', replacer, value)
    elif isinstance(value, list):
        return [expand_env_vars(item) for item in value]
    elif isinstance(value, dict):
        return {k: expand_env_vars(v) for k, v in value.items()}
    return value


# ============================================================================
# Built-in Tools
# ============================================================================

# --- Filesystem Tools ---
if ENABLE_FILESYSTEM:
    ALLOWED_PATHS = os.environ.get("FASTMCP_ALLOWED_PATHS", "/data/workspace").split(",")
    ALLOWED_PATHS = [Path(p.strip()).resolve() for p in ALLOWED_PATHS if p.strip()]

    def is_path_allowed(path: str) -> bool:
        """Check if a path is within allowed directories."""
        try:
            resolved = Path(path).resolve()
            return any(
                resolved == allowed or allowed in resolved.parents
                for allowed in ALLOWED_PATHS
            )
        except Exception:
            return False

    @mcp.tool()
    async def read_file(path: str) -> str:
        """Read the contents of a file.

        Args:
            path: The file path to read

        Returns:
            The file contents as a string
        """
        if not is_path_allowed(path):
            raise PermissionError(f"Access denied: {path} is not in allowed paths")

        file_path = Path(path)
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {path}")
        if not file_path.is_file():
            raise ValueError(f"Not a file: {path}")

        return file_path.read_text()

    @mcp.tool()
    async def write_file(path: str, content: str) -> str:
        """Write content to a file.

        Args:
            path: The file path to write to
            content: The content to write

        Returns:
            Confirmation message
        """
        if not is_path_allowed(path):
            raise PermissionError(f"Access denied: {path} is not in allowed paths")

        file_path = Path(path)
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content)
        return f"Successfully wrote {len(content)} bytes to {path}"

    @mcp.tool()
    async def list_directory(path: str) -> list[dict]:
        """List contents of a directory.

        Args:
            path: The directory path to list

        Returns:
            List of directory entries with name, type, and size
        """
        if not is_path_allowed(path):
            raise PermissionError(f"Access denied: {path} is not in allowed paths")

        dir_path = Path(path)
        if not dir_path.exists():
            raise FileNotFoundError(f"Directory not found: {path}")
        if not dir_path.is_dir():
            raise ValueError(f"Not a directory: {path}")

        entries = []
        for entry in dir_path.iterdir():
            stat = entry.stat()
            entries.append({
                "name": entry.name,
                "type": "directory" if entry.is_dir() else "file",
                "size": stat.st_size if entry.is_file() else None,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
            })
        return sorted(entries, key=lambda x: (x["type"] != "directory", x["name"]))

    @mcp.tool()
    async def create_directory(path: str) -> str:
        """Create a directory (including parent directories).

        Args:
            path: The directory path to create

        Returns:
            Confirmation message
        """
        if not is_path_allowed(path):
            raise PermissionError(f"Access denied: {path} is not in allowed paths")

        dir_path = Path(path)
        dir_path.mkdir(parents=True, exist_ok=True)
        return f"Successfully created directory: {path}"

    @mcp.tool()
    async def delete_file(path: str) -> str:
        """Delete a file.

        Args:
            path: The file path to delete

        Returns:
            Confirmation message
        """
        if not is_path_allowed(path):
            raise PermissionError(f"Access denied: {path} is not in allowed paths")

        file_path = Path(path)
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {path}")
        if not file_path.is_file():
            raise ValueError(f"Not a file: {path}")

        file_path.unlink()
        return f"Successfully deleted: {path}"

    @mcp.tool()
    async def move_file(source: str, destination: str) -> str:
        """Move or rename a file.

        Args:
            source: The source file path
            destination: The destination file path

        Returns:
            Confirmation message
        """
        if not is_path_allowed(source):
            raise PermissionError(f"Access denied: {source} is not in allowed paths")
        if not is_path_allowed(destination):
            raise PermissionError(f"Access denied: {destination} is not in allowed paths")

        src_path = Path(source)
        dst_path = Path(destination)

        if not src_path.exists():
            raise FileNotFoundError(f"Source not found: {source}")

        dst_path.parent.mkdir(parents=True, exist_ok=True)
        src_path.rename(dst_path)
        return f"Successfully moved {source} to {destination}"

    @mcp.tool()
    async def search_files(
        path: str,
        pattern: str,
        recursive: bool = True
    ) -> list[str]:
        """Search for files matching a pattern.

        Args:
            path: The directory to search in
            pattern: Glob pattern to match (e.g., "*.py", "**/*.json")
            recursive: Whether to search recursively

        Returns:
            List of matching file paths
        """
        if not is_path_allowed(path):
            raise PermissionError(f"Access denied: {path} is not in allowed paths")

        dir_path = Path(path)
        if not dir_path.exists():
            raise FileNotFoundError(f"Directory not found: {path}")

        if recursive and not pattern.startswith("**/"):
            pattern = f"**/{pattern}"

        matches = [str(p) for p in dir_path.glob(pattern) if p.is_file()]
        return matches[:100]  # Limit results

    logger.info("Filesystem tools enabled")


# --- Memory Tools ---
if ENABLE_MEMORY:
    MEMORY_PATH = Path(os.environ.get("FASTMCP_MEMORY_PATH", "/app/memory/knowledge.json"))

    def load_memory() -> dict:
        """Load memory from persistent storage."""
        if MEMORY_PATH.exists():
            with open(MEMORY_PATH) as f:
                return json.load(f)
        return {"entities": {}, "relations": []}

    def save_memory(memory: dict):
        """Save memory to persistent storage."""
        MEMORY_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(MEMORY_PATH, "w") as f:
            json.dump(memory, f, indent=2)

    @mcp.tool()
    async def memory_store(
        entity_name: str,
        entity_type: str,
        observations: list[str]
    ) -> str:
        """Store information about an entity in memory.

        Args:
            entity_name: Name of the entity
            entity_type: Type of entity (e.g., "person", "project", "concept")
            observations: List of observations about the entity

        Returns:
            Confirmation message
        """
        memory = load_memory()

        if entity_name not in memory["entities"]:
            memory["entities"][entity_name] = {
                "type": entity_type,
                "observations": [],
                "created": datetime.now(timezone.utc).isoformat()
            }

        memory["entities"][entity_name]["observations"].extend(observations)
        memory["entities"][entity_name]["updated"] = datetime.now(timezone.utc).isoformat()

        save_memory(memory)
        return f"Stored {len(observations)} observations for entity '{entity_name}'"

    @mcp.tool()
    async def memory_retrieve(entity_name: str) -> dict:
        """Retrieve information about an entity from memory.

        Args:
            entity_name: Name of the entity to retrieve

        Returns:
            Entity information including type and observations
        """
        memory = load_memory()

        if entity_name not in memory["entities"]:
            return {"error": f"Entity '{entity_name}' not found in memory"}

        return memory["entities"][entity_name]

    @mcp.tool()
    async def memory_search(query: str) -> list[dict]:
        """Search memory for entities matching a query.

        Args:
            query: Search query (matches entity names and observations)

        Returns:
            List of matching entities
        """
        memory = load_memory()
        query_lower = query.lower()

        results = []
        for name, entity in memory["entities"].items():
            if query_lower in name.lower():
                results.append({"name": name, "match": "name", **entity})
            elif any(query_lower in obs.lower() for obs in entity.get("observations", [])):
                results.append({"name": name, "match": "observation", **entity})

        return results

    @mcp.tool()
    async def memory_relate(
        entity1: str,
        relation: str,
        entity2: str
    ) -> str:
        """Create a relation between two entities.

        Args:
            entity1: First entity name
            relation: Type of relation (e.g., "works_on", "knows", "related_to")
            entity2: Second entity name

        Returns:
            Confirmation message
        """
        memory = load_memory()

        new_relation = {
            "from": entity1,
            "relation": relation,
            "to": entity2,
            "created": datetime.now(timezone.utc).isoformat()
        }

        # Avoid duplicates
        for r in memory["relations"]:
            if r["from"] == entity1 and r["relation"] == relation and r["to"] == entity2:
                return f"Relation already exists: {entity1} --[{relation}]--> {entity2}"

        memory["relations"].append(new_relation)
        save_memory(memory)
        return f"Created relation: {entity1} --[{relation}]--> {entity2}"

    @mcp.tool()
    async def memory_list_entities() -> list[dict]:
        """List all entities in memory.

        Returns:
            List of entity summaries
        """
        memory = load_memory()

        return [
            {
                "name": name,
                "type": entity.get("type"),
                "observation_count": len(entity.get("observations", [])),
                "created": entity.get("created"),
                "updated": entity.get("updated")
            }
            for name, entity in memory["entities"].items()
        ]

    logger.info("Memory tools enabled")


# --- Time Tools ---
if ENABLE_TIME:
    from zoneinfo import ZoneInfo

    @mcp.tool()
    async def get_current_time(timezone_name: str = "UTC") -> dict:
        """Get the current time in a specific timezone.

        Args:
            timezone_name: IANA timezone name (e.g., "America/New_York", "Europe/London", "UTC")

        Returns:
            Current time information
        """
        try:
            tz = ZoneInfo(timezone_name)
        except Exception:
            return {"error": f"Invalid timezone: {timezone_name}"}

        now = datetime.now(tz)
        return {
            "timezone": timezone_name,
            "datetime": now.isoformat(),
            "date": now.strftime("%Y-%m-%d"),
            "time": now.strftime("%H:%M:%S"),
            "day_of_week": now.strftime("%A"),
            "unix_timestamp": int(now.timestamp())
        }

    @mcp.tool()
    async def convert_time(
        time_str: str,
        from_timezone: str,
        to_timezone: str
    ) -> dict:
        """Convert time between timezones.

        Args:
            time_str: Time string in ISO format (e.g., "2024-01-15T10:30:00")
            from_timezone: Source timezone
            to_timezone: Target timezone

        Returns:
            Converted time information
        """
        try:
            from_tz = ZoneInfo(from_timezone)
            to_tz = ZoneInfo(to_timezone)
        except Exception as e:
            return {"error": f"Invalid timezone: {e}"}

        try:
            dt = datetime.fromisoformat(time_str.replace("Z", "+00:00"))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=from_tz)
            else:
                dt = dt.astimezone(from_tz)

            converted = dt.astimezone(to_tz)

            return {
                "original": {
                    "datetime": dt.isoformat(),
                    "timezone": from_timezone
                },
                "converted": {
                    "datetime": converted.isoformat(),
                    "timezone": to_timezone,
                    "date": converted.strftime("%Y-%m-%d"),
                    "time": converted.strftime("%H:%M:%S")
                }
            }
        except Exception as e:
            return {"error": f"Failed to parse time: {e}"}

    @mcp.tool()
    async def list_timezones(region: str = "") -> list[str]:
        """List available timezones, optionally filtered by region.

        Args:
            region: Optional region filter (e.g., "America", "Europe", "Asia")

        Returns:
            List of timezone names
        """
        import zoneinfo
        all_zones = sorted(zoneinfo.available_timezones())

        if region:
            return [tz for tz in all_zones if tz.startswith(region)]
        return all_zones

    logger.info("Time tools enabled")


# --- Fetch Tools ---
if ENABLE_FETCH:
    MAX_CONTENT_LENGTH = int(os.environ.get("FASTMCP_FETCH_MAX_LENGTH", 100000))
    FETCH_TIMEOUT = int(os.environ.get("FASTMCP_FETCH_TIMEOUT", 30))

    @mcp.tool()
    async def fetch_url(
        url: str,
        extract_text: bool = True,
        max_length: int = None
    ) -> dict:
        """Fetch content from a URL.

        Args:
            url: The URL to fetch
            extract_text: Whether to extract plain text from HTML
            max_length: Maximum content length to return

        Returns:
            Fetched content with metadata
        """
        max_length = max_length or MAX_CONTENT_LENGTH

        async with httpx.AsyncClient(timeout=FETCH_TIMEOUT, follow_redirects=True) as client:
            try:
                response = await client.get(url)
                response.raise_for_status()

                content_type = response.headers.get("content-type", "")
                content = response.text

                # Simple HTML to text conversion
                if extract_text and "html" in content_type.lower():
                    import re
                    # Remove scripts and styles
                    content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL | re.IGNORECASE)
                    content = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL | re.IGNORECASE)
                    # Remove HTML tags
                    content = re.sub(r'<[^>]+>', ' ', content)
                    # Clean up whitespace
                    content = re.sub(r'\s+', ' ', content).strip()

                # Truncate if needed
                if len(content) > max_length:
                    content = content[:max_length] + "... [truncated]"

                return {
                    "url": str(response.url),
                    "status_code": response.status_code,
                    "content_type": content_type,
                    "content_length": len(content),
                    "content": content
                }
            except httpx.HTTPError as e:
                return {
                    "url": url,
                    "error": str(e),
                    "error_type": type(e).__name__
                }

    @mcp.tool()
    async def fetch_json(url: str) -> dict:
        """Fetch and parse JSON from a URL.

        Args:
            url: The URL to fetch JSON from

        Returns:
            Parsed JSON data
        """
        async with httpx.AsyncClient(timeout=FETCH_TIMEOUT, follow_redirects=True) as client:
            try:
                response = await client.get(url)
                response.raise_for_status()
                return {
                    "url": str(response.url),
                    "status_code": response.status_code,
                    "data": response.json()
                }
            except httpx.HTTPError as e:
                return {"url": url, "error": str(e)}
            except json.JSONDecodeError as e:
                return {"url": url, "error": f"Invalid JSON: {e}"}

    logger.info("Fetch tools enabled")


# ============================================================================
# Brave Search Integration
# ============================================================================

if ENABLE_BRAVE:
    BRAVE_API_KEY = os.environ.get("BRAVE_API_KEY", "")

    if BRAVE_API_KEY:
        @mcp.tool()
        async def brave_search(
            query: str,
            count: int = 10,
            search_type: str = "web"
        ) -> dict:
            """Search the web using Brave Search API.

            Args:
                query: Search query
                count: Number of results (1-20)
                search_type: Type of search ("web" or "news")

            Returns:
                Search results
            """
            count = min(max(1, count), 20)

            async with httpx.AsyncClient(timeout=30) as client:
                try:
                    endpoint = "web" if search_type == "web" else "news"
                    response = await client.get(
                        f"https://api.search.brave.com/res/v1/{endpoint}/search",
                        params={"q": query, "count": count},
                        headers={
                            "X-Subscription-Token": BRAVE_API_KEY,
                            "Accept": "application/json"
                        }
                    )
                    response.raise_for_status()
                    return response.json()
                except httpx.HTTPError as e:
                    return {"error": str(e)}

        logger.info("Brave Search enabled")
    else:
        logger.warning("Brave Search enabled but BRAVE_API_KEY not set")


# ============================================================================
# GitHub Integration
# ============================================================================

if ENABLE_GITHUB:
    GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")

    if GITHUB_TOKEN:
        @mcp.tool()
        async def github_search_repos(
            query: str,
            sort: str = "stars",
            max_results: int = 10
        ) -> dict:
            """Search GitHub repositories.

            Args:
                query: Search query
                sort: Sort by (stars, forks, updated)
                max_results: Maximum results to return

            Returns:
                Repository search results
            """
            async with httpx.AsyncClient(timeout=30) as client:
                try:
                    response = await client.get(
                        "https://api.github.com/search/repositories",
                        params={
                            "q": query,
                            "sort": sort,
                            "per_page": min(max_results, 100)
                        },
                        headers={
                            "Authorization": f"token {GITHUB_TOKEN}",
                            "Accept": "application/vnd.github.v3+json"
                        }
                    )
                    response.raise_for_status()
                    data = response.json()

                    return {
                        "total_count": data.get("total_count"),
                        "repositories": [
                            {
                                "name": repo["full_name"],
                                "description": repo.get("description"),
                                "url": repo["html_url"],
                                "stars": repo["stargazers_count"],
                                "language": repo.get("language"),
                                "updated": repo["updated_at"]
                            }
                            for repo in data.get("items", [])
                        ]
                    }
                except httpx.HTTPError as e:
                    return {"error": str(e)}

        @mcp.tool()
        async def github_get_file(
            repo: str,
            path: str,
            ref: str = "main"
        ) -> dict:
            """Get a file from a GitHub repository.

            Args:
                repo: Repository in owner/repo format
                path: Path to the file
                ref: Branch, tag, or commit ref

            Returns:
                File content and metadata
            """
            import base64

            async with httpx.AsyncClient(timeout=30) as client:
                try:
                    response = await client.get(
                        f"https://api.github.com/repos/{repo}/contents/{path}",
                        params={"ref": ref},
                        headers={
                            "Authorization": f"token {GITHUB_TOKEN}",
                            "Accept": "application/vnd.github.v3+json"
                        }
                    )
                    response.raise_for_status()
                    data = response.json()

                    content = ""
                    if data.get("encoding") == "base64":
                        content = base64.b64decode(data["content"]).decode("utf-8")

                    return {
                        "name": data["name"],
                        "path": data["path"],
                        "size": data["size"],
                        "sha": data["sha"],
                        "content": content
                    }
                except httpx.HTTPError as e:
                    return {"error": str(e)}

        logger.info("GitHub tools enabled")
    else:
        logger.warning("GitHub enabled but GITHUB_TOKEN not set")


# ============================================================================
# External MCP Server Proxying
# ============================================================================

def initialize_external_servers():
    """Initialize and mount external MCP servers as proxies."""
    config = load_servers_config()

    for server_name, server_config in config.get("servers", {}).items():
        if server_name.startswith("_"):
            continue

        if not server_config.get("enabled"):
            continue

        server_type = server_config.get("type", "builtin")

        # Skip builtin servers - they're handled directly above
        if server_type == "builtin":
            continue

        if server_type == "external":
            command = server_config.get("command")
            args = server_config.get("args", [])

            if not command:
                logger.warning(f"External server '{server_name}' missing 'command' field")
                continue

            # Expand environment variables in args
            expanded_args = [expand_env_vars(arg) for arg in args]

            # Build environment for the subprocess
            server_env = {}
            for key, value in server_config.get("env", {}).items():
                expanded_value = expand_env_vars(value)
                if expanded_value:  # Only set if non-empty
                    server_env[key] = expanded_value

            try:
                logger.info(f"Starting external server: {server_name} ({command} {' '.join(expanded_args)})")

                # Create stdio transport for the external command
                transport = StdioTransport(
                    command=command,
                    args=expanded_args,
                    env=server_env if server_env else None
                )

                # Create proxy server from transport and mount it
                proxy = FastMCP.as_proxy(transport, name=f"{server_name}-proxy")
                mcp.mount(proxy, prefix=server_name)
                logger.info(f"Mounted external server: {server_name}")

            except Exception as e:
                logger.error(f"Failed to mount external server '{server_name}': {e}")
                import traceback
                traceback.print_exc()

        elif server_type == "http":
            url = server_config.get("url")
            if not url:
                logger.warning(f"HTTP server '{server_name}' missing 'url' field")
                continue

            # Expand URL (in case it has env vars)
            expanded_url = expand_env_vars(url)

            # Build headers if present
            headers = {}
            for key, value in server_config.get("headers", {}).items():
                expanded_value = expand_env_vars(value)
                if expanded_value:
                    headers[key] = expanded_value

            try:
                logger.info(f"Connecting to HTTP MCP server: {server_name} ({expanded_url})")

                # Create proxy server from URL and mount it
                # Note: headers support may require custom transport
                proxy = FastMCP.as_proxy(expanded_url, name=f"{server_name}-proxy")
                mcp.mount(proxy, prefix=server_name)
                logger.info(f"Mounted HTTP server: {server_name}")

            except Exception as e:
                logger.error(f"Failed to mount HTTP server '{server_name}': {e}")
                import traceback
                traceback.print_exc()


# ============================================================================
# HTTP Server Setup
# ============================================================================

async def health_check(request):
    """Health check endpoint."""
    # Count external servers
    config = load_servers_config()
    external_servers = [
        name for name, cfg in config.get("servers", {}).items()
        if cfg.get("enabled") and cfg.get("type") in ("external", "http") and not name.startswith("_")
    ]

    return JSONResponse({
        "status": "healthy",
        "server": SERVER_NAME,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "tools_count": len(mcp._tool_manager._tools) if hasattr(mcp, '_tool_manager') else 0,
        "builtin_features": {
            "filesystem": ENABLE_FILESYSTEM,
            "memory": ENABLE_MEMORY,
            "time": ENABLE_TIME,
            "fetch": ENABLE_FETCH,
            "brave_search": ENABLE_BRAVE and bool(os.environ.get("BRAVE_API_KEY")),
            "github": ENABLE_GITHUB and bool(os.environ.get("GITHUB_TOKEN"))
        },
        "external_servers": external_servers
    })


async def server_info(request):
    """Server information endpoint."""
    config = load_servers_config()
    enabled_servers = [
        name for name, cfg in config.get("servers", {}).items()
        if cfg.get("enabled") and not name.startswith("_")
    ]

    return JSONResponse({
        "name": SERVER_NAME,
        "version": "1.0.0",
        "mcp_endpoint": f"http://{HOST}:{PORT}/mcp",
        "transport": "streamable-http",
        "enabled_features": {
            "filesystem": ENABLE_FILESYSTEM,
            "memory": ENABLE_MEMORY,
            "time": ENABLE_TIME,
            "fetch": ENABLE_FETCH,
            "brave_search": ENABLE_BRAVE,
            "github": ENABLE_GITHUB
        },
        "configured_servers": enabled_servers
    })


# Create Starlette app with middleware
middleware = [
    Middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    ),
    Middleware(APIKeyAuthMiddleware),
]

# Get the MCP HTTP app with its lifespan
mcp_http_app = mcp.http_app()


@asynccontextmanager
async def combined_lifespan(app):
    """Combined lifespan that initializes external servers and FastMCP."""
    # Initialize external MCP servers (sync function, called during startup)
    logger.info("Initializing external MCP servers...")
    initialize_external_servers()

    # Enter FastMCP lifespan
    async with mcp_http_app.lifespan(app):
        yield

    logger.info("Shutting down...")


# Create the app with routes and combined lifespan
# Mount at root so FastMCP's internal /mcp route is accessible at /mcp (not /mcp/mcp)
app = Starlette(
    routes=[
        Route("/health", health_check),
        Route("/info", server_info),
        Mount("/", app=mcp_http_app),
    ],
    middleware=middleware,
    lifespan=combined_lifespan,
)


if __name__ == "__main__":
    import uvicorn

    logger.info(f"Starting {SERVER_NAME} on {HOST}:{PORT}")
    logger.info(f"MCP endpoint: http://{HOST}:{PORT}/mcp")
    logger.info(f"Health check: http://{HOST}:{PORT}/health")
    logger.info(f"Server info: http://{HOST}:{PORT}/info")

    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
