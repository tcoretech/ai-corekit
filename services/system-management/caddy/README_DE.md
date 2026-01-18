# 🌐 Caddy - Automatischer HTTPS Reverse Proxy

### Was ist Caddy?

Caddy ist ein moderner, leistungsstarker Webserver in Go geschrieben, der als **automatischer HTTPS Reverse Proxy** für alle AI CoreKit Services dient. Er übernimmt SSL-Zertifikatsverwaltung, Erneuerung und Routing - vollständig automatisch ohne manuelle Konfiguration.

Caddy bezieht, erneuert und verwaltet automatisch SSL/TLS-Zertifikate von Let's Encrypt über das ACME-Protokoll und stellt sicher, dass alle deine Services standardmäßig mit HTTPS gesichert sind. Im Gegensatz zu traditionellen Webservern wie Nginx oder Apache erfordert Caddy keine manuelle Zertifikatsverwaltung - es funktioniert einfach.

### Funktionen

- **Automatisches HTTPS:** SSL-Zertifikate ohne Konfiguration von Let's Encrypt mit automatischer 90-Tage-Erneuerung
- **Reverse Proxy:** Leitet Traffic zu Backend-Services mit Load Balancing, Health Checks und Failover
- **WebSocket-Unterstützung:** Volle Unterstützung für Echtzeit-Verbindungen (Jitsi, LiveKit, n8n Workflows)
- **Basic Authentication:** Passwortschutz für Services mit bcrypt-gehashten Zugangsdaten
- **Streaming-Unterstützung:** Optimiert für KI-Modell-APIs mit `flush_interval -1` für Streaming-Antworten
- **Wildcard DNS:** Einzelne Konfiguration bedient alle `*.deinedomain.com` Subdomains
- **Null Ausfallzeit:** Sanfte Config-Reloads ohne Verbindungsabbrüche
- **Performance:** In Go geschrieben für hohen Durchsatz und niedrigen Ressourcenverbrauch

### Ersteinrichtung

**Caddy im AI CoreKit ist vollautomatisch - keine manuelle Einrichtung erforderlich!**

Wenn du den Installer ausführst, macht Caddy automatisch:

1. **Konfiguriert alle Service-Routen** aus deiner `.env`-Datei
2. **Bezieht SSL-Zertifikate** für alle aktivierten Services
3. **Richtet Reverse Proxies ein** mit optimalen Headern und Timeouts
4. **Aktiviert automatische Erneuerung** für Zertifikate (alle 60 Tage)

**Zugriff auf Caddy:**
- Caddy läuft im Hintergrund - du interagierst nie direkt damit
- Alle Services sind automatisch verfügbar unter `https://[service].deinedomain.com`
- Zertifikatsstatus sichtbar in Logs: `docker logs caddy | grep certificate`

**Caddyfile-Speicherort:**
```bash
# Caddy-Konfiguration anzeigen
cat Caddyfile

# Nach manuellen Änderungen neu laden
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Wie Caddy im AI CoreKit funktioniert

**1. Automatische SSL-Zertifikate:**
Caddy kommuniziert mit Let's Encrypt über das ACME-Protokoll und bezieht automatisch Zertifikate bei der ersten Anfrage an jede Domain. Zertifikate werden in Docker Volumes gespeichert und automatisch vor Ablauf erneuert.

**2. Reverse Proxy Routing:**
Jeder Service erhält seine eigene Subdomain-Konfiguration im `Caddyfile`:

```caddyfile
# Beispiel: n8n Service
{$N8N_HOSTNAME} {
    reverse_proxy n8n:5678
}

# Beispiel: Service mit Basic Auth
{$VAULTWARDEN_HOSTNAME} {
    basic_auth {
        {$VAULTWARDEN_USERNAME} {$VAULTWARDEN_PASSWORD_HASH}
    }
    reverse_proxy vaultwarden:80
}

# Beispiel: KI-Service mit Streaming
{$OLLAMA_HOSTNAME} {
    reverse_proxy ollama:11434 {
        flush_interval -1  # Streaming-Antworten aktivieren
    }
}
```

**3. Umgebungsvariablen:**
Alle Service-Hostnamen sind in `.env` konfiguriert:

```bash
# Service-Hostnamen
N8N_HOSTNAME=n8n.deinedomain.com
VAULTWARDEN_HOSTNAME=vault.deinedomain.com
OLLAMA_HOSTNAME=ollama.deinedomain.com

