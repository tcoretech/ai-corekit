# 💾 Kopia - Encrypted Backup Solution

### What is Kopia?

Kopia is a fast, secure, open-source backup and restore tool that creates encrypted, compressed, and deduplicated snapshots of your data. Unlike full system imaging tools, Kopia allows you to selectively backup specific files and directories to various storage backends including cloud storage (S3, Azure, Google Cloud), WebDAV servers (like Nextcloud), SFTP servers, or local storage. It provides both a command-line interface (CLI) and a web-based graphical interface (GUI), making it accessible for both technical users and administrators.

**Current Version:** v0.21.1 (July 2025)

### Features

- **End-to-End Encryption** - AES-256-GCM or ChaCha20-Poly1305 encryption with your own passphrase
- **Data Deduplication** - Content-defined chunking eliminates duplicate data across all snapshots
- **Compression** - Multiple algorithms available (zstd, pgzip, s2) to reduce storage usage
- **Incremental Backups** - Only changed data is backed up, saving time and bandwidth
- **Snapshot Management** - Create, browse, and restore snapshots with flexible retention policies
- **WebDAV Support** - Full support for Nextcloud, ownCloud, and other WebDAV providers
- **Scheduling & Automation** - Built-in scheduler for automatic daily, hourly, or custom interval backups
- **Error Correction** - Reed-Solomon error correction codes protect against data corruption
- **Multi-Platform** - Works on Linux, Windows, macOS, FreeBSD, and in Docker containers

### Initial Setup

**First Login to Kopia:**

1. Navigate to `https://backup.yourdomain.com`
2. **Login Credentials** (set during installation):
```
   Username: [from KOPIA_SERVER_USERNAME in .env]
   Password: [from KOPIA_SERVER_PASSWORD in .env]
```
3. On first access, you'll need to **connect to a repository**

**Connect to Repository (WebDAV/Nextcloud):**

If you're using Nextcloud as your backup destination:

1. Click **Repository** → **Connect to Repository**
2. Select **WebDAV Server**
3. **WebDAV Configuration:**
```
   Server URL: https://your-nextcloud.com/remote.php/dav/files/USERNAME/kopia-backups
   WebDAV Username: [Nextcloud username]
   WebDAV Password: [Nextcloud app password - NOT your regular password!]
```
   
   **Important:** Create a dedicated **App Password** in Nextcloud:
   - Go to Nextcloud → **Settings** → **Security**
   - Create new app password: "Kopia Backup"
   - Use this app password in Kopia, NOT your main Nextcloud password

4. **Repository Password Setup:**
```
   Repository Password: [Choose a STRONG password - this encrypts your data!]
```
   
   ⚠️ **CRITICAL:** This password:
   - Must be DIFFERENT from your WebDAV/Nextcloud password
   - Encrypts all your backup data
   - Cannot be recovered if lost - write it down securely!
   - Store in password manager (Vaultwarden)

5. **Advanced Options** (click "Show Advanced Options"):
   - **Encryption:** AES-256-GCM (default, recommended)
   - **Hash Algorithm:** BLAKE2b-256 (default, recommended)
   - **Splitter:** DYNAMIC-4M-BUZHASH (default, recommended)
   - **Compression:** zstd (recommended) or pgzip
   - Leave defaults unless you know what you're doing

6. Click **Connect**

**Alternative: Create New Repository (Filesystem):**

For local/NAS storage instead of Nextcloud:

1. Click **Repository** → **New Repository**
2. Select **Filesystem**
3. Enter path: `/repository` (this is mounted from `/mnt/user-data/kopia-backups`)
4. Enter repository password (as above)
5. Click **Create Repository**

**Create Your First Snapshot:**

1. Go to **Snapshots** tab
2. Click **New Snapshot**
3. **Select Directory to Backup:**
   - For Docker volumes: `/docker-volumes`
   - For AI LaunchKit files: `/ai-launchkit`
   - For shared data: `/shared`
4. Click **Snapshot Now** for immediate backup
5. Or **Estimate** to see what will be backed up first

**Set Up Automated Backups:**

