# Add this section to README.md after the "Quick Start" section

## 🔒 Secure Access with Cloudflare Tunnel (Optional)

Cloudflare Tunnel provides zero-trust access to your services without exposing any ports on your server. All traffic is routed through Cloudflare's secure network, providing DDoS protection and hiding your server's IP address.

### ⚠️ Important Architecture: Independent Tunnel Services
Optional deployment of  **web + ssh** Cloudflare Tunnel services:

1. **Web Services Tunnel** (`cloudflared-web`): Routes web traffic to your applications
2. **SSH Management Tunnel** (`cloudflared-ssh`): Provides secure SSH access for server administration

**Key Architectural Points:**
- **Separate tunnels required**: You must create TWO different tunnels in your Cloudflare dashboard
- **Independent operation**: Each tunnel can be started/stopped/managed separately  
- **Different network modes**: Web tunnel uses Docker network, SSH tunnel uses host network
- **Complete port closure**: Both tunnels allow closing ALL server ports (22, 80, 443)
- **Bypasses Caddy**: Direct service connection means you lose Caddy's auth features
- **Enhanced security**: Management traffic isolated from user traffic

### Benefits
- **Complete port closure** - ALL ports (22, 80, 443) can be closed on your firewall
- **Independent tunnel services** - Web and SSH traffic through separate, isolated tunnels
- **DDoS protection** - Built-in Cloudflare protection for all services
- **IP hiding** - Your server's real IP is never exposed
- **Zero-trust security** - Optional Cloudflare Access integration
- **Management isolation** - SSH access separated from user web traffic
- **High availability** - Independent restart and monitoring for each tunnel
- **No public IP required** - Works on private networks and behind NAT

### Setup Instructions

#### 1. Create TWO Separate Cloudflare Tunnels

**Important**: You need to create **two independent tunnels** in your Cloudflare dashboard.

##### Web Services Tunnel (Required)
1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** connector
5. Name your tunnel: **"ai-corekit-web"**
6. Copy the tunnel token (save as `CLOUDFLARE_TUNNEL_TOKEN` in your .env)

##### SSH Management Tunnel (Highly Recommended)
1. In the same dashboard, click **Create a tunnel** again
2. Choose **Cloudflared** connector  
3. Name your tunnel: **"ai-corekit-ssh"**
4. Copy this tunnel token (save as `CLOUDFLARE_SSH_TUNNEL_TOKEN` in your .env)


### 2. Configure Public Hostnames

#### Web Services Configuration
In your web tunnel configuration, add public hostnames for services you want to expose:

| Service | Public Hostname | Service URL | Notes |
|---------|----------------|-------------|-------|
| **n8n** | n8n.yourdomain.com | `http://n8n:5678` | Workflow automation |
| **Flowise** | flowise.yourdomain.com | `http://flowise:3001` | LangChain UI |
| **Dify** | dify.yourdomain.com | `http://nginx:80` | AI application platform |
| **Open WebUI** | webui.yourdomain.com | `http://open-webui:8080` | Chat interface |
| **Langfuse** | langfuse.yourdomain.com | `http://langfuse-web:3000` | LLM observability |
| **Supabase** | supabase.yourdomain.com | `http://kong:8000` | Backend as a Service |
| **Grafana** | grafana.yourdomain.com | `http://grafana:3000` | Metrics dashboard (⚠️ No auth) |
| **Prometheus** | prometheus.yourdomain.com | `http://prometheus:9090` | Metrics collection (⚠️ No auth) |
| **Portainer** | portainer.yourdomain.com | `http://portainer:9000` | Docker management |
| **Letta** | letta.yourdomain.com | `http://letta:8283` | Memory management |
| **Weaviate** | weaviate.yourdomain.com | `http://weaviate:8080` | Vector database |
| **Qdrant** | qdrant.yourdomain.com | `http://qdrant:6333` | Vector database |
| **ComfyUI** | comfyui.yourdomain.com | `http://comfyui:8188` | Image generation (⚠️ No auth) |
| **Neo4j** | neo4j.yourdomain.com | `http://neo4j:7474` | Graph database |
| **SearXNG** | searxng.yourdomain.com | `http://searxng:8080` | Private search (⚠️ No auth) |



