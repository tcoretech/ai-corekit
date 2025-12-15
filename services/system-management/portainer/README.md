# 🐳 Portainer - Docker Container Management UI

### What is Portainer?

Portainer is a lightweight, open-source container management platform that provides an intuitive web-based interface for managing Docker containers, images, volumes, networks, and stacks. It simplifies container operations that would otherwise require complex CLI commands, making Docker accessible to both beginners and enterprise teams. Portainer can manage local Docker environments, remote Docker hosts, Docker Swarm clusters, and even Kubernetes.

### Features

- **Visual Container Management** - Start, stop, restart, and monitor containers with a simple click interface
- **Stack Deployment** - Deploy multi-container applications using Docker Compose files directly from the UI
- **Multi-Environment Support** - Manage multiple Docker hosts, Swarm clusters, and Kubernetes from a single dashboard
- **Resource Monitoring** - Real-time CPU, memory, and network usage statistics for containers and hosts
- **Role-Based Access Control (RBAC)** - Define user roles and permissions (Business Edition feature)
- **App Templates** - Pre-configured templates for popular applications like WordPress, MySQL, Nginx, and more

### Initial Setup

**First Login to Portainer:**

1. Navigate to `https://portainer.yourdomain.com`
2. **Create Admin Account** (first-time setup):
   ```
   Username: admin
   Password: [Choose a strong password - at least 12 characters]
   ```
3. Click **Create user**
4. **Connect to Docker Environment:**
   - Select **Get Started** or **Docker**
   - Portainer auto-detects local Docker via `/var/run/docker.sock`
   - Click **Connect**

**Explore the Dashboard:**

1. **Home** - Overview of all environments and quick stats
2. **Containers** - List and manage running/stopped containers
3. **Images** - Browse, pull, and delete Docker images
4. **Volumes** - Manage persistent data volumes
5. **Networks** - View and configure Docker networks
6. **Stacks** - Deploy and manage Docker Compose applications
7. **App Templates** - Quick-deploy popular applications

**Deploy Your First Stack:**

1. Go to **Stacks** → **Add stack**
2. Name: `test-nginx`
3. Choose **Web editor**
4. Paste this example:
   ```yaml
   version: '3.8'
   services:
     nginx:
       image: nginx:alpine
       ports:
         - "8080:80"
       restart: unless-stopped
   ```
5. Click **Deploy the stack**
6. Access at `http://your-server-ip:8080`

### n8n Integration Setup

**Internal URL for n8n:** `http://portainer:9000`

Portainer provides a comprehensive REST API that n8n can use to automate container management tasks. Authentication is done via API access tokens.

#### Generate API Access Token

**Method 1: Via Portainer UI (Recommended)**

1. In Portainer, go to **User Settings** (click your username in top-right)
2. Select **Access tokens**
3. Click **Add access token**
4. Configure:
   ```
   Description: n8n-automation
   Expiry: Never (or set custom expiry)
   ```
5. Click **Add**
6. **Copy the token immediately** - it won't be shown again!
7. Store securely in n8n credentials or `.env` file

**Method 2: Via API**

```bash
# First login to get JWT token
curl -X POST http://portainer:9000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}'

# Response: {"jwt":"eyJhbGci..."}

# Create access token
curl -X POST http://portainer:9000/api/users/1/tokens \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"n8n-automation"}'

# Response: {"rawAPIKey":"ptr_YOUR_ACCESS_TOKEN"}
```

**Create HTTP Request Credentials in n8n:**

1. In n8n, go to **Credentials** → **Create New**
2. Search for **Header Auth**
3. Configure:
   ```
   Name: Portainer API
   Header Name: X-API-Key
   Header Value: ptr_YOUR_ACCESS_TOKEN_HERE
   ```
4. Test and save

### Example Workflows

#### Example 1: Monitor Container Health & Auto-Restart Failed Containers

Automatically detect and restart containers that have exited unexpectedly:

```javascript
// n8n Workflow: Container Health Monitor

// 1. Schedule Trigger - Every 5 minutes

// 2. HTTP Request Node - Get all containers
Method: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/json
Authentication: Use Portainer API credentials
Query Parameters:
  all: true

// Response: Array of container objects

// 3. Code Node - Filter for failed containers
const containers = $input.first().json;

// Find containers that exited unexpectedly (not manually stopped)
const failedContainers = containers.filter(container => {
  const state = container.State;
  const status = container.Status;
  
  // Container is stopped but has restart policy
  const hasRestartPolicy = container.HostConfig?.RestartPolicy?.Name !== 'no';
  const isExited = state === 'exited';
  const recentlyExited = status.includes('Exited') && 
    !status.includes('hours ago') && 
    !status.includes('days ago');
  
  return isExited && recentlyExited && hasRestartPolicy;
});

// Return container details
return failedContainers.map(container => ({
  json: {
    id: container.Id,
    name: container.Names[0].replace('/', ''),
    image: container.Image,
    status: container.Status,
    exitCode: container.State,
    created: new Date(container.Created * 1000).toISOString()
  }
}));

// 4. IF Node - Check if failed containers exist
Condition: {{ $json.id }} is not empty

// 5a. Loop Node - Process each failed container
Items: {{ $input.all() }}

// 6. HTTP Request Node - Get container details
Method: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/{{ $json.id }}/json
Authentication: Use Portainer API credentials

// 7. Code Node - Analyze failure
const container = $input.first().json;
const restartCount = container.RestartCount || 0;
const maxRestarts = 3;

// Check if container is in restart loop
const shouldRestart = restartCount < maxRestarts;

return {
  json: {
    id: container.Id,
    name: container.Name.replace('/', ''),
    image: container.Config.Image,
    restartCount: restartCount,
    shouldRestart: shouldRestart,
    exitCode: container.State.ExitCode,
    error: container.State.Error || 'Unknown error',
    finishedAt: container.State.FinishedAt
  }
};

// 8. IF Node - Should restart?
Condition: {{ $json.shouldRestart }} === true

// 9a. HTTP Request Node - Restart container
Method: POST
URL: http://portainer:9000/api/endpoints/1/docker/containers/{{ $json.id }}/restart
Authentication: Use Portainer API credentials

// 10. Code Node - Prepare notification
const container = $('Code Node1').first().json;
const restarted = $('HTTP Request2').first().json;

return {
  json: {
    message: `🔄 Auto-restarted container: ${container.name}`,
    details: {
      container: container.name,
      image: container.image,
      exitCode: container.exitCode,
      error: container.error,
      restartCount: container.restartCount,
      timestamp: new Date().toISOString()
    }
  }
};

// 11. Slack Node - Notify success
Channel: #infrastructure
Message: |
  {{ $json.message }}
  
  *Details:*
  • Container: `{{ $json.details.container }}`
  • Image: `{{ $json.details.image }}`
  • Exit Code: {{ $json.details.exitCode }}
  • Error: {{ $json.details.error }}
  • Restart #{{ $json.details.restartCount }}

// 9b. Code Node - Prepare alert (if max restarts exceeded)
const container = $('Code Node1').first().json;

return {
  json: {
    severity: 'critical',
    message: `🚨 Container restart loop detected: ${container.name}`,
    details: {
      container: container.name,
      image: container.image,
      restartCount: container.restartCount,
      exitCode: container.exitCode,
      error: container.error,
      action: 'Manual intervention required'
    }
  }
};

// 12. Slack Node - Alert ops team
Channel: #incidents
Message: |
  {{ $json.message }}
  
  Container has exceeded maximum auto-restart attempts ({{ $json.details.restartCount }}).
  
  *Details:*
  • Container: `{{ $json.details.container }}`
  • Image: `{{ $json.details.image }}`
  • Exit Code: {{ $json.details.exitCode }}
  • Error: {{ $json.details.error }}
  
  ⚠️ Action Required: Investigate and manually fix

// 13. Email Node - Send to on-call engineer
To: oncall@yourdomain.com
Subject: [CRITICAL] Container Failure: {{ $json.details.container }}
Priority: High
Body: {{ $json.message }}

// 5b. Do Nothing (if no failed containers)
```

#### Example 2: Automated Stack Updates via Webhook

Trigger stack updates from external CI/CD pipelines or GitHub webhooks:

```javascript
// n8n Workflow: Automated Stack Deployment

// 1. Webhook Trigger
// URL: /webhook/deploy-stack
// Method: POST
// Expected payload: { "stack_name": "myapp", "compose_file": "..." }

// 2. Code Node - Validate webhook payload
const payload = $input.first().json;

if (!payload.stack_name || !payload.compose_file) {
  throw new Error('Missing required fields: stack_name and compose_file');
}

return {
  json: {
    stackName: payload.stack_name,
    composeFile: payload.compose_file,
    environment: payload.environment || 'production',
    pullImages: payload.pull_images !== false,
    branch: payload.branch || 'main',
    commit: payload.commit_sha || 'unknown'
  }
};

// 3. HTTP Request Node - Get existing stacks
Method: GET
URL: http://portainer:9000/api/stacks
Authentication: Use Portainer API credentials

// 4. Code Node - Check if stack exists
const stacks = $input.first().json;
const webhookData = $('Code Node').first().json;
const stackName = webhookData.stackName;

const existingStack = stacks.find(s => s.Name === stackName);

return {
  json: {
    ...webhookData,
    stackExists: !!existingStack,
    stackId: existingStack?.Id || null,
    endpoint: existingStack?.EndpointId || 1
  }
};

// 5. Switch Node - Route based on stack existence
// Mode: Expression
// Output 0: {{ $json.stackExists }} === true
// Output 1: {{ $json.stackExists }} === false

// 6a. HTTP Request Node - Update existing stack
Method: PUT
URL: http://portainer:9000/api/stacks/{{ $json.stackId }}
Authentication: Use Portainer API credentials
Query Parameters:
  endpointId: {{ $json.endpoint }}
Body (JSON):
{
  "stackFileContent": "{{ $json.composeFile }}",
  "prune": true,
  "pullImage": {{ $json.pullImages }}
}

// 6b. HTTP Request Node - Create new stack
Method: POST
URL: http://portainer:9000/api/stacks
Authentication: Use Portainer API credentials
Query Parameters:
  type: 2
  method: string
  endpointId: 1
Body (JSON):
{
  "name": "{{ $json.stackName }}",
  "stackFileContent": "{{ $json.composeFile }}"
}

// 7. Wait Node - Give stack time to deploy
Amount: 10
Unit: seconds

// 8. HTTP Request Node - Get stack status
Method: GET
URL: http://portainer:9000/api/stacks/{{ $('Switch Node').first().json.stackId || $('HTTP Request1').first().json.Id }}
Authentication: Use Portainer API credentials

// 9. Code Node - Verify deployment
const stack = $input.first().json;
const webhookData = $('Code Node').first().json;

// Get container count and status
const containerCount = stack.ResourceControl?.ResourceCount || 0;

return {
  json: {
    success: true,
    stackName: stack.Name,
    stackId: stack.Id,
    containers: containerCount,
    environment: webhookData.environment,
    branch: webhookData.branch,
    commit: webhookData.commit,
    deployedAt: new Date().toISOString(),
    url: `https://portainer.yourdomain.com/#!/stacks/${stack.Id}`
  }
};

// 10. Slack Node - Notify deployment success
Channel: #deployments
Message: |
  ✅ *Deployment Successful*
  
  *Stack:* {{ $json.stackName }}
  *Environment:* {{ $json.environment }}
  *Containers:* {{ $json.containers }}
  *Branch:* {{ $json.branch }}
  *Commit:* {{ $json.commit }}
  
  🔗 <{{ $json.url }}|View in Portainer>

// 11. HTTP Request Node - Trigger health check (optional)
Method: POST
URL: https://your-monitoring-service.com/api/healthcheck
Body (JSON):
{
  "stack": "{{ $json.stackName }}",
  "environment": "{{ $json.environment }}",
  "timestamp": "{{ $json.deployedAt }}"
}

// 12. Respond to Webhook - Success
Response Code: 200
Response Body:
{
  "status": "success",
  "message": "Stack deployed successfully",
  "stack_id": {{ $json.stackId }},
  "containers": {{ $json.containers }}
}
```

#### Example 3: Resource Usage Monitoring & Alerts

Monitor container resource consumption and alert when thresholds are exceeded:

```javascript
// n8n Workflow: Container Resource Monitoring

// 1. Schedule Trigger - Every 10 minutes

// 2. HTTP Request Node - Get running containers
Method: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/json
Authentication: Use Portainer API credentials
Query Parameters:
  filters: {"status":["running"]}