1. Go to **Policies** tab
2. Select the path you want to configure (e.g., `/docker-volumes`)
3. Click **Edit Policy**
4. **Scheduling** tab:
```
   Interval: Every 24 hours (daily at 2 AM recommended)
```
5. **Retention** tab (how long to keep snapshots):
```
   Latest snapshots: Keep 7 (last 7 days)
   Daily snapshots: Keep 14 (2 weeks)
   Weekly snapshots: Keep 8 (2 months)
   Monthly snapshots: Keep 12 (1 year)
   Annual snapshots: Keep all
```
6. **Files** tab (what to exclude):
```
   Exclude:
   - **/node_modules/**
   - **/.git/**
   - **/__pycache__/**
   - **/tmp/**
   - **/*.log
```
7. **Compression** tab:
```
   Algorithm: zstd (recommended - best compression/speed balance)
```
8. Click **Save Policy**

### n8n Integration Setup

**Internal URL for n8n:** `http://kopia:51515`

Kopia provides a RESTful API that n8n can use to trigger backups, check snapshot status, and manage policies. Authentication is done via HTTP Basic Auth using server credentials.

#### Generate API Credentials

Kopia uses the same server username/password for API access (set in `.env` during installation):

- **Username:** Value from `KOPIA_SERVER_USERNAME` 
- **Password:** Value from `KOPIA_SERVER_PASSWORD`

**Create HTTP Request Credentials in n8n:**

1. In n8n, go to **Credentials** → **Create New**
2. Search for **HTTP Request (Basic Auth)**
3. Configure:
```
   Name: Kopia API
   Username: [your KOPIA_SERVER_USERNAME]
   Password: [your KOPIA_SERVER_PASSWORD]
```
4. Test and save

#### Kopia API Endpoints

Kopia's API uses JSON-RPC 2.0 protocol. Here are key endpoints:

**Base URL:** `http://kopia:51515/api/v1/`

Common endpoints:
- `POST /repo/status` - Get repository status
- `POST /sources` - List snapshot sources
- `POST /snapshots` - List all snapshots
- `POST /snapshot-create` - Create new snapshot
- `POST /restore` - Restore files from snapshot
- `POST /policy-list` - List policies

**API Call Format:**
```json
{
  "jsonrpc": "2.0",
  "method": "method-name",
  "params": {},
  "id": 1
}
```

### Example Workflows

#### Example 1: Automated Daily Backup with Notification

Trigger daily backups and send Slack notifications on success/failure:
```javascript
// n8n Workflow: Automated Kopia Backup

// 1. Schedule Trigger - Every day at 2 AM
// Schedule: 0 2 * * *

// 2. HTTP Request Node - Trigger Backup for Docker Volumes
Method: POST
URL: http://kopia:51515/api/v1/snapshot-create
Authentication: Use Kopia API credentials (Basic Auth)
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "snapshot-create",
  "params": {
    "path": "/docker-volumes",
    "force": false
  },
  "id": 1
}

// 3. Code Node - Parse API Response
const response = $input.first().json;

// Check if backup was successful
const success = response.result && !response.error;
const snapshotId = response.result?.snapshotID || 'unknown';
const stats = response.result?.stats || {};

return {
  json: {
    success: success,
    snapshotId: snapshotId,
    filesBackedUp: stats.numFiles || 0,
    bytesBackedUp: stats.totalSize || 0,
    duration: stats.duration || 'unknown',
    timestamp: new Date().toISOString(),
    error: response.error?.message || null
  }
};

// 4. IF Node - Check Success
Condition: {{ $json.success }} === true

// 5a. Code Node - Format Success Message
const data = $input.first().json;
const sizeGB = (data.bytesBackedUp / 1024 / 1024 / 1024).toFixed(2);

return {
  json: {
    message: `✅ *Backup Successful*`,
    details: {
      snapshot: data.snapshotId.substring(0, 8),
      files: data.filesBackedUp,
      size: `${sizeGB} GB`,
      duration: data.duration,
      timestamp: data.timestamp
    }
  }
};

// 6a. Slack Node - Success Notification
Channel: #infrastructure
Message: |
  {{ $json.message }}
  
  *Backup Details:*
  • Snapshot ID: `{{ $json.details.snapshot }}...`
  • Files Backed Up: {{ $json.details.files }}
  • Total Size: {{ $json.details.size }}
  • Duration: {{ $json.details.duration }}
  • Completed: {{ $json.details.timestamp }}

// 5b. Code Node - Format Error Message (if backup failed)
const data = $('Code Node').first().json;

return {
  json: {
    severity: 'critical',
    message: `🚨 *Backup Failed*`,
    error: data.error || 'Unknown error',
    timestamp: data.timestamp
  }
};

// 7b. Slack Node - Error Alert
Channel: #incidents
Message: |
  {{ $json.message }}
  
  ⚠️ The automated backup at {{ $json.timestamp }} failed.
  
  *Error:* {{ $json.error }}
  
  Please check Kopia logs immediately.

// 8b. Email Node - Alert Administrator
To: admin@yourdomain.com
Subject: [CRITICAL] Kopia Backup Failed
Priority: High
Body: |
  Automated backup failed at {{ $json.timestamp }}.
  
  Error: {{ $json.error }}
  
  Please investigate: https://backup.yourdomain.com
```

