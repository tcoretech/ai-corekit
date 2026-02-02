### What is Caddy?

Caddy is a modern, powerful web server written in Go that serves as the **automatic HTTPS reverse proxy** for all AI CoreKit services. It handles SSL certificate provisioning, renewal, and routing - completely automatically with zero manual configuration required.

Caddy automatically obtains, renews, and manages SSL/TLS certificates from Let's Encrypt using the ACME protocol, ensuring all your services are secured with HTTPS by default. Unlike traditional web servers like Nginx or Apache, Caddy requires no manual certificate management - it just works.

### Features

- **Automatic HTTPS:** Zero-configuration SSL certificates from Let's Encrypt with automatic 90-day renewal
- **Reverse Proxy:** Routes traffic to backend services with load balancing, health checks, and failover
- **WebSocket Support:** Full support for real-time connections (Jitsi, LiveKit, n8n workflows)
- **Basic Authentication:** Password-protect services with bcrypt-hashed credentials
- **Streaming Support:** Optimized for AI model APIs with `flush_interval -1` for streaming responses
- **Wildcard DNS:** Single configuration serves all `*.yourdomain.com` subdomains
- **Zero Downtime:** Graceful config reloads without dropping connections
- **Performance:** Written in Go for high throughput and low resource usage

### Initial Setup

**Caddy in AI CoreKit is fully automated - no manual setup required!**

When you run the installer, Caddy automatically:

1. **Configures all service routes** from your `.env` file
2. **Obtains SSL certificates** for all enabled services
3. **Sets up reverse proxies** with optimal headers and timeouts
4. **Enables automatic renewal** for certificates (every 60 days)

**Access Caddy:**
- Caddy runs in the background - you never interact with it directly
- All services are automatically available at `https://[service].yourdomain.com`
- Certificate status visible in logs: `docker logs caddy | grep certificate`

**Caddyfile Location:**
```bash
# View Caddy configuration
cat Caddyfile

# Reload after manual changes
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### How Caddy Works in AI CoreKit

**1. Automatic SSL Certificates:**
Caddy communicates with Let's Encrypt via the ACME protocol, automatically obtaining certificates during the first request to each domain. Certificates are stored in Docker volumes and renewed automatically before expiration.

**2. Reverse Proxy Routing:**
Each service gets its own subdomain configuration in the `Caddyfile`:

```caddyfile
# Example: n8n service
{$N8N_HOSTNAME} {
    reverse_proxy n8n:5678
}

# Example: Service with basic auth
{$VAULTWARDEN_HOSTNAME} {
    basic_auth {
        {$VAULTWARDEN_USERNAME} {$VAULTWARDEN_PASSWORD_HASH}
    }
    reverse_proxy vaultwarden:80
}

# Example: AI service with streaming
{$OLLAMA_HOSTNAME} {
    reverse_proxy ollama:11434 {
        flush_interval -1  # Enable streaming responses
    }
}
```

**3. Environment Variables:**
All service hostnames are configured in `.env`:

```bash
# Service hostnames
N8N_HOSTNAME=n8n.yourdomain.com
VAULTWARDEN_HOSTNAME=vault.yourdomain.com
OLLAMA_HOSTNAME=ollama.yourdomain.com

# Basic auth (optional)
VAULTWARDEN_USERNAME=admin
VAULTWARDEN_PASSWORD=your-secure-password
VAULTWARDEN_PASSWORD_HASH=hashed-with-bcrypt
```

### n8n Integration Setup

**Use Case:** Monitor SSL certificate expiration, test service availability, or automate Caddy configuration changes.

**Caddy has no native n8n node**, but you can interact with services through Caddy or manage it via Docker commands.

#### Example 1: Check SSL Certificate Expiration

Monitor when certificates need renewal (Caddy does this automatically, but you may want alerts):

```javascript
// 1. Trigger: Schedule (daily at 9 AM)

// 2. Execute Command Node
// Command: docker
// Arguments: exec,caddy,caddy,list-certificates,--json

// 3. Code Node: Parse certificate expiration
const certificates = JSON.parse($json.stdout);
const expiringS soon = [];
const warningDays = 30; // Alert 30 days before expiration

for (const cert of certificates) {
  const expiryDate = new Date(cert.not_after);
  const daysUntilExpiry = Math.floor((expiryDate - new Date()) / (1000 * 60 * 60 * 24));
  
  if (daysUntilExpiry < warningDays) {
    expiringSoon.push({
      domain: cert.names[0],
      expiresIn: daysUntilExpiry,
      expiryDate: expiryDate.toISOString()
    });
  }
}

return expiringSoon.length > 0 ? expiringSoon : [];

// 4. IF Node: Check if any certificates expiring soon
// Condition: {{ $json.length > 0 }}

// 5. Send Email / Slack Notification
// Subject: SSL Certificates Expiring Soon
// Body: {{ $json }}
```

#### Example 2: Test Service Availability via Caddy

Verify that services are accessible through the reverse proxy:

```javascript
// 1. Trigger: Schedule (every 5 minutes)