// 3. Code Node - Extract container IDs
const containers = $input.first().json;
return containers.map(c => ({ json: { id: c.Id, name: c.Names[0].replace('/', '') } }));

// 4. Loop Node - Process each container
Items: {{ $input.all() }}

// 5. HTTP Request Node - Get container stats
Method: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/{{ $json.id }}/stats
Authentication: Use Portainer API credentials
Query Parameters:
  stream: false

// 6. Code Node - Calculate resource usage
const stats = $input.first().json;
const containerInfo = $('Loop Node').first().json;

// Calculate CPU percentage
const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - 
                 stats.precpu_stats.cpu_usage.total_usage;
const systemDelta = stats.cpu_stats.system_cpu_usage - 
                    stats.precpu_stats.system_cpu_usage;
const cpuPercent = (cpuDelta / systemDelta) * 
                   stats.cpu_stats.online_cpus * 100;

// Calculate memory usage
const memoryUsage = stats.memory_stats.usage;
const memoryLimit = stats.memory_stats.limit;
const memoryPercent = (memoryUsage / memoryLimit) * 100;

// Calculate network I/O
let networkRx = 0;
let networkTx = 0;
if (stats.networks) {
  Object.values(stats.networks).forEach(net => {
    networkRx += net.rx_bytes;
    networkTx += net.tx_bytes;
  });
}

// Thresholds
const cpuThreshold = 80;
const memoryThreshold = 85;

const alerts = [];
if (cpuPercent > cpuThreshold) {
  alerts.push(`CPU: ${cpuPercent.toFixed(1)}% (threshold: ${cpuThreshold}%)`);
}
if (memoryPercent > memoryThreshold) {
  alerts.push(`Memory: ${memoryPercent.toFixed(1)}% (threshold: ${memoryThreshold}%)`);
}

return {
  json: {
    container: containerInfo.name,
    containerId: containerInfo.id,
    cpu_percent: parseFloat(cpuPercent.toFixed(2)),
    memory_usage_mb: parseFloat((memoryUsage / 1024 / 1024).toFixed(2)),
    memory_limit_mb: parseFloat((memoryLimit / 1024 / 1024).toFixed(2)),
    memory_percent: parseFloat(memoryPercent.toFixed(2)),
    network_rx_mb: parseFloat((networkRx / 1024 / 1024).toFixed(2)),
    network_tx_mb: parseFloat((networkTx / 1024 / 1024).toFixed(2)),
    has_alerts: alerts.length > 0,
    alerts: alerts
  }
};

// 7. Aggregate Node - Collect all stats
Mode: Append All

// 8. Code Node - Generate report
const allStats = $input.all().map(item => item.json);

// Sort by CPU usage
const topCPU = [...allStats].sort((a, b) => b.cpu_percent - a.cpu_percent).slice(0, 5);

// Sort by memory usage
const topMemory = [...allStats].sort((a, b) => b.memory_percent - a.memory_percent).slice(0, 5);

// Containers with alerts
const alertingContainers = allStats.filter(s => s.has_alerts);

return {
  json: {
    total_containers: allStats.length,
    alerting_containers: alertingContainers.length,
    top_cpu: topCPU,
    top_memory: topMemory,
    alerts: alertingContainers,
    timestamp: new Date().toISOString()
  }
};

// 9. IF Node - Check for alerts
Condition: {{ $json.alerting_containers }} > 0

// 10a. Slack Node - Send alert
Channel: #infrastructure-alerts
Message: |
  ⚠️ *Container Resource Alert*
  
  {{ $json.alerting_containers }} container(s) exceeding thresholds:
  
  {{ $json.alerts.map(a => `*${a.container}:*\n${a.alerts.join('\n')}`).join('\n\n') }}
  
  *Top CPU Consumers:*
  {{ $json.top_cpu.slice(0,3).map(c => `• ${c.container}: ${c.cpu_percent}%`).join('\n') }}
  
  *Top Memory Consumers:*
  {{ $json.top_memory.slice(0,3).map(c => `• ${c.container}: ${c.memory_percent}%`).join('\n') }}

// 10b. Do Nothing (if no alerts)

