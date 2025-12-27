# 🤖 n8n-MCP - KI-Workflow-Generator

### Was ist n8n-MCP?

n8n-MCP ermöglicht es KI-Assistenten wie Claude Desktop und Cursor, vollständige n8n-Workflows durch natürliche Sprache zu generieren. Es bietet Zugriff auf Dokumentation für 525+ n8n-Nodes und erlaubt KI-Tools, Node-Eigenschaften, Authentifizierungsanforderungen und Konfigurationsoptionen zu verstehen.

n8n-MCP implementiert den Model Context Protocol (MCP) Standard, was es mit jedem MCP-fähigen KI-Tool kompatibel macht.

### Features

- **Vollständige Node-Dokumentation** - Eigenschaften, Authentifizierung und Beispiele für 525+ Nodes
- **Workflow-Generierung** - Erstelle komplexe Automatisierungen aus natürlichsprachigen Prompts
- **Validierung** - Stellt korrekte Node-Konfiguration vor Deployment sicher
- **99% Abdeckung** - Unterstützt nahezu alle n8n-Node-Eigenschaften und Einstellungen
- **MCP-Standard** - Funktioniert mit jedem MCP-kompatiblen KI-Tool (Claude, Cursor, etc.)

### Erste Einrichtung

**Zugriff auf n8n-MCP:**
- **Externe URL:** `https://n8nmcp.deinedomain.com`
- **Interne URL:** `http://n8nmcp:3000`
- **Token:** Zu finden in `.env`-Datei als `N8N_MCP_TOKEN`

**Keine Web-Oberfläche** - n8n-MCP ist ein Backend-Service, der über KI-Tools zugänglich ist.

### Setup mit Claude Desktop

**1. Claude Desktop Konfig-Datei finden:**

**macOS/Linux:**
```bash
~/.config/claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

**2. Claude Desktop konfigurieren:**

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["@czlonkowski/n8n-mcp-client"],
      "env": {
        "N8N_MCP_URL": "https://n8nmcp.deinedomain.com",
        "N8N_MCP_TOKEN": "dein-token-aus-env-datei",
        "N8N_API_URL": "https://n8n.deinedomain.com",
        "N8N_API_KEY": "dein-n8n-api-key"
      }
    }
  }
}
```

**3. Claude Desktop neu starten**

### Setup mit Cursor IDE

**Erstelle `.cursor/mcp_config.json` in deinem Projekt:**

```json
{
  "servers": {
    "n8n-mcp": {
      "url": "https://n8nmcp.deinedomain.com",
      "token": "dein-token-aus-env-datei"
    }
  }
}
```

### Beispiel-Prompts für Claude/Cursor

#### Basis-Automatisierung

```
"Erstelle einen n8n-Workflow, der ein Gmail-Postfach auf Rechnungen überwacht,
Daten mit KI extrahiert und in Google Sheets speichert"
```

**Claude wird:**
1. n8n-MCP verwenden, um Node-Dokumentation nachzuschlagen
2. Vollständiges Workflow-JSON generieren
3. Alle Node-Eigenschaften korrekt konfigurieren
4. Authentifizierungsanforderungen einschließen
5. Deployment-Anweisungen bereitstellen

#### Komplexe Integration

```
"Erstelle einen Workflow, der:
1. Bei neuer Stripe-Zahlung triggert
2. Rechnung in QuickBooks erstellt
3. Quittung über SendGrid sendet
4. Kunde in Airtable aktualisiert
5. In Slack-Kanal postet"
```

**Ergebnis:** Vollständiger Workflow mit allen konfigurierten Nodes, einschließlich:
- Webhook-Trigger
- API-Credentials
- Datentransformationen
- Fehlerbehandlung
- Benachrichtigungs-Logik

#### KI-Pipeline

```
"Entwirf eine Content-Pipeline, die YouTube-Videos nimmt,
mit Whisper transkribiert, mit GPT-4 zusammenfasst
und mit SEO-Optimierung auf WordPress postet"
```

