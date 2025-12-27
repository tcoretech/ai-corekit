### What is the Webhook Testing Suite?

The Webhook Testing Suite provides two complementary tools for testing and debugging API integrations and webhooks in your n8n workflows. It consists of Webhook Tester for receiving and inspecting incoming webhooks, and Hoppscotch for sending API requests and testing webhook triggers.

These tools are essential for developing, testing, and troubleshooting n8n workflows that involve external APIs, webhook triggers, or HTTP requests.

### Features

**Webhook Tester:**
- **Real-time webhook reception** - See incoming webhooks instantly
- **Request inspection** - View headers, body, query parameters, and metadata
- **Persistent storage** - All requests saved in dedicated Redis instance
- **Unique URLs** - Auto-generated UUID-based endpoints for each test
- **Response customization** - Configure status codes and response bodies
- **Multiple formats** - Support for JSON, XML, form data, and raw payloads

**Hoppscotch:**
- **API testing platform** - REST, GraphQL, WebSocket, and SSE support
- **Collections management** - Save and organize test requests
- **Environment variables** - Switch between dev, staging, and production
- **Code generation** - Export requests to various programming languages
- **Team collaboration** - Share collections and environments (requires account)
- **Import/Export** - Support for Postman, Insomnia, and OpenAPI formats

### Initial Setup

**Access URLs:**
- **Webhook Tester:** `https://webhook-test.yourdomain.com`
  - Username: Your email (from installation)
  - Password: Found in `.env` as `WEBHOOK_TESTER_PASSWORD`
- **Hoppscotch:** `https://api-test.yourdomain.com`
  - No authentication required for basic use
  - Optional: Create account for saving collections

### Using Webhook Tester

**1. Generate a Test Endpoint:**

Navigate to `https://webhook-test.yourdomain.com` and you'll get a unique URL like:
```
https://webhook-test.yourdomain.com/06c63b1e-c400-4ed4-b30a-fb1e9ad90260
```

**2. Send Webhooks to Test Endpoint:**

From any service or n8n workflow:
```bash
curl -X POST https://webhook-test.yourdomain.com/YOUR-UUID \
  -H "Content-Type: application/json" \
  -d '{"event": "test", "data": "hello world"}'
```

**3. Inspect in Real-Time:**

The Webhook Tester interface shows:
- Request method and URL
- All headers (including auth tokens)
- Request body (formatted JSON/XML)
- Query parameters
- Timestamp and response status

**4. Customize Response:**

Click "New URL" button to create endpoint with custom:
- Status code (200, 201, 400, 500, etc.)
- Response body
- Response delay (simulate slow APIs)
- Content-Type header

### Using Hoppscotch

**1. Create API Request:**
```javascript
// Example: Test n8n Webhook
Method: POST
URL: https://n8n.yourdomain.com/webhook/test

Headers:
Content-Type: application/json
X-Custom-Header: test-value

Body (JSON):
{
  "trigger": "manual",
  "data": {
    "id": 123,
    "status": "pending",
    "timestamp": "2025-10-31T10:00:00Z"
  }
}
```

**2. Test with Authentication:**
```javascript
// Basic Auth
Authorization: Basic Auth
Username: api-user
Password: api-key

// Bearer Token
Authorization: Bearer Token
Token: eyJhbGciOiJIUzI1NiIs...

// API Key
Headers:
X-API-Key: your-api-key-here
```

**3. Save to Collections:**
```
My API Tests/
├── n8n Webhooks/
│   ├── Test Trigger
│   ├── Production Trigger
│   └── Error Handling Test
├── External APIs/
│   ├── Stripe Payment
│   ├── SendGrid Email
│   └── Twilio SMS
└── Environments/
    ├── Development
    ├── Staging
    └── Production
```

### n8n Integration Examples

#### Testing n8n Webhook Trigger

**1. Create n8n Webhook Node:**
```javascript
// n8n Webhook Node
HTTP Method: POST
Path: /test
Response Mode: Last Node
Response Data: JSON
Response Code: 200
```

**2. Test with Hoppscotch:**
```javascript
POST https://n8n.yourdomain.com/webhook/test
Content-Type: application/json

{
  "action": "process",
  "items": [
    {"id": 1, "name": "Item 1"},
    {"id": 2, "name": "Item 2"}
  ]
}
```

**3. Debug with Webhook Tester:**

Point n8n HTTP Request node to Webhook Tester to inspect outgoing requests:
```javascript
// n8n HTTP Request Node
Method: POST
URL: https://webhook-test.yourdomain.com/YOUR-UUID
Authentication: Basic Auth
  Username: your-email@domain.com
  Password: (from .env file)
Body:
  {{ $json }}
```

#### Debugging External Webhook Integration

**Scenario:** Stripe webhook not triggering n8n workflow

**1. Create test endpoint in Webhook Tester**
**2. Configure Stripe webhook to test endpoint:**
```
Stripe Dashboard > Webhooks > Add Endpoint
URL: https://webhook-test.yourdomain.com/YOUR-UUID
Events: payment_intent.succeeded
```

**3. Inspect actual Stripe payload in Webhook Tester**
**4. Copy exact payload structure to Hoppscotch**
**5. Test n8n webhook with real Stripe data structure**

