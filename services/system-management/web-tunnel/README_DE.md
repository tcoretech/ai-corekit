# ☁️ Cloudflare Tunnel - Zero-Trust Sicherer Zugriff

### Was ist Cloudflare Tunnel?

Cloudflare Tunnel (früher Argo Tunnel) erstellt eine sichere, verschlüsselte Verbindung zwischen deinen Services und Cloudflares globalem Netzwerk **ohne deinen Server im öffentlichen Internet freizugeben**. Keine offenen Ports, keine Port-Weiterleitung, keine Firewall-Änderungen erforderlich.

Der leichtgewichtige `cloudflared`-Daemon läuft in deiner Infrastruktur und etabliert eine **Nur-ausgehende Verbindung** zu Cloudflare. Die IP-Adresse deines Servers bleibt vollständig verborgen und schützt dich vor direkten Angriffen, DDoS und Aufklärung. Gesamter Traffic wird über Cloudflares Zero Trust Plattform geleitet mit integriertem DDoS-Schutz und identitätsbasierter Zugriffskontrolle.

**Perfekt für:** Umgehung restriktiver Firewalls, Absicherung selbst gehosteter Services, Schutz von Entwicklungsumgebungen oder Verbindung von IoT-Geräten ohne statische IPs.

### Funktionen

- **Null Firewall-Konfiguration:** Keine offenen Ports 80/443 erforderlich - nur ausgehende HTTPS-Verbindungen (Port 443)
- **Versteckte Origin-IP:** Die öffentliche IP deines Servers bleibt vollständig privat - verhindert direkte Angriffe
- **Zero Trust Sicherheit:** Integration mit Cloudflare Access für E-Mail-basierte Authentifizierung, OTP oder SSO
- **DDoS-Schutz:** Automatischer Schutz über Cloudflares globales Netzwerk (200+ Rechenzentren)
- **Einfache Docker-Integration:** Als leichtgewichtiger Container neben deinen Services laufen
- **WebSocket-Unterstützung:** Volle Unterstützung für Echtzeit-Verbindungen (WebSockets, gRPC, etc.)
- **Kostenloser Tarif verfügbar:** Bis zu 50 Benutzer mit Cloudflare Zero Trust Free Plan
- **Kein VPN erforderlich:** Direkter Zugriff auf interne Services ohne komplexes VPN-Setup

### Wann Cloudflare Tunnel nutzen

**✅ Nutze Cloudflare Tunnel wenn:**
- Dein VPS-Provider eingehende Ports blockiert (häufig bei manchen Cloud-Anbietern)
- Du die öffentliche IP deines Servers aus Sicherheitsgründen verstecken willst
- Du Zero Trust Authentifizierung benötigst (E-Mail OTP, SSO, etc.)
- Du hinter einer restriktiven Firewall oder CGNAT bist
- Du DDoS-Schutz standardmäßig integriert haben willst
- Du Services in einem Heimnetzwerk ohne statische IP betreibst
- Du Port-Weiterleitung auf deinem Router umgehen willst

**❌ Nutze Cloudflare Tunnel nicht wenn:**
- Du bereits Caddy mit Let's Encrypt nutzt (Caddy bietet SSL automatisch)
- Du volle Kontrolle über SSL-Zertifikate willst (Cloudflare beendet SSL an ihrem Edge)
- Du Nicht-HTTP-Protokolle ohne Cloudflares WARP-Client benötigst
- Du Latenz minimieren willst (fügt ~20-50ms über Cloudflare-Routing hinzu)
- Du sensible Daten verarbeitest, die nicht durch Drittanbieter-Netzwerke gehen dürfen

**Hinweis:** Im AI CoreKit ist Cloudflare Tunnel **optional**. Das Standard-Setup nutzt Caddy für automatisches HTTPS, was für die meisten Anwendungsfälle perfekt funktioniert. Nutze Cloudflare Tunnel nur wenn du spezifische Anforderungen wie IP-Versteckung oder Zero Trust Authentifizierung benötigst.