#### Example 2: Backup Before System Updates

Create snapshots before running system updates or deployments:
```javascript
// n8n Workflow: Pre-Update Backup

// 1. Webhook Trigger
// URL: /webhook/pre-update-backup
// Method: POST
// Expected payload: { "component": "n8n", "version": "1.x.x" }

// 2. Code Node - Validate Payload
const payload = $input.first().json;

if (!payload.component) {
  throw new Error('Component name required');
}

return {
  json: {
    component: payload.component,
    version: payload.version || 'unknown',
    timestamp: new Date().toISOString()
  }
};

// 3. HTTP Request Node - Get Current Snapshots
Method: POST
URL: http://kopia:51515/api/v1/snapshots
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "snapshots-list",
  "params": {
    "path": "/docker-volumes"
  },
  "id": 1
}

// 4. Code Node - Check Last Snapshot Age
const response = $input.first().json;
const webhookData = $('Code Node').first().json;
const snapshots = response.result?.snapshots || [];

// Get most recent snapshot
const lastSnapshot = snapshots.length > 0 
  ? new Date(snapshots[0].startTime)
  : null;

const now = new Date();
const hoursSinceLastBackup = lastSnapshot 
  ? (now - lastSnapshot) / (1000 * 60 * 60)
  : 999;

// Only create new backup if last one is older than 2 hours
const needsBackup = hoursSinceLastBackup > 2;

return {
  json: {
    ...webhookData,
    lastSnapshot: lastSnapshot?.toISOString() || 'none',
    hoursSinceLastBackup: parseFloat(hoursSinceLastBackup.toFixed(2)),
    needsBackup: needsBackup
  }
};

// 5. IF Node - Needs Backup?
Condition: {{ $json.needsBackup }} === true

// 6a. HTTP Request Node - Create Pre-Update Snapshot
Method: POST
URL: http://kopia:51515/api/v1/snapshot-create
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "snapshot-create",
  "params": {
    "path": "/docker-volumes",
    "description": "Pre-update backup for {{ $json.component }} v{{ $json.version }}",
    "force": false,
    "tags": {
      "type": "pre-update",
      "component": "{{ $json.component }}",
      "version": "{{ $json.version }}"
    }
  },
  "id": 1
}

// 7. Wait Node - Give Backup Time to Complete
Amount: 30
Unit: seconds

// 8. HTTP Request Node - Verify Backup Status
Method: POST
URL: http://kopia:51515/api/v1/repo/status
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "repo-status",
  "params": {},
  "id": 1
}

// 9. Code Node - Prepare Success Response
const webhookData = $('Code Node1').first().json;
const backupResult = $('HTTP Request1').first().json;
const snapshotId = backupResult.result?.snapshotID || 'unknown';

return {
  json: {
    success: true,
    message: `Pre-update backup completed for ${webhookData.component}`,
    snapshotId: snapshotId,
    component: webhookData.component,
    version: webhookData.version,
    timestamp: webhookData.timestamp
  }
};

// 10. Respond to Webhook
Response Code: 200
Response Body:
{
  "status": "success",
  "message": "{{ $json.message }}",
  "snapshot_id": "{{ $json.snapshotId }}",
  "safe_to_proceed": true
}

// 6b. Code Node - Skip Backup (recent snapshot exists)
const webhookData = $('Code Node1').first().json;

return {
  json: {
    success: true,
    message: `Recent backup exists (${webhookData.hoursSinceLastBackup}h ago), skipping`,
    component: webhookData.component,
    lastSnapshot: webhookData.lastSnapshot
  }
};

// 11. Respond to Webhook - Recent Backup
Response Code: 200
Response Body:
{
  "status": "skipped",
  "message": "{{ $json.message }}",
  "last_snapshot": "{{ $json.lastSnapshot }}",
  "safe_to_proceed": true
}
```