# Basic Auth (optional)
VAULTWARDEN_USERNAME=admin
VAULTWARDEN_PASSWORD=dein-sicheres-passwort
VAULTWARDEN_PASSWORD_HASH=mit-bcrypt-gehasht
```

### n8n Integration Einrichtung

**Anwendungsfall:** SSL-Zertifikatsablauf überwachen, Service-Verfügbarkeit testen oder Caddy-Konfigurationsänderungen automatisieren.

**Caddy hat keine native n8n-Node**, aber du kannst mit Services über Caddy interagieren oder es über Docker-Befehle verwalten.

#### Beispiel 1: SSL-Zertifikatsablauf prüfen

Überwache, wann Zertifikate erneuert werden müssen (Caddy macht dies automatisch, aber du möchtest vielleicht Benachrichtigungen):

```javascript
// 1. Trigger: Zeitplan (täglich um 9 Uhr)

// 2. Execute Command Node
// Command: docker
// Arguments: exec,caddy,caddy,list-certificates,--json

// 3. Code Node: Zertifikatsablauf parsen
const certificates = JSON.parse($json.stdout);
const expiringSoon = [];
const warningDays = 30; // Warnung 30 Tage vor Ablauf

for (const cert of certificates) {
  const expiryDate = new Date(cert.not_after);
  const daysUntilExpiry = Math.floor((expiryDate - new Date()) / (1000 * 60 * 60 * 24));
  
  if (daysUntilExpiry < warningDays) {
    expiringSoon.push({
      domain: cert.names[0],
      expiresIn: daysUntilExpiry,
      expiryDatum: expiryDate.toISOString()
    });
  }
}

return expiringSoon.length > 0 ? expiringSoon : [];

// 4. IF Node: Prüfe ob Zertifikate bald ablaufen
// Bedingung: {{ $json.length > 0 }}

// 5. E-Mail / Slack Benachrichtigung senden
// Betreff: SSL-Zertifikate laufen bald ab
// Inhalt: {{ $json }}
```

#### Beispiel 2: Service-Verfügbarkeit über Caddy testen

Überprüfe, dass Services über den Reverse Proxy erreichbar sind:

```javascript
// 1. Trigger: Zeitplan (alle 5 Minuten)

// 2. HTTP Request Node
// Methode: GET
// URL: https://n8n.deinedomain.com/healthz
// Authentication: None
// Optionen:
//   - Timeout: 5000ms
//   - Follow Redirects: true
//   - Ignore SSL Issues: false

// 3. Code Node: Antwort prüfen
const services = [
  'https://n8n.deinedomain.com/healthz',
  'https://vault.deinedomain.com',
  'https://ollama.deinedomain.com'
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

// 4. Filter Node: Offline-Services abrufen
// Bedingung: {{ $json.status === "offline" }}

// 5. Benachrichtigung senden falls Services offline
```

#### Beispiel 3: Caddy nach Konfigurationsänderung neu laden

Automatisiere Caddy Config-Reload wenn du das Caddyfile aktualisierst:

```javascript
// 1. Trigger: Webhook (aufgerufen nach Config-Änderungen)

// 2. Execute Command Node
// Command: docker
// Arguments: exec,caddy,caddy,reload,--config,/etc/caddy/Caddyfile

// 3. Code Node: Reload-Erfolg prüfen
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
  message: 'Caddy erfolgreich neu geladen',
  output: output
}];

// 4. Benachrichtigung senden
// Erfolg: "Caddy-Konfiguration neu geladen"
// Fehler: "Caddy-Reload fehlgeschlagen: {{ $json.error }}"
```

#### Beispiel 4: Neuen Service zu Caddy hinzufügen (Erweitert)

Füge automatisch eine neue Service-Route zum Caddyfile hinzu und lade neu:

```javascript
// 1. Trigger: Manuell / Webhook mit Service-Details

// 2. Code Node: Caddyfile-Eintrag generieren
const serviceName = $input.item.json.serviceName; // z.B. "myapp"
const hostname = $input.item.json.hostname; // z.B. "myapp.deinedomain.com"
const port = $input.item.json.port; // z.B. 8080
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

// 3. Execute Command: An Caddyfile anhängen
// Command: bash
// Arguments: -c,"echo '{{ $json.caddyConfig }}' >> /path/to/Caddyfile"