### Ersteinrichtung

Cloudflare Tunnel erfordert einen Cloudflare-Account und eine von Cloudflare verwaltete Domain.

#### Voraussetzungen

1. **Cloudflare-Account:** Registriere dich unter https://dash.cloudflare.com
2. **Domain auf Cloudflare:** Füge deine Domain hinzu und ändere Nameserver zu Cloudflare
3. **Zero Trust Account:** Aktiviere unter https://one.dash.cloudflare.com (kostenloser Tarif verfügbar)

#### Schritt 1: Tunnel im Cloudflare Dashboard erstellen

1. **Navigiere zum Zero Trust Dashboard:**
   - Gehe zu https://one.dash.cloudflare.com
   - Klicke **Networks** → **Tunnels**
   - Klicke **Create a tunnel**

2. **Connector-Typ auswählen:**
   - Wähle **Cloudflared** (nicht WARP Connector)
   - Klicke **Next**

3. **Tunnel benennen:**
   - Gib einen Namen ein (z.B. `ai-corekit-prod`)
   - Klicke **Save tunnel**

4. **Tunnel-Token abrufen:**
   - Cloudflare zeigt einen Docker-Befehl mit deinem Tunnel-Token
   - Kopiere das Token aus dem Befehl (beginnt mit `eyJ...`)
   - **Speichere dieses Token** - du brauchst es für Docker-Setup

#### Schritt 2: Tunnel in Docker konfigurieren

Füge Cloudflare Tunnel zu deiner `docker-compose.yml` hinzu:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-tunnel
    restart: unless-stopped
    environment:
      - TUNNEL_TOKEN=eyJhIjoiNTU2MDgw...  # Dein Token aus Schritt 1
    command: tunnel run
    networks:
      - default

networks:
  default:
    name: ${PROJECT_NAME:-localai}_default
    external: true
```

**Tunnel starten:**
```bash
docker compose up -d cloudflared
```

**Verifiziere dass er läuft:**
```bash
# Container-Status prüfen
docker ps | grep cloudflared

# Logs anzeigen
docker logs cloudflared-tunnel

# Sollte zeigen: "Connection established" und "Registered tunnel"
```

#### Schritt 3: Öffentliche Hostnamen hinzufügen

Zurück im Cloudflare Zero Trust Dashboard:

1. **Klicke auf deinen Tunnel-Namen** in der Tunnels-Liste
2. **Gehe zum Public Hostname Tab**
3. **Klicke Add a public hostname**

4. **Service konfigurieren:**
   ```
   Subdomain: n8n
   Domain: deinedomain.com
   Type: HTTP
   URL: n8n:5678
   ```
   - Falls cloudflared im selben Docker-Netzwerk ist, nutze Container-Namen (z.B. `n8n:5678`)
   - Falls anderes Netzwerk, nutze `http://IP:PORT`

5. **Klicke Save hostname**

6. **Zugriff testen:**
   - Besuche `https://n8n.deinedomain.com`
   - DNS zeigt automatisch auf Cloudflare (CNAME-Record erstellt)
   - Traffic-Route: Benutzer → Cloudflare → Tunnel → n8n

#### Schritt 4: Zero Trust Authentifizierung hinzufügen (Optional)

**Services mit E-Mail-basiertem OTP schützen:**

1. **Access Application erstellen:**
   - Gehe zu **Access** → **Applications**
   - Klicke **Add an application**
   - Wähle **Self-hosted**

2. **Application konfigurieren:**
   ```
   Application name: n8n
   Session Duration: 24 hours
   Application domain: https://n8n.deinedomain.com
   ```

3. **Access Policy erstellen:**
   - Policy name: Email whitelist
   - Action: Allow
   - Configure rule: **Emails**
   - Gib erlaubte E-Mails ein (z.B. `admin@deinefirma.com`)