#### Example 3: Monitor Backup Health & Storage Usage

Check repository health and alert if storage is filling up:
```javascript
// n8n Workflow: Kopia Health Monitor

// 1. Schedule Trigger - Every 6 hours

// 2. HTTP Request Node - Get Repository Status
Method: POST
URL: http://kopia:51515/api/v1/repo/status
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "repo-status",
  "params": {},
  "id": 1
}

// 3. Code Node - Parse Repository Status
const response = $input.first().json;
const status = response.result || {};

// Calculate storage metrics
const totalSize = status.storage?.totalSize || 0;
const usedSize = status.storage?.usedSize || 0;
const usagePercent = totalSize > 0 ? (usedSize / totalSize * 100).toFixed(1) : 0;

// Define thresholds
const warningThreshold = 80;
const criticalThreshold = 90;

let alertLevel = 'ok';
if (usagePercent >= criticalThreshold) {
  alertLevel = 'critical';
} else if (usagePercent >= warningThreshold) {
  alertLevel = 'warning';
}

return {
  json: {
    connected: status.connected || false,
    totalSize_GB: (totalSize / 1024 / 1024 / 1024).toFixed(2),
    usedSize_GB: (usedSize / 1024 / 1024 / 1024).toFixed(2),
    freeSize_GB: ((totalSize - usedSize) / 1024 / 1024 / 1024).toFixed(2),
    usagePercent: parseFloat(usagePercent),
    alertLevel: alertLevel,
    timestamp: new Date().toISOString()
  }
};

// 4. HTTP Request Node - List Recent Snapshots
Method: POST
URL: http://kopia:51515/api/v1/snapshots
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "snapshots-list",
  "params": {},
  "id": 1
}

// 5. Code Node - Analyze Snapshot Health
const snapshotsResponse = $input.first().json;
const statusData = $('Code Node').first().json;
const snapshots = snapshotsResponse.result?.snapshots || [];

// Group snapshots by source
const sourceStats = {};
snapshots.forEach(snap => {
  const source = snap.source || 'unknown';
  if (!sourceStats[source]) {
    sourceStats[source] = {
      count: 0,
      lastSnapshot: null,
      oldestSnapshot: null
    };
  }
  
  sourceStats[source].count++;
  
  const snapTime = new Date(snap.startTime);
  if (!sourceStats[source].lastSnapshot || snapTime > sourceStats[source].lastSnapshot) {
    sourceStats[source].lastSnapshot = snapTime;
  }
  if (!sourceStats[source].oldestSnapshot || snapTime < sourceStats[source].oldestSnapshot) {
    sourceStats[source].oldestSnapshot = snapTime;
  }
});

// Check for stale backups (no snapshot in last 48 hours)
const now = new Date();
const staleBackups = [];
Object.entries(sourceStats).forEach(([source, stats]) => {
  const hoursSinceLastBackup = (now - stats.lastSnapshot) / (1000 * 60 * 60);
  if (hoursSinceLastBackup > 48) {
    staleBackups.push({
      source: source,
      lastBackup: stats.lastSnapshot.toISOString(),
      hoursAgo: parseFloat(hoursSinceLastBackup.toFixed(1))
    });
  }
});

return {
  json: {
    ...statusData,
    totalSnapshots: snapshots.length,
    sourcesCount: Object.keys(sourceStats).length,
    staleBackups: staleBackups,
    hasStaleBackups: staleBackups.length > 0
  }
};

// 6. IF Node - Any Issues?
Condition: {{ $json.alertLevel }} !== 'ok' OR {{ $json.hasStaleBackups }} === true

// 7a. Code Node - Format Alert Message
const data = $input.first().json;

let message = '';
let severity = 'warning';

if (data.alertLevel === 'critical') {
  message = `🚨 *CRITICAL: Kopia Storage ${data.usagePercent}% Full*`;
  severity = 'critical';
} else if (data.alertLevel === 'warning') {
  message = `⚠️ *WARNING: Kopia Storage ${data.usagePercent}% Full*`;
}

if (data.hasStaleBackups) {
  message += `\n\n📅 *Stale Backups Detected:*`;
}

return {
  json: {
    severity: severity,
    message: message,
    storage: {
      total: data.totalSize_GB,
      used: data.usedSize_GB,
      free: data.freeSize_GB,
      percent: data.usagePercent
    },
    staleBackups: data.staleBackups,
    totalSnapshots: data.totalSnapshots
  }
};

// 8a. Slack Node - Send Alert
Channel: #infrastructure-alerts
Message: |
  {{ $json.message }}
  
  *Storage Status:*
  • Total: {{ $json.storage.total }} GB
  • Used: {{ $json.storage.used }} GB ({{ $json.storage.percent }}%)
  • Free: {{ $json.storage.free }} GB
  • Total Snapshots: {{ $json.totalSnapshots }}
  
  {{ $json.staleBackups.length > 0 ? `*Stale Backups:*\n${$json.staleBackups.map(b => `• ${b.source}: ${b.hoursAgo}h ago`).join('\n')}` : '' }}
  
  Action Required: Review backup configuration

// 9a. Email Node - Alert Administrator (if critical)
Condition: {{ $('Code Node1').first().json.severity }} === 'critical'
To: admin@yourdomain.com
Subject: [CRITICAL] Kopia Storage Almost Full
Priority: High
Body: |
  Kopia repository storage is {{ $('Code Node1').first().json.storage.percent }}% full.
  
  Please free up space or expand storage immediately.
  
  Dashboard: https://backup.yourdomain.com

// 7b. Do Nothing (if all healthy)
```