**⚠️ Security Warning:** Services marked with "No auth" normally have basic authentication through Caddy. When using Cloudflare Tunnel, you should:
- Enable [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/) for these services, OR
- Keep them internal only (don't create public hostnames for them)

#### SSH Management Configuration  
In your **SSH tunnel** configuration, add TCP service for server administration:

| Service | Public Hostname | Service URL | Notes |
|---------|----------------|-------------|-------|
| **SSH** | ssh.yourdomain.com | `tcp://localhost:22` | Server management access |

**Important**: This SSH tunnel configuration must be done manually in your Cloudflare dashboard - it's not automated by the installer.

#### 3. DNS Configuration

When you create public hostnames in the tunnel configuration, Cloudflare automatically creates the necessary DNS records. These will appear in your DNS dashboard as CNAME records pointing to the tunnel, with **Proxy status ON** (orange cloud).

**Note:** If DNS records aren't created automatically:
1. Go to your domain's DNS settings in Cloudflare
2. Add CNAME records manually:
   - **Name**: Service subdomain (e.g., `n8n`)
   - **Target**: Your tunnel ID (shown in tunnel dashboard)
   - **Proxy status**: ON (orange cloud)

#### 4. Install with Tunnel Support

1. Run the n8n-installer as normal:
   ```bash
   sudo bash ./scripts/install.sh
   ```
2. When prompted for **Cloudflare Tunnel Token**, paste your token
3. In the Service Selection Wizard, select **Cloudflare Tunnel** to enable the service
4. Complete the rest of the installation

Note: Providing the token alone does not auto-enable the tunnel; you must enable the "cloudflare-tunnel" profile in the wizard (or add it to `COMPOSE_PROFILES`).

#### SSH Management Tunnel Configuration
In your **SSH tunnel** (ai-corekit-ssh) configuration:

- **Service Type**: TCP
- **Public hostname**: `ssh.yourdomain.com` 
- **Service URL**: `tcp://localhost:22`

**Critical**: This SSH tunnel runs with host networking mode and connects directly to your server's SSH daemon on port 22. Once this tunnel is working, you can completely close port 22 on your firewall.


**⚠️ Emergency Recovery Plan**: Always ensure you have alternative access (VPS console, emergency recovery) before closing port 22!

#### 5. Secure Your VPS (Recommended)

#### Test SSH Management Access (If Enabled)
```bash
# Test SSH through the management tunnel
ssh username@ssh.yourdomain.com

# Verify you can perform administrative tasks
ssh username@ssh.yourdomain.com "sudo systemctl status ssh"

# Test both tunnels independently  
docker compose ps | grep cloudflared
# Should show both cloudflared-web and cloudflared-ssh if both enabled
```

### 6. Progressive Security Lockdown 

Once you've confirmed your independent tunnel services work:

```bash
# Close web ports (UFW example)
sudo ufw delete allow 80/tcp
sudo ufw delete allow 443/tcp
sudo ufw delete allow 7687/tcp
sudo ufw reload

# Verify only SSH remains open
sudo ufw status
```

Close SSH Port (After SSH Tunnel Confirmed Working)
```bash
# CRITICAL: Only do this AFTER confirming SSH tunnel works!
# Test SSH tunnel access first: ssh username@ssh.yourdomain.com

# Close SSH port 22 completely
sudo ufw delete allow 22/tcp
sudo ufw reload

# Verify SSH tunnel access still works
ssh username@ssh.yourdomain.com
```

Zero-Port Security State  
```bash
# Verify your final security posture
sudo ufw status numbered

# Should show NO open ports:
# - SSH access: ONLY through Cloudflare SSH tunnel (ssh.yourdomain.com)
# - Web access: ONLY through Cloudflare web tunnel (*.yourdomain.com)
# - Complete elimination of direct server access
```

### Choosing Between Caddy and Cloudflare Tunnel

You have two options for accessing your services:

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Caddy (Traditional)** | • Caddy auth features work<br>• Simple subdomain setup<br>• No Cloudflare account needed | • Requires open ports<br>• Server IP exposed<br>• No DDoS protection | Local/trusted networks |
| **Cloudflare Tunnel** | • No open ports<br>• DDoS protection<br>• IP hiding<br>• Global CDN | • Requires Cloudflare account<br>• Loses Caddy auth<br>• Each service needs configuration | Internet-facing servers |

### Adding Cloudflare Access (Optional but Recommended)

For services that lose Caddy's basic auth protection, you can add Cloudflare Access:

1. In Cloudflare Zero Trust → Access → Applications
2. Click **Add an application**
3. Select **Self-hosted**
4. Configure:
   - **Application name**: e.g., "Prometheus"
   - **Application domain**: `prometheus.yourdomain.com`
   - **Identity providers**: Configure your preferred auth method
5. Create access policies (who can access the service)

### 🛡️ Advanced Security with WAF Rules

Cloudflare's Web Application Firewall (WAF) allows you to create sophisticated security rules. This is especially important for **n8n webhooks** which need to be publicly accessible but should be protected from abuse.

#### Creating IP Allow Lists

1. **Go to Cloudflare Dashboard** → **Manage Account** → **Configurations** → **Lists**
2. Click **Create new list**
3. Configure:
   - **List name**: `approved_IP_addresses`
   - **Content type**: IP Address
4. Add IP addresses:
   ```
   # Example entries:
   1.2.3.4         # Office IP
   5.6.7.0/24      # Partner network
   10.0.0.0/8      # Internal network
   ```

#### Protecting n8n Webhooks with WAF Rules

n8n webhooks need special consideration because they must be publicly accessible for external services to trigger workflows, but you want to limit who can access them.

1. **Go to your domain** → **Security** → **WAF** → **Custom rules**
2. Click **Create rule**
3. **Rule name**: "Protect n8n webhooks"
4. **Expression Builder** or use **Edit expression**:

**Example 1: Block all except approved IPs for entire domain**
```
(not ip.src in $approved_IP_addresses and http.host contains "yourdomain.com")
```
- **Action**: Block
- **Description**: Blocks all traffic except from approved IPs

**Example 2: Protect n8n but allow specific webhook paths**
```
(http.host eq "n8n.yourdomain.com" and not ip.src in $approved_IP_addresses and not http.request.uri.path contains "/webhook/")
```
- **Action**: Block
- **Description**: Protects n8n UI but allows webhook endpoints

**Example 3: Allow webhooks from specific services only**
```
(http.host eq "n8n.yourdomain.com" and http.request.uri.path contains "/webhook/" and not ip.src in $webhook_allowed_IPs)
```
- **Action**: Block
- **Description**: Webhooks only accessible from specific service IPs

**Example 4: Rate limiting for webhook endpoints**
```
(http.host eq "n8n.yourdomain.com" and http.request.uri.path contains "/webhook/")
```
- **Action**: Managed Challenge
- **Description**: Add CAPTCHA if suspicious activity detected

#### Common Security Rule Patterns

| Use Case | Expression | Action | Notes |
|----------|------------|--------|-------|
| **Protect webhooks (CRITICAL)** | `(http.request.uri.path contains "/webhook" and not ip.src in $webhook_service_IPs)` | Block | Webhooks have NO auth - must restrict! |
| **Protect all services** | `(not ip.src in $approved_IP_addresses)` | Block | Strictest - only approved IPs |
| **Geographic restrictions** | `(ip.geoip.country ne "US" and ip.geoip.country ne "GB")` | Block | Allow only specific countries |
| **Block bots on sensitive services** | `(http.host in {"prometheus.yourdomain.com" "grafana.yourdomain.com"} and cf.bot_management.score lt 30)` | Block | Blocks likely bots |
| **Moderate UI protection** | `(not http.request.uri.path contains "/webhook" and cf.threat_score gt 30)` | Managed Challenge | UI has login, less strict |
| **Rate limit webhooks** | `(http.request.uri.path contains "/webhook/")` | Rate Limit (10 req/min) | Additional webhook protection |
| **Separate webhook types** | `(http.request.uri.path contains "/webhook/stripe" and not ip.src in $stripe_IPs)` | Block | Service-specific webhook protection |

#### Service-Specific Security Strategies

**n8n (CRITICAL - Webhooks are the highest risk):**

⚠️ **Important**: n8n webhooks have NO built-in authentication and can trigger powerful workflows. They need STRONGER protection than the UI (which has login protection).

```
# Rule 1: STRICT webhook protection - only allow from known service IPs
(http.host eq "n8n.yourdomain.com" and 
 (http.request.uri.path contains "/webhook/" or 
  http.request.uri.path contains "/webhook-test/") and 
 not ip.src in $webhook_service_IPs)
Action: Block
Note: webhook_service_IPs should ONLY contain verified service IPs (Stripe, GitHub, etc.)

# Rule 2: Moderate UI protection - has login screen protection
(http.host eq "n8n.yourdomain.com" and 
 not http.request.uri.path contains "/webhook" and
 cf.threat_score gt 30)
Action: Managed Challenge
Note: UI has login protection, so can be less strict than webhooks
```

**Why this approach:**
- **Webhooks = No Auth** = Need IP allowlisting
- **UI = Has Login** = Can use lighter protection
- **Never expose webhooks broadly** - They can trigger database changes, send emails, call APIs

**Flowise:**
```
# API endpoints from approved IPs, public chatbot access
(http.host eq "flowise.yourdomain.com" and 
 http.request.uri.path contains "/api/" and 
 not ip.src in $api_allowed_IPs)
Action: Block
```

**Monitoring Services (Grafana/Prometheus):**
```
# Strict IP allowlist for monitoring
(http.host in {"grafana.yourdomain.com" "prometheus.yourdomain.com"} and 
 not ip.src in $monitoring_team_IPs)
Action: Block
```

#### Managing Multiple IP Lists

Create separate lists for different access levels:

| List Name | Purpose | Example IPs |
|-----------|---------|-------------|
| `approved_IP_addresses` | General admin access | Office IPs, VPN endpoints |
| `webhook_allowed_IPs` | Services that call webhooks | Stripe, GitHub, Slack servers |
| `monitoring_team_IPs` | DevOps team access | Team member home IPs |
| `api_consumer_IPs` | Third-party API access | Partner service IPs |

#### Webhook Security Best Practices

⚠️ **CRITICAL**: Webhooks are your biggest security risk! Unlike the UI which has login protection, webhooks have NO authentication and can directly execute workflows that might:
- Access your database
- Send emails/messages  
- Call external APIs with your credentials
- Modify data
- Trigger financial transactions

**Essential Protection Steps:**

1. **Never expose webhooks to the entire internet**
   - Always use IP allowlists for webhook endpoints
   - Only add IPs of services that legitimately need webhook access

2. **Create strict webhook IP allowlists**:
   ```
   $webhook_service_IPs should only contain:
   - GitHub webhook IPs: 192.30.252.0/22, 185.199.108.0/22, etc.
   - Stripe webhook IPs: 3.18.12.63, 3.130.192.231, etc.
   - Your specific partner/integration IPs
   - Your monitoring service IPs
   ```

3. **Use webhook-specific paths** in n8n:
   - Production: `/webhook/prod-[unique-id]`
   - Testing: `/webhook-test/test-[unique-id]`
   - Never use simple, guessable webhook URLs

4. **Implement webhook signatures** in n8n workflows:
   - Always verify HMAC signatures from services like GitHub/Stripe
   - Add header validation in your n8n workflows
   - Reject requests without proper signatures

5. **Create separate rules for different webhook types**:
   ```
   # Stripe webhooks - only from Stripe's published IPs
   (http.host eq "n8n.yourdomain.com" and 
    http.request.uri.path contains "/webhook/stripe" and 
    not ip.src in $stripe_webhook_IPs)
   Action: Block
   
   # Internal webhooks - only from your infrastructure
   (http.host eq "n8n.yourdomain.com" and 
    http.request.uri.path contains "/webhook/internal" and 
    not ip.src in $internal_system_IPs)
   Action: Block
   ```

6. **Add rate limiting as additional protection**:
   ```
   # Rate limit even approved webhook IPs
   (http.host eq "n8n.yourdomain.com" and 
    http.request.uri.path contains "/webhook/")
   Action: Rate Limit (10 requests per minute)
   ```

7. **Monitor webhook access closely**:
   - Check Cloudflare Analytics → Security → Events regularly
   - Set up alerts for blocked webhook attempts
   - Review which IPs are trying to access your webhooks
   - Investigate any unexpected webhook triggers

#### Testing Your Rules

1. **Use Cloudflare's Trace Tool**:
   - Go to **Account Home** → **Trace**
   - Enter test URLs and IPs
   - See which rules would trigger

2. **Start with Log mode**:
   - Set initial action to "Log" instead of "Block"
   - Monitor for false positives
   - Switch to "Block" after verification

3. **Test webhook access**:
   ```bash
   # Test from allowed IP
   curl -X POST https://n8n.yourdomain.com/webhook/test-webhook
   
   # Test from non-allowed IP (should be blocked)
   curl -X POST https://n8n.yourdomain.com/admin
   ```

#### Important Considerations

- **Webhook IPs can change**: Services like GitHub, Stripe publish their webhook IP ranges - add these to your lists
- **Development vs Production**: Consider separate rules for development environments
- **Bypass for emergencies**: Keep a "break glass" rule you can quickly enable for emergency access
- **API rate limits**: Implement rate limiting on webhook endpoints to prevent abuse
- **Logging**: Enable logging on security rules to track access patterns

### Verifying Tunnel Connection

Check if the tunnel is running:
```bash
docker logs cloudflared --tail 20
```

You should see:
```
INF Registered tunnel connection connIndex=0
INF Updated to new configuration
```

### Troubleshooting

**"Too many redirects" error (Web tunnel):**
- Make sure you're pointing to the service directly (e.g., `http://n8n:5678`), NOT to Caddy
- Verify the service URL uses HTTP, not HTTPS
- Check that DNS records have Proxy status ON (orange cloud)

**"Server not found" error:**
- Verify DNS records exist for your subdomain
- Check that the correct tunnel is healthy in Cloudflare dashboard
- Ensure the correct tunnel token is in `.env` (`CLOUDFLARE_TUNNEL_TOKEN` for web, `CLOUDFLARE_SSH_TUNNEL_TOKEN` for SSH)

**Web services not accessible:**
- Verify web tunnel status: `docker compose ps | grep cloudflared-web`
- Check web tunnel logs: `docker compose logs cloudflared-web`
- Ensure the service is running: `docker compose ps`
- Verify service name and port in web tunnel configuration

**SSH tunnel not working:**
- Verify SSH tunnel status: `docker compose ps | grep cloudflared-ssh`
- Check SSH tunnel logs: `docker compose logs cloudflared-ssh`
- Ensure SSH daemon is running: `sudo systemctl status ssh`
- Test local SSH first: `ssh localhost`
- Verify SSH tunnel configuration points to `tcp://localhost:22`

### Important Notes

1. **Service-to-service communication** remains unchanged - containers still communicate directly via Docker network
2. **Ollama** is not included in the tunnel setup as it's typically used internally only
3. **Database ports** (PostgreSQL, Redis) should never be exposed through the tunnel
4. Consider using **Cloudflare Access** for any services that need authentication

### What is Cloudflare Tunnel?

Cloudflare Tunnel (formerly Argo Tunnel) creates a secure, encrypted connection between your services and Cloudflare's global network **without exposing your server to the public internet**. No open ports, no port forwarding, no firewall changes required.

The lightweight `cloudflared` daemon runs in your infrastructure and establishes an **outbound-only connection** to Cloudflare. Your server's IP address remains completely hidden, protecting you from direct attacks, DDoS, and reconnaissance. All traffic is routed through Cloudflare's Zero Trust platform with built-in DDoS mitigation and identity-based access control.

**Perfect for:** Bypassing restrictive firewalls, securing self-hosted services, protecting development environments, or connecting IoT devices without static IPs.

### Features

- **Zero Firewall Configuration:** No open ports 80/443 required - only outbound HTTPS connections (port 443)
- **Hidden Origin IP:** Your server's public IP remains completely private - prevents direct attacks
- **Zero Trust Security:** Integrate with Cloudflare Access for email-based authentication, OTP, or SSO
- **DDoS Protection:** Automatic protection via Cloudflare's global network (200+ data centers)
- **Easy Docker Integration:** Run as a lightweight container alongside your services
- **WebSocket Support:** Full support for real-time connections (WebSockets, gRPC, etc.)
- **Free Tier Available:** Up to 50 users with Cloudflare Zero Trust Free plan
- **No VPN Required:** Direct access to internal services without complex VPN setup

### When to Use Cloudflare Tunnel

**✅ Use Cloudflare Tunnel when:**
- Your VPS provider blocks incoming ports (common with some cloud providers)
- You want to hide your server's public IP for security
- You need Zero Trust authentication (email OTP, SSO, etc.)
- You're behind a restrictive firewall or CGNAT
- You want DDoS protection included by default
- You're running services on a home network without static IP
- You want to bypass port forwarding on your router

**❌ Don't use Cloudflare Tunnel when:**
- You're already using Caddy with Let's Encrypt (Caddy provides SSL automatically)
- You want full control over SSL certificates (Cloudflare terminates SSL at their edge)
- You need non-HTTP protocols without Cloudflare's WARP client
- You want to minimize latency (adds ~20-50ms via Cloudflare routing)
- You're handling sensitive data that cannot pass through third-party networks

**Note:** In AI CoreKit, Cloudflare Tunnel is **optional**. The default setup uses Caddy for automatic HTTPS, which works perfectly for most use cases. Use Cloudflare Tunnel only if you have specific requirements like hiding your IP or need Zero Trust authentication.

### Initial Setup

Cloudflare Tunnel requires a Cloudflare account and a domain managed by Cloudflare.

#### Prerequisites

1. **Cloudflare Account:** Sign up at https://dash.cloudflare.com
2. **Domain on Cloudflare:** Add your domain and change nameservers to Cloudflare
3. **Zero Trust Account:** Enable at https://one.dash.cloudflare.com (free tier available)

#### Step 1: Create Tunnel in Cloudflare Dashboard

1. **Navigate to Zero Trust Dashboard:**
   - Go to https://one.dash.cloudflare.com
   - Click **Networks** → **Tunnels**
   - Click **Create a tunnel**

2. **Select Connector Type:**
   - Choose **Cloudflared** (not WARP Connector)
   - Click **Next**

3. **Name Your Tunnel:**
   - Enter a name (e.g., `ai-corekit-prod`)
   - Click **Save tunnel**

4. **Get Tunnel Token:**
   - Cloudflare will display a Docker command with your tunnel token
   - Copy the token from the command (it starts with `eyJ...`)
   - **Save this token** - you'll need it for Docker setup

#### Step 2: Configure Tunnel in Docker

Add Cloudflare Tunnel to your `docker-compose.yml`:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-tunnel
    restart: unless-stopped
    environment:
      - TUNNEL_TOKEN=eyJhIjoiNTU2MDgw...  # Your token from Step 1
    command: tunnel run
    networks:
      - default

networks:
  default:
    name: ${PROJECT_NAME:-localai}_default
    external: true
```

**Start the tunnel:**
```bash
docker compose up -d cloudflared
```

**Verify it's running:**
```bash
# Check container status
docker ps | grep cloudflared

# View logs
docker logs cloudflared-tunnel

# Should see: "Connection established" and "Registered tunnel"
```

#### Step 3: Add Public Hostnames

Back in the Cloudflare Zero Trust Dashboard:

1. **Click on your tunnel name** in the Tunnels list
2. **Go to Public Hostname tab**
3. **Click Add a public hostname**

4. **Configure Service:**
   ```
   Subdomain: n8n
   Domain: yourdomain.com
   Type: HTTP
   URL: n8n:5678
   ```
   - If cloudflared is on the same Docker network, use container name (e.g., `n8n:5678`)
   - If different network, use `http://IP:PORT`

5. **Click Save hostname**

6. **Test Access:**
   - Visit `https://n8n.yourdomain.com`
   - DNS will automatically point to Cloudflare (CNAME record created)
   - Traffic routes: User → Cloudflare → Tunnel → n8n

#### Step 4: Add Zero Trust Authentication (Optional)

**Protect services with email-based OTP:**

1. **Create Access Application:**
   - Go to **Access** → **Applications**
   - Click **Add an application**
   - Select **Self-hosted**

2. **Configure Application:**
   ```
   Application name: n8n
   Session Duration: 24 hours
   Application domain: https://n8n.yourdomain.com
   ```

3. **Create Access Policy:**
   - Policy name: Email whitelist
   - Action: Allow
   - Configure rule: **Emails**
   - Enter allowed emails (e.g., `admin@yourcompany.com`)

4. **Save and Test:**
   - Visit `https://n8n.yourdomain.com`
   - You'll be redirected to Cloudflare Access login
   - Enter your email → receive OTP code → access granted

### n8n Integration Setup

**Cloudflare has no native n8n node**, but you can manage tunnels via the Cloudflare API using HTTP Request nodes.

**Cloudflare API Setup:**
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Create API Token with permissions:
   - **Zone.DNS** - Edit
   - **Account.Cloudflare Tunnel** - Edit
   - **Account.Access** - Edit
3. Save token for n8n credentials

#### Example 1: List All Tunnels

Monitor tunnel status and health:

```javascript
// 1. HTTP Request Node
// Method: GET
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel
// Authentication: Generic Credential Type
//   Header Auth:
//     Name: Authorization
//     Value: Bearer {{$env.CF_API_TOKEN}}

// 2. Code Node: Parse tunnel status
const tunnels = $json.result || [];
const tunnelStatus = [];

for (const tunnel of tunnels) {
  tunnelStatus.push({
    name: tunnel.name,
    id: tunnel.id,
    status: tunnel.status,
    created: tunnel.created_at,
    connections: tunnel.connections?.length || 0,
    healthy: tunnel.status === 'healthy'
  });
}

return tunnelStatus;

// 3. IF Node: Check if any tunnels down
// Condition: {{ $json.filter(t => !t.healthy).length > 0 }}

// 4. Send Alert if tunnels unhealthy
```

#### Example 2: Create New Tunnel via API

Automate tunnel creation for new services:

```javascript
// 1. Trigger: Manual / Webhook with service details

// 2. HTTP Request Node: Create Tunnel
// Method: POST
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel
// Authentication: Bearer Token (CF_API_TOKEN)
// Body (JSON):
{
  "name": "{{ $json.serviceName }}-tunnel",
  "config_src": "cloudflare"
}

// 3. Code Node: Extract tunnel ID and token
const tunnel = $json.result;
return [{
  tunnelId: tunnel.id,
  tunnelName: tunnel.name,
  tunnelToken: tunnel.token  // Use this to run cloudflared
}];

// 4. HTTP Request: Create DNS Record
// Method: POST
// URL: https://api.cloudflare.com/client/v4/zones/{{$env.CF_ZONE_ID}}/dns_records
// Body:
{
  "type": "CNAME",
  "name": "{{ $json.serviceName }}",
  "content": "{{ $json.tunnelId }}.cfargotunnel.com",
  "proxied": true
}

// 5. HTTP Request: Add Public Hostname
// Method: PUT
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$json.tunnelId}}/configurations
// Body:
{
  "config": {
    "ingress": [
      {
        "hostname": "{{ $json.serviceName }}.yourdomain.com",
        "service": "http://{{ $json.serviceName }}:{{ $json.port }}"
      },
      {
        "service": "http_status:404"
      }
    ]
  }
}

// 6. Notify admin with tunnel details
```

#### Example 3: Monitor Tunnel Health

Check if tunnels are connected and responsive:

```javascript
// 1. Trigger: Schedule (every 5 minutes)

// 2. HTTP Request: Get Tunnel Details
// Method: GET
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$env.TUNNEL_ID}}

// 3. Code Node: Check connection status
const tunnel = $json.result;
const connections = tunnel.connections || [];

const health = {
  tunnelName: tunnel.name,
  status: tunnel.status,
  totalConnections: connections.length,
  activeConnections: connections.filter(c => c.is_pending_reconnect === false).length,
  unhealthy: connections.filter(c => c.is_pending_reconnect).length,
  datacenters: connections.map(c => c.colo_name),
  uptime: connections.length > 0
};

return [health];

// 4. IF Node: Check if tunnel unhealthy
// Condition: {{ $json.unhealthy > 0 || $json.totalConnections === 0 }}

// 5. Send Slack/Email Alert
// Message: "Tunnel {{ $json.tunnelName }} is unhealthy! Active connections: {{ $json.activeConnections }}"
```

#### Example 4: Update Tunnel Configuration

Add or remove services from tunnel programmatically:

```javascript
// 1. Trigger: Webhook (when service added/removed)

// 2. HTTP Request: Get Current Config
// Method: GET
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$env.TUNNEL_ID}}/configurations

// 3. Code Node: Modify ingress rules
const currentConfig = $json.result.config;
const newService = $input.item.json;  // { hostname, service, port }

// Add new ingress rule (before the catch-all 404)
const ingressRules = currentConfig.ingress.slice(0, -1);  // Remove 404 rule
ingressRules.push({
  hostname: newService.hostname,
  service: `http://${newService.service}:${newService.port}`
});
ingressRules.push({ service: "http_status:404" });  // Re-add catch-all