// 11. PostgreSQL Node - Log metrics
Operation: Insert
Table: container_metrics
Data: {{ $json }}
```

#### Example 4: Image Update Scanner

Scan for outdated container images and notify about available updates:

```javascript
// n8n Workflow: Container Image Update Scanner

// 1. Schedule Trigger - Daily at 3 AM

// 2. HTTP Request Node - Get all containers
Method: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/json
Authentication: Use Portainer API credentials
Query Parameters:
  all: true

// 3. Code Node - Extract unique images
const containers = $input.first().json;

// Get unique images in use
const imagesInUse = {};
containers.forEach(container => {
  const image = container.Image;
  const imageTag = container.ImageID;
  
  if (!imagesInUse[image]) {
    imagesInUse[image] = {
      image: image,
      imageId: imageTag,
      containers: []
    };
  }
  
  imagesInUse[image].containers.push(container.Names[0].replace('/', ''));
});

return Object.values(imagesInUse).map(img => ({ json: img }));

// 4. Loop Node - Check each image
Items: {{ $input.all() }}

// 5. Code Node - Parse image name and tag
const imageInfo = $input.first().json;
const imageParts = imageInfo.image.split(':');
const imageName = imageParts[0];
const currentTag = imageParts[1] || 'latest';

return {
  json: {
    ...imageInfo,
    imageName: imageName,
    currentTag: currentTag
  }
};

// 6. HTTP Request Node - Pull latest image info from Docker Hub
Method: GET
URL: https://hub.docker.com/v2/repositories/{{ $json.imageName.replace('library/', '') }}/tags/{{ $json.currentTag }}
// Note: For official images, remove 'library/' prefix

// 7. Code Node - Compare digest
const dockerHubInfo = $input.first().json;
const localInfo = $('Code Node1').first().json;

// Compare image digests
const localDigest = localInfo.imageId.split(':')[1]?.substring(0, 12) || '';
const remoteDigest = dockerHubInfo.images?.[0]?.digest?.split(':')[1]?.substring(0, 12) || '';

const updateAvailable = localDigest !== remoteDigest && remoteDigest !== '';

return {
  json: {
    image: localInfo.image,
    containers: localInfo.containers,
    currentDigest: localDigest,
    latestDigest: remoteDigest,
    updateAvailable: updateAvailable,
    lastUpdated: dockerHubInfo.last_updated
  }
};

// 8. Aggregate Node - Collect results

// 9. Code Node - Filter images with updates
const allImages = $input.all().map(item => item.json);
const updatesAvailable = allImages.filter(img => img.updateAvailable);

return {
  json: {
    total_images: allImages.length,
    updates_available: updatesAvailable.length,
    outdated_images: updatesAvailable,
    timestamp: new Date().toISOString()
  }
};

// 10. IF Node - Updates available?
Condition: {{ $json.updates_available }} > 0

// 11a. Slack Node - Notify about updates
Channel: #infrastructure
Message: |
  📦 *Container Image Updates Available*
  
  {{ $json.updates_available }} image(s) have updates:
  
  {{ $json.outdated_images.map(img => 
    `*${img.image}*\nUsed by: ${img.containers.join(', ')}\nLast updated: ${new Date(img.lastUpdated).toLocaleDateString()}`
  ).join('\n\n') }}
  
  Update containers in Portainer or via CI/CD.

// 11b. Do Nothing (if up to date)
```

### Best Practices

1. **API Token Security** - Store Portainer API tokens securely in n8n credentials, never in workflow code
2. **Use Endpoint IDs** - Always specify endpoint ID in API calls (default: 1 for local Docker)
3. **Error Handling** - Wrap Portainer API calls in try-catch blocks to handle connection failures
4. **Rate Limiting** - Add delays between bulk operations to avoid overloading Portainer
5. **Container Labels** - Use Docker labels to categorize containers for easier n8n automation
6. **Stack Management** - Prefer stacks over individual containers for better organization and updates
7. **Backup Volumes** - Regularly backup Portainer data volume (`portainer_data`) to preserve configurations
8. **RBAC Planning** - Use Portainer Business for team environments requiring role-based access
9. **Webhook Security** - Validate webhook payloads and use HMAC signatures for production deployments
10. **Monitor Portainer** - Set up health checks for the Portainer container itself in n8n workflows

### Troubleshooting

#### Portainer Container Won't Start

```bash
# Check logs
docker logs portainer --tail 100