**Claude generiert:**
- YouTube-Datenextraktion
- Whisper-Transkriptions-Node
- OpenAI-Zusammenfassung
- WordPress-API-Integration
- SEO-Metadaten-Generierung

### Verfügbare MCP-Befehle

n8n-MCP stellt diese Befehle für KI-Assistenten bereit:

**`list_nodes`** - Alle verfügbaren n8n-Nodes abrufen
```json
Antwort: {
  "nodes": ["HTTP Request", "Code", "IF", "Gmail", "Slack", ...]
}
```

**`get_node_docs`** - Vollständige Dokumentation für spezifischen Node
```json
Request: { "node": "HTTP Request" }
Antwort: {
  "properties": [...],
  "authentication": [...],
  "examples": [...]
}
```

**`validate_workflow`** - Workflow-Konfiguration prüfen
```json
Request: { "workflow": {...} }
Antwort: {
  "valid": true,
  "errors": []
}
```

**`suggest_nodes`** - Node-Empfehlungen für Aufgabe erhalten
```json
Request: { "task": "E-Mail mit Anhang senden" }
Antwort: {
  "nodes": ["Gmail", "Send Email", "IMAP"],
  "reasoning": "..."
}
```

### n8n-Integration

**HTTP-Request zu n8n-MCP von n8n-Workflow:**

```javascript
// HTTP Request Node Konfiguration
Methode: POST
URL: https://n8nmcp.deinedomain.com/generate
Authentication: Header Auth
  Header: Authorization
  Wert: Bearer {{$env.N8N_MCP_TOKEN}}
  
Body (JSON):
{
  "prompt": "Erstelle Workflow um Notion-Datenbank mit Google Kalender zu synchronisieren",
  "target_n8n": "https://n8n.deinedomain.com",
  "auto_import": true
}

// Antwort:
{
  "workflow": {...},
  "import_url": "https://n8n.deinedomain.com/workflows/import",
  "validation": { "valid": true }
}
```

### Beispiel: KI-generierter Workflow

**Prompt an Claude:**
```
"Erstelle einen n8n-Workflow, der:
1. Einen Ordner in Google Drive überwacht
2. Wenn ein neues PDF hinzugefügt wird, Text mit OCR extrahiert
3. Den Inhalt mit OpenAI zusammenfasst
4. Eine Aufgabe in Vikunja mit der Zusammenfassung erstellt
5. Benachrichtigung an Slack sendet"
```

**Claude mit n8n-MCP generiert:**

```javascript
// 1. Google Drive Trigger Node
Trigger: On File Created
Folder: "/Rechnungen"
Dateityp: PDF

// 2. HTTP Request Node - OCR Service
Methode: POST
URL: http://tesseract:8000/ocr
Body: 
  Datei: {{$binary.data}}
  language: deu

// 3. OpenAI Node - Zusammenfassung
Operation: Message a Model
Modell: gpt-4o-mini
System Nachricht: "Fasse diese Rechnung in 2-3 Sätzen zusammen"
User Nachricht: {{$json.text}}

// 4. HTTP Request Node - Vikunja API
Methode: POST
URL: http://vikunja:3456/api/v1/tasks
Header:
  Authorization: Bearer {{$credentials.vikunjaToken}}
Body:
{
  "title": "Rechnung: {{$('Google Drive').json.name}}",
  "description": "{{$json.summary}}",
  "project_id": 1
}

// 5. Slack Node
Operation: Send Message
Kanal: #finanzen
Nachricht: |
  Neue Rechnung verarbeitet:
  Datei: {{$('Google Drive').json.name}}
  Zusammenfassung: {{$('OpenAI').json.summary}}
  Aufgabe: {{$('Vikunja').json.link}}
```

### Tipps für beste Ergebnisse

**Sei spezifisch:**
```
❌ "Erstelle einen Workflow um E-Mails zu verarbeiten"
✅ "Erstelle einen Workflow, der ungelesene Gmail-E-Mails liest,
   Anhänge extrahiert, auf Google Drive hochlädt
   und E-Mail als gelesen markiert"
```