4. **Speichern und testen:**
   - Besuche `https://n8n.deinedomain.com`
   - Du wirst zu Cloudflare Access Login umgeleitet
   - E-Mail eingeben → OTP-Code erhalten → Zugriff gewährt

### n8n Integration Einrichtung

**Cloudflare hat keine native n8n-Node**, aber du kannst Tunnel über die Cloudflare API mit HTTP Request Nodes verwalten.

**Cloudflare API Setup:**
1. Gehe zu https://dash.cloudflare.com/profile/api-tokens
2. Erstelle API-Token mit Berechtigungen:
   - **Zone.DNS** - Bearbeite
   - **Account.Cloudflare Tunnel** - Bearbeite
   - **Account.Access** - Bearbeite
3. Speichere Token für n8n-Zugangsdaten

#### Beispiel 1: Alle Tunnel auflisten

Tunnel-Status und -Gesundheit überwachen:

```javascript
// 1. HTTP Request Node
// Methode: GET
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel
// Authentifizierung: Generischer Zugangsdaten-Typ
//   Header Auth:
//     Name: Authorization
//     Wert: Bearer {{$env.CF_API_TOKEN}}

// 2. Code Node: Tunnel-Status parsen
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

// 3. IF Node: Prüfe ob Tunnel ausgefallen
// Bedingung: {{ $json.filter(t => !t.healthy).length > 0 }}

// 4. Benachrichtigung senden falls Tunnel ungesund
```

#### Beispiel 2: Neuen Tunnel über API erstellen

Tunnel-Erstellung für neue Services automatisieren:

```javascript
// 1. Trigger: Manuell / Webhook mit Service-Details

// 2. HTTP Request Node: Tunnel erstellen
// Methode: POST
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel
// Authentication: Bearer Token (CF_API_TOKEN)
// Body (JSON):
{
  "name": "{{ $json.serviceName }}-tunnel",
  "config_src": "cloudflare"
}

// 3. Code Node: Tunnel-ID und Token extrahieren
const tunnel = $json.result;
return [{
  tunnelId: tunnel.id,
  tunnelName: tunnel.name,
  tunnelToken: tunnel.token  // Nutze dies um cloudflared zu starten
}];

// 4. HTTP Request: DNS-Record erstellen
// Methode: POST
// URL: https://api.cloudflare.com/client/v4/zones/{{$env.CF_ZONE_ID}}/dns_records
// Body:
{
  "type": "CNAME",
  "name": "{{ $json.serviceName }}",
  "content": "{{ $json.tunnelId }}.cfargotunnel.com",
  "proxied": true
}

// 5. HTTP Request: Public Hostname hinzufügen
// Methode: PUT
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$json.tunnelId}}/configurations
// Body:
{
  "config": {
    "ingress": [
      {
        "hostname": "{{ $json.serviceName }}.deinedomain.com",
        "service": "http://{{ $json.serviceName }}:{{ $json.port }}"
      },
      {
        "service": "http_status:404"
      }
    ]
  }
}

// 6. Admin über Tunnel-Details benachrichtigen
```

#### Beispiel 3: Tunnel-Gesundheit überwachen

Prüfe ob Tunnel verbunden und reaktionsfähig sind:

```javascript
// 1. Trigger: Zeitplan (alle 5 Minuten)

// 2. HTTP Request: Tunnel-Details abrufen
// Methode: GET
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$env.TUNNEL_ID}}

// 3. Code Node: Verbindungsstatus prüfen
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

// 4. IF Node: Prüfe ob Tunnel ungesund
// Bedingung: {{ $json.unhealthy > 0 || $json.totalConnections === 0 }}

// 5. Slack/E-Mail Benachrichtigung senden
// Nachricht: "Tunnel {{ $json.tunnelName }} ist ungesund! Aktive Verbindungen: {{ $json.activeConnections }}"
```

#### Beispiel 4: Tunnel-Konfiguration aktualisieren

Services programmatisch zu Tunnel hinzufügen oder entfernen:

```javascript
// 1. Trigger: Webhook (wenn Service hinzugefügt/entfernt)

// 2. HTTP Request: Aktuelle Config abrufen
// Methode: GET
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$env.TUNNEL_ID}}/configurations

// 3. Code Node: Ingress-Regeln modifizieren
const currentConfig = $json.result.config;
const newService = $input.item.json;  // { hostname, service, port }

// Neue Ingress-Regel hinzufügen (vor der Catch-All 404)
const ingressRules = currentConfig.ingress.slice(0, -1);  // 404-Regel entfernen
ingressRules.push({
  hostname: newService.hostname,
  service: `http://${newService.service}:${newService.port}`
});
ingressRules.push({ service: "http_status:404" });  // Catch-All wieder hinzufügen

return [{
  config: {
    ingress: ingressRules
  }
}];

// 4. HTTP Request: Tunnel-Config aktualisieren
// Methode: PUT
// URL: https://api.cloudflare.com/client/v4/accounts/{{$env.CF_ACCOUNT_ID}}/cfd_tunnel/{{$env.TUNNEL_ID}}/configurations
// Body: {{ $json.config }}

// 5. Erfolg benachrichtigen
```

**Interne Cloudflare Tunnel URL:** Nicht anwendbar - Tunnel ist der Einstiegspunkt vom externen Internet.

### Fehlerbehebung

**Problem 1: Tunnel zeigt als "Inactive" oder "Down"**

```bash
# cloudflared Container-Status prüfen
docker ps | grep cloudflared

# Falls nicht läuft, Logs prüfen
docker logs cloudflared-tunnel

# Häufiger Fehler: "authentication failed"
# Lösung: Verifiziere dass TUNNEL_TOKEN in docker-compose.yml korrekt ist

# Häufiger Fehler: "no route to host"
# Lösung: Docker-Netzwerk-Konfiguration prüfen
docker network inspect ${PROJECT_NAME:-localai}_default

# Tunnel neu starten
docker compose restart cloudflared
```

**Lösung:**
- Verifiziere Tunnel-Token ist korrekt (beginnt mit `eyJ`)
- Prüfe Docker-Netzwerk existiert und cloudflared ist verbunden
- Stelle sicher ausgehendes HTTPS (Port 443) in Firewall erlaubt ist
- Prüfe Cloudflare Dashboard zeigt Tunnel als "Healthy"

**Problem 2: Services über Tunnel nicht erreichbar**

```bash
# Teste ob Service vom cloudflared-Container erreichbar ist
docker exec cloudflared-tunnel ping n8n

# Sollte Ping-Antworten geben falls im selben Netzwerk

# HTTP-Konnektivität testen
docker exec cloudflared-tunnel curl http://n8n:5678

# Sollte HTML-Antwort oder Redirect geben

# Tunnel-Konfiguration im Dashboard prüfen
# Verifiziere Hostname, Service-Typ (HTTP) und URL sind korrekt
```

**Lösung:**
- Stelle sicher cloudflared und Service sind im selben Docker-Netzwerk
- Nutze Container-Namen (nicht localhost) für Service-URLs
- Verifiziere Service läuft tatsächlich: `docker ps | grep n8n`
- Prüfe Public Hostname Konfiguration im Cloudflare Dashboard
- Warte 1-2 Minuten bis Konfigurationsänderungen propagiert sind

**Problem 3: DNS löst nicht auf**

```bash
# Prüfe ob CNAME-Record existiert
nslookup n8n.deinedomain.com

# Sollte zeigen auf: xxxxx.cfargotunnel.com

# Cloudflare DNS Dashboard prüfen
# Gehe zu: dash.cloudflare.com → deine Domain → DNS