return [{
  config: {
    ingress: ingressRules
  }
}];

// 4. HTTP Request: Update Tunnel Config
// Method: PUT
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$env.TUNNEL_ID}}/configurations
// Body: {{ $json.config }}

// 5. Notify success
```

**Internal Cloudflare Tunnel URL:** Not applicable - Tunnel is the entry point from external internet.

### Troubleshooting

**Issue 1: Tunnel Shows as "Inactive" or "Down"**

```bash
# Check cloudflared container status
docker ps | grep cloudflared

# If not running, check logs
docker logs cloudflared-tunnel

# Common error: "authentication failed"
# Solution: Verify TUNNEL_TOKEN is correct in docker-compose.yml

# Common error: "no route to host"
# Solution: Check Docker network configuration
docker network inspect ${PROJECT_NAME:-localai}_default

# Restart tunnel
docker compose restart cloudflared
```

**Solution:**
- Verify tunnel token is correct (starts with `eyJ`)
- Check Docker network exists and cloudflared is connected
- Ensure outbound HTTPS (port 443) is allowed on firewall
- Check Cloudflare dashboard shows tunnel as "Healthy"

**Issue 2: Services Not Accessible via Tunnel**

```bash
# Test service is reachable from cloudflared container
docker exec cloudflared-tunnel ping n8n

