# 🐳 Portainer - Docker-Container-Management-UI

### Was ist Portainer?

Portainer ist eine leichtgewichtige, Open-Source-Container-Management-Plattform, die eine intuitive webbasierte Oberfläche zur Verwaltung von Docker-Containern, Images, Volumes, Netzwerken und Stacks bietet. Sie vereinfacht Container-Operationen, die sonst komplexe CLI-Befehle erfordern würden, und macht Docker sowohl für Anfänger als auch für Enterprise-Teams zugänglich. Portainer kann lokale Docker-Umgebungen, Remote-Docker-Hosts, Docker-Swarm-Cluster und sogar Kubernetes verwalten.

### Features

- **Visuelle Container-Verwaltung** - Starte, stoppe, restarte und überwache Container mit einfacher Klick-Oberfläche
- **Stack-Deployment** - Deploye Multi-Container-Anwendungen mit Docker-Compose-Dateien direkt über die UI
- **Multi-Umgebungs-Support** - Verwalte mehrere Docker-Hosts, Swarm-Cluster und Kubernetes von einem einzigen Dashboard aus
- **Ressourcen-Monitoring** - Echtzeit-CPU-, Speicher- und Netzwerk-Nutzungsstatistiken für Container und Hosts
- **Rollenbasierte Zugriffskontrolle (RBAC)** - Definiere Benutzerrollen und Berechtigungen (Business Bearbeiteion Feature)
- **App-Templates** - Vorkonfigurierte Templates für beliebte Anwendungen wie WordPress, MySQL, Nginx und mehr

### Erste Einrichtung

**Erster Login in Portainer:**

1. Navigiere zu `https://portainer.deinedomain.com`
2. **Admin-Account erstellen** (Erstmalige Einrichtung):
   ```
   Benutzername: admin
   Passwort: [Wähle ein starkes Passwort - mindestens 12 Zeichen]
   ```
3. Klicke **Create user**
4. **Mit Docker-Umgebung verbinden:**
   - Wähle **Get Started** oder **Docker**
   - Portainer erkennt lokales Docker automatisch über `/var/run/docker.sock`
   - Klicke **Connect**

**Dashboard erkunden:**

1. **Home** - Übersicht aller Umgebungen und Quick-Stats
2. **Containers** - Liste und verwalte laufende/gestoppte Container
3. **Images** - Durchsuche, ziehe und lösche Docker-Images
4. **Volumes** - Verwalte persistente Daten-Volumes
5. **Networks** - Zeige und konfiguriere Docker-Netzwerke
6. **Stacks** - Deploye und verwalte Docker-Compose-Anwendungen
7. **App Templates** - Quick-Deploy beliebter Anwendungen

**Deinen ersten Stack deployen:**

1. Gehe zu **Stacks** → **Add stack**
2. Name: `test-nginx`
3. Wähle **Web editor**
4. Füge dieses Beispiel ein:
   ```yaml
      services:
     nginx:
       image: nginx:alpine
       ports:
         - "8080:80"
       restart: unless-stopped
   ```
5. Klicke **Deploy the stack**
6. Zugriff auf `http://deine-server-ip:8080`

### n8n Integrations-Setup

**Interne URL für n8n:** `http://portainer:9000`

Portainer bietet eine umfassende REST-API, die n8n zur Automatisierung von Container-Management-Aufgaben nutzen kann. Authentifizierung erfolgt über API-Access-Tokens.

#### API-Access-Token generieren

**Methode 1: Über Portainer UI (Empfohlen)**

1. Gehe in Portainer zu **User Settings** (klicke auf deinen Benutzernamen oben rechts)
2. Wähle **Access tokens**
3. Klicke **Add access token**
4. Konfiguriere:
   ```
   Description: n8n-automation
   Expiry: Never (oder setze benutzerdefiniertes Ablaufdatum)
   ```
5. Klicke **Add**
6. **Kopiere den Token sofort** - er wird nicht noch einmal angezeigt!
7. Speichere sicher in n8n-Credentials oder `.env`-Datei

**Methode 2: Über API**

```bash
# Zuerst einloggen um JWT-Token zu erhalten
curl -X POST http://portainer:9000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"dein_passwort"}'

# Antwort: {"jwt":"eyJhbGci..."}

# Access-Token erstellen
curl -X POST http://portainer:9000/api/users/1/tokens \
  -H "Authorization: Bearer DEIN_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"n8n-automation"}'

# Antwort: {"rawAPIKey":"ptr_DEIN_ACCESS_TOKEN"}
```

**HTTP Request Credentials in n8n erstellen:**