# Verifiziere CNAME-Record:
# Type: CNAME
# Name: n8n
# Target: <tunnel-id>.cfargotunnel.com
# Proxied: Yes (orange cloud)
```

**Lösung:**
- Cloudflare erstellt automatisch CNAME-Records wenn du Public Hostname hinzufügst
- Falls fehlend, manuell CNAME erstellen der auf `<tunnel-id>.cfargotunnel.com` zeigt
- Stelle sicher "Proxied" (orange Wolke) aktiviert ist
- DNS-Änderungen können 1-5 Minuten zur Propagierung benötigen
- Browser-DNS-Cache leeren: Chrome → `chrome://net-internals/#dns` → Clear

**Problem 4: Cloudflare Access Login-Schleife**

```bash
# Access Application Policy prüfen
# Gehe zu: Zero Trust Dashboard → Access → Applications

# Häufige Probleme:
# 1. E-Mail nicht in erlaubter Liste
# 2. Session abgelaufen
# 3. Cookie vom Browser blockiert

# Teste ohne Access-Policy zuerst
# Entferne Policy temporär um zu verifizieren dass Tunnel funktioniert
```

**Lösung:**
- Verifiziere deine E-Mail ist in der Access-Policy "Allowed emails" Liste
- Prüfe Browser erlaubt Cookies (erforderlich für Access-Sessions)
- Versuche Inkognito/Privates Fenster um Cookie-Probleme auszuschließen
- Prüfe Session-Dauer in Access-Application-Einstellungen
- Browser-Cookies für deine Domain leeren

**Problem 5: Hohe Latenz durch Tunnel**

```bash
# Latenz zu Cloudflare Edge testen
ping deine-tunnel-domain.com

# Typische Latenz: 20-100ms abhängig vom Standort

# Direkt zu Service testen (Tunnel umgehen)
curl -w "@curl-format.txt" https://n8n.deinedomain.com

# Mit direktem IP-Zugriff vergleichen
curl -w "@curl-format.txt" http://DEINE_SERVER_IP:5678
```

**Lösung:**
- Cloudflare Tunnel fügt durchschnittlich 20-50ms Latenz hinzu (Traffic läuft über Cloudflare)
- Für latenz-sensitive Anwendungen erwäge direkten Zugriff mit Caddy stattdessen
- Nutze Cloudflares Smart Routing (erfordert Argo Smart Routing - kostenpflichtig)
- Stelle sicher Tunnel ist mit nächstem Cloudflare-Rechenzentrum verbunden
- Prüfe `cloudflared` Logs für Routing-Informationen

### Ressourcen

- **Offizielle Dokumentation:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- **Getting Started Guide:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/
- **Docker Setup:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/deployment-guides/docker/
- **API-Dokumentation:** https://developers.cloudflare.com/api/operations/cloudflare-tunnel-create-a-tunnel
- **GitHub:** https://github.com/cloudflare/cloudflared
- **Docker Hub:** https://hub.docker.com/r/cloudflare/cloudflared
- **Zero Trust Dashboard:** https://one.dash.cloudflare.com
- **Cloudflare Access:** https://developers.cloudflare.com/cloudflare-one/policies/access/
- **Community Forum:** https://community.cloudflare.com/c/security/access/51
- **Tutorials:** https://developers.cloudflare.com/learning-paths/zero-trust-web-access/

### Best Practices

**Sicherheit:**
- Exponiere niemals Tunnel-Tokens in Git-Repositories oder Logs
- Nutze Umgebungsvariablen für Tokens in docker-compose.yml
- Rotiere Tunnel-Tokens vierteljährlich (alten Tunnel löschen, neuen erstellen)
- Aktiviere Cloudflare Access für Produktions-Services
- Nutze E-Mail-Whitelisting für Access-Policies (nicht "anyone with email")
- Überprüfe Access-Logs regelmäßig: Zero Trust → Logs → Access requests

**Konfiguration:**
- Ein Tunnel pro Umgebung (dev, staging, prod)
- Nutze beschreibende Tunnel-Namen: `firma-umgebung-standort` (z.B. `acme-prod-vps1`)
- Dokumentiere Tunnel-ID und Erstellungsdatum im Team-Wiki
- Behalte Tunnel-Konfiguration in Versionskontrolle (Infrastructure as Code)
- Richte Überwachung/Benachrichtigungen für Tunnel-Gesundheit ein

