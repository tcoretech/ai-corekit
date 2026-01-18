# 🔄 Airbyte - Data Integration Platform

### What is Airbyte?

Airbyte is the leading open-source data integration platform that syncs data from 600+ sources (APIs, databases, SaaS tools) to destinations like databases, data warehouses, and data lakes. Unlike traditional ETL tools, Airbyte is built for developers and data engineers with a modern, API-first approach. It's perfect for building automated data pipelines, consolidating marketing data, creating unified analytics dashboards, and replacing expensive proprietary integration tools like Fivetran or Stitch.

### Features

- **600+ Pre-built Connectors:** Google Ads, Meta Ads, TikTok, Shopify, Stripe, Salesforce, HubSpot, and more
- **No-Code UI:** Visual connector builder for non-developers
- **Custom Connectors:** Python CDK for building your own connectors
- **Incremental Sync:** Only sync changed data (efficient)
- **CDC Support:** Real-time Change Data Capture for databases
- **Transformation:** dbt integration for data transformation
- **Scheduling:** Cron-based sync schedules
- **REST API:** Full API for automation and programmatic control
- **Normalization:** Automatic schema normalization
- **Multi-Destination:** Sync one source to multiple destinations
- **Open Source:** Full control, no vendor lock-in

### Architecture in AI CoreKit

Airbyte runs via `abctl` (Airbyte Command Line Tool) which creates a Kind (Kubernetes in Docker) cluster:
```
┌─────────────────────────────────────────────────────┐
│  abctl → Kind Cluster (Docker Container)            │
│  ├─ Airbyte Server                                  │
│  ├─ Temporal (workflow orchestration)               │
│  ├─ Built-in PostgreSQL (metadata, jobs, state)     │
│  └─ Ingress (Port 8001 → Host)                      │
└─────────────────────────────────────────────────────┘
              ▼ syncs data to
┌─────────────────────────────────────────────────────┐
│  Docker Compose Stack                               │
│  └─ airbyte_destination_db (PostgreSQL)             │
│     └─ marketing_data database (synced data)        │
└─────────────────────────────────────────────────────┘
              ▼ analyzed by
┌─────────────────────────────────────────────────────┐
│  Metabase + n8n                                     │
│  ├─ Metabase: Dashboards on marketing_data          │
│  └─ n8n: Trigger syncs via Airbyte API              │
└─────────────────────────────────────────────────────┘
```

### System Requirements

**CRITICAL - inotify limits:**

Some servers (especially high-density VPS) have very low inotify limits that prevent Kind/systemd from starting. This must be fixed BEFORE installation:
```bash
# Check current limits
cat /proc/sys/fs/inotify/max_user_instances

# If below 8192, increase it:
sudo sysctl fs.inotify.max_user_instances=8192
echo "fs.inotify.max_user_instances=8192" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Restart Docker
sudo systemctl restart docker

# Clean up any leftover state from failed attempts
sudo abctl local uninstall --persisted
sudo rm -rf /root/.airbyte
sudo docker rm -f $(sudo docker ps -aq --filter "name=airbyte") 2>/dev/null || true

# Retry installation
sudo bash scripts/update.sh
```

#### Installation Fails: "pod airbyte-abctl-bootloader failed"