#### Example 4: Automated Restore Testing

Periodically test that backups can actually be restored:
```javascript
// n8n Workflow: Backup Restore Test

// 1. Schedule Trigger - Weekly on Sunday at 3 AM

// 2. HTTP Request Node - List Available Snapshots
Method: POST
URL: http://kopia:51515/api/v1/snapshots
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "snapshots-list",
  "params": {
    "path": "/docker-volumes"
  },
  "id": 1
}

// 3. Code Node - Select Random Snapshot for Testing
const response = $input.first().json;
const snapshots = response.result?.snapshots || [];

if (snapshots.length === 0) {
  throw new Error('No snapshots available for testing');
}

// Select a random recent snapshot (from last 7 days)
const recentSnapshots = snapshots.filter(snap => {
  const snapDate = new Date(snap.startTime);
  const daysDiff = (new Date() - snapDate) / (1000 * 60 * 60 * 24);
  return daysDiff <= 7;
});

const selectedSnapshot = recentSnapshots[Math.floor(Math.random() * recentSnapshots.length)];

return {
  json: {
    snapshotId: selectedSnapshot.id,
    snapshotDate: selectedSnapshot.startTime,
    path: selectedSnapshot.source,
    size: selectedSnapshot.stats?.totalSize || 0
  }
};

// 4. HTTP Request Node - List Files in Snapshot
Method: POST
URL: http://kopia:51515/api/v1/snapshot-list-files
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "snapshot-list-files",
  "params": {
    "snapshotID": "{{ $json.snapshotId }}",
    "path": "/"
  },
  "id": 1
}

// 5. Code Node - Select Random File for Restore Test
const response = $input.first().json;
const snapshotInfo = $('Code Node').first().json;
const files = response.result?.entries || [];

// Filter for actual files (not directories)
const regularFiles = files.filter(f => f.type === 'f' && f.size < 10 * 1024 * 1024); // Max 10MB

if (regularFiles.length === 0) {
  throw new Error('No suitable files found for restore test');
}

const testFile = regularFiles[Math.floor(Math.random() * regularFiles.length)];

return {
  json: {
    ...snapshotInfo,
    testFile: testFile.name,
    testFilePath: testFile.path,
    testFileSize: testFile.size
  }
};

// 6. HTTP Request Node - Restore Test File
Method: POST
URL: http://kopia:51515/api/v1/restore
Authentication: Use Kopia API credentials
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "restore",
  "params": {
    "snapshotID": "{{ $json.snapshotId }}",
    "path": "{{ $json.testFilePath }}",
    "target": "/tmp/kopia-restore-test/"
  },
  "id": 1
}

// 7. Wait Node - Give Restore Time
Amount: 10
Unit: seconds

// 8. Code Node - Verify Restore Success
const restoreResult = $input.first().json;
const testInfo = $('Code Node1').first().json;

const success = restoreResult.result && !restoreResult.error;

return {
  json: {
    success: success,
    testFile: testInfo.testFile,
    snapshotId: testInfo.snapshotId.substring(0, 8),
    snapshotDate: testInfo.snapshotDate,
    fileSize: (testInfo.testFileSize / 1024).toFixed(2),
    error: restoreResult.error?.message || null,
    timestamp: new Date().toISOString()
  }
};

// 9. IF Node - Test Successful?
Condition: {{ $json.success }} === true

// 10a. Slack Node - Success Report
Channel: #infrastructure
Message: |
  ✅ *Weekly Backup Restore Test: PASSED*
  
  *Test Details:*
  • Snapshot: `{{ $json.snapshotId }}...`
  • Date: {{ $json.snapshotDate }}
  • Test File: {{ $json.testFile }}
  • Size: {{ $json.fileSize }} KB
  • Status: Restore successful
  
  Backups are working correctly! 🎉

// 10b. Code Node - Format Failure Alert
const data = $('Code Node2').first().json;

return {
  json: {
    severity: 'critical',
    message: `🚨 *Backup Restore Test FAILED*`,
    testFile: data.testFile,
    snapshotId: data.snapshotId,
    error: data.error,
    timestamp: data.timestamp
  }
};

// 11b. Slack Node - Failure Alert
Channel: #incidents
Message: |
  {{ $json.message }}
  
  ⚠️ The weekly restore test failed!
  
  *Details:*
  • Test File: {{ $json.testFile }}
  • Snapshot: `{{ $json.snapshotId }}...`
  • Error: {{ $json.error }}
  
  🔥 Action Required: Investigate backup integrity immediately

// 12b. Email Node - Critical Alert
To: admin@yourdomain.com
Subject: [CRITICAL] Kopia Restore Test Failed
Priority: Highest
Body: |
  Weekly backup restore test has FAILED.
  
  Error: {{ $json.error }}
  
  This indicates your backups may not be restorable!
  Please investigate immediately: https://backup.yourdomain.com
```