**Performance:**
- Minimiere Anzahl der Public Hostnames pro Tunnel (besser mehrere Tunnel erstellen)
- Nutze Cloudflares Argo Smart Routing für bessere Performance (kostenpflichtige Funktion)
- Aktiviere Cloudflare-Caching für statische Assets
- Überwache Latenz: erwarte 20-50ms Overhead verglichen mit direktem Zugriff
- Für latenz-sensitive Apps erwäge direkten Zugriff + WAF-Regeln stattdessen

**Docker-Integration:**
- Führe cloudflared im selben Docker-Netzwerk wie deine Services aus
- Nutze Container-Namen für Service-URLs (nicht `localhost` oder IP-Adressen)
- Setze `restart: unless-stopped` um sicherzustellen dass Tunnel automatisch startet
- Überwache Container-Logs: `docker logs cloudflared-tunnel --follow`
- Ressourcenlimits: cloudflared nutzt ~20-50MB RAM (sehr leichtgewichtig)

**Überwachung:**
```bash
# Tunnel-Status prüfen
docker ps | grep cloudflared
docker logs cloudflared-tunnel --tail 50

# Verbindungen überwachen
# Im Cloudflare Dashboard: Networks → Tunnels → [Dein Tunnel]
# Sollte "Healthy" zeigen mit 1+ aktiven Verbindungen

# Service-Erreichbarkeit testen
curl -I https://deinservice.deinedomain.com

# Access-Logs überwachen (falls Zero Trust genutzt)
# Zero Trust Dashboard → Logs → Access requests
# Suche nach fehlgeschlagenen Authentifizierungen oder ungewöhnlichen Mustern
```

**Backup & Disaster Recovery:**
```bash
# Tunnel-Token sichern (KRITISCH!)
# In Passwort-Manager speichern (Vaultwarden)
echo "TUNNEL_TOKEN=eyJ..." > tunnel-token.txt.gpg
gpg -c tunnel-token.txt

# Tunnel-Konfiguration dokumentieren
# Aus Cloudflare Zero Trust Dashboard exportieren
# Networks → Tunnels → [Tunnel] → Configure → Export config

# Failover testen
# Zweiten Tunnel in anderer Region/VPS erstellen
# Mit gleichen Hostnamen für sofortiges Failover konfigurieren
```

**Kostenoptimierung:**
- Cloudflare Tunnel ist **kostenlos** bis zu 50 Benutzer
- Zero Trust Access ist **kostenlos** für bis zu 50 Benutzer
- Keine Bandbreiten-Gebühren für Tunnel-Traffic
- Argo Smart Routing ist kostenpflichtig ($0.10/GB)
- Für >50 Benutzer beginnt Pricing bei $7/Benutzer/Monat

**Häufige Muster:**

**Muster 1: Einfache Service-Freigabe**
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

**Muster 2: Service mit Zero Trust Auth**
- Im Cloudflare Dashboard konfigurieren (einfacher als API)
- Access → Applications → Add application
- E-Mail-basierte OTP-Policy anwenden
- Session-Dauer: 24 Stunden

**Muster 3: Mehrere Services, ein Tunnel**
```
Public Hostnames (im Cloudflare Dashboard):
- n8n.beispiel.com → http://n8n:5678
- vault.beispiel.com → http://vaultwarden:80
- webui.beispiel.com → http://open-webui:8080
```

**Muster 4: Entwicklungs- vs Produktions-Tunnel**
```bash
# Entwicklung
Tunnel-Name: acme-dev
Hostnamen: *.dev.beispiel.com
Keine Access-Policies

# Produktion
Tunnel-Name: acme-prod
Hostnamen: *.beispiel.com
Access-Policies: E-Mail-Whitelist
```