# Should get ping responses if on same network

# Test HTTP connectivity
docker exec cloudflared-tunnel curl http://n8n:5678

# Should get HTML response or redirect

# Check tunnel configuration in dashboard
# Verify hostname, service type (HTTP), and URL are correct
```

**Solution:**
- Ensure cloudflared and service are on the same Docker network
- Use container names (not localhost) for service URLs
- Verify service is actually running: `docker ps | grep n8n`
- Check Public Hostname configuration in Cloudflare dashboard
- Wait 1-2 minutes for configuration changes to propagate

**Issue 3: DNS Not Resolving**

```bash
# Check if CNAME record exists
nslookup n8n.yourdomain.com

# Should point to: xxxxx.cfargotunnel.com

# Check Cloudflare DNS dashboard
# Go to: dash.cloudflare.com → your domain → DNS

# Verify CNAME record:
# Type: CNAME
# Name: n8n
# Target: <tunnel-id>.cfargotunnel.com
# Proxied: Yes (orange cloud)
```

**Solution:**
- Cloudflare auto-creates CNAME records when you add Public Hostname
- If missing, manually create CNAME pointing to `<tunnel-id>.cfargotunnel.com`
- Ensure "Proxied" (orange cloud) is enabled
- DNS changes can take 1-5 minutes to propagate
- Clear browser DNS cache: Chrome → `chrome://net-internals/#dns` → Clear

