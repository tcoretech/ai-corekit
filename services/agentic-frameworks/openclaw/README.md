# OpenClaw Service

OpenClaw is a versatile agentic framework that connects LLMs to the real world securely. This service provides a gateway that enables multi-channel messaging (WhatsApp, Slack, Telegram, Discord, etc.), webhook automation, and API access.

## Quick Start

```bash
# Enable the service
corekit enable openclaw

# Start the service (generates secrets, builds image, starts containers)
corekit up openclaw

# Run onboarding wizard (optional, for channel configuration)
corekit run openclaw onboard
```

## Service Ports

| Port | Purpose |
|------|---------|
| 18789 | Gateway WebSocket + HTTP control plane |
| 18790 | Bridge port for node connections |

## Configuration

### Environment Variables

Edit `/root/ai-launchkit/services/agentic-frameworks/openclaw/.env`:

```bash
# Required - Auto-generated during corekit up
OPENCLAW_GATEWAY_TOKEN='<generated-32-byte-hex>'

# Gateway ports
OPENCLAW_GATEWAY_PORT='18789'
OPENCLAW_BRIDGE_PORT='18790'

# Network binding (lan = accessible on network, local = localhost only)
OPENCLAW_GATEWAY_BIND='lan'

# Optional AI Provider Keys (inherited from global config if not set)
# ANTHROPIC_API_KEY and OPENAI_API_KEY are inherited from .env.global
```

### OpenClaw Configuration File

The gateway configuration is stored in a Docker volume at `/home/node/.openclaw/openclaw.json`. You can configure it via:

1. **Interactive onboarding**: `corekit run openclaw onboard`
2. **CLI config commands**: `corekit run openclaw config set <path> <value>`
3. **Direct file editing** (inside container)

---

## Cloudflare Tunnel Exposure (Security-First Approach)

### Overview

Exposing OpenClaw through Cloudflare Tunnel provides:
- **Zero Trust access**: No open ports on your server
- **DDoS protection**: Cloudflare absorbs attacks
- **Access policies**: Fine-grained authentication controls
- **Audit logging**: All requests logged

### Step 1: Configure Tunnel Route

In your Cloudflare Zero Trust dashboard:

1. Go to **Networks** > **Tunnels** > Select your tunnel
2. Click **Configure** > **Public Hostname**
3. Add a new public hostname:
   - **Subdomain**: `openclaw` (or your preference)
   - **Domain**: `yourdomain.com`
   - **Service**: `http://openclaw-gateway:18789`

### Step 2: Configure Access Policies (CRITICAL)

**Never expose OpenClaw without access policies!**

1. Go to **Access** > **Applications** > **Add an Application**
2. Select **Self-hosted**
3. Configure:
   - **Application name**: OpenClaw Gateway
   - **Session Duration**: 24 hours (adjust as needed)
   - **Application domain**: `openclaw.yourdomain.com`

4. **Add Access Policies**:

   **Policy 1: Webhook Endpoints (Bypass for automated services)**
   ```
   Name: Webhook Bypass
   Action: Bypass
   Include:
     - Path matches: /hooks/*
     - Valid HTTP Methods: POST
   ```

   **Policy 2: Authenticated Users**
   ```
   Name: Authenticated Access
   Action: Allow
   Include:
     - Emails ending in: @yourdomain.com
     - OR Login Methods: Google, GitHub (your preferred IdP)
   ```

### Step 3: Additional Security Measures

#### 3.1 Enable Hooks Token Authentication