### Best Practices

1. **Separate Passwords** - ALWAYS use different passwords for:
   - Kopia server authentication (WebUI access)
   - Repository encryption (data encryption)
   - WebDAV/Nextcloud credentials
   
2. **Secure Password Storage** - Store all Kopia passwords in Vaultwarden
   
3. **Regular Restore Testing** - Test restores monthly to verify backup integrity

4. **Storage Monitoring** - Monitor repository storage usage and set alerts at 80%

5. **Retention Policies** - Configure appropriate retention:
   - Daily backups: 7-14 days
   - Weekly backups: 4-8 weeks
   - Monthly backups: 12 months
   - Yearly backups: Keep all

6. **Backup Verification** - Enable snapshot verification in policies

7. **Network Security** - Keep Kopia WebUI behind Caddy reverse proxy with HTTPS

8. **Off-site Backups** - Use remote WebDAV (Nextcloud) or cloud storage, not just local

9. **Exclude Unnecessary Files** - Use `.kopiaignore` files to exclude:
   - Cache directories
   - Temporary files
   - Large log files
   - node_modules
   - Build artifacts

10. **Document Recovery Procedures** - Maintain written recovery procedures and test them

### Troubleshooting

#### Kopia Container Won't Start
```bash
# Check logs
docker logs kopia --tail 100

# Common issue: Repository not mounted
docker inspect kopia | grep -A5 "Mounts"
# Should show: /mnt/user-data/kopia-backups

# Check directory permissions
ls -la /mnt/user-data/kopia-backups

# Restart Kopia
docker restart kopia
```