**Issue 4: Cloudflare Access Login Loop**

```bash
# Check Access application policy
# Go to: Zero Trust Dashboard → Access → Applications

# Common issues:
# 1. Email not in allowed list
# 2. Session expired
# 3. Cookie blocked by browser

# Test without Access policy first
# Temporarily remove policy to verify tunnel works
```

**Solution:**
- Verify your email is in the Access policy "Allowed emails" list
- Check browser allows cookies (required for Access sessions)
- Try incognito/private browsing to rule out cookie issues
- Check session duration in Access application settings
- Clear browser cookies for your domain

**Issue 5: High Latency Through Tunnel**

```bash
# Test latency to Cloudflare edge
ping your-tunnel-domain.com

# Typical latency: 20-100ms depending on location

# Test direct to service (bypass tunnel)
curl -w "@curl-format.txt" https://n8n.yourdomain.com

# Compare with direct IP access
curl -w "@curl-format.txt" http://YOUR_SERVER_IP:5678
```

**Solution:**
- Cloudflare Tunnel adds 20-50ms latency on average (traffic routes through Cloudflare)
- For latency-sensitive applications, consider direct access with Caddy instead
- Use Cloudflare's Smart Routing (requires Argo Smart Routing - paid)
- Ensure tunnel connected to nearest Cloudflare datacenter
- Check `cloudflared` logs for routing information