1. Gehe in n8n zu **Credentials** → **Create New**
2. Suche nach **Header Auth**
3. Konfiguriere:
   ```
   Name: Portainer API
   Header Name: X-API-Key
   Header Wert: ptr_DEIN_ACCESS_TOKEN_HIER
   ```
4. Teste und speichere

### Beispiel-Workflows

#### Beispiel 1: Container-Gesundheit überwachen & fehlgeschlagene Container automatisch neustarten

Erkenne automatisch Container, die unerwartet beendet wurden, und starte sie neu:

```javascript
// n8n Workflow: Container Health Monitor

// 1. Schedule Trigger - Every 5 minutes

// 2. HTTP Request Node - Get all containers
Methode: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/json
Authentication: Use Portainer API credentials
Query Parameter:
  all: true

// Antwort: Array of container objects

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
Bedingung: {{ $json.id }} is not empty

// 5a. Loop Node - Process each failed container
Items: {{ $input.all() }}

// 6. HTTP Request Node - Get container details
Methode: GET
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
Bedingung: {{ $json.shouldRestart }} === true

// 9a. HTTP Request Node - Restart container
Methode: POST
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
Kanal: #infrastructure
Nachricht: |
  {{ $json.message }}
  
  *Details:*
  • Container: `{{ $json.details.container }}`
  • Image: `{{ $json.details.image }}`
  • Exit Code: {{ $json.details.exitCode }}
  • Fehler: {{ $json.details.error }}
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
Kanal: #incidents
Nachricht: |
  {{ $json.message }}
  
  Container has exceeded maximum auto-restart attempts ({{ $json.details.restartCount }}).
  
  *Details:*
  • Container: `{{ $json.details.container }}`
  • Image: `{{ $json.details.image }}`
  • Exit Code: {{ $json.details.exitCode }}
  • Fehler: {{ $json.details.error }}
  
  ⚠️ Action Erforderlich: Investigate and manually fix

// 13. Email Node - Send to on-call engineer
To: oncall@yourdomain.com
Subject: [CRITICAL] Container Failure: {{ $json.details.container }}
Priority: High
Body: {{ $json.message }}

// 5b. Do Nothing (if no failed containers)
```

#### Beispiel 2: Automatisierte Stack-Updates über Webhook

Löse Stack-Updates von externen CI/CD-Pipelines oder GitHub-Webhooks aus:

```javascript
// n8n Workflow: Automated Stack Deployment

// 1. Webhook Trigger
// URL: /webhook/deploy-stack
// Methode: POST
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
Methode: GET
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
Methode: PUT
URL: http://portainer:9000/api/stacks/{{ $json.stackId }}
Authentication: Use Portainer API credentials
Query Parameter:
  endpointId: {{ $json.endpoint }}
Body (JSON):
{
  "stackFileContent": "{{ $json.composeFile }}",
  "prune": true,
  "pullImage": {{ $json.pullImages }}
}

// 6b. HTTP Request Node - Create new stack
Methode: POST
URL: http://portainer:9000/api/stacks
Authentication: Use Portainer API credentials
Query Parameter:
  type: 2
  method: string
  endpointId: 1
Body (JSON):
{
  "name": "{{ $json.stackName }}",
  "stackFileContent": "{{ $json.composeFile }}"
}

// 7. Wait Node - Give stack time to deploy
Betrag: 10
Unit: seconds

// 8. HTTP Request Node - Get stack status
Methode: GET
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
Kanal: #deployments
Nachricht: |
  ✅ *Deployment Successful*
  
  *Stack:* {{ $json.stackName }}
  *Environment:* {{ $json.environment }}
  *Containers:* {{ $json.containers }}
  *Branch:* {{ $json.branch }}
  *Commit:* {{ $json.commit }}
  
  🔗 <{{ $json.url }}|View in Portainer>

// 11. HTTP Request Node - Trigger health check (optional)
Methode: POST
URL: https://your-monitoring-service.com/api/healthcheck
Body (JSON):
{
  "stack": "{{ $json.stackName }}",
  "environment": "{{ $json.environment }}",
  "timestamp": "{{ $json.deployedAt }}"
}

// 12. Respond to Webhook - Success
Response Code: 200
Antwort-Body:
{
  "status": "success",
  "message": "Stack deployed successfully",
  "stack_id": {{ $json.stackId }},
  "containers": {{ $json.containers }}
}
```

#### Beispiel 3: Ressourcen-Nutzungsüberwachung & Alarme

Überwache Container-Ressourcenverbrauch und alarmiere, wenn Schwellenwerte überschritten werden:

```javascript
// n8n Workflow: Container Resource Monitoring

// 1. Schedule Trigger - Every 10 minutes

// 2. HTTP Request Node - Get running containers
Methode: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/json
Authentication: Use Portainer API credentials
Query Parameter:
  filters: {"status":["running"]}

// 3. Code Node - Extract container IDs
const containers = $input.first().json;
return containers.map(c => ({ json: { id: c.Id, name: c.Names[0].replace('/', '') } }));

// 4. Loop Node - Process each container
Items: {{ $input.all() }}

// 5. HTTP Request Node - Get container stats
Methode: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/{{ $json.id }}/stats
Authentication: Use Portainer API credentials
Query Parameter:
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
Bedingung: {{ $json.alerting_containers }} > 0

// 10a. Slack Node - Send alert
Kanal: #infrastructure-alerts
Nachricht: |
  ⚠️ *Container Resource Alert*
  
  {{ $json.alerting_containers }} container(s) exceeding thresholds:
  
  {{ $json.alerts.map(a => `*${a.container}:*\n${a.alerts.join('\n')}`).join('\n\n') }}
  
  *Top CPU Consumers:*
  {{ $json.top_cpu.slice(0,3).map(c => `• ${c.container}: ${c.cpu_percent}%`).join('\n') }}
  
  *Top Memory Consumers:*
  {{ $json.top_memory.slice(0,3).map(c => `• ${c.container}: ${c.memory_percent}%`).join('\n') }}

// 10b. Do Nothing (if no alerts)

// 11. PostgreSQL Node - Log metrics
Operation: Einfügen
Table: container_metrics
Daten: {{ $json }}
```

#### Example 4: Image Update Scanner

Scan for outdated container images and notify about available updates:

```javascript
// n8n Workflow: Container Image Update Scanner

// 1. Schedule Trigger - Daily at 3 AM

// 2. HTTP Request Node - Get all containers
Methode: GET
URL: http://portainer:9000/api/endpoints/1/docker/containers/json
Authentication: Use Portainer API credentials
Query Parameter:
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
Methode: GET
URL: https://hub.docker.com/v2/repositories/{{ $json.imageName.replace('library/', '') }}/tags/{{ $json.currentTag }}
// Hinweis: For official images, remove 'library/' prefix

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
Bedingung: {{ $json.updates_available }} > 0

// 11a. Slack Node - Notify about updates
Kanal: #infrastructure
Nachricht: |
  📦 *Container Image Updates Available*
  
  {{ $json.updates_available }} image(s) have updates:
  
  {{ $json.outdated_images.map(img => 
    `*${img.image}*\nUsed by: ${img.containers.join(', ')}\nLast updated: ${new Date(img.lastUpdated).toLocaleDateString()}`
  ).join('\n\n') }}
  
  Update containers in Portainer or via CI/CD.

// 11b. Do Nothing (if up to date)
```

### Best Practices

1. **API-Token-Sicherheit** - Speichere Portainer-API-Tokens sicher in n8n-Credentials, niemals im Workflow-Code
2. **Endpoint-IDs verwenden** - Gib immer Endpoint-ID in API-Aufrufen an (Standard: 1 für lokales Docker)
3. **Fehlerbehandlung** - Packe Portainer-API-Aufrufe in try-catch-Blöcke um Verbindungsfehler zu behandeln
4. **Rate Limiting** - Füge Verzögerungen zwischen Bulk-Operationen hinzu um Portainer nicht zu überlasten
5. **Container-Labels** - Nutze Docker-Labels um Container zu kategorisieren für einfachere n8n-Automatisierung
6. **Stack-Verwaltung** - Bevorzuge Stacks gegenüber einzelnen Containern für bessere Organisation und Updates
7. **Volumes sichern** - Sichere regelmäßig Portainer-Data-Volume (`portainer_data`) um Konfigurationen zu bewahren
8. **RBAC-Planung** - Verwende Portainer Business für Team-Umgebungen, die rollenbasierten Zugriff benötigen
9. **Webhook-Sicherheit** - Validiere Webhook-Payloads und verwende HMAC-Signaturen für Produktiv-Deployments
10. **Portainer überwachen** - Richte Health-Checks für den Portainer-Container selbst in n8n-Workflows ein

### Fehlerbehebung

#### Portainer-Container startet nicht

```bash
# Logs prüfen
docker logs portainer --tail 100

# Häufiges Problem: Port 9000 oder 9443 bereits belegt
sudo lsof -i :9000
sudo lsof -i :9443

# Konfliktierenden Prozess beenden oder Port in docker-compose.yml ändern

# Docker-Socket-Montierung verifizieren
docker inspect portainer | grep -A5 "Mounts"
# Sollte zeigen: /var/run/docker.sock

# Portainer neu starten
docker restart portainer
```

#### Kein Zugriff auf Portainer UI

