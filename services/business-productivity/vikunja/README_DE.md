# ✅ Vikunja - Aufgabenverwaltung

### Was ist Vikunja?

Vikunja ist eine moderne, Open-Source-Aufgabenverwaltungsplattform, die leistungsstarke Projektorganisation mit mehreren Ansichtstypen (Kanban, Gantt, Kalender, Tabelle) bietet. Sie ist perfekt für die Automatisierung von Projekt-Workflows und Aufgabenverwaltung in n8n, mit vollständiger CalDAV-Unterstützung und mobilen Apps.

### Funktionen

- **Mehrere Ansichten:** Kanban-Boards, Gantt-Diagramme, Kalenderansicht, Tabellenansicht
- **Echtzeit-Zusammenarbeit:** Team-Workspaces, Aufgabenzuweisungen, Kommentare, Dateianhänge (bis zu 20MB)
- **Import/Export:** Import von Todoist, Trello, Microsoft To-Do; Export als CSV/JSON
- **CalDAV-Unterstützung:** Vollständige Kalendersynchronisation unter `https://vikunja.deinedomain.com/dav`
- **Mobile Apps:** Native iOS (App Store - "Vikunja Cloud") und Android (Play Store - "Vikunja") Apps
- **API-First:** Umfassende REST-API für Automatisierung und Integration

### Erste Einrichtung

**Erste Anmeldung bei Vikunja:**

1. Navigiere zu `https://vikunja.deinedomain.com`
2. Klicke auf "Registrieren", um dein erstes Konto zu erstellen
   - Der erste registrierte Benutzer wird automatisch Admin
3. Erstelle dein erstes Projekt und Listen
4. Konfiguriere deine Workspace-Einstellungen
5. API-Token generieren:
   - Gehe zu Benutzereinstellungen → API-Tokens
   - Klicke auf "Neuen Token erstellen"
   - Nenne ihn "n8n Integration"
   - Kopiere den Token zur Verwendung in n8n

### n8n-Integrations-Setup

**Option 1: Community Node (Empfohlen)**

1. In n8n, gehe zu Einstellungen → Community-Nodes
2. Installiere `n8n-nodes-vikunja`
3. Vikunja-Credentials erstellen:
   - **URL:** `http://vikunja:3456` (intern) oder `https://vikunja.deinedomain.com` (extern)
   - **API-Token:** Dein Token aus Vikunja-Einstellungen

**Option 2: HTTP Request Node**

```javascript
// HTTP Request Credentials
Base URL: http://vikunja:3456/api/v1
Authentication: Bearer Token
Token: [Dein API-Token von Vikunja]
```

**Interne URL für n8n:** `http://vikunja:3456`

### Beispiel-Workflows

#### Beispiel 1: Aufgabe aus E-Mail erstellen

```javascript
// Automatisch Aufgaben aus eingehenden E-Mails erstellen

// 1. Email Trigger (IMAP) oder Webhook
// Überwacht Posteingang auf E-Mails mit [TASK] im Betreff

// 2. Code Node - E-Mail parsen
const subject = $json.subject.replace('[TASK]', '').trim();
const description = $json.textPlain || $json.textHtml;

return {
  title: subject,
  description: description,
  projectId: 1 // Deine Standard-Projekt-ID
};

// 3. HTTP Request Node - Aufgabe in Vikunja erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/projects/{{$json.projectId}}/tasks
Header:
  Authorization: Bearer {{$credentials.vikunjaToken}}
Body: {
  "title": "{{$json.title}}",
  "description": "{{$json.description}}"
}

// 4. Send Email Node - Bestätigung
To: {{$('Email Trigger').json.from}}
Subject: Aufgabe erstellt: {{$('HTTP Request').json.title}}
Nachricht: |
  Deine Aufgabe wurde in Vikunja erstellt:
  
  Titel: {{$('HTTP Request').json.title}}
  Link: https://vikunja.deinedomain.com/tasks/{{$('HTTP Request').json.id}}
```

