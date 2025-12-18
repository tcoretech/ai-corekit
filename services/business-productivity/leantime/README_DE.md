# 🎯 Leantime - Projektmanagement

### Was ist Leantime?

Leantime ist eine zielorientierte Projektmanagement-Suite, die speziell für ADHS- und neurodiverse Teams entwickelt wurde. Sie kombiniert traditionelle PM-Tools (Sprints, Zeiterfassung, Gantt-Diagramme) mit strategischen Planungs-Frameworks (Lean Canvas, SWOT, Goal Canvas) und ADHS-freundlichen Funktionen wie Fokusmodus, Pausenerinnerungen und Gamification-Elementen.

### Funktionen

- **Strategie-Tools:** Goal Canvas (OKRs), Lean Canvas, SWOT-Analyse, Opportunity Canvas
- **Projektmanagement:** Kanban-Boards, Gantt-Diagramme, Meilensteine, Sprints
- **Zeiterfassung:** Integrierter Timer, Timesheets, Schätzungen vs. tatsächliche Stunden
- **ADHS-freundliche Oberfläche:** Dopamin-getriebenes Design, Fokusmodus, Pomodoro-Technik-Unterstützung
- **Team-Zusammenarbeit:** Kommentare, Dateianhänge, @Erwähnungen, Echtzeit-Updates
- **JSON-RPC API:** Vollständige Automatisierungsunterstützung über JSON-RPC 2.0 Protokoll

### Erste Einrichtung

**Erster Login bei Leantime:**

1. Navigiere zu `https://leantime.deinedomain.com`
2. Der Installationsassistent startet automatisch
3. Erstelle dein Admin-Konto (erster Benutzer wird Admin)
4. Vervollständige das Firmenprofil
5. Generiere einen API-Schlüssel:
   - Gehe zu Benutzereinstellungen → API-Zugriff
   - Klicke auf "API-Schlüssel erstellen"
   - Benenne ihn "n8n Integration"
   - Kopiere den Schlüssel für die Verwendung in n8n

**MySQL 8.4 Automatische Installation:**
- Leantime installiert automatisch MySQL 8.4 während des Setups
- Diese MySQL-Instanz kann für andere Dienste wiederverwendet werden (WordPress, Ghost, etc.)
- Root-Passwort verfügbar in der `.env` Datei als `LEANTIME_MYSQL_ROOT_PASSWORD`

### n8n Integration einrichten

**WICHTIG:** Leantime nutzt die JSON-RPC 2.0 API, nicht REST. Alle Anfragen gehen an den `/api/jsonrpc` Endpunkt.

**Leantime-Zugangsdaten in n8n erstellen:**

1. Gehe zu Credentials → New → Header Auth
2. Konfiguriere:
   - **Name:** `Leantime API`
   - **Header Name:** `x-api-key`
   - **Header Wert:** `[Dein API-Schlüssel aus den Leantime-Einstellungen]`

**HTTP Request Node Konfiguration:**

```javascript
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Authentication: Header Auth (wähle deine Leantime API Zugangsdaten)
Header:
  Content-Type: application/json
  Accept: application/json
Body Type: JSON
```

**Interne URL für n8n:** `http://leantime:8080`

### JSON-RPC API Referenz

**Verfügbare Methoden:**

**Projekte:**
- `leantime.rpc.projects.getAll` - Alle Projekte abrufen
- `leantime.rpc.projects.getProject` - Spezifisches Projekt abrufen
- `leantime.rpc.projects.addProject` - Neues Projekt erstellen
- `leantime.rpc.projects.updateProject` - Projekt aktualisieren

**Aufgaben/Tickets:**
- `leantime.rpc.tickets.getAll` - Alle Tickets abrufen
- `leantime.rpc.tickets.getTicket` - Spezifisches Ticket abrufen
- `leantime.rpc.tickets.addTicket` - Neues Ticket erstellen
- `leantime.rpc.tickets.updateTicket` - Ticket aktualisieren
- `leantime.rpc.tickets.deleteTicket` - Ticket löschen

**Zeiterfassung:**
- `leantime.rpc.timesheets.getAll` - Timesheets abrufen
- `leantime.rpc.timesheets.addTime` - Zeiteintrag erfassen
- `leantime.rpc.timesheets.updateTime` - Zeiteintrag aktualisieren