**Tool-Namen angeben:**
```
❌ "Sende Daten an mein CRM"
✅ "Sende Daten an Odoo CRM über HTTP Request Node"
```

**Beispieldaten bereitstellen:**
```
"Verarbeite Kundendaten wie:
{
  'name': 'Max Mustermann',
  'email': 'max@example.com',
  'firma': 'Acme GmbH'
}"
```

**Durch Konversation iterieren:**
```
1. "Erstelle Workflow um Rechnungen zu verarbeiten"
2. [Claude generiert initialen Workflow]
3. "Füge Fehlerbehandlung und Retry-Logik hinzu"
4. [Claude erweitert Workflow]
5. "Füge Benachrichtigung an Microsoft Teams statt Slack hinzu"
6. [Claude aktualisiert Benachrichtigungs-Node]
```

### Workflow-Versionskontrolle

**Workflows als JSON exportieren:**

```bash
# Nach KI-Generierung, exportiere Workflow
curl -X GET https://n8n.deinedomain.com/api/v1/workflows/123 \
  -H "Authorization: Bearer DEIN_API_KEY" \
  > workflow-v1.json

# Commit zu Git
git add workflow-v1.json
git commit -m "KI-generierter Rechnungsverarbeitungs-Workflow hinzugefügt"
```

### Fehlerbehebung

**Verbindung abgelehnt:**
```bash
# Prüfe ob n8n-MCP läuft
docker ps | grep n8nmcp

# Prüfe Token in .env
grep N8N_MCP_TOKEN .env

# Teste Verbindung
curl -H "Authorization: Bearer DEIN_TOKEN" \
  https://n8nmcp.deinedomain.com/health
```

**Ungültiger Workflow generiert:**
```bash
# Nutze Validierungs-Endpunkt
curl -X POST https://n8nmcp.deinedomain.com/validate \
  -H "Authorization: Bearer DEIN_TOKEN" \
  -d '{"workflow": {...}}'

# Prüfe n8n-MCP-Logs
docker logs n8nmcp --tail 100
```

**Fehlende Node-Dokumentation:**
```bash
# Aktualisiere n8n-MCP auf neueste Version
docker compose pull n8nmcp
docker compose up -d n8nmcp

# Baue Node-Cache neu
docker exec n8nmcp npm run rebuild-cache
```

**Timeout-Fehler:**
```bash
# Erhöhe Timeout in MCP-Client-Config
{
  "mcpServers": {
    "n8n-mcp": {
      ...
      "timeout": 60000
    }
  }
}
```

### Ressourcen

- **Dokumentation:** https://github.com/czlonkowski/n8n-mcp
- **MCP-Protokoll:** https://modelcontextprotocol.io
- **n8n API-Referenz:** https://docs.n8n.io/api/
- **Community-Beispiele:** https://n8n.io/workflows (filtern nach "AI-generated")

### Best Practices

**Prompt-Engineering:**
- Beginne mit High-Level-Beschreibung
- Füge Details schrittweise hinzu
- Teste jede Ergänzung
- Nutze echte Datenbeispiele
- Spezifiziere Fehlerbehandlungs-Anforderungen

**Sicherheit:**
- Niemals Credentials in Prompts einschließen
- Nutze n8n-Credential-System
- Validiere KI-generierte Workflows vor Produktion
- Überprüfe generierten Code auf Sicherheitsprobleme

**Wartung:**
- Exportiere Workflows nach Generierung zu Git
- Dokumentiere verwendeten Prompt für Workflow-Generierung
- Teste generierte Workflows gründlich
- Halte n8n-MCP für neueste Node-Unterstützung aktuell

**Performance:**
- Teile komplexe Workflows in kleinere auf
- Nutze Webhook-Trigger statt Polling wo möglich
- Implementiere Rate-Limiting für externe APIs
- Überwache Workflow-Ausführungszeiten