#### Beispiel 2: Tägliche Aufgabenzusammenfassung

```javascript
// Sende tägliche Zusammenfassung der heute fälligen Aufgaben

// 1. Schedule Trigger - Jeden Tag um 8 Uhr

// 2. HTTP Request - Heute fällige Aufgaben abrufen
Methode: GET
URL: http://vikunja:3456/api/v1/tasks/all
Query Parameter:
  filter_by: due_date
  filter_value: {{$now.toISODate()}}

// 3. Code Node - Aufgabenliste formatieren
const tasks = $json;
let message = `📋 Heute fällige Aufgaben (${tasks.length})\n\n`;

tasks.forEach((task, index) => {
  message += `${index + 1}. ${task.title}\n`;
  message += `   Projekt: ${task.project.title}\n`;
  message += `   Zugewiesen an: ${task.assignees[0]?.username || 'Nicht zugewiesen'}\n\n`;
});

return { message };

// 4. Slack/Email Node - Zusammenfassung senden
Nachricht: {{$json.message}}
```

#### Beispiel 3: Aufgaben-Automatisierungs-Pipeline

```javascript
// Aufgaben aus Webhooks erstellen (z.B. aus Formularen, anderen Tools)

// 1. Webhook Trigger
// Empfängt JSON-Daten aus externen Quellen

// 2. Switch Node - Nach Aufgabentyp routen
// Verzweigung nach Aufgabenpriorität oder -kategorie

// Branch 1: Hohe Priorität
// 3a. HTTP Request - Dringende Aufgabe erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body: {
  "title": "DRINGEND: {{$json.title}}",
  "priority": 5,
  "due_date": "{{$now.plus(1, 'days').toISO()}}"
}

// 4a. Slack Node - Team sofort benachrichtigen
Kanal: #urgent-tasks
Nachricht: 🚨 Dringende Aufgabe erstellt: {{$json.title}}

// Branch 2: Normale Priorität
// 3b. HTTP Request - Normale Aufgabe erstellen
Priority: 3
Due Datum: {{$now.plus(7, 'days').toISO()}}

// 4b. Email Node - Tägliche Zusammenfassung (gebündelt)
```

#### Beispiel 4: Wiederkehrende Aufgaben-Generator

```javascript
// Automatisch wiederkehrende Aufgaben erstellen

// 1. Schedule Trigger - Jeden Montag um 9 Uhr

// 2. Code Node - Wöchentliche Aufgaben generieren
const weeklyTasks = [
  { title: 'Wöchentliches Team-Meeting', day: 'monday', time: '10:00' },
  { title: 'Kundenbericht', day: 'friday', time: '16:00' },
  { title: 'Backup-Prüfung', day: 'sunday', time: '22:00' }
];

return weeklyTasks.map(task => ({
  title: task.title,
  dueDatum: getNextDayOfWeek(task.day, task.time)
}));

// 3. Loop Over Items

// 4. HTTP Request - Jede Aufgabe erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body: {
  "title": "{{$json.title}}",
  "due_date": "{{$json.dueDate}}",
  "repeat_after": 604800 // 7 Tage in Sekunden
}
```

#### Beispiel 5: Aufgaben-Import aus Trello/Asana/CSV

```javascript
// Aufgaben aus anderen Plattformen migrieren

// 1. HTTP Request - Aus Quelle abrufen (Trello API, CSV-Datei, etc.)

// 2. Code Node - Daten in Vikunja-Format transformieren
const tasks = $json.cards || $json.tasks || [];

return tasks.map(task => ({
  title: task.name || task.title,
  description: task.desc || task.description,
  dueDatum: task.due || task.dueDate,
  labels: task.labels?.map(l => l.name).join(',')
}));

// 3. Loop Over Items

// 4. HTTP Request - In Vikunja erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/projects/1/tasks
Body: {
  "title": "{{$json.title}}",
  "description": "{{$json.description}}",
  "due_date": "{{$json.dueDate}}"
}

// 5. Wait Node - 500ms zwischen Anfragen (Rate-Limiting)

// 6. Finale Benachrichtigung wenn abgeschlossen
```

