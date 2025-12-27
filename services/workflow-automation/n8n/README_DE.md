# 🔧 n8n - Workflow-Automatisierungs-Plattform

### Was ist n8n?

n8n ist eine leistungsstarke, erweiterbare Workflow-Automatisierungsplattform, die es dir ermöglicht, alles mit allem über ihr offenes, Fair-Code-Modell zu verbinden. Sie ist das Herz des AI LaunchKit und orchestriert alle Integrationen zwischen den 50+ Services.

### Features

- **400+ Integrationen:** Vorgefertigte Nodes für beliebte Services
- **Visueller Workflow-Bearbeiteor:** Drag-and-Drop-Oberfläche zum Erstellen von Automatisierungen
- **Benutzerdefinierte Code-Ausführung:** JavaScript/Python-Nodes für komplexe Logik
- **Selbst gehostet:** Volle Datenkontrolle, keine externen Abhängigkeiten
- **Aktive Community:** 300+ vorgefertigte Workflow-Vorlagen enthalten
- **Erweiterte Planung:** Cron-Ausdrücke, Intervalle, Webhook-Trigger
- **Fehlerbehandlung:** Integrierte Retry-Logik, Fehler-Workflows, Monitoring

### Erste Einrichtung

**Erster Login zu n8n:**

1. Navigiere zu `https://n8n.deinedomain.com`
2. **Erster Besucher wird Besitzer** - Erstelle dein Admin-Konto
3. Setze starkes Passwort (mindestens 8 Zeichen)
4. Setup abgeschlossen!

**API-Schlüssel generieren (für externe Integrationen):**

1. Klicke auf dein Profil (unten links)
2. Settings → API
3. Erstelle neuen API-Schlüssel
4. Sicher speichern - wird für n8n-MCP und externe Automatisierungen verwendet

### n8n-Integrations-Setup

n8n integriert sich mit sich selbst und anderen AI LaunchKit Services:

#### Mit internen Services verbinden

**Alle Services sind mit internen URLs vorkonfiguriert:**

```javascript
// PostgreSQL (interne Datenbank)
Host: postgres
Port: 5432
Database: n8n
User: n8n
Password: [aus .env-Datei]

// Redis (Queue-Management)
Host: redis
Port: 6379

// Ollama (lokale LLMs)
Base URL: http://ollama:11434

// Mailpit (E-Mail-Testing)
SMTP Host: mailpit
SMTP Port: 1025
```

#### API-Zugriff von externen Tools

```bash
# n8n API-Endpunkt (extern)
https://n8n.deinedomain.com/api/v1

# Authentifizierungs-Header
Authorization: Bearer DEIN_API_KEY

# Beispiel: Alle Workflows auflisten
curl -X GET https://n8n.deinedomain.com/api/v1/workflows \
  -H "Authorization: Bearer DEIN_API_KEY"
```

### Beispiel-Workflows

#### Beispiel 1: KI E-Mail-Verarbeitungs-Pipeline

Vollständiger Workflow für intelligente E-Mail-Behandlung:

```javascript
// 1. Email (IMAP) Trigger Node
Host: mailserver (oder mailpit zum Testen)
Port: 993
TLS: Enabled
Prüfe auf neue E-Mails alle: 1 Minute

// 2. Code Node - E-Mail-Daten extrahieren
const email = {
  from: $json.from.value[0].address,
  subject: $json.subject,
  body: $json.textPlain || $json.html,
  date: $json.date,
  attachments: $json.attachments ? $json.attachments.length : 0
};

// E-Mail-Priorität klassifizieren
const urgent = /dringend|asap|wichtig/i.test(email.subject);
email.priority = urgent ? 'high' : 'normal';

return { json: email };

// 3. OpenAI Node - E-Mail-Inhalt analysieren
Operation: Message a Model
Modell: gpt-4o-mini
Nachrichten:
  System: "Du bist ein E-Mail-Klassifizierungs-Assistent. Kategorisiere E-Mails in: Support, Vertrieb, Allgemein, Spam"
  User: "Betreff: {{$json.subject}}\n\nNachricht: {{$json.body}}"

// 4. Switch Node - Nach Kategorie routen
Mode: Rules
Rules:
  - category equals "Support" → Route zu Support-Workflow
  - category equals "Vertrieb" → Route zu CRM
  - category equals "Spam" → Löschen
  - default → Archivieren

// 5a. Support-Route: Ticket erstellen
// HTTP Request zu Ticketsystem
Methode: POST
URL: http://baserow:8000/api/database/rows/table/tickets/
Body: {
  "title": "{{$('Extract Email').json.subject}}",
  "description": "{{$('Extract Email').json.body}}",
  "customer_email": "{{$('Extract Email').json.from}}",
  "priority": "{{$('Extract Email').json.priority}}",
  "status": "Neu"
}

// 6. Send Email Node - Auto-Antwort
To: {{$('Extract Email').json.from}}
Subject: Re: {{$('Extract Email').json.subject}}
Nachricht: |
  Vielen Dank für Ihre Kontaktaufnahme!
  
  Ihr Ticket #{{$json.id}} wurde erstellt.
  Unser Team wird innerhalb von 24 Stunden antworten.
  
  Mit freundlichen Grüßen,
  Support-Team
```

