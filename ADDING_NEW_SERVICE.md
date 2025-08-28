# Guide: Adding a New Service to AI LaunchKit

This document shows how to add a new optional service (behind Docker Compose profiles) and wire it into the installer, Caddy, and final report.

Use a short lowercase slug for your service, e.g., `myservice` or for AI services: `aiagent`, `vectordb`, etc.

## Quick Overview
Adding a new service requires changes to these files:
1. `docker-compose.yml` - Service definition
2. `Caddyfile` - HTTPS routing
3. `.env.example` - Configuration variables
4. `scripts/03_generate_secrets.sh` - Secret generation
5. `scripts/04_wizard.sh` - Installation wizard
6. `scripts/06_final_report.sh` - Post-install report
7. `README.md` - Documentation

## 1) docker-compose.yml
Add a service block under `services:` with a Compose profile:

### Basic Service Template
```yaml
  myservice:
    image: yourorg/myservice:latest
    container_name: myservice
    profiles: ["myservice"]  # Required for selective deployment
    restart: unless-stopped
    # volumes:
    #   - myservice_data:/data
    #   - ./shared:/data/shared  # For file sharing with n8n/other services
    # environment:
    #   - SOME_CONFIG=${MYSERVICE_CONFIG}
    # healthcheck:
    #   test: ["CMD-SHELL", "curl -fsS http://localhost:8080/health || exit 1"]
    #   interval: 30s
    #   timeout: 10s
    #   retries: 5
```

### AI Service Example (with GPU support)
```yaml
  aimodel:
    image: huggingface/text-generation-inference:latest
    container_name: aimodel
    profiles: ["aimodel"]
    restart: unless-stopped
    volumes:
      - aimodel_cache:/data
      - ./shared:/data/shared
    environment:
      - MODEL_ID=${AIMODEL_NAME:-microsoft/phi-2}
    # Optional GPU support
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

### Important Notes:
- **DO NOT** use `ports:` - Let Caddy handle external HTTPS
- **DO NOT** use `expose:` unless required for internal discovery
- Add volumes to the `volumes:` section at the bottom of docker-compose.yml
- For AI services, consider GPU requirements and model storage

### Caddy Environment Passthrough
If your service needs external access, add environment variables to Caddy:

```yaml
  caddy:
    # ...existing config...
    environment:
      # ...existing variables...
      - MYSERVICE_HOSTNAME=${MYSERVICE_HOSTNAME}
      # If using basic auth:
      - MYSERVICE_USERNAME=${MYSERVICE_USERNAME}
      - MYSERVICE_PASSWORD_HASH=${MYSERVICE_PASSWORD_HASH}
```

## 2) Caddyfile
Add a site block if the service should be reachable externally:

### Basic Proxy (No Auth)
```caddyfile
# MyService
{$MYSERVICE_HOSTNAME} {
    reverse_proxy myservice:8080
}
```

### With Basic Authentication
```caddyfile
# MyService (Protected)
{$MYSERVICE_HOSTNAME} {
    basic_auth {
        {$MYSERVICE_USERNAME} {$MYSERVICE_PASSWORD_HASH}
    }
    reverse_proxy myservice:8080
}
```

### AI Service with Special Headers
```caddyfile
# AI Model Service
{$AIMODEL_HOSTNAME} {
    basic_auth {
        {$AIMODEL_USERNAME} {$AIMODEL_PASSWORD_HASH}
    }
    reverse_proxy aimodel:8080 {
        # For streaming responses
        flush_interval -1
        # For large model uploads
        header_up X-Real-IP {remote}
    }
}
```

## 3) .env.example
Add configuration variables in the appropriate section:

### Basic Service Variables
```dotenv
# Under Caddy/domain configuration section:
MYSERVICE_HOSTNAME=myservice.yourdomain.com