#### API Chain Testing

Test complex API chains before implementing in n8n:

**1. OAuth Flow Testing:**
```javascript
// Step 1: Get Auth Code (Hoppscotch)
GET https://api.example.com/oauth/authorize
  ?client_id=YOUR_CLIENT_ID
  &redirect_uri=https://webhook-test.yourdomain.com/YOUR-UUID
  &response_type=code

// Step 2: Inspect callback in Webhook Tester
// Captures: code, state parameters

// Step 3: Exchange code for token (Hoppscotch)
POST https://api.example.com/oauth/token
{
  "grant_type": "authorization_code",
  "code": "CAPTURED_CODE",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_SECRET"
}

// Step 4: Test API with token
GET https://api.example.com/data
Authorization: Bearer ACCESS_TOKEN
```

### Advanced Features

#### Webhook Tester Response Templates

Create reusable response templates:
```javascript
// Success Response Template
Status: 200
Headers:
  X-Request-ID: {{uuid}}
  X-Timestamp: {{timestamp}}
Body:
{
  "success": true,
  "message": "Webhook received",
  "id": "{{uuid}}",
  "processed_at": "{{timestamp}}"
}

// Error Response Template  
Status: 400
Body:
{
  "error": "Invalid payload",
  "details": "Missing required field: email"
}
```

#### Hoppscotch Environment Variables
```javascript
// Development Environment
{
  "base_url": "http://localhost:5678",
  "api_key": "dev-key-123",
  "webhook_url": "https://webhook-test.yourdomain.com/dev-uuid"
}

// Production Environment
{
  "base_url": "https://n8n.yourdomain.com",
  "api_key": "{{$secret.PROD_API_KEY}}",
  "webhook_url": "https://production-webhook.com/endpoint"
}

// Usage in requests:
POST {{base_url}}/webhook/{{endpoint}}
X-API-Key: {{api_key}}
```

#### Performance Testing

Test n8n webhook performance:
```bash
# Load test with multiple concurrent requests
for i in {1..100}; do
  curl -X POST https://n8n.yourdomain.com/webhook/test \
    -H "Content-Type: application/json" \
    -d '{"test": "'$i'"}' &
done

# Monitor in Webhook Tester for response times
```

### Troubleshooting

**Webhook Tester not receiving requests:**
```bash
# Check if service is running
docker ps | grep webhook-tester

# Check Basic Auth credentials
grep "WEBHOOK_TESTER" .env

# Test without auth (should return 401)
curl -I https://webhook-test.yourdomain.com

# Test with auth
curl -u "email:password" https://webhook-test.yourdomain.com
```

**Hoppscotch authentication issues:**
```bash
# Note: Community Edition has limited auth support
# Works without login for basic testing
# For team features, consider:
# 1. Setting up GitHub OAuth (complex)
# 2. Using without authentication
# 3. Waiting for future updates

# Check if service is running
docker ps | grep hoppscotch
docker logs hoppscotch --tail 50
```

**Connection refused errors:**
```bash
# Verify internal URLs for n8n workflows
http://webhook-tester:8080  # Internal webhook tester
http://hoppscotch:3000      # Internal hoppscotch

# Check network connectivity
docker exec n8n ping webhook-tester
```

**Redis connection issues:**
```bash
# Check Redis for Webhook Tester
docker ps | grep webhook-tester-redis
docker logs webhook-tester-redis

# Clear Redis if needed
docker exec webhook-tester-redis redis-cli FLUSHDB
```

### Best Practices

**Security:**
- Rotate Webhook Tester password regularly
- Don't expose sensitive data in test webhooks
- Use environment variables for credentials
- Clear test data after debugging sessions

**Testing Strategy:**
- Test with Hoppscotch first (controlled environment)
- Validate with real service to Webhook Tester
- Implement in n8n workflow
- Monitor production webhooks periodically

**Documentation:**
- Save Hoppscotch collections for each integration
- Document expected webhook payloads
- Keep response examples for reference
- Export and version control test collections

**Debugging Workflow:**
1. Reproduce issue in Hoppscotch
2. Capture actual payload with Webhook Tester
3. Compare expected vs actual structure
4. Test fix in Hoppscotch
5. Implement fix in n8n
6. Validate with production webhook

### Tips & Tricks

**Quick Webhook Echo Service:**
```javascript
// n8n Workflow: Webhook Echo for Testing
1. Webhook Node (trigger)
2. HTTP Request Node
   URL: https://webhook-test.yourdomain.com/echo-uuid
   Body: {{ $json }}
3. Respond to Webhook Node
   Response: {{ $json }}
```

**Webhook Replay:**
```javascript
// Copy webhook from Webhook Tester
// Paste into Hoppscotch
// Modify and replay as needed
// Perfect for testing error scenarios
```

**Batch Testing:**
```javascript
// Hoppscotch Collections Runner
// Run entire collection sequentially
// Export results as JSON
// Compare with expected outputs
```

### Resources

- **Webhook Tester GitHub:** https://github.com/tarampampam/webhook-tester
- **Hoppscotch Documentation:** https://docs.hoppscotch.io
- **n8n Webhook Guide:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- **HTTP Status Codes:** https://httpstatuses.com
- **Webhook Best Practices:** https://webhooks.dev