#### Beispiel 2: Multi-Service Datensynchronisation

Daten automatisch über mehrere Services synchronisieren:

```javascript
// 1. Schedule Trigger Node
Trigger Interval: Alle 15 Minuten
Cron Expression: */15 * * * *

// 2. HTTP Request - Neue Kunden von Supabase abrufen
Methode: GET
URL: http://supabase-kong:8000/rest/v1/customers
Header:
  apikey: {{$env.SUPABASE_ANON_KEY}}
  Authorization: Bearer {{$env.SUPABASE_ANON_KEY}}
Query Parameter:
  select: *
  created_at: gte.{{$now.minus(15, 'minutes').toISO()}}

// 3. Loop Over Items Node
// Jeden neuen Kunden verarbeiten

// 4. Zweig 1: In CRM erstellen (Twenty)
HTTP Request Node
Methode: POST
URL: http://twenty:3000/graphql
Body (GraphQL):
mutation {
  createPerson(data: {
    firstName: "{{$json.first_name}}"
    lastName: "{{$json.last_name}}"
    email: "{{$json.email}}"
    phone: "{{$json.phone}}"
    companyId: "{{$json.company_id}}"
  }) {
    id
  }
}

// 5. Zweig 2: Zu Mailing-Liste hinzufügen (Mautic)
HTTP Request Node  
Methode: POST
URL: http://mautic_web/api/contacts/new
Body: {
  "email": "{{$json.email}}",
  "firstname": "{{$json.first_name}}",
  "lastname": "{{$json.last_name}}",
  "tags": ["neukunde", "supabase-sync"]
}

// 6. Zweig 3: Projekt erstellen (Leantime)
HTTP Request Node
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.projects.addProject",
  "params": {
    "values": {
      "name": "Onboarding - {{$json.company_name}}",
      "clientId": 1,
      "state": 0
    }
  },
  "id": 1
}

// 7. Slack Benachrichtigung
Kanal: #neue-kunden
Nachricht: |
  🎉 Neuer Kunde hinzugefügt!
  
  Name: {{$json.first_name}} {{$json.last_name}}
  E-Mail: {{$json.email}}
  Firma: {{$json.company_name}}
  
  Abgeschlossene Aktionen:
  ✅ Zu CRM hinzugefügt
  ✅ Zu Mailing-Liste hinzugefügt
  ✅ Onboarding-Projekt erstellt
```

#### Beispiel 3: KI-Content-Generierungs-Pipeline

Content automatisch generieren und veröffentlichen:

```javascript
// 1. Schedule Trigger
Trigger: Wöchentlich montags um 10 Uhr

// 2. Code Node - Content-Themen definieren
const topics = [
  "KI-Automatisierungs-Trends",
  "Vorteile selbst gehosteter Tools",
  "Workflow-Optimierungs-Tipps",
  "Datenschutz Best Practices"
];

// Zufällige Themenauswahl
const randomTopic = topics[Math.floor(Math.random() * topics.length)];

return {
  json: {
    topic: randomTopic,
    date: new Date().toISOString()
  }
};

// 3. OpenAI Node - Blog-Post generieren
Operation: Message a Model
Modell: gpt-4o
Nachrichten:
  System: "Du bist ein technischer Content-Autor spezialisiert auf KI und Automatisierung."
  User: |
    Schreibe einen umfassenden Blog-Post über: {{$json.topic}}
    
    Anforderungen:
    - 800-1000 Wörter
    - Praktische Beispiele einschließen
    - SEO-optimiert mit relevanten Keywords
    - Ansprechender Ton für technisches Publikum
    - 3-5 umsetzbare Erkenntnisse einschließen

// 4. OpenAI Node - Social-Media-Posts generieren
Operation: Message a Model
Modell: gpt-4o-mini
Nachrichten:
  User: |
    Erstelle Social-Media-Posts für diesen Blog:
    {{$('Generate Blog Post').json.choices[0].message.content}}
    
    Erstelle:
    1. LinkedIn-Post (max 1300 Zeichen)
    2. Twitter-Thread (3-5 Tweets)
    3. Instagram-Caption (max 2200 Zeichen)

// 5. HTTP Request - Auf WordPress/Ghost veröffentlichen
Methode: POST
URL: http://wordpress:80/wp-json/wp/v2/posts
Header:
  Authorization: Basic {{$env.WORDPRESS_AUTH}}
Body: {
  "title": "{{$json.topic}}",
  "content": "{{$('Generate Blog Post').json.content}}",
  "status": "draft",
  "categories": [1]
}

// 6. Postiz Node - Social Posts planen
// Nutze nativen Postiz-Node oder HTTP-Requests
// Plane LinkedIn, Twitter, Instagram Posts

// 7. Slack Benachrichtigung
Kanal: #content-team
Nachricht: |
  📝 Neuer Blog-Post generiert!
  
  Thema: {{$('Define Topics').json.topic}}
  Status: Entwurf (bereit zur Überprüfung)
  WordPress: {{$('Publish').json.link}}
  
  Social Posts geplant ✅
```

### n8n Native Python Task Runner (Beta)

**⚠️ BREAKING CHANGES von Pyodide**

AI LaunchKit nutzt jetzt n8n's **Native Python Task Runner** statt der alten Pyodide (WebAssembly) Implementierung. Das bietet:

- ✅ **10-20x schneller** Python-Ausführung
- ✅ **Volle Python-Paket-Unterstützung** (pandas, numpy, scikit-learn, etc.)
- ✅ **Native CPython 3.11** (kein WebAssembly)
- ⚠️ **Breaking Syntax-Änderungen** - bestehende Python Code Nodes müssen angepasst werden

#### Syntax-Migration erforderlich

**ALT (Pyodide - funktioniert nicht mehr):**
```python
# Dot-Notation
name = item.json.customer.name
for item in items:  # "items" Variable
```

**NEU (Native Python - erforderlich):**
```python
# Bracket-Notation
name = item["json"]["customer"]["name"]
for item in _items:  # "_items" Variable (Unterstrich!)
```

#### Wie es funktioniert
```
n8n Container ←→ n8n-runner Container (n8nio/runners:latest)
(Workflow)        (Native Python Ausführung)
```

Der `n8n-runner` Container startet automatisch mit dem `n8n` Profil und führt alle Python Code Node Ausführungen über WebSocket aus.

#### Überprüfen ob es funktioniert
```bash
# n8n-runner Container prüfen
docker ps | grep n8n-runner

# In n8n testen
# 1. Workflow mit Manual Trigger + Code Node erstellen
# 2. Python Sprache wählen
# 3. Ausführen: return [{"json": {"test": "Native Python funktioniert!"}}]
```

#### Python-Pakete installieren

Standardmäßig ist nur die Python-Standardbibliothek verfügbar. Um Pakete wie pandas oder numpy zu nutzen, musst du ein eigenes `n8nio/runners` Image bauen:

**Siehe:** [n8n Task Runners Dokumentation](https://docs.n8n.io/hosting/configuration/task-runners/) für detaillierte Anleitungen zum Hinzufügen von Paketen.

**Ressourcen:**
- [n8n Task Runners Docs](https://docs.n8n.io/hosting/configuration/task-runners/)
- [Python-Pakete hinzufügen](https://docs.n8n.io/hosting/configuration/task-runners/#adding-extra-dependencies)
- [Code Node Dokumentation](https://docs.n8n.io/code/code-node/)

### Fehlerbehebung

**Workflows werden nicht ausgeführt:**

```bash
# 1. Prüfe n8n-Container-Status
docker ps | grep n8n

# 2. Prüfe n8n-Logs
docker logs n8n --tail 100

# 3. Prüfe Worker-Prozesse
docker logs n8n-worker --tail 100

# 4. Überprüfe Redis-Verbindung
docker exec n8n nc -zv redis 6379

# 5. Prüfe PostgreSQL-Verbindung
docker exec n8n nc -zv postgres 5432
```

**"Service nicht erreichbar"-Fehler:**

```bash
# 1. Überprüfe ob interner Service läuft
docker ps | grep [dienst-name]

# 2. Teste interne DNS-Auflösung
docker exec n8n ping [dienst-name]

# 3. Prüfe Docker-Netzwerk
docker network inspect ai-launchkit_default

# 4. Überprüfe ob Port korrekt ist
docker port [dienst-name]

# 5. Prüfe Service-Logs
docker logs [dienst-name] --tail 50
```

**Speicher-/Performance-Probleme:**

```bash
# 1. Prüfe Ressourcen-Nutzung
docker stats n8n --no-stream

# 2. Prüfe Worker-Anzahl
grep N8N_WORKER_COUNT .env

# 3. Erhöhe Speicher-Limit (falls nötig)
# Bearbeite docker-compose.yml:
# mem_limit: 2g

# 4. Optimiere Workflows
# - Nutze Paginierung für große Datensätze
# - Füge Wait-Nodes zwischen Bulk-Operationen hinzu
# - Teile komplexe Workflows in kleinere auf

# 5. Lösche Ausführungsdaten
docker exec n8n n8n clear:executions --all
```

**Credential-Authentifizierungsfehler:**

```bash
# 1. Prüfe Credential-Konfiguration
# In n8n: Credentials → Test Connection

# 2. Überprüfe Umgebungsvariablen
docker exec n8n printenv | grep [SERVICE]

# 3. Prüfe interne URLs
# Nutze Service-Namen, nicht localhost
# ✅ http://mailserver:587
# ❌ http://localhost:587

# 4. Erstelle Credential neu
# Lösche und erstelle neu in n8n UI

# 5. Starte n8n neu
docker compose restart n8n
```

**Webhook empfängt keine Daten:**

```bash
# 1. Teste Webhook-URL
curl -X POST https://n8n.deinedomain.com/webhook-test/dein-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "daten"}'

# 2. Prüfe Caddy-Logs
docker logs caddy | grep webhook

# 3. Überprüfe ob Webhook aktiv ist
# n8n → Workflow → Webhook-Node → Prüfe "Listening"

# 4. Prüfe Firewall
sudo ufw status | grep 443

# 5. Teste von externem Service
# Überprüfe ob Webhook-URL vom Internet aus erreichbar ist
```

### Ressourcen

- **Offizielle Dokumentation:** https://docs.n8n.io/
- **Community-Forum:** https://community.n8n.io/
- **Workflow-Vorlagen:** https://n8n.io/workflows
- **API-Dokumentation:** https://docs.n8n.io/api/
- **YouTube-Tutorials:** https://www.youtube.com/@n8n-io
- **GitHub:** https://github.com/n8n-io/n8n

### Best Practices

**Workflow-Organisation:**
- Nutze beschreibende Workflow-Namen
- Füge Notizen zu komplexen Nodes hinzu
- Gruppiere verwandte Nodes mit Sticky Notes
- Nutze konsistente Benennung für Credentials
- Versionskontrolle: Exportiere Workflows als JSON

**Performance-Optimierung:**
- Nutze Batch-Verarbeitung für große Datensätze
- Füge Wait-Nodes zwischen API-Aufrufen hinzu
- Implementiere Fehlerbehandlung mit Try/Catch-Nodes
- Nutze Paginierung für API-Requests
- Überwache Ausführungszeiten

**Sicherheit:**
- Niemals Credentials direkt in Workflows hart kodieren
- Nutze Umgebungsvariablen für sensible Daten
- Implementiere Webhook-Authentifizierung
- Rotiere API-Schlüssel regelmäßig
- Überprüfe Workflow-Berechtigungen

**Wartung:**
- Prüfe regelmäßig Fehler-Ausführungen
- Überwache Workflow-Ausführungszeiten
- Aktualisiere Community-Nodes
- Sichere Workflows wöchentlich
- Dokumentiere komplexe Logik in Notizen