Even with Cloudflare Access bypass for webhooks, OpenClaw requires token authentication:

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-secure-webhook-token",
    "path": "/hooks"
  }
}
```

**Never use the same token as OPENCLAW_GATEWAY_TOKEN for hooks!**

#### 3.2 Configure Gateway Authentication

For WebSocket/API access, configure gateway auth:

```json
{
  "gateway": {
    "auth": {
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    }
  }
}
```

#### 3.3 Rate Limiting (Cloudflare)

In Cloudflare dashboard:
1. Go to **Security** > **WAF** > **Rate limiting rules**
2. Add rule for `openclaw.yourdomain.com`:
   - Requests per 10 seconds: 100
   - Action: Block

---

## Slack Integration

### Option 1: Socket Mode (Recommended for Security)

Socket Mode doesn't require exposing any endpoints - Slack connects outbound to their servers.

#### Setup Steps:

1. **Create Slack App**: https://api.slack.com/apps
2. **Enable Socket Mode**: Settings > Socket Mode > Enable
3. **Generate App Token**: Basic Information > App-Level Tokens > Generate Token with `connections:write` scope
4. **Get Bot Token**: OAuth & Permissions > Install to Workspace > Copy Bot Token
5. **Configure Event Subscriptions**: Event Subscriptions > Enable > Subscribe to bot events:
   - `message.im`
   - `message.channels`
   - `message.groups`
   - `app_mention`

#### OpenClaw Configuration:

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "appToken": "xapp-...",
      "botToken": "xoxb-...",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "channels": {
        "#allowed-channel": {
          "allow": true,
          "requireMention": true
        }
      }
    }
  }
}
```

### Option 2: HTTP Mode (Requires Cloudflare Tunnel)

Use HTTP mode when you want Slack to send events directly to your gateway.

#### Setup Steps:

1. Create Slack app and **disable Socket Mode**
2. Copy **Signing Secret** from Basic Information
3. Set **Request URL** in Event Subscriptions: `https://openclaw.yourdomain.com/slack/events`