# Common issue: Port 9000 or 9443 already in use
sudo lsof -i :9000
sudo lsof -i :9443

# Kill conflicting process or change port in docker-compose.yml

# Verify Docker socket is mounted
docker inspect portainer | grep -A5 "Mounts"
# Should show: /var/run/docker.sock

# Restart Portainer
docker restart portainer
```

#### Cannot Access Portainer UI

```bash
# 1. Check if container is running
docker ps | grep portainer

# 2. Verify port mapping
docker port portainer

# 3. Test local connectivity
curl -k https://localhost:9443

# 4. Check firewall rules
sudo ufw status
sudo ufw allow 9443/tcp  # If needed

# 5. Check Caddy reverse proxy config
docker logs caddy | grep portainer
```

#### API Authentication Failed (401 Unauthorized)

```bash
# 1. Verify API token is valid
curl -k -H "X-API-Key: YOUR_TOKEN" \
  https://localhost:9443/api/status

# Should return Portainer version info, not 401

# 2. Check if token expired (if you set expiry)
# Login to Portainer UI → User → Access tokens

# 3. Generate new token if needed
curl -k -X POST https://localhost:9443/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}'

# 4. In n8n, update Header Auth credential with new token
```

#### n8n Cannot Connect to Portainer

```bash
# 1. Test internal connectivity from n8n container
docker exec n8n curl -k http://portainer:9000/api/status

# Should return: {"Version":"..."}

# 2. Verify services are on same Docker network
docker network inspect ai-launchkit_default | grep -E "n8n|portainer"

# 3. Check if Portainer is exposed internally
docker inspect portainer | grep "IPAddress"

# 4. Test with correct internal URL
# From n8n: http://portainer:9000
# NOT: https://portainer.yourdomain.com
```

#### Stack Deployment Fails via API

```bash
# 1. Validate Docker Compose syntax
# Copy compose file content and test locally:
docker-compose -f test-compose.yml config

# 2. Check Portainer logs for specific error
docker logs portainer --tail 50 | grep -i error

# Common errors:
# - Invalid YAML syntax
# - Missing image registry credentials
# - Port conflicts with existing containers
# - Invalid volume paths

# 3. Test stack creation manually in UI first
# Then export working stack to get correct API payload

# 4. Verify endpoint ID exists
curl -k -H "X-API-Key: YOUR_TOKEN" \
  https://localhost:9443/api/endpoints
```

#### Container Stats Not Available

```bash
# 1. Check if container is running
docker ps | grep CONTAINER_ID

# 2. Verify Docker API access
curl --unix-socket /var/run/docker.sock \
  http://localhost/containers/CONTAINER_ID/stats?stream=false

# 3. Check Portainer permissions
docker exec portainer ls -la /var/run/docker.sock

# Should be accessible (socket mounted correctly)

# 4. For remote Docker hosts, ensure Docker API is exposed
# Check docker-compose.yml for DOCKER_HOST environment variable
```

#### High Memory Usage by Portainer

```bash
# Check Portainer resource usage
docker stats portainer --no-stream

# If high, check number of managed containers
docker ps -a | wc -l

# Portainer memory scales with managed resources

# Increase memory limit if needed (docker-compose.yml):
deploy:
  resources:
    limits:
      memory: 512M  # Increase from default

# Restart Portainer
docker-compose up -d portainer
```

### Resources

- **Documentation:** [https://docs.portainer.io/](https://docs.portainer.io/)
- **API Documentation:** [https://docs.portainer.io/api/docs](https://docs.portainer.io/api/docs)
- **API Examples:** [https://docs.portainer.io/api/examples](https://docs.portainer.io/api/examples)
- **GitHub:** [https://github.com/portainer/portainer](https://github.com/portainer/portainer)
- **Community Forum:** [https://community.portainer.io/](https://community.portainer.io/)
- **App Templates:** [https://github.com/portainer/templates](https://github.com/portainer/templates)
- **YouTube Tutorials:** [https://www.youtube.com/c/Portainer](https://www.youtube.com/c/Portainer)
- **n8n + Portainer Workflows:** [https://n8n.io/workflows/?search=portainer](https://n8n.io/workflows/?search=portainer)
