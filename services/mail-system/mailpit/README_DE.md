# 📧 Mailpit - Entwicklungs-Mail-Catcher

### Was ist Mailpit?

Mailpit ist ein moderner E-Mail-Test-Server mit integrierter Web-UI. Er fängt alle ausgehenden E-Mails ab und zeigt sie in einer benutzerfreundlichen Oberfläche an - perfekt für Entwicklung und Testing.

### Features

- **E-Mail-Erfassung:** Fängt ALLE E-Mails von allen Diensten ab
- **Web-UI:** Moderne, schnelle, responsive Oberfläche
- **Echtzeit-Updates:** Neue E-Mails erscheinen sofort
- **Suche & Filter:** Durchsuche E-Mails nach Absender, Betreff, etc.
- **API-Zugriff:** Programmatischer Zugriff auf E-Mails
- **Null-Konfiguration:** Funktioniert sofort ohne Setup

### Erste Einrichtung

**Mailpit ist bereits vorkonfiguriert!** Kein Setup erforderlich.

**Zugriff auf die Web-UI:**

1. Navigiere zu `https://mail.deinedomain.com`
2. Keine Authentifizierung erforderlich
3. Alle von Diensten gesendeten E-Mails erscheinen hier automatisch

**Alle Dienste sind vorkonfiguriert:**
- SMTP Host: `mailpit`
- SMTP Port: `1025`
- Keine Authentifizierung erforderlich
- Kein SSL/TLS

### n8n-Integrations-Setup

Mailpit ist **bereits in n8n vorkonfiguriert**. Alle "Send Email"-Nodes nutzen Mailpit automatisch.

**E-Mail von n8n senden (bereits konfiguriert):**

1. Erstelle Workflow
2. Füge "Send Email"-Node hinzu
3. Node ist bereits mit Mailpit konfiguriert
4. E-Mail wird automatisch in Mailpit erfasst

**Interne URL für manuelle Konfiguration:** `http://mailpit:1025`

### Beispiel-Workflows

#### Beispiel 1: Test-E-Mail senden

```javascript
// 1. Manual Trigger Node

// 2. Send Email Node (bereits vorkonfiguriert)
{
  "to": "test@example.com",
  "subject": "Test vom AI LaunchKit",
  "text": "Diese E-Mail wurde von Mailpit erfasst!"
}

// 3. Öffne Mailpit Web-UI
// → E-Mail erscheint sofort bei mail.deinedomain.com
```

#### Beispiel 2: Automatische Benachrichtigungen testen

```javascript
// 1. Webhook Trigger Node
// Empfängt POST von externem Service

// 2. Code Node - E-Mail formatieren
const emailData = {
  to: "admin@example.com",
  subject: `Neue Benachrichtigung: ${$json.event}`,
  html: `
    <h2>Event-Details</h2>
    <p><strong>Typ:</strong> ${$json.event}</p>
    <p><strong>Zeit:</strong> ${new Date().toLocaleString()}</p>
    <p><strong>Daten:</strong> ${JSON.stringify($json.data, null, 2)}</p>
  `
};
return emailData;

// 3. Send Email Node
// → Sendet an Mailpit zur Überprüfung

// 4. Teste in Mailpit Web-UI
// → Validiere HTML-Formatierung und Daten
```

#### Beispiel 3: Service-E-Mail-Konfiguration testen

```javascript
// Teste Cal.com, Vikunja, Invoice Ninja, etc.
// Alle Services → Mailpit automatisch konfiguriert

// Test-Prozess:
// 1. Führe Aktion im Service aus (z.B. Meeting in Cal.com buchen)
// 2. Service sendet E-Mail
// 3. Prüfe E-Mail in Mailpit Web-UI
// 4. Validiere Format und Inhalt

// Kein Code nötig - Services senden direkt an Mailpit!
```

### Fehlerbehebung

**E-Mails erscheinen nicht in Mailpit:**

```bash
# 1. Prüfe Mailpit-Status
docker ps | grep mailpit
# Sollte zeigen: STATUS = Up

# 2. Prüfe Mailpit-Logs
docker logs mailpit --tail 50

# 3. Teste SMTP-Verbindung
docker exec n8n nc -zv mailpit 1025
# Sollte zurückgeben: Connection successful

# 4. Teste von anderem Container
docker exec -it [dienst-name] sh
nc -zv mailpit 1025
```

**Mailpit Web-UI nicht erreichbar:**

```bash
# 1. Prüfe Caddy-Logs
docker logs caddy | grep mailpit

# 2. Starte Mailpit-Container neu
docker compose restart mailpit

# 3. Leere Browser-Cache
# STRG+F5 oder Inkognito-Modus

# 4. Prüfe DNS
nslookup mail.deinedomain.com
# Sollte deine Server-IP zurückgeben
```

**Service kann keine E-Mails senden:**

```bash
# 1. Prüfe Service-SMTP-Einstellungen
docker exec [dienst] env | grep SMTP
# Sollte zeigen: SMTP_HOST=mailpit, SMTP_PORT=1025

# 2. Prüfe Docker-Netzwerk
docker network inspect ai-launchkit_default | grep mailpit

# 3. Prüfe Service-Logs
docker logs [dienst] | grep -i "mail\|smtp"

# 4. Starte Service neu
docker compose restart [dienst]
```

### Ressourcen

- **GitHub:** https://github.com/axllent/mailpit
- **Dokumentation:** https://mailpit.axllent.org/docs/
- **API-Dokumentation:** https://mailpit.axllent.org/docs/api/
- **Web-UI:** `https://mail.deinedomain.com`