# If using Basic Auth:
############
# MyService credentials (for Caddy basic auth)
############
MYSERVICE_USERNAME=
MYSERVICE_PASSWORD=
MYSERVICE_PASSWORD_HASH=
```

### AI Service Variables
```dotenv
# AI Model Service
AIMODEL_HOSTNAME=aimodel.yourdomain.com
AIMODEL_NAME=microsoft/phi-2
AIMODEL_USERNAME=
AIMODEL_PASSWORD=
AIMODEL_PASSWORD_HASH=
# Optional API keys
AIMODEL_API_KEY=
```

## 4) scripts/03_generate_secrets.sh
Generate secrets and handle user-provided values:

### Add to VARS_TO_GENERATE
```bash
declare -A VARS_TO_GENERATE=(
    # ...existing entries...
    ["MYSERVICE_PASSWORD"]="password:32"
    # For API keys use:
    ["MYSERVICE_API_KEY"]="apikey:32"
)
```

### Set Default Username
```bash
# In the section where usernames are defaulted
found_vars["MYSERVICE_USERNAME"]=0
# ...later in the script
generated_values["MYSERVICE_USERNAME"]="$USER_EMAIL"
```

### Generate Password Hash
Add this block following the pattern of other services:

```bash
# Generate hash for MyService
MYSERVICE_PLAIN_PASS="${generated_values["MYSERVICE_PASSWORD"]}"
FINAL_MYSERVICE_HASH="${generated_values[MYSERVICE_PASSWORD_HASH]}"
if [[ -z "$FINAL_MYSERVICE_HASH" && -n "$MYSERVICE_PLAIN_PASS" ]]; then
    NEW_HASH=$(_generate_and_get_hash "$MYSERVICE_PLAIN_PASS")
    if [[ -n "$NEW_HASH" ]]; then
        FINAL_MYSERVICE_HASH="$NEW_HASH"
        generated_values["MYSERVICE_PASSWORD_HASH"]="$NEW_HASH"
    fi
fi
_update_or_add_env_var "MYSERVICE_PASSWORD_HASH" "$FINAL_MYSERVICE_HASH"
```

## 5) scripts/04_wizard.sh
Add the service to the wizard selection list:

### Find the appropriate category and add your service:
```bash
# For AI Development Tools:
"myaiservice" "MyAIService (AI-powered feature description)"

# For Databases:
"myvectordb" "MyVectorDB (Vector similarity search)"

# For Utilities:
"myutil" "MyUtility (Utility description)"
```

Services are displayed in the order they appear in the array.

## 6) scripts/06_final_report.sh
Add a block to display service information after installation:

### Basic Service Report
```bash
if is_profile_active "myservice"; then
  echo
  echo "================================= MyService ==========================="
  echo
  echo "Host: ${MYSERVICE_HOSTNAME:-<hostname_not_set>}"
  echo "User: ${MYSERVICE_USERNAME:-<not_set_in_env>}"
  echo "Password: ${MYSERVICE_PASSWORD:-<not_set_in_env>}"
  echo
  echo "Access:"
  echo "  External (HTTPS): https://${MYSERVICE_HOSTNAME:-<hostname_not_set>}"
  echo "  Internal (Docker): http://myservice:8080"
  echo
  echo "Documentation: https://myservice.docs.example.com"
fi
```

### AI Service Report with API Info
```bash
if is_profile_active "aimodel"; then
  echo
  echo "================================= AI Model Service ===================="
  echo
  echo "Host: ${AIMODEL_HOSTNAME:-<hostname_not_set>}"
  echo "Model: ${AIMODEL_NAME:-microsoft/phi-2}"
  echo "User: ${AIMODEL_USERNAME:-<not_set_in_env>}"
  echo "Password: ${AIMODEL_PASSWORD:-<not_set_in_env>}"
  echo
  echo "API Endpoints:"
  echo "  Generate: https://${AIMODEL_HOSTNAME:-<hostname_not_set>}/generate"
  echo "  Health: https://${AIMODEL_HOSTNAME:-<hostname_not_set>}/health"
  echo
  echo "n8n Integration:"
  echo "  Use HTTP Request node with URL: http://aimodel:8080/generate"
  echo
  echo "Documentation: https://aimodel.docs.example.com"