### Resources

- **Official Documentation:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- **Getting Started Guide:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/
- **Docker Setup:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/deployment-guides/docker/
- **API Documentation:** https://developers.cloudflare.com/api/operations/cloudflare-tunnel-create-a-tunnel
- **GitHub:** https://github.com/cloudflare/cloudflared
- **Docker Hub:** https://hub.docker.com/r/cloudflare/cloudflared
- **Zero Trust Dashboard:** https://one.dash.cloudflare.com
- **Cloudflare Access:** https://developers.cloudflare.com/cloudflare-one/policies/access/
- **Community Forum:** https://community.cloudflare.com/c/security/access/51
- **Tutorials:** https://developers.cloudflare.com/learning-paths/zero-trust-web-access/

### Best Practices

**Security:**
- Never expose tunnel tokens in Git repositories or logs
- Use environment variables for tokens in docker-compose.yml
- Rotate tunnel tokens quarterly (delete old tunnel, create new)
- Enable Cloudflare Access for production services
- Use email whitelisting for Access policies (not "anyone with email")
- Review Access logs regularly: Zero Trust → Logs → Access requests

**Configuration:**
- One tunnel per environment (dev, staging, prod)
- Use descriptive tunnel names: `company-env-location` (e.g., `acme-prod-vps1`)
- Document tunnel ID and creation date in team wiki
- Keep tunnel configuration in version control (infrastructure as code)
- Set up monitoring/alerts for tunnel health