// 4. Execute Command: Caddy neu laden
// Command: docker
// Arguments: exec,caddy,caddy,reload,--config,/etc/caddy/Caddyfile

// 5. Admin über neuen Service benachrichtigen
```

**Interne Caddy-URL:** Nicht anwendbar - Caddy ist der Einstiegspunkt, nicht intern aufgerufen.

### Fehlerbehebung

**Problem 1: SSL-Zertifikat nicht ausgestellt**

```bash
# Caddy Logs auf Zertifikatsfehler prüfen
docker logs caddy | grep -i certificate

# Häufiger Fehler: "CAA record prevents issuance"
# Lösung: DNS CAA-Records prüfen, ob Let's Encrypt erlaubt ist
dig CAA deinedomain.com

# Häufiger Fehler: "Rate limit exceeded"
# Lösung: Let's Encrypt hat Ratenlimits (50 Zertifikate/Woche pro Domain)
# Warten oder Staging-Umgebung zum Testen nutzen

# Häufiger Fehler: "Challenge failed"
# Lösung: Ports 80 und 443 müssen offen sein und DNS korrekt
curl -I http://deinedomain.com
curl -I https://deinedomain.com
```

**Lösung:**
- **DNS verifizieren:** Wildcard A-Record `*.deinedomain.com` zeigt auf deine Server-IP
- **Firewall prüfen:** Ports 80 (HTTP) und 443 (HTTPS) müssen offen sein
- **Staging-Modus:** Mit Let's Encrypt Staging testen um Ratenlimits zu vermeiden
- **Erneuerung erzwingen:** `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

**Problem 2: 502 Bad Gateway**

```bash
# Prüfe ob Backend-Service läuft
docker ps | grep [service-name]

# Caddy Logs auf Proxy-Fehler prüfen
docker logs caddy --tail 100 | grep 502

# Backend direkt testen
curl http://localhost:[service-port]

# Häufige Ursache: Service noch nicht vollständig gestartet
docker logs [service-name] --tail 50
```

**Lösung:**
- 2-3 Minuten warten bis Services starten (besonders ComfyUI, Supabase, Cal.com)
- Verifiziere, dass Service auf korrektem Port lauscht in `docker-compose.yml`
- Service-Logs auf Startfehler prüfen
- Spezifischen Service neu starten: `docker compose restart [service-name]`

**Problem 3: Zertifikatswarnungen im Browser**

```bash
# Zertifikatsgültigkeit prüfen
docker exec caddy caddy list-certificates

# Sollte gültige Zertifikate für deine Domains zeigen
# Falls selbst-signierte Zertifikate angezeigt werden, 5-10 Minuten warten

# Zertifikatserneuerung erzwingen
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

**Lösung:**
- **Temporär:** Caddy nutzt möglicherweise kurzzeitig ein selbst-signiertes Zertifikat während der Anfrage bei Let's Encrypt - dies löst sich normalerweise innerhalb von 1-24 Stunden
- **Browser-Cache leeren:** Inkognito/Privates Fenster versuchen
- **E-Mails prüfen:** Let's Encrypt sendet Benachrichtigungen falls Zertifikatsausstellung fehlschlägt
- **Hostname verifizieren:** Stelle sicher, dass `HOSTNAME` in `.env` mit deiner tatsächlichen Domain übereinstimmt

**Problem 4: WebSocket-Verbindungen schlagen fehl**

```bash
# WebSockets benötigen spezifische Header - Caddy Logs prüfen
docker logs caddy | grep -i websocket

# WebSocket-Verbindung testen
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  https://deinservice.deinedomain.com
```

**Lösung:**
- Caddy unterstützt WebSockets standardmäßig über `reverse_proxy`-Direktive
- In den meisten Fällen keine spezielle Konfiguration nötig
- Für Services wie Jitsi oder LiveKit, stelle sicher dass auch UDP-Ports offen sind
- Service-spezifische Anforderungen prüfen (manche benötigen zusätzliche Header)

**Problem 5: Service nach Hinzufügen zum Caddyfile nicht erreichbar**

```bash
# Caddyfile-Syntax verifizieren
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Auf Syntaxfehler in Ausgabe prüfen
# Caddy neu laden um Änderungen anzuwenden
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Reload überwachen
docker logs caddy --follow
```

**Lösung:**
- Immer Caddyfile-Syntax vor Reload validieren
- Prüfen, dass Umgebungsvariablen in `.env`-Datei existieren
- Exaktes Format verwenden: `{$VARIABLE_NAME}` für Umgebungsvariablen
- Caddy neu starten falls Reload fehlschlägt: `docker compose restart caddy`
- Neue Route verifizieren: `curl -I https://neuerservice.deinedomain.com`