// 2. HTTP Request Node
// Method: GET
// URL: https://n8n.yourdomain.com/healthz
// Authentication: None
// Options:
//   - Timeout: 5000ms
//   - Follow Redirects: true
//   - Ignore SSL Issues: false

// 3. Code Node: Check response
const services = [
  'https://n8n.yourdomain.com/healthz',
  'https://vault.yourdomain.com',
  'https://ollama.yourdomain.com'
];

const results = [];
for (const serviceUrl of services) {
  try {
    const response = await this.helpers.httpRequest({
      method: 'GET',
      url: serviceUrl,
      timeout: 5000
    });
    results.push({
      service: serviceUrl,
      status: 'online',
      statusCode: response.statusCode
    });
  } catch (error) {
    results.push({
      service: serviceUrl,
      status: 'offline',
      error: error.message
    });
  }
}

return results;

// 4. Filter Node: Get offline services
// Condition: {{ $json.status === "offline" }}

// 5. Send Alert if any services offline
```

#### Example 3: Reload Caddy After Configuration Change

Automate Caddy config reload when you update the Caddyfile:

```javascript
// 1. Trigger: Webhook (called after config changes)

// 2. Execute Command Node
// Command: docker
// Arguments: exec,caddy,caddy,reload,--config,/etc/caddy/Caddyfile

// 3. Code Node: Check reload success
const output = $json.stdout || '';
const error = $json.stderr || '';

if (error.includes('error') || $json.exitCode !== 0) {
  return [{
    success: false,
    error: error,
    output: output
  }];
}

return [{
  success: true,
  message: 'Caddy reloaded successfully',
  output: output
}];

// 4. Send Notification
// Success: "Caddy configuration reloaded"
// Failure: "Caddy reload failed: {{ $json.error }}"
```

#### Example 4: Add New Service to Caddy (Advanced)

Automatically add a new service route to the Caddyfile and reload:

```javascript
// 1. Trigger: Manual / Webhook with service details

// 2. Code Node: Generate Caddyfile entry
const serviceName = $input.item.json.serviceName; // e.g., "myapp"
const hostname = $input.item.json.hostname; // e.g., "myapp.yourdomain.com"
const port = $input.item.json.port; // e.g., 8080
const requiresAuth = $input.item.json.requiresAuth || false;

let caddyConfig = `\n# ${serviceName}\n`;
caddyConfig += `${hostname} {\n`;

if (requiresAuth) {
  caddyConfig += `    basic_auth {\n`;
  caddyConfig += `        {$${serviceName.toUpperCase()}_USERNAME} {$${serviceName.toUpperCase()}_PASSWORD_HASH}\n`;
  caddyConfig += `    }\n`;
}

caddyConfig += `    reverse_proxy ${serviceName}:${port}\n`;
caddyConfig += `}\n`;

return [{ caddyConfig }];

// 3. Execute Command: Append to Caddyfile
// Command: bash
// Arguments: -c,"echo '{{ $json.caddyConfig }}' >> /path/to/Caddyfile"

// 4. Execute Command: Reload Caddy
// Command: docker
// Arguments: exec,caddy,caddy,reload,--config,/etc/caddy/Caddyfile

// 5. Notify admin of new service added
```

**Internal Caddy URL:** Not applicable - Caddy is the entry point, not called internally.

### Troubleshooting

**Issue 1: SSL Certificate Not Issued**

```bash
# Check Caddy logs for certificate errors
docker logs caddy | grep -i certificate

# Common error: "CAA record prevents issuance"
# Solution: Check DNS CAA records allow Let's Encrypt
dig CAA yourdomain.com

# Common error: "Rate limit exceeded"
# Solution: Let's Encrypt has rate limits (50 certs/week per domain)
# Wait or use staging environment for testing

# Common error: "Challenge failed"
# Solution: Ensure ports 80 and 443 are open and DNS is correct
curl -I http://yourdomain.com
curl -I https://yourdomain.com
```

**Solution:**
- **Verify DNS:** Wildcard A record `*.yourdomain.com` points to your server IP
- **Check Firewall:** Ports 80 (HTTP) and 443 (HTTPS) must be open
- **Staging Mode:** Test with Let's Encrypt staging to avoid rate limits
- **Force Renewal:** `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

**Issue 2: 502 Bad Gateway**

```bash
# Check if backend service is running
docker ps | grep [service-name]

# Check Caddy logs for proxy errors
docker logs caddy --tail 100 | grep 502

# Test backend directly
curl http://localhost:[service-port]

# Common cause: Service hasn't fully started yet
docker logs [service-name] --tail 50
```

**Solution:**
- Wait 2-3 minutes for services to start (especially ComfyUI, Supabase, Cal.com)
- Verify service is listening on correct port in `docker-compose.yml`
- Check service logs for startup errors
- Restart specific service: `docker compose restart [service-name]`