**Performance:**
- Minimize number of Public Hostnames per tunnel (better to create multiple tunnels)
- Use Cloudflare's Argo Smart Routing for better performance (paid feature)
- Enable Cloudflare caching for static assets
- Monitor latency: expect 20-50ms overhead compared to direct access
- For latency-sensitive apps, consider direct access + WAF rules instead

**Docker Integration:**
- Run cloudflared on the same Docker network as your services
- Use container names for service URLs (not `localhost` or IP addresses)
- Set `restart: unless-stopped` to ensure tunnel auto-starts
- Monitor container logs: `docker logs cloudflared-tunnel --follow`
- Resource limits: cloudflared uses ~20-50MB RAM (very lightweight)

**Monitoring:**
```bash
# Check tunnel status
docker ps | grep cloudflared
docker logs cloudflared-tunnel --tail 50

# Monitor connections
# In Cloudflare Dashboard: Networks → Tunnels → [Your tunnel]
# Should show "Healthy" with 1+ active connections

# Test service accessibility
curl -I https://yourservice.yourdomain.com

# Monitor Access logs (if using Zero Trust)
# Zero Trust Dashboard → Logs → Access requests
# Look for failed authentications or unusual patterns
```

**Backup & Disaster Recovery:**
```bash
# Backup tunnel token (CRITICAL!)
# Store in password manager (Vaultwarden)
echo "TUNNEL_TOKEN=eyJ..." > tunnel-token.txt.gpg
gpg -c tunnel-token.txt

# Document tunnel configuration
# Export from Cloudflare Zero Trust Dashboard
# Networks → Tunnels → [Tunnel] → Configure → Export config

# Test failover
# Create second tunnel in different region/VPS
# Configure with same hostnames for instant failover
```