**This is a known intermittent bug in abctl v0.30.2 - see [GitHub Discussion #45458](https://github.com/airbytehq/airbyte/discussions/45458) for the official tracking of this "pod airbyte-abctl-bootloader failed" error.**

```bash
# Check installation status
sudo abctl local status

# If you see: Status: failed
# This is a known abctl v0.30.2 bug with service name resolution
```

**Root Cause:** The Helm chart creates a service named `airbyte-db-svc` but the bootloader tries to connect to `airbyte-db`, causing a DNS resolution failure.

**Fix:**
```bash
# 1. Create service alias
cat <<EOF | sudo docker exec -i airbyte-abctl-control-plane kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: airbyte-db
  namespace: airbyte-abctl
spec:
  type: ExternalName
  externalName: airbyte-db-svc.airbyte-abctl.svc.cluster.local
EOF

# 2. Verify DNS works
sudo docker exec airbyte-abctl-control-plane kubectl exec -n airbyte-abctl airbyte-db-0 -- nslookup airbyte-db
# Should resolve to: airbyte-db-svc.airbyte-abctl.svc.cluster.local

# 3. Retry installation
sudo abctl local install --port 8001

# 4. Verify success
sudo abctl local status
# Should show: Status: deployed
```

**This is a race condition bug in abctl that occurs intermittently.** The service alias workaround forces correct DNS resolution.

**Minimum Resources:**
- 8GB RAM (16GB recommended for production)
- 4 CPU cores
- 20GB free disk space
- Modern Linux kernel (5.x+)
- Ubuntu 22.04/24.04 recommended

**Known Compatible Hosting:**
- ✅ Hetzner Cloud
- ✅ AWS EC2
- ✅ DigitalOcean
- ✅ Most modern KVM/dedicated servers
- ⚠️ May not work on OpenVZ/LXC containers
- ⚠️ May not work on heavily customized kernels

### Initial Setup

**First Login to Airbyte:**

1. Navigate to `https://airbyte.yourdomain.com`
2. First-time setup screen appears:
   - **Email:** Enter your email (this becomes your username)
   - **Password:** Use the password from installation report or `.env` file (`AIRBYTE_PASSWORD`)
3. Complete the welcome wizard:
   - Skip the quick start tutorial (or follow it)
   - Optionally configure your first source

**Important:** The email address is NOT pre-configured - you enter it on first login. Only the password is pre-generated.

### Port Configuration

**Airbyte uses non-standard ports to avoid conflicts with Supabase:**

- **Web UI:** Port 8001 (instead of default 8000 to avoid Supabase Kong)
- **Destination DB:** Port 5433 (instead of 5432 to avoid Supabase PostgreSQL)

**If you see installation errors about ports already in use:**
- Check which service is using the port: `sudo docker ps | grep <port>`
- Either stop the conflicting service or change ports in configuration

### Network Configuration

**UFW Firewall Rules (Required):**

Airbyte's Kind cluster needs access to the destination database:
```bash
# Allow Kind network to access destination PostgreSQL
sudo ufw allow from 172.19.0.0/16 to any port 5433 comment 'Kind to Airbyte Destination DB'

# Allow Docker network to access Airbyte API (for Caddy)
sudo ufw allow from 172.18.0.0/16 to any port 8001 comment 'Caddy to Airbyte'

# Verify rules
sudo ufw status | grep -E "5433|8001"
```

**Caddy Reverse Proxy:**

Caddy must route to Airbyte via the Docker gateway IP. This IP can vary per server:
```bash
# Find your gateway IP
docker network inspect ${PROJECT_NAME:-localai}_default | grep Gateway
# Output example: "Gateway": "172.18.0.1"

# Update Caddyfile with the correct IP:
{$AIRBYTE_HOSTNAME} {
    reverse_proxy 172.18.0.1:8001  # Use YOUR gateway IP here
}

# Common gateway IPs: 172.18.0.1, 172.19.0.1, 172.20.0.1
```

**If you get 502 errors after installation:**
1. Find gateway IP: `docker network inspect ${PROJECT_NAME:-localai}_default | grep Gateway`
2. Update `Caddyfile` with the correct IP
3. Restart Caddy: `corekit restart caddy`

### Destination Database Setup

The `airbyte_destination_db` is a separate PostgreSQL instance specifically for storing synced data (not Airbyte's internal metadata).

**Connection Details:**
```
Host: airbyte_destination_db (from Docker) or <your-server-ip> (external)
Port: 5433
Database: marketing_data
Username: airbyte
Password: Check AIRBYTE_DESTINATION_DB_PASSWORD in .env
SSL: Not required (internal network)
```

**Configure in Airbyte UI:**

1. Go to **Settings** → **Destinations** → **+ New Destination**
2. Select **Postgres**
3. Configure:
   - **Name:** Marketing Data Warehouse
   - **Host:** `airbyte_destination_db` (or your server IP if accessing externally)
   - **Port:** `5433`
   - **Database:** `marketing_data`
   - **Username:** `airbyte`
   - **Password:** From your `.env` file
   - **SSL Mode:** `disable`
4. Click **Test** → Should show ✅ success
5. Click **Save**

**Why a separate destination database?**
- Airbyte's built-in PostgreSQL stores metadata (connections, jobs, state)
- The destination database stores your actual synced marketing data
- Metabase connects to the destination database for analytics
- Clean separation of concerns

### n8n Integration Setup

**Internal URL for n8n:** `http://localhost:8001/api/v1/`

#### Method 1: Trigger Sync via Webhook (Recommended)
```javascript
// HTTP Request Node - Trigger Connection Sync
Method: POST
URL: http://localhost:8001/api/v1/jobs
Authentication: Basic Auth
  Username: {{$env.AIRBYTE_EMAIL}}
  Password: {{$env.AIRBYTE_PASSWORD}}
Body (JSON):
{
  "connectionId": "YOUR-CONNECTION-ID",
  "jobType": "sync"
}

// Get Connection ID from Airbyte UI:
// Connections → Your Connection → URL shows: /connections/<connection-id>
```

#### Method 2: API Integration (Full Control)
```javascript
// 1. HTTP Request Node - List all connections
Method: GET
URL: http://localhost:8001/api/v1/connections/list
Authentication: Basic Auth
Body (JSON):
{
  "workspaceId": "YOUR-WORKSPACE-ID"  // Get from Settings → General
}

// 2. Filter Node - Find specific connection
// Filter by name or sourceId

// 3. HTTP Request Node - Get connection status
Method: POST
URL: http://localhost:8001/api/v1/connections/get
Body (JSON):
{
  "connectionId": "{{$json.connectionId}}"
}

// 4. IF Node - Check last sync status
Condition: {{$json.latestSyncJobStatus}} === 'failed'

// 5. HTTP Request Node - Trigger sync if needed
Method: POST
URL: http://localhost:8001/api/v1/jobs
Body (JSON):
{
  "connectionId": "{{$json.connectionId}}",
  "jobType": "sync"
}

// 6. Wait for completion (poll job status)
// Loop with delay until job.status === 'succeeded'

// 7. Slack/Email Notification
Message: |
  ✅ Airbyte Sync Completed
  Connection: {{$json.connectionName}}
  Records Synced: {{$json.recordsSynced}}
  Duration: {{$json.duration}}
```

#### Method 3: Webhook Trigger (Event-Driven)

Configure Airbyte to call n8n webhook when sync completes:
```javascript
// 1. n8n Webhook Trigger Node
HTTP Method: POST
Path: airbyte-sync-complete
Authentication: Header Auth (X-Webhook-Token)

// 2. Airbyte UI Configuration:
// Settings → Webhooks → Add Webhook
// URL: https://n8n.yourdomain.com/webhook/airbyte-sync-complete
// Headers: X-Webhook-Token: <your-secret-token>
// Events: connection.sync.succeeded, connection.sync.failed

// 3. Code Node - Process webhook data
const syncStatus = $input.first().json;

return [{
  json: {
    connectionId: syncStatus.connectionId,
    status: syncStatus.status,
    recordsSynced: syncStatus.recordsEmitted,
    duration: syncStatus.duration,
    timestamp: syncStatus.endedAt
  }
}];

// 4. Switch Node - Handle success/failure
// Route 1: success → Update dashboard, send report
// Route 2: failure → Create alert, notify team

// 5. PostgreSQL Node - Log to tracking table
Operation: Insert
Table: airbyte_sync_log
Columns:
  connection_id: {{$json.connectionId}}
  status: {{$json.status}}
  records_synced: {{$json.recordsSynced}}
  synced_at: NOW()
```

### Metabase Integration

Connect Metabase to the Airbyte destination database to visualize synced data:

**In Metabase:**

1. Go to **Settings** → **Admin** → **Databases** → **Add Database**
2. Select **PostgreSQL**
3. Configure:
```
   Name: Airbyte Marketing Data
   Host: airbyte_destination_db
   Port: 5433
   Database: marketing_data
   Username: airbyte
   Password: <AIRBYTE_DESTINATION_DB_PASSWORD from .env>
```
4. Click **Save**
5. Click **Sync database schema now**

**Example Dashboard - Marketing Performance:**
```sql
-- Google Ads Campaign Performance (if synced)
SELECT 
  campaign_name,
  SUM(impressions) as total_impressions,
  SUM(clicks) as total_clicks,
  ROUND(SUM(clicks)::numeric / NULLIF(SUM(impressions), 0) * 100, 2) as ctr,
  SUM(cost_micros) / 1000000.0 as total_cost,
  SUM(conversions) as total_conversions,
  ROUND(SUM(cost_micros) / 1000000.0 / NULLIF(SUM(conversions), 0), 2) as cost_per_conversion
FROM google_ads_campaign_stats
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY campaign_name
ORDER BY total_cost DESC;

-- Meta Ads Performance (if synced)
SELECT 
  campaign_name,
  DATE(date_start) as date,
  SUM(impressions) as impressions,
  SUM(clicks) as clicks,
  SUM(spend) as spend,
  SUM(conversions) as conversions
FROM facebook_ads_insights
WHERE date_start >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY campaign_name, DATE(date_start)
ORDER BY date DESC;

-- Cross-Platform Comparison
SELECT 
  'Google Ads' as platform,
  SUM(cost_micros) / 1000000.0 as total_spend,
  SUM(conversions) as conversions
FROM google_ads_campaign_stats
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
UNION ALL
SELECT 
  'Meta Ads' as platform,
  SUM(spend) as total_spend,
  SUM(conversions) as conversions
FROM facebook_ads_insights
WHERE date_start >= CURRENT_DATE - INTERVAL '30 days';
```

### Example Workflows

#### Example 1: Automated Daily Sync + Report
```javascript
// Schedule Trigger - Daily at 6 AM

// 1. HTTP Request - Trigger Google Ads sync
Method: POST
URL: http://localhost:8001/api/v1/jobs
Body: {"connectionId": "google-ads-connection-id", "jobType": "sync"}

// 2. Wait 5 minutes for sync to complete

// 3. HTTP Request - Check sync status
Method: POST
URL: http://localhost:8001/api/v1/jobs/get
Body: {"id": "{{$json.jobId}}"}

// 4. IF Node - Check if successful
Condition: {{$json.status}} === 'succeeded'

// 5. PostgreSQL Node - Query yesterday's data
Query: |
  SELECT 
    SUM(impressions) as impressions,
    SUM(clicks) as clicks,
    SUM(cost_micros)/1000000 as spend
  FROM google_ads_campaign_stats
  WHERE date = CURRENT_DATE - 1

// 6. Email/Slack - Send daily report
Subject: Daily Marketing Report - {{$now.toFormat('yyyy-MM-dd')}}
Message: |
  📊 Yesterday's Performance:
  
  Impressions: {{$json.impressions}}
  Clicks: {{$json.clicks}}
  Spend: ${{$json.spend}}
  CTR: {{($json.clicks / $json.impressions * 100).toFixed(2)}}%
  
  Dashboard: https://analytics.yourdomain.com/dashboard/marketing
```

#### Example 2: Sync Failure Alert & Auto-Retry
```javascript
// Schedule Trigger - Every hour

// 1. HTTP Request - List recent job failures
Method: POST
URL: http://localhost:8001/api/v1/jobs/list
Body: {
  "configTypes": ["sync"],
  "statuses": ["failed"]
}

// 2. IF Node - Check if any failures
Condition: {{$json.jobs.length}} > 0

// 3. Loop - For each failed job

// 4. HTTP Request - Get failure details
Method: POST
URL: http://localhost:8001/api/v1/jobs/get
Body: {"id": "{{$json.id}}"}

// 5. Code Node - Analyze error
const job = $json;
const errorMsg = job.attempts[job.attempts.length - 1].logs.logLines
  .filter(l => l.level === 'ERROR')
  .map(l => l.message)
  .join('\n');

return [{
  json: {
    connectionId: job.connectionId,
    failureReason: errorMsg,
    attemptCount: job.attempts.length,
    shouldRetry: job.attempts.length < 3  // Max 3 retries
  }
}];

// 6. IF Node - Should retry?
Condition: {{$json.shouldRetry}} === true

// 7. HTTP Request - Trigger retry
Method: POST
URL: http://localhost:8001/api/v1/jobs
Body: {
  "connectionId": "{{$json.connectionId}}",
  "jobType": "sync"
}

// 8. Slack Alert - Notify team
Channel: #data-alerts
Message: |
  ⚠️ Airbyte Sync Failed
  
  Connection: {{$json.connectionName}}
  Attempt: {{$json.attemptCount}}
  Error: {{$json.failureReason}}
  
  Action: {{$json.shouldRetry ? 'Auto-retry triggered' : 'Manual intervention required'}}
```

#### Example 3: Dynamic Source Configuration
```javascript
// Webhook Trigger - New customer onboarding

// 1. Code Node - Prepare source config
const customer = $input.first().json;

return [{
  json: {
    workspaceId: "YOUR-WORKSPACE-ID",
    sourceDefinitionId: "SOURCE-DEF-ID",  // e.g., Google Ads
    connectionConfiguration: {
      credentials: {
        client_id: customer.google_client_id,
        client_secret: customer.google_client_secret,
        refresh_token: customer.google_refresh_token
      },
      customer_id: customer.google_ads_customer_id
    },
    name: `${customer.name} - Google Ads`
  }
}];

// 2. HTTP Request - Create source
Method: POST
URL: http://localhost:8001/api/v1/sources/create
Body: {{$json}}

// 3. HTTP Request - Create destination (if needed)
Method: POST
URL: http://localhost:8001/api/v1/destinations/create
Body: {
  "workspaceId": "YOUR-WORKSPACE-ID",
  "destinationDefinitionId": "POSTGRES-DEF-ID",
  "connectionConfiguration": {
    "host": "airbyte_destination_db",
    "port": 5433,
    "database": "marketing_data",
    "username": "airbyte",
    "password": "{{$env.AIRBYTE_DESTINATION_DB_PASSWORD}}",
    "schema": "customer_{{$json.customer_id}}"  // Isolated schema per customer
  },
  "name": `${customer.name} - Database`
}

// 4. HTTP Request - Create connection
Method: POST
URL: http://localhost:8001/api/v1/connections/create
Body: {
  "sourceId": "{{$json.sourceId}}",
  "destinationId": "{{$json.destinationId}}",
  "schedule": {
    "timeUnit": "hours",
    "units": 24
  },
  "status": "active",
  "name": `${customer.name} - Sync`
}

// 5. Email - Notify customer
To: {{$json.customer.email}}
Subject: Your Data Pipeline is Ready
Body: |
  Hi {{$json.customer.name}},
  
  Your automated data sync is now active!
  
  View your dashboard: https://analytics.yourdomain.com/dashboard/{{$json.customer_id}}
```

### Common Source Connectors

#### Google Ads Setup

1. **Airbyte UI:** Sources → + New Source → Google Ads
2. **Authentication:** OAuth (click "Authenticate your Google Ads account")
3. **Configuration:**
   - **Customer ID:** Your Google Ads customer ID (format: 123-456-7890)
   - **Start Date:** How far back to sync historical data
   - **Conversion Window:** Days to look back for conversion attribution
4. **Streams to Sync:**
   - `campaigns`
   - `ad_groups`
   - `ads`
   - `campaign_stats` (performance metrics)
   - `ad_group_stats`
   - `keyword_stats`
5. **Test & Save**

#### Meta Ads (Facebook) Setup

1. **Airbyte UI:** Sources → + New Source → Facebook Marketing
2. **Authentication:** OAuth (Facebook Business login)
3. **Configuration:**
   - **Account ID:** Your Facebook Ads account ID
   - **Start Date:** Historical data start date
   - **Include Deleted:** Sync deleted campaigns/ads for historical analysis
4. **Streams to Sync:**
   - `campaigns`
   - `adsets`
   - `ads`
   - `ads_insights` (performance data)
   - `ad_creatives`
5. **Test & Save**

#### Stripe Setup

1. **Airbyte UI:** Sources → + New Source → Stripe
2. **Authentication:** API Key (from Stripe Dashboard)
3. **Configuration:**
   - **Account ID:** Your Stripe account ID
   - **Client Secret:** Secret API key
   - **Start Date:** Historical data start date
4. **Streams to Sync:**
   - `customers`
   - `charges`
   - `subscriptions`
   - `invoices`
   - `payment_intents`
5. **Test & Save**

#### Shopify Setup

1. **Airbyte UI:** Sources → + New Source → Shopify
2. **Authentication:** API Password (from Shopify Admin)
3. **Configuration:**
   - **Shop Name:** Your shop name (from shop URL)
   - **Start Date:** Historical data start date
   - **API Password:** Private app password
4. **Streams to Sync:**
   - `orders`
   - `customers`
   - `products`
   - `inventory_levels`
   - `transactions`
5. **Test & Save**

### Advanced Features

#### Incremental Sync (CDC)

For large datasets, use incremental sync to only sync changed data:
```yaml
# Connection Configuration in Airbyte UI
Sync Mode: Incremental - Append + Deduped
Cursor Field: updated_at  # Column that tracks changes
Primary Key: id  # Unique identifier for deduplication

# This syncs only new/changed records since last sync
# Dramatically reduces sync time and resource usage
```

#### Custom Transformations

Use dbt (Data Build Tool) for post-sync transformations:
```sql
-- models/staging/stg_google_ads_campaigns.sql
WITH source AS (
  SELECT * FROM {{ source('airbyte', 'google_ads_campaign_stats') }}
),

renamed AS (
  SELECT
    campaign_id,
    campaign_name,
    date,
    impressions,
    clicks,
    cost_micros / 1000000.0 AS cost_usd,
    CASE 
      WHEN impressions > 0 THEN clicks::float / impressions * 100
      ELSE 0 
    END AS ctr_percent
  FROM source
  WHERE date >= CURRENT_DATE - 90  -- Last 90 days only
)

SELECT * FROM renamed;

-- Enable in Airbyte: Connections → Transformation → Enable dbt
```

#### Schema Evolution

Airbyte automatically handles schema changes in sources:

- **New columns:** Automatically added to destination tables
- **Removed columns:** Kept in destination (nullable)
- **Type changes:** Logged as warnings, may require manual intervention
- **Normalization:** Optional feature to flatten nested JSON

**Best Practice:** Enable "Basic Normalization" for clean, queryable tables.

### Troubleshooting

#### Installation Fails: "unable to create kind cluster"
```bash
# Check inotify limits
cat /proc/sys/fs/inotify/max_user_instances

# If below 8192:
sudo sysctl fs.inotify.max_user_instances=8192
echo "fs.inotify.max_user_instances=8192" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Restart Docker
sudo systemctl restart docker

# Clean up failed installation
sudo abctl local uninstall --persisted
sudo rm -rf /root/.airbyte

# Retry installation
sudo bash scripts/05a_init_airbyte.sh
```

#### 502 Bad Gateway After Installation
```bash
# 1. Find Docker gateway IP
docker network inspect ${PROJECT_NAME:-localai}_default | grep Gateway
# Output: "Gateway": "172.18.0.1"

# 2. Update Caddyfile
nano Caddyfile
# Change: reverse_proxy 172.XX.0.1:8001

# 3. Restart Caddy
docker restart caddy

# 4. Verify Airbyte is running
curl http://localhost:8001
# Should return HTML
```

#### Destination Connection Test Fails
```bash
# 1. Verify destination DB is running
docker ps | grep airbyte_destination_db

# 2. Check UFW rules
sudo ufw status | grep 5433

# 3. Test connection from Kind cluster
docker exec airbyte-abctl-control-plane sh -c \
  "PGPASSWORD='<password>' psql -h <server-ip> -p 5433 -U airbyte -d marketing_data -c 'SELECT 1'"

# 4. If timeout, add UFW rule:
sudo ufw allow from 172.19.0.0/16 to any port 5433 comment 'Kind to Destination DB'

# 5. Use server PUBLIC IP in Airbyte UI, not container name
# Host: <your-server-ip> instead of airbyte_destination_db
```

#### Sync Fails: "Out of Memory"
```bash
# 1. Check Kind cluster resources
docker stats airbyte-abctl-control-plane

# 2. Increase server RAM if possible

# 3. Reduce sync frequency
# Airbyte UI: Connections → Schedule → Every 12/24 hours

# 4. Limit streams to sync
# Airbyte UI: Connections → Streams → Deselect unused streams

# 5. Enable incremental sync
# Airbyte UI: Sync Mode → Incremental instead of Full Refresh
```

#### Source Authentication Expires
```bash
# OAuth tokens expire periodically

# 1. Airbyte UI: Sources → Your Source → Settings
# 2. Click "Re-authenticate"
# 3. Complete OAuth flow
# 4. Test connection
# 5. Syncs will resume automatically

# For n8n automation:
# Build token refresh workflow that monitors for auth errors
# and triggers re-authentication
```

#### Sync is Very Slow
```bash
# 1. Check network connectivity
docker exec airbyte-abctl-control-plane ping -c 3 google.com

# 2. Optimize sync configuration:
# - Use incremental sync instead of full refresh
# - Reduce historical data range
# - Sync less frequently (daily instead of hourly)
# - Disable unused streams

# 3. Check source API rate limits
# Most APIs have rate limits (e.g., Google Ads: 15K requests/day)
# Spread syncs throughout the day

# 4. Monitor Airbyte logs
docker logs airbyte-abctl-control-plane | grep -i "rate limit"
```

#### Database Connection Pool Exhausted
```bash
# Increase PostgreSQL connection limit

# 1. Edit docker-compose.yml
airbyte_destination_db:
  command: postgres -c max_connections=200  # Default: 100

# 2. Restart database
corekit restart airbyte_destination_db

# 3. Verify
docker exec airbyte_destination_db psql -U airbyte -c "SHOW max_connections;"
```

### Monitoring & Observability

#### Key Metrics to Track
```sql
-- Sync Success Rate (Last 7 Days)
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_syncs,
  SUM(CASE WHEN status = 'succeeded' THEN 1 ELSE 0 END) as successful,
  ROUND(AVG(CASE WHEN status = 'succeeded' THEN 100 ELSE 0 END), 2) as success_rate
FROM airbyte_jobs
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Data Freshness (Time Since Last Sync)
SELECT 
  connection_name,
  MAX(updated_at) as last_sync,
  EXTRACT(EPOCH FROM (NOW() - MAX(updated_at)))/3600 as hours_since_sync
FROM airbyte_sync_log
GROUP BY connection_name
HAVING EXTRACT(EPOCH FROM (NOW() - MAX(updated_at)))/3600 > 25  -- Alert if >25 hours
ORDER BY hours_since_sync DESC;

-- Volume Metrics
SELECT 
  connection_name,
  DATE(synced_at) as date,
  SUM(records_synced) as total_records,
  SUM(bytes_synced) / 1024 / 1024 as mb_synced
FROM airbyte_sync_log
WHERE synced_at >= NOW() - INTERVAL '30 days'
GROUP BY connection_name, DATE(synced_at)
ORDER BY date DESC, total_records DESC;
```

#### Create Monitoring Dashboard in Metabase

1. Create "Airbyte Monitoring" collection
2. Add questions for each metric above
3. Create dashboard with:
   - Sync success rate (line chart)
   - Failed syncs (table with drill-down)
   - Data freshness (gauge chart)
   - Volume trends (stacked bar chart)
4. Set up Pulse (email alert) for failures

### Resources

- **Documentation:** https://docs.airbyte.com
- **Connector Catalog:** https://docs.airbyte.com/integrations
- **API Reference:** https://airbyte-public-api-docs.s3.us-east-2.amazonaws.com/rapidoc-api-docs.html
- **Community Forum:** https://discuss.airbyte.io
- **GitHub:** https://github.com/airbytehq/airbyte
- **abctl Documentation:** https://docs.airbyte.com/using-airbyte/getting-started/oss-quickstart

### Best Practices

**Connection Management:**
- Use descriptive names for sources/destinations/connections
- Document OAuth credentials in a secure password manager
- Set up monitoring for sync failures
- Test connections after any server changes
- Regular backups of Airbyte configuration (export via API)

**Performance Optimization:**
- Use incremental sync for large datasets
- Schedule heavy syncs during off-peak hours
- Disable unused streams to reduce load
- Monitor API rate limits for each source
- Use connection pooling for destinations

**Data Quality:**
- Enable schema change notifications
- Set up data validation checks in Metabase
- Monitor for sudden drops in record counts
- Regularly review sync logs for errors
- Test connections after source schema changes

**Security:**
- Rotate OAuth credentials quarterly
- Use read-only database users where possible
- Enable 2FA on all source accounts
- Audit access logs regularly
- Keep Airbyte updated (check for updates monthly)

**Cost Management:**
- Monitor API usage to stay within free tiers
- Use incremental sync to reduce compute costs
- Archive old syncs to save database storage
- Consolidate similar sources when possible
- Review and remove unused connections