**Meilensteine:**
- `leantime.rpc.tickets.getAllMilestones` - Meilensteine abrufen
- `leantime.rpc.tickets.addMilestone` - Meilenstein erstellen

### Status- & Typ-Codes

```javascript
// Aufgaben-Status-Codes
const STATUS = {
  NEW: 3,           // Neu
  IN_PROGRESS: 1,   // In Bearbeitung
  DONE: 0,          // Fertig
  BLOCKED: 4,       // Blockiert
  REVIEW: 2         // Review
};

// Aufgaben-Typen
const TYPES = {
  TASK: "task",
  BUG: "bug",
  STORY: "story",
  MILESTONE: "milestone"
};

// Prioritätsstufen
const PRIORITY = {
  HIGH: "1",
  MEDIUM: "2",
  LOW: "3"
};
```

### Beispiel-Workflows

#### Beispiel 1: Alle Projekte abrufen

```javascript
// Einfache Abfrage zum Auflisten aller Projekte

// HTTP Request Node
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Header:
  x-api-key: {{$credentials.leantimeApiKey}}
  Content-Type: application/json
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.projects.getAll",
  "id": 1,
  "params": {}
}

// Antwortformat:
{
  "jsonrpc": "2.0",
  "result": [
    {
      "id": 1,
      "name": "AI LaunchKit Entwicklung",
      "clientId": 1,
      "state": 0
    }
  ],
  "id": 1
}
```

#### Beispiel 2: Aufgabe aus E-Mail erstellen

```javascript
// Automatisch Leantime-Aufgaben aus E-Mails erstellen

// 1. Email Trigger (IMAP)
// Überwacht Posteingang auf E-Mails mit [TASK] im Betreff

// 2. Code Node - E-Mail parsen
const subject = $json.subject.replace('[TASK]', '').trim();
const description = $json.textPlain || $json.textHtml;

return {
  headline: subject,
  description: description,
  projectId: 1
};

// 3. HTTP Request - Aufgabe in Leantime erstellen
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.addTicket",
  "id": 1,
  "params": {
    "values": {
      "headline": "{{$json.headline}}",
      "description": "{{$json.description}}",
      "type": "task",
      "projectId": {{$json.projectId}},
      "status": 3,
      "priority": "2"
    }
  }
}

// 4. Send Email Node - Bestätigung
To: {{$('Email Trigger').json.from}}
Subject: Aufgabe in Leantime erstellt
Nachricht: |
  Deine Aufgabe wurde erstellt:
  
  Titel: {{$json.headline}}
  Projekt: AI LaunchKit Entwicklung
  Status: Neu
  
  In Leantime anzeigen: https://leantime.deinedomain.com
```

#### Beispiel 3: Automatisierung der wöchentlichen Sprint-Planung

```javascript
// Automatisch Sprint-Aufgaben jeden Montag erstellen

// 1. Schedule Trigger - Jeden Montag um 9 Uhr

// 2. Code Node - Wöchentliche Aufgaben generieren
const weekNumber = Math.ceil((new Date() - new Date(new Date().getFullYear(), 0, 1)) / 604800000);

const weeklyTasks = [
  {
    headline: `Woche ${weekNumber} - Sprint-Planung`,
    type: "task",
    priority: "1"
  },
  {
    headline: `Woche ${weekNumber} - Tägliche Standups`,
    type: "task",
    priority: "2"
  },
  {
    headline: `Woche ${weekNumber} - Sprint-Review`,
    type: "task",
    priority: "2"
  },
  {
    headline: `Woche ${weekNumber} - Sprint-Retrospektive`,
    type: "task",
    priority: "2"
  }
];

return weeklyTasks;

// 3. Loop Over Items

// 4. HTTP Request - Jede Aufgabe erstellen
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.addTicket",
  "id": 1,
  "params": {
    "values": {
      "headline": "{{$json.headline}}",
      "type": "{{$json.type}}",
      "projectId": 1,
      "status": 3,
      "priority": "{{$json.priority}}",
      "tags": "weekly,automated"
    }
  }
}

// 5. Slack Notification
Kanal: #project-updates
Nachricht: |
  📋 Wöchentliche Sprint-Aufgaben erstellt für Woche {{$('Code Node').json.weekNumber}}
  
  ✅ Sprint-Planung
  ✅ Tägliche Standups
  ✅ Sprint-Review
  ✅ Sprint-Retrospektive
```