#### Cannot Connect to Repository
```bash
# 1. Verify repository directory exists and is accessible
ls -la /repository/

# 2. Check Kopia logs for specific error
docker logs kopia --tail 50 | grep -i error

# Common errors:
# - "invalid repository password" → Wrong KOPIA_PASSWORD
# - "repository not found" → Run repository initialization
# - "WebDAV connection failed" → Check Nextcloud URL and credentials

# 3. Test WebDAV connectivity manually
curl -u "user:pass" "https://nextcloud.com/remote.php/dav/files/user/"

# 4. For WebDAV issues, verify Nextcloud app password is valid
# Nextcloud → Settings → Security → check app passwords
```

#### Snapshots Failing Silently
```bash
# 1. Check Kopia server logs
docker exec kopia kopia logs show --max-count 50

# 2. Verify repository status
docker exec kopia kopia repository status

# 3. Check for disk space issues
df -h /mnt/user-data/kopia-backups

# 4. Validate policy settings
docker exec kopia kopia policy list

# 5. Test manual snapshot
docker exec kopia kopia snapshot create /docker-volumes --verbose
```

#### High Memory Usage
```bash
# Check Kopia resource usage
docker stats kopia --no-stream

# Kopia memory scales with:
# - Number of files being backed up
# - Compression level (zstd uses more memory)
# - Parallel upload streams

# Adjust in docker-compose.yml if needed:
deploy:
  resources:
    limits:
      memory: 2G  # Increase from default

# Reduce parallelism in Kopia policy:
docker exec kopia kopia policy set /docker-volumes \
  --parallel 2  # Default is 8
```

#### WebDAV Upload Failures (Nextcloud)
```bash
# 1. Check Nextcloud upload limits
# Nextcloud config.php:
'max_chunk_size' => 10485760,  # 10MB chunks
'bulkupload.enabled' => true,

# 2. Check reverse proxy (Caddy/Nginx) upload limits
# Caddy should allow large uploads by default

# 3. Test direct WebDAV upload
curl -T largefile.dat -u "user:pass" \
  "https://nextcloud.com/remote.php/dav/files/user/test.dat"

# 4. Adjust Kopia chunk size if needed
docker exec kopia kopia repository set-parameters \
  --max-pack-size=50MB

# 5. Check PHP memory limit in Nextcloud
# php.ini: memory_limit = 512M
```

#### Cannot Access Kopia WebUI
```bash
# 1. Verify container is running
docker ps | grep kopia

# 2. Check port mapping
docker port kopia

# 3. Test internal connectivity
curl -k http://localhost:51515/

# 4. Check Caddy reverse proxy
docker logs caddy | grep backup

# 5. Verify authentication credentials
# Username/password from KOPIA_SERVER_USERNAME/PASSWORD in .env
```

#### Restore Operation Fails
```bash
# 1. Verify snapshot exists
docker exec kopia kopia snapshot list

# 2. Check available disk space for restore
df -h /restore-target

# 3. Test with smaller file first
docker exec kopia kopia restore \
  ksnapshotID:/path/to/small-file \
  /tmp/test-restore/

# 4. Check repository connectivity during restore
docker exec kopia kopia repository status

# 5. Review error logs
docker exec kopia kopia logs show --max-count 100 | grep -i error
```

### Resources

- **Documentation:** [https://kopia.io/docs/](https://kopia.io/docs/)
- **GitHub:** [https://github.com/kopia/kopia](https://github.com/kopia/kopia)
- **Community Forum:** [https://kopia.discourse.group/](https://kopia.discourse.group/)
- **Installation Guide:** [https://kopia.io/docs/installation/](https://kopia.io/docs/installation/)
- **Repositories Guide:** [https://kopia.io/docs/repositories/](https://kopia.io/docs/repositories/)
- **Policies Documentation:** [https://kopia.io/docs/advanced/policies/](https://kopia.io/docs/advanced/policies/)
- **API Reference:** [https://kopia.io/docs/reference/command-line/](https://kopia.io/docs/reference/command-line/)
- **Docker Hub:** [https://hub.docker.com/r/kopia/kopia](https://hub.docker.com/r/kopia/kopia)
- **Release Notes:** [https://github.com/kopia/kopia/releases](https://github.com/kopia/kopia/releases)