fi
```

## 7) README.md
Add your service to the appropriate section with a concise description:

```markdown
### AI Development Tools
✅ [**MyAIService**](https://example.com) - AI-powered feature with specific capabilities

### Databases & Vector Stores  
✅ [**MyVectorDB**](https://example.com) - High-performance vector similarity search

### Utilities
✅ [**MyUtility**](https://example.com) - Specific utility function description
```

## 8) Security Considerations

### When to Use Basic Auth
Always protect services that:
- Have no built-in authentication
- Expose sensitive data or operations
- Are development/debugging tools
- Have potential for abuse if publicly accessible

### When Basic Auth is Optional
Services with their own auth systems:
- Supabase (has built-in auth)
- n8n (has user management)
- Open WebUI (has login system)

### API Key Management
For AI services requiring API keys:
```bash
# In .env.example
MYSERVICE_OPENAI_KEY=
MYSERVICE_ANTHROPIC_KEY=

# Pass to container in docker-compose.yml
environment:
  - OPENAI_API_KEY=${MYSERVICE_OPENAI_KEY}
  - ANTHROPIC_API_KEY=${MYSERVICE_ANTHROPIC_KEY}
```

## 9) Testing Your Service

### Regenerate Secrets
```bash
bash scripts/03_generate_secrets.sh
```

### Deploy Only Your Service
```bash
# Add your profile to COMPOSE_PROFILES in .env
echo "COMPOSE_PROFILES=n8n,myservice" >> .env

# Start your service
docker compose -p localai up -d myservice

# Force recreate if needed
docker compose -p localai up -d --no-deps --force-recreate myservice
```

### Check Logs
```bash
# Your service logs
docker compose -p localai logs -f myservice

# Caddy logs (for routing issues)
docker compose -p localai logs -f caddy

# Check if service is running
docker compose -p localai ps | grep myservice
```

### Test Access
```bash
# Internal test (from within the Docker network)
docker exec n8n curl -s http://myservice:8080/health

# External test (through Caddy)
curl -u username:password https://myservice.yourdomain.com/health
```

## 10) Pre-flight Checklist

Before committing your changes:

- [ ] Service added to `docker-compose.yml` with profile
- [ ] No external ports exposed (unless absolutely necessary)
- [ ] Volume added if service needs persistent storage
- [ ] Hostname added to `.env.example`
- [ ] Credentials added to `.env.example` (if using auth)
- [ ] Secret generation in `scripts/03_generate_secrets.sh`
- [ ] Caddy routing in `Caddyfile`
- [ ] Caddy environment variables in `docker-compose.yml`
- [ ] Service in wizard (`scripts/04_wizard.sh`)
- [ ] Service report in `scripts/06_final_report.sh`
- [ ] Documentation in `README.md`
- [ ] Health check configured
- [ ] Tested deployment and access
- [ ] Tested integration with n8n (if applicable)

## 11) AI Service Specific Considerations

### Model Storage
```yaml
volumes:
  - ${MODEL_PATH:-./models}:/models
```

### GPU Support
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

### Memory Limits
```yaml
deploy:
  resources:
    limits:
      memory: 8G
```

### n8n Integration Examples
Document how to use your service from n8n:
- HTTP Request node configuration
- Expected request/response format
- Authentication method
- Example workflow JSON

## 12) Common Issues and Solutions

### Service Not Accessible
1. Check if container is running: `docker ps | grep myservice`
2. Check Caddy routing: `docker logs caddy | grep myservice`
3. Verify DNS resolution: `nslookup myservice.yourdomain.com`
4. Check firewall rules: `sudo ufw status`

### Authentication Failures
1. Verify password hash generation: Check `.env` for `MYSERVICE_PASSWORD_HASH`
2. Test with curl: `curl -u user:pass https://myservice.yourdomain.com`
3. Check Caddy logs for auth errors

### Container Keeps Restarting
1. Check logs: `docker logs myservice`
2. Verify health check: May be failing
3. Check resource limits: Out of memory?
4. Verify environment variables: Missing required config?

## Contributing

When adding a new AI service to AI LaunchKit:
1. Consider the target audience (developers, data scientists, automation engineers)
2. Ensure it complements existing services
3. Document integration points with n8n and other services
4. Provide example workflows or use cases
5. Test with both minimal and full installations

## Questions?

If you need help adding a service:
1. Check existing services in docker-compose.yml for patterns
2. Review the Git history for how other services were added
3. Open an issue on GitHub: https://github.com/freddy-schuetz/ai-launchkit

---

*Last updated: August 2025 - AI LaunchKit v1.0*  
*Based on the original [n8n-installer](https://github.com/kossakovsky/n8n-installer) documentation*