### Ressourcen

- **Offizielle Dokumentation:** https://caddyserver.com/docs/
- **Reverse Proxy Guide:** https://caddyserver.com/docs/quick-starts/reverse-proxy
- **Automatisches HTTPS:** https://caddyserver.com/docs/automatic-https
- **Caddyfile Syntax:** https://caddyserver.com/docs/caddyfile
- **JSON Config API:** https://caddyserver.com/docs/api
- **GitHub:** https://github.com/caddyserver/caddy
- **Community Forum:** https://caddy.community/
- **Let's Encrypt Ratenlimits:** https://letsencrypt.org/docs/rate-limits/
- **ACME-Protokoll:** https://caddyserver.com/docs/automatic-https#acme-protocol
- **Docker Image:** https://hub.docker.com/_/caddy

### Best Practices

**Sicherheit:**
- Caddy aktiviert HTTPS automatisch - niemals in Produktion deaktivieren
- Nutze starke bcrypt-Passwort-Hashes für Basic Auth (Cost Factor 14+)
- Rotiere Basic Auth Passwörter vierteljährlich
- Überwache Zertifikatsablauf (obwohl Caddy automatisch erneuert)
- Halte Caddy aktuell: `docker compose pull caddy && docker compose up -d caddy`

**Performance:**
- Nutze `flush_interval -1` für KI-Streaming-Antworten (Ollama, OpenAI-Proxies)
- Aktiviere Kompression für Text-Antworten (Caddy macht dies standardmäßig)
- Für Traffic-intensive Services erwäge `load_balancing`-Direktive
- Überwache Container-Stats: `docker stats caddy --no-stream`

**Konfigurations-Management:**
- Nutze immer Umgebungsvariablen für Hostnamen (`.env`-Datei)
- Behalte Caddyfile in Versionskontrolle (Git)
- Teste Änderungen mit `caddy validate` vor Reload
- Dokumentiere benutzerdefinierte Routen in Kommentaren im Caddyfile
- Nutze konsistente Benennung: `{$SERVICE_HOSTNAME}` Muster

**Überwachung:**
```bash
# Caddy-Gesundheit prüfen
docker ps | grep caddy  # Sollte "Up"-Status zeigen

# Aktive Verbindungen anzeigen
docker exec caddy caddy list-certificates | jq

# Logs in Echtzeit überwachen
docker logs caddy --follow --tail 100

# Zertifikatsablauf prüfen
docker exec caddy caddy list-certificates | grep -i "not after"

# Ressourcennutzung
docker stats caddy --no-stream
# Typisch: 50-150MB RAM, <5% CPU
```

**Backup:**
```bash
# SSL-Zertifikate sichern (in Docker Volume gespeichert)
docker run --rm -v caddy_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/caddy-certs-backup.tar.gz /data

# Caddyfile sichern
cp Caddyfile Caddyfile.backup.$(date +%Y%m%d)
```

**Häufige Muster:**

**Muster 1: Service mit Authentifizierung**
```caddyfile
{$SERVICE_HOSTNAME} {
    basic_auth {
        {$SERVICE_USERNAME} {$SERVICE_PASSWORD_HASH}
    }
    reverse_proxy service:port
}
```

**Muster 2: KI-Service mit Streaming**
```caddyfile
{$AI_SERVICE_HOSTNAME} {
    reverse_proxy ai-service:port {
        flush_interval -1
        header_up X-Real-IP {remote}
    }
}
```

**Muster 3: WebSocket-Service**
```caddyfile
{$WS_SERVICE_HOSTNAME} {
    reverse_proxy ws-service:port
    # WebSockets funktionieren automatisch, keine spezielle Config nötig
}
```

**Muster 4: Statische Seite mit Caching**
```caddyfile
static.deinedomain.com {
    root * /var/www/static
    file_server
    encode gzip
    header Cache-Control "max-age=31536000"
}
```