**Issue 3: Certificate Warnings in Browser**

```bash
# Check certificate validity
docker exec caddy caddy list-certificates

# Should show valid certificates for your domains
# If showing self-signed certs, wait 5-10 minutes

# Force certificate renewal
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

**Solution:**
- **Temporary:** Caddy may briefly use a self-signed certificate while requesting one from Let's Encrypt - this usually resolves within 1-24 hours
- **Clear Browser Cache:** Try incognito/private browsing window
- **Check Email:** Let's Encrypt sends notifications if certificate issuance fails
- **Verify Hostname:** Ensure `HOSTNAME` in `.env` matches your actual domain

**Issue 4: WebSocket Connections Failing**

```bash
# WebSockets require specific headers - check Caddy logs
docker logs caddy | grep -i websocket

# Test WebSocket connection
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  https://yourservice.yourdomain.com
```

**Solution:**
- Caddy supports WebSockets by default via `reverse_proxy` directive
- No special configuration needed in most cases
- For services like Jitsi or LiveKit, ensure UDP ports are also open
- Check service-specific requirements (some need additional headers)

**Issue 5: Service Not Accessible After Adding to Caddyfile**

```bash
# Verify Caddyfile syntax
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Check for syntax errors in output
# Reload Caddy to apply changes
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Monitor reload
docker logs caddy --follow
```

**Solution:**
- Always validate Caddyfile syntax before reloading
- Check that environment variables exist in `.env` file
- Use exact format: `{$VARIABLE_NAME}` for environment variables
- Restart Caddy if reload fails: `docker compose restart caddy`
- Verify new route works: `curl -I https://newservice.yourdomain.com`

### Resources

- **Official Documentation:** https://caddyserver.com/docs/
- **Reverse Proxy Guide:** https://caddyserver.com/docs/quick-starts/reverse-proxy
- **Automatic HTTPS:** https://caddyserver.com/docs/automatic-https
- **Caddyfile Syntax:** https://caddyserver.com/docs/caddyfile
- **JSON Config API:** https://caddyserver.com/docs/api
- **GitHub:** https://github.com/caddyserver/caddy
- **Community Forum:** https://caddy.community/
- **Let's Encrypt Rate Limits:** https://letsencrypt.org/docs/rate-limits/
- **ACME Protocol:** https://caddyserver.com/docs/automatic-https#acme-protocol
- **Docker Image:** https://hub.docker.com/_/caddy

### Best Practices

**Security:**
- Caddy automatically enables HTTPS - never disable it in production
- Use strong bcrypt password hashes for basic auth (cost factor 14+)
- Rotate basic auth passwords quarterly
- Monitor certificate expiration (though Caddy auto-renews)
- Keep Caddy updated: `docker compose pull caddy && docker compose up -d caddy`

**Performance:**
- Use `flush_interval -1` for AI streaming responses (Ollama, OpenAI proxies)
- Enable compression for text responses (Caddy does this by default)
- For high-traffic services, consider `load_balancing` directive
- Monitor container stats: `docker stats caddy --no-stream`

**Configuration Management:**
- Always use environment variables for hostnames (`.env` file)
- Keep Caddyfile in version control (Git)
- Test changes with `caddy validate` before reloading
- Document custom routes in comments within Caddyfile
- Use consistent naming: `{$SERVICE_HOSTNAME}` pattern

**Monitoring:**
```bash
# Check Caddy health
docker ps | grep caddy  # Should show "Up" status

# View active connections
docker exec caddy caddy list-certificates | jq

# Monitor logs in real-time
docker logs caddy --follow --tail 100

# Check certificate expiration
docker exec caddy caddy list-certificates | grep -i "not after"

# Resource usage
docker stats caddy --no-stream
# Typical: 50-150MB RAM, <5% CPU
```

**Backup:**
```bash
# Backup SSL certificates (stored in Docker volume)
docker run --rm -v caddy_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/caddy-certs-backup.tar.gz /data

# Backup Caddyfile
cp Caddyfile Caddyfile.backup.$(date +%Y%m%d)
```

**Common Patterns:**

**Pattern 1: Service with Authentication**
```caddyfile
{$SERVICE_HOSTNAME} {
    basic_auth {
        {$SERVICE_USERNAME} {$SERVICE_PASSWORD_HASH}
    }
    reverse_proxy service:port
}
```

**Pattern 2: AI Service with Streaming**
```caddyfile
{$AI_SERVICE_HOSTNAME} {
    reverse_proxy ai-service:port {
        flush_interval -1
        header_up X-Real-IP {remote}
    }
}
```

**Pattern 3: WebSocket Service**
```caddyfile
{$WS_SERVICE_HOSTNAME} {
    reverse_proxy ws-service:port
    # WebSockets work automatically, no special config needed
}
```

**Pattern 4: Static Site with Caching**
```caddyfile
static.yourdomain.com {
    root * /var/www/static
    file_server
    encode gzip
    header Cache-Control "max-age=31536000"
}
```