### Fehlerbehebung

**Aufgaben werden nicht angezeigt:**

```bash
# 1. Vikunja-Status prüfen
docker ps | grep vikunja
# Sollte zeigen: STATUS = Up

# 2. Vikunja-Logs prüfen
docker logs vikunja --tail 100

# 3. API-Token überprüfen
# Generiere neuen Token in Vikunja-Einstellungen falls nötig

# 4. API-Verbindung von n8n testen
docker exec n8n curl -H "Authorization: Bearer DEIN_TOKEN" \
  http://vikunja:3456/api/v1/projects
# Sollte Liste der Projekte zurückgeben
```

**API-Authentifizierungsfehler:**

```bash
# 1. Token-Format überprüfen
# Sollte sein: Authorization: Bearer token_hier

# 2. Interne URL korrekt prüfen
# Von n8n: http://vikunja:3456
# Nicht: https://vikunja.deinedomain.com

# 3. API-Token neu generieren
# Benutzereinstellungen → API-Tokens → Neuen Token erstellen

# 4. Vikunja-Container-Netzwerk prüfen
docker network inspect ai-corekit_default | grep vikunja
```

**CalDAV-Sync funktioniert nicht:**

```bash
# 1. CalDAV-URL-Format
# https://vikunja.deinedomain.com/dav/projects/[projekt-id]

# 2. Vikunja-Credentials verwenden (nicht API-Token)
# Benutzername: deine@email.com
# Passwort: dein Vikunja-Passwort

# 3. CalDAV-Verbindung testen
curl -X PROPFIND https://vikunja.deinedomain.com/dav \
  -u "deine@email.com:passwort"
```

### Tipps für Vikunja + n8n Integration

**Best Practices:**

1. **Interne URLs verwenden:** Nutze immer `http://vikunja:3456` von n8n-Containern (schneller, kein SSL-Overhead)
2. **Dedizierte API-Tokens:** Erstelle separate Tokens für jeden n8n-Workflow oder Integration
3. **Rate-Limiting:** Füge Wait-Nodes (200-500ms) zwischen Bulk-Operationen hinzu, um Überlastung zu vermeiden
4. **Fehlerbehandlung:** Nutze Try/Catch-Nodes für belastbare Workflows
5. **Webhook-Setup:** Konfiguriere Vikunja-Webhooks für Echtzeit-Aufgabenaktualisierungen
6. **Projekt-IDs:** Speichere Projekt-IDs in n8n-Umgebungsvariablen für einfache Referenz
7. **Label-Verwaltung:** Nutze Labels für Workflow-Automatisierungs-Trigger

**Projektorganisation:**

- Erstelle separate Projekte für verschiedene Workflow-Typen
- Nutze Listen innerhalb von Projekten zur Organisation nach Status/Kategorie
- Wende konsistente Beschriftung für Automatisierungs-Trigger an
- Richte Vorlagen für häufige Aufgabentypen ein

**Mobile & Kalender-Integration:**

- iOS/Android-Apps funktionieren nahtlos mit selbst gehosteter Instanz
- CalDAV-Integration synchronisiert mit Apple Calendar, Google Calendar, Thunderbird
- Nutze CalDAV-URL: `https://vikunja.deinedomain.com/dav`
- Mobile Benachrichtigungen für Aufgabenzuweisungen und Fälligkeitsdaten

### Ressourcen

- **Dokumentation:** https://vikunja.io/docs/
- **API-Referenz:** https://try.vikunja.io/api/v1/docs
- **GitHub:** https://github.com/go-vikunja/vikunja
- **Community-Forum:** https://community.vikunja.io/
- **Mobile Apps:**
  - iOS: https://apps.apple.com/app/vikunja-cloud/id1660089863
  - Android: https://play.google.com/store/apps/details?id=io.vikunja.app