#### OpenClaw Configuration:

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "mode": "http",
      "botToken": "xoxb-...",
      "signingSecret": "your-signing-secret",
      "webhookPath": "/slack/events"
    }
  }
}
```

#### Cloudflare Access Policy for Slack:

```
Name: Slack Webhooks
Action: Bypass
Include:
  - Path matches: /slack/*
  - IP ranges:
    - 44.226.2.0/22
    - 54.187.176.0/22
    - (See Slack's current IP ranges)
```

### Slack Security Checklist

- [ ] Use **pairing mode** for DMs to prevent unauthorized access
- [ ] Set **groupPolicy: "allowlist"** to control which channels the bot responds in
- [ ] Enable **requireMention: true** for public channels
- [ ] Configure **allowFrom** with specific user IDs/emails
- [ ] Review bot token scopes - remove any you don't need

---

## WhatsApp Integration

### Important Security Considerations

1. **Use a dedicated phone number** - Never use your personal WhatsApp for the bot
2. **Default to pairing mode** - Unknown users must be approved before they can chat
3. **Never use Twilio** - WhatsApp Business API has 24-hour reply windows and aggressive blocking

### Setup Steps:

1. **Get a phone number**: Local eSIM or prepaid SIM (VoIP numbers are blocked)
2. **Configure OpenClaw**:

```json
{
  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing",
      "allowFrom": ["+15551234567"],
      "groupPolicy": "disabled"
    }
  }
}
```

3. **Login via QR code**:
```bash
corekit run openclaw channels login
```

4. **Approve pairing requests**:
```bash
corekit run openclaw pairing list whatsapp
corekit run openclaw pairing approve whatsapp <code>
```

### WhatsApp Security Checklist

- [ ] Use **dmPolicy: "pairing"** (default) - requires approval for new users
- [ ] Set **groupPolicy: "disabled"** unless you specifically need group support
- [ ] Configure **allowFrom** with trusted phone numbers
- [ ] Enable **sendReadReceipts: false** if you don't want to leak presence
- [ ] Keep credentials safe - they're stored in the Docker volume

### Personal Number Mode (Fallback Only)

If you must use your personal number:

```json
{
  "channels": {
    "whatsapp": {
      "selfChatMode": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["+15551234567"]
    }
  }
}
```

---

## Webhook Security

### Hook Endpoint Authentication

All webhook requests to `/hooks/*` must include authentication:

```bash
# Recommended: Authorization header
curl -X POST https://openclaw.yourdomain.com/hooks/agent \
  -H 'Authorization: Bearer YOUR_HOOK_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Hello"}'

# Alternative: X-OpenClaw-Token header
curl -X POST https://openclaw.yourdomain.com/hooks/agent \
  -H 'X-OpenClaw-Token: YOUR_HOOK_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Hello"}'
```

### Webhook Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/hooks/wake` | POST | Trigger agent wake event |
| `/hooks/agent` | POST | Send message to agent (async) |
| `/hooks/<custom>` | POST | Custom mapped webhooks |

### Payload Examples

**Wake endpoint:**
```json
{"text": "New email received", "mode": "now"}
```

**Agent endpoint:**
```json
{
  "message": "Summarize inbox",
  "name": "Email",
  "sessionKey": "hook:email:msg-123",
  "channel": "slack",
  "to": "C123456789"
}
```

---

## API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Control UI (web dashboard) |
| `/v1/chat/completions` | POST | OpenAI-compatible API |
| `/v1/responses` | POST | OpenResponses streaming API |
| `/tools/invoke` | POST | Tool command invocation |
| `/slack/events` | POST | Slack webhooks (HTTP mode) |

---

## Operational Commands

```bash
# View logs
corekit logs openclaw
corekit logs openclaw -f --tail 100

# Restart service
corekit restart openclaw

# Stop service
corekit down openclaw

# Run CLI commands
corekit run openclaw status
corekit run openclaw health
corekit run openclaw channels status
corekit run openclaw config get
```

---

## Security Best Practices Summary

### Token Management
1. **OPENCLAW_GATEWAY_TOKEN**: Use only for gateway WebSocket auth
2. **hooks.token**: Separate token for webhook endpoints
3. **Slack tokens**: Store securely, never commit to git
4. **Never reuse tokens** across different purposes

### Network Security
1. **Always use Cloudflare Access** when exposing to internet
2. **Bypass policies only for specific paths** (webhooks with their own auth)
3. **Rate limit** all public endpoints
4. **Log all requests** for audit trail

### Channel Security
1. **Default to pairing/allowlist modes** - explicit approval required
2. **Disable groups by default** - enable only when needed
3. **Require mentions** in public channels
4. **Review permissions regularly**

### Data Protection
1. **Volumes contain credentials** - protect Docker volumes
2. **Session data is sensitive** - don't expose session endpoints
3. **Logs may contain PII** - handle appropriately

---

## Troubleshooting

### Gateway Won't Start
```bash
# Check logs
corekit logs openclaw --tail 50

# Verify environment
cat services/agentic-frameworks/openclaw/.env

# Force recreate
corekit down openclaw && corekit up openclaw --force-recreate
```

### WhatsApp Disconnected
```bash
# Check channel status
corekit run openclaw channels status

# Re-login if needed
corekit run openclaw channels login
```

### Webhook Returns 401
- Verify `hooks.token` matches your Authorization header
- Check if hooks are enabled in config
- Ensure token format: `Bearer <token>` or header `X-OpenClaw-Token`

### Slack Not Receiving Messages
- Verify bot is invited to channels
- Check event subscriptions are configured
- For HTTP mode, verify Cloudflare Access bypass is configured
- Check signing secret matches

---

## Files Reference

```
services/agentic-frameworks/openclaw/
├── .env                    # Service environment (generated)
├── .env.example            # Environment template
├── docker-compose.yml      # Container definition
├── service.json            # Service metadata
├── cli.sh                  # CLI wrapper
├── prepare.sh              # Pre-startup hook
├── secrets.sh              # Secret generation
└── repo/                   # OpenClaw source (cloned from GitHub)
```

## Resources

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Gateway Configuration](https://docs.openclaw.ai/gateway/configuration)
- [Webhook Automation](https://docs.openclaw.ai/automation/webhook)
- [Slack Channel Setup](https://docs.openclaw.ai/channels/slack)
- [WhatsApp Channel Setup](https://docs.openclaw.ai/channels/whatsapp)