#### Beispiel 4: Automatisierung von Zeiterfassungs-Reports

```javascript
// Wöchentliche Zeitberichte generieren

// 1. Schedule Trigger - Jeden Freitag um 17 Uhr

// 2. HTTP Request - Alle Tickets mit Zeiteinträgen abrufen
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.getAll",
  "id": 1,
  "params": {}
}

// 3. Code Node - Zeitzusammenfassungen berechnen
const tickets = $json.result;

const timeReport = tickets
  .filter(t => t.bookedHours > 0)
  .map(ticket => ({
    task: ticket.headline,
    project: ticket.projectName,
    plannedHours: ticket.planHours || 0,
    actualHours: ticket.bookedHours,
    remaining: ticket.hourRemaining || 0,
    status: ticket.statusLabel
  }));

const totalBooked = timeReport.reduce((sum, t) => sum + t.actualHours, 0);
const totalPlanned = timeReport.reduce((sum, t) => sum + t.plannedHours, 0);
const efficiency = totalPlanned > 0 ? (totalBooked / totalPlanned * 100).toFixed(2) : 0;

return {
  report: timeReport,
  summary: {
    totalBookedHours: totalBooked,
    totalPlannedHours: totalPlanned,
    efficiency: efficiency + '%',
    weekEnding: new Date().toISOString()
  }
};

// 4. Send Email - Wochenbericht
To: team@firma.de
Subject: Wöchentlicher Zeitbericht - Woche bis {{$json.summary.weekEnding}}
Nachricht: |
  📊 Wöchentlicher Zeiterfassungs-Report
  
  Gebuchte Gesamtstunden: {{$json.summary.totalBookedHours}}h
  Geplante Gesamtstunden: {{$json.summary.totalPlannedHours}}h
  Effizienz: {{$json.summary.efficiency}}
  
  Detaillierte Aufschlüsselung im Anhang.
```

#### Beispiel 5: KI-Ideen zu Aufgaben-Pipeline

```javascript
// Ideen mit KI in umsetzbare Aufgaben umwandeln

// 1. Webhook Trigger
// Empfängt Ideenvorschläge von Formularen/Chat

// 2. OpenAI Node - Idee analysieren und aufschlüsseln
Modell: gpt-4o-mini
Prompt: |
  Zerlege diese Idee in 3-5 konkrete, umsetzbare Aufgaben:
  
  "{{$json.idea}}"
  
  Liefere für jede Aufgabe:
  - Titel (kurz, umsetzbar)
  - Beschreibung (2-3 Sätze)
  - Geschätzte Stunden (realistisch)
  
  Rückgabe als JSON-Array.

// 3. Code Node - KI-Antwort parsen
const tasks = JSON.parse($json.choices[0].message.content);

return tasks.map(task => ({
  headline: task.title,
  description: task.description,
  storypoints: task.estimatedHours
}));

// 4. Loop Over Items

// 5. HTTP Request - Jede Aufgabe erstellen
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.addTicket",
  "id": 1,
  "params": {
    "values": {
      "headline": "{{$json.headline}}",
      "description": "{{$json.description}}",
      "type": "task",
      "projectId": 1,
      "status": 3,
      "storypoints": "{{$json.storypoints}}",
      "tags": "idea-generated,ai-enhanced"
    }
  }
}

// 6. Abschluss-Benachrichtigung
Nachricht: |
  🤖 KI hat deine Idee verarbeitet und {{$('Loop Over Items').itemsLength}} Aufgaben erstellt!
  
  In Leantime anzeigen: https://leantime.deinedomain.com
```

#### Beispiel 6: Aufgabenstatus aktualisieren

```javascript
// Aufgabenstatus aktualisieren, wenn Bedingungen erfüllt sind

// 1. Webhook oder Schedule Trigger

// 2. HTTP Request - Spezifische Aufgabe abrufen
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.getTicket",
  "id": 1,
  "params": {
    "id": 10
  }
}

// 3. Code Node - Bedingungen prüfen
const task = $json.result;
let newStatus = task.status;

if (task.progress >= 100) {
  newStatus = 0; // DONE
} else if (task.progress > 0) {
  newStatus = 1; // IN_PROGRESS
}

return { taskId: task.id, newStatus };

// 4. HTTP Request - Aufgabe aktualisieren
Methode: POST
URL: http://leantime:8080/api/jsonrpc
Body: {
  "jsonrpc": "2.0",
  "method": "leantime.rpc.tickets.updateTicket",
  "id": 1,
  "params": {
    "id": {{$json.taskId}},
    "values": {
      "status": {{$json.newStatus}}
    }
  }
}
```