**Cost Optimization:**
- Cloudflare Tunnel is **free** up to 50 users
- Zero Trust Access is **free** for up to 50 users
- No bandwidth charges for tunnel traffic
- Argo Smart Routing is paid ($0.10/GB)
- For >50 users, pricing starts at $7/user/month

**Common Patterns:**

**Pattern 1: Simple Service Exposure**
```yaml
# docker-compose.yml
cloudflared:
  image: cloudflare/cloudflared:latest
  container_name: cloudflared
  restart: unless-stopped
  environment:
    - TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}
  command: tunnel run
```

**Pattern 2: Service with Zero Trust Auth**
- Configure in Cloudflare Dashboard (easier than API)
- Access → Applications → Add application
- Apply email-based OTP policy
- Session duration: 24 hours

**Pattern 3: Multiple Services, One Tunnel**
```
Public Hostnames (in Cloudflare Dashboard):
- n8n.example.com → http://n8n:5678
- vault.example.com → http://vaultwarden:80
- webui.example.com → http://open-webui:8080
```

**Pattern 4: Development vs Production Tunnels**
```bash
# Development
Tunnel name: acme-dev
Hostnames: *.dev.example.com
No Access policies

# Production
Tunnel name: acme-prod
Hostnames: *.example.com
Access policies: Email whitelist
```
