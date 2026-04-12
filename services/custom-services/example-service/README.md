# Example Custom Service

This is a minimal template for adding your own services to AI LaunchKit.

## Structure

```
example-service/
├── docker-compose.yml   # Container definition
├── service.json         # Service metadata
├── .env.example         # Config template (copy to .env)
├── prepare.sh           # Runs before startup (mkdir, etc.)
├── build.sh             # Custom image build logic (if needed)
├── startup.sh           # Post-startup hooks (migrations, etc.)
├── healthcheck.sh       # Health verification
└── secrets.sh           # Secret generation
```

## How to create your own service

1. **Duplicate this directory**:
   ```bash
   cp -r services/custom-services/example-service services/custom-services/my-service
   ```

2. **Update `service.json`** with your service name, description, and any `depends_on` entries.

3. **Edit `docker-compose.yml`** to set the image and ports you need.

4. **Copy and configure `.env`**:
   ```bash
   cd services/custom-services/my-service
   cp .env.example .env
   ```

5. **Enable and start**:
   ```bash
   corekit up my-service
   ```

## Lifecycle hooks

CoreKit calls these scripts in order during `corekit up`:

| Script | When | Purpose |
|---|---|---|
| `secrets.sh` | First | Generate passwords/API keys into `.env` |
| `prepare.sh` | Second | Create directories, render config templates |
| `build.sh` | Third | Build custom Docker images |
| `startup.sh` | After container starts | DB migrations, seed data, API calls |
| `healthcheck.sh` | Last | Verify the service is healthy |

Each script is optional — return `exit 0` if there's nothing to do.

## Docs

See `docs/ADDING_NEW_SERVICE.md` for the full guide.