### Fehlerbehebung

**Fehler "Method not found":**

```bash
# 1. Methodennamen-Schreibweise und Groß-/Kleinschreibung prüfen
# Format muss sein: leantime.rpc.resource.method

# 2. API-Zugriff in Leantime verifizieren
# Benutzereinstellungen → API-Zugriff → Prüfen, ob Schlüssel aktiv ist

# 3. API-Endpunkt testen
docker exec n8n curl -X POST http://leantime:8080/api/jsonrpc \
  -H "x-api-key: DEIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"leantime.rpc.projects.getAll","id":1,"params":{}}'
```

**Authentifizierung fehlgeschlagen:**

```bash
# 1. API-Schlüssel-Format prüfen
# Header muss exakt sein: x-api-key (nicht X-API-KEY oder x-api-token)

# 2. API-Schlüssel neu generieren
# Leantime → Benutzereinstellungen → API-Zugriff → Neuen Schlüssel erstellen

# 3. Header in n8n verifizieren
# Credentials → Header Auth → Header Name: x-api-key

# 4. Test vom n8n-Container
docker exec n8n curl -H "x-api-key: DEIN_KEY" http://leantime:8080/api/jsonrpc
```

**Fehler bei ungültigen Parametern:**

```bash
# 1. Parameter müssen in "params"-Objekt eingeschlossen sein
# Korrekt:
{
  "jsonrpc": "2.0",
  "method": "...",
  "id": 1,
  "params": {
    "values": {...}
  }
}

# 2. Für Updates muss ID separat sein
{
  "params": {
    "id": 10,
    "values": {
      "headline": "Aktualisiert"
    }
  }
}
```

**Verbindung abgelehnt:**

```bash
# 1. Internen Docker-Hostnamen verwenden
# VON n8n: http://leantime:8080
# NICHT: http://localhost:8080

# 2. Leantime-Container-Status prüfen
docker ps | grep leantime
# Sollte zeigen: STATUS = Up

# 3. Netzwerkverbindung prüfen
docker exec n8n ping leantime
# Sollte zurückgeben: Pakete übertragen und empfangen

# 4. Port verifizieren ist 8080
grep LEANTIME_PORT .env
# Sollte zeigen: LEANTIME_PORT=8080
```

### Tipps für Leantime + n8n Integration

**Best Practices:**

1. **Immer JSON-RPC-Format verwenden:** Alle API-Aufrufe müssen POST an `/api/jsonrpc` sein
2. **Interne URLs:** Nutze `http://leantime:8080` von n8n aus (schneller, kein SSL)
3. **Fehlerbehandlung:** Prüfe auf `error`-Feld in JSON-RPC-Antworten
4. **Antwortformat:** Ergebnisse sind immer im `result`-Feld
5. **Batch-Operationen:** Kann Array von Anfragen für Effizienz senden
6. **ID-Parameter:** Die meisten Update/Delete-Operationen benötigen ID in params
7. **Zeitformat:** Nutze ISO 8601 für Datumsangaben

**ADHS-freundliche Automatisierung:**

- Automatisiere wiederkehrende Aufgabenerstellung, um mentale Last zu reduzieren
- Richte Erinnerungen für Pausenzeiten mit Schedule Triggers ein
- Erstelle visuelle Fortschritts-Dashboards mit n8n → Slack/E-Mail
- Generiere tägliche Fokus-Listen basierend auf Priorität und Fristen

**Strategie-Integration:**

- Automatisiere Zielverfolgung vom Goal Canvas
- Generiere Erkenntnisse aus Lean Canvas-Daten
- Erstelle Feedbackschleifen zwischen Umsetzung (Aufgaben) und Strategie
- Synchronisiere strategische Ziele mit Team-Aufgaben-Zuweisungen

### Ressourcen

- **Dokumentation:** https://docs.leantime.io/
- **API-Referenz:** https://docs.leantime.io/api/
- **GitHub:** https://github.com/Leantime/leantime
- **Community-Forum:** https://community.leantime.io/
- **Philosophie:** "Start with WHY"-Ansatz für ADHS-freundliches Projektmanagement