```bash
# 1. Prüfen ob Container läuft
docker ps | grep portainer

# 2. Port-Mapping verifizieren
docker port portainer

# 3. Lokale Konnektivität testen
curl -k https://localhost:9443

# 4. Firewall-Regeln prüfen
sudo ufw status
sudo ufw allow 9443/tcp  # Falls benötigt

# 5. Caddy Reverse-Proxy-Config prüfen
docker logs caddy | grep portainer
```

#### API-Authentifizierung fehlgeschlagen (401 Unauthorized)

```bash
# 1. API-Token auf Gültigkeit prüfen
curl -k -H "X-API-Key: DEIN_TOKEN" \
  https://localhost:9443/api/status

# Sollte Portainer-Versionsinformationen zurückgeben, nicht 401

# 2. Prüfen ob Token abgelaufen ist (falls du Ablaufdatum gesetzt hast)
# In Portainer UI einloggen → User → Access tokens

# 3. Neuen Token generieren falls benötigt
curl -k -X POST https://localhost:9443/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"dein_passwort"}'

# 4. In n8n, Header-Auth-Credential mit neuem Token aktualisieren
```

#### n8n kann sich nicht mit Portainer verbinden

```bash
# 1. Interne Konnektivität vom n8n-Container testen
docker exec n8n curl -k http://portainer:9000/api/status

# Sollte zurückgeben: {"Version":"..."}

# 2. Prüfen ob Services im selben Docker-Netzwerk sind
docker network inspect ai-corekit_default | grep -E "n8n|portainer"

# 3. Prüfen ob Portainer intern exponiert ist
docker inspect portainer | grep "IPAddress"

# 4. Mit korrekter interner URL testen
# Von n8n: http://portainer:9000
# NICHT: https://portainer.deinedomain.com
```

#### Stack-Deployment schlägt über API fehl

```bash
# 1. Docker-Compose-Syntax validieren
# Compose-Datei-Inhalt kopieren und lokal testen:
docker-compose -f test-compose.yml config

# 2. Portainer-Logs auf spezifische Fehler prüfen
docker logs portainer --tail 50 | grep -i error

# Häufige Fehler:
# - Ungültige YAML-Syntax
# - Fehlende Image-Registry-Credentials
# - Port-Konflikte mit existierenden Containern
# - Ungültige Volume-Pfade

# 3. Stack-Erstellung zuerst manuell in UI testen
# Dann funktionierenden Stack exportieren um korrektes API-Payload zu erhalten

# 4. Prüfen ob Endpoint-ID existiert
curl -k -H "X-API-Key: DEIN_TOKEN" \
  https://localhost:9443/api/endpoints
```

#### Container-Stats nicht verfügbar

```bash
# 1. Prüfen ob Container läuft
docker ps | grep CONTAINER_ID

# 2. Docker-API-Zugriff verifizieren
curl --unix-socket /var/run/docker.sock \
  http://localhost/containers/CONTAINER_ID/stats?stream=false

# 3. Portainer-Berechtigungen prüfen
docker exec portainer ls -la /var/run/docker.sock

# Sollte zugänglich sein (Socket korrekt montiert)

# 4. Für Remote-Docker-Hosts sicherstellen, dass Docker-API exponiert ist
# docker-compose.yml auf DOCKER_HOST-Umgebungsvariable prüfen
```

#### Hohe Speicherauslastung durch Portainer

```bash
# Portainer-Ressourcennutzung prüfen
docker stats portainer --no-stream

# Falls hoch, Anzahl verwalteter Container prüfen
docker ps -a | wc -l

# Portainer-Speicher skaliert mit verwalteten Ressourcen

# Speicherlimit bei Bedarf erhöhen (docker-compose.yml):
deploy:
  resources:
    limits:
      memory: 512M  # Von Standard erhöhen

# Portainer neu starten
docker-compose up -d portainer
```

### Ressourcen

- **Dokumentation:** [https://docs.portainer.io/](https://docs.portainer.io/)
- **API-Dokumentation:** [https://docs.portainer.io/api/docs](https://docs.portainer.io/api/docs)
- **API-Beispiele:** [https://docs.portainer.io/api/examples](https://docs.portainer.io/api/examples)
- **GitHub:** [https://github.com/portainer/portainer](https://github.com/portainer/portainer)
- **Community-Forum:** [https://community.portainer.io/](https://community.portainer.io/)
- **App-Templates:** [https://github.com/portainer/templates](https://github.com/portainer/templates)
- **YouTube-Tutorials:** [https://www.youtube.com/c/Portainer](https://www.youtube.com/c/Portainer)
- **n8n + Portainer Workflows:** [https://n8n.io/workflows/?search=portainer](https://n8n.io/workflows/?search=portainer)
