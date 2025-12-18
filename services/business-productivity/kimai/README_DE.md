# ⏱️ Kimai - Zeiterfassung

### Was ist Kimai?

Kimai ist eine professionelle Zeiterfassungslösung aus Österreich, die DSGVO/GDPR-konform ist und perfekt für Freelancer und kleine Teams geeignet ist. Sie bietet umfassende Zeiterfassung mit Rechnungsstellung, Team-Management, 2FA-Unterstützung und einer vollständigen REST API für Automatisierung.

### Funktionen

- **DSGVO/GDPR-konform:** Entwickelt nach europäischen Datenschutzstandards
- **Professionelle Rechnungsstellung:** Export zu Excel, CSV, PDF mit anpassbaren Vorlagen
- **Team-Management:** Rollen-Hierarchie (Benutzer → Teamleiter → Admin → Super-Admin)
- **Multi-Projekt-Tracking:** Zeit nach Kunden, Projekten und Aktivitäten organisieren
- **Mobile Apps:** Native iOS- und Android-Apps für unterwegs
- **REST API:** Vollständige API für Automatisierung und Integration

### Erste Einrichtung

**Erster Login bei Kimai:**

1. Navigiere zu `https://time.deinedomain.com`
2. Login mit Admin-Zugangsdaten aus dem Installationsbericht:
   - **E-Mail:** Deine E-Mail-Adresse (während Installation festgelegt)
   - **Passwort:** Prüfe die `.env` Datei für `KIMAI_ADMIN_PASSWORD`
3. Vervollständige die Ersteinrichtung:
   - Firmendetails konfigurieren (Einstellungen → System → Einstellungen)
   - Standardwährung und Zeitzone festlegen
   - Kunden erstellen (Kunden → Kunde hinzufügen)
   - Projekte erstellen (Projekte → Projekt hinzufügen)
   - Aktivitäten erstellen (Aktivitäten → Aktivität hinzufügen)
   - Team-Mitglieder hinzufügen (Einstellungen → Benutzer → Benutzer hinzufügen)

**API-Token für n8n generieren:**

1. Klicke auf dein Profil-Symbol (oben rechts)
2. Gehe zu API-Zugriff
3. Klicke auf "Token erstellen"
4. Benenne es "n8n Integration"
5. Wähle alle Berechtigungen
6. Kopiere den Token sofort (wird nur einmal angezeigt!)

### n8n Integration einrichten

**Kimai-Zugangsdaten in n8n erstellen:**

```javascript
// HTTP Request Credentials - Header Auth
Authentication: Header Auth

Main Header:
  Name: X-AUTH-USER
  Wert: admin@example.com (deine Kimai E-Mail)

Additional Header:
  Name: X-AUTH-TOKEN
  Wert: [Dein API-Token von Kimai]
```

**Basis-URL für internen Zugriff:** `http://kimai:8001/api`

### API-Endpunkte-Referenz

**Timesheets:**
- `GET /api/timesheets` - Zeiteinträge auflisten
- `POST /api/timesheets` - Zeiteintrag erstellen
- `PATCH /api/timesheets/{id}` - Zeiteintrag aktualisieren
- `DELETE /api/timesheets/{id}` - Zeiteintrag löschen

**Projekte:**
- `GET /api/projects` - Alle Projekte auflisten
- `POST /api/projects` - Projekt erstellen
- `GET /api/projects/{id}/rates` - Projektstatistiken abrufen

**Kunden:**
- `GET /api/customers` - Kunden auflisten
- `POST /api/customers` - Kunde erstellen

**Aktivitäten:**
- `GET /api/activities` - Aktivitäten auflisten
- `POST /api/activities` - Aktivität erstellen

### Beispiel-Workflows

#### Beispiel 1: Automatische Zeiterfassung aus abgeschlossenen Aufgaben

```javascript
// Zeit automatisch erfassen, wenn Aufgaben als abgeschlossen markiert werden

// 1. Vikunja/Leantime Trigger - Aufgabe als abgeschlossen markiert

// 2. Code Node - Dauer berechnen
const taskStarted = new Date($json.task_created);
const taskCompleted = new Date($json.task_completed);
const durationSeconds = Math.round((taskCompleted - taskStarted) / 1000);

return {
  projectId: $json.project_id,
  activityId: 1, // Standard-Aktivität
  description: $json.task_name,
  begin: taskStarted.toISOString(),
  end: taskCompleted.toISOString()
};

// 3. HTTP Request - Timesheet-Eintrag in Kimai erstellen
Methode: POST
URL: http://kimai:8001/api/timesheets
Header:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
  Content-Type: application/json
Body: {
  "begin": "{{$json.begin}}",
  "end": "{{$json.end}}",
  "project": {{$json.projectId}},
  "activity": {{$json.activityId}},
  "description": "{{$json.description}}"
}

// 4. Notification Node - Zeiterfassung bestätigen
Slack/Email: |
  ⏱️ Zeit automatisch erfasst
  
  Aufgabe: {{$json.description}}
  Dauer: {{Math.round(durationSeconds/3600, 2)}} Stunden
  Projekt: {{$json.projectId}}
```

#### Beispiel 2: Wöchentliche Rechnungsgenerierung aus Kimai

```javascript
// Automatisch Rechnungen aus erfasster Zeit generieren

// 1. Schedule Trigger - Jeden Freitag um 17 Uhr

// 2. HTTP Request - Zeiteinträge der Woche abrufen
Methode: GET
URL: http://kimai:8001/api/timesheets
Header:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
Query Parameter:
  begin: {{$now.startOf('week').toISO()}}
  end: {{$now.endOf('week').toISO()}}

// 3. Code Node - Nach Kunde gruppieren und Summen berechnen
const timesheets = $json;
const byCustomer = {};

timesheets.forEach(ts => {
  const customerName = ts.project.customer.name;
  const customerId = ts.project.customer.id;
  
  if (!byCustomer[customerName]) {
    byCustomer[customerName] = {
      id: customerId,
      name: customerName,
      entries: [],
      totalHours: 0,
      totalBetrag: 0
    };
  }
  
  const hours = ts.duration / 3600; // Sekunden in Stunden umwandeln
  const amount = ts.rate || 0;
  
  byCustomer[customerName].entries.push({
    date: new Date(ts.begin).toLocaleDateString(),
    project: ts.project.name,
    activity: ts.activity.name,
    description: ts.description,
    hours: hours.toFixed(2),
    rate: (amount / hours).toFixed(2),
    amount: amount.toFixed(2)
  });
  
  byCustomer[customerName].totalHours += hours;
  byCustomer[customerName].totalAmount += amount;
});

return Object.values(byCustomer);

// 4. Loop Over Customers

// 5. Generate Invoice PDF (mit Gotenberg)
Methode: POST
URL: http://gotenberg:3000/forms/chromium/convert/html
Body (HTML-Vorlage):
<html>
  <h1>Rechnung für {{$json.name}}</h1>
  <p>Woche: {{$now.startOf('week').toFormat('MMM dd')}} - {{$now.endOf('week').toFormat('MMM dd, yyyy')}}</p>
  
  <table>
    <tr>
      <th>Datum</th>
      <th>Projekt</th>
      <th>Beschreibung</th>
      <th>Stunden</th>
      <th>Stundensatz</th>
      <th>Betrag</th>
    </tr>
    {{#each $json.entries}}
    <tr>
      <td>{{this.date}}</td>
      <td>{{this.project}}</td>
      <td>{{this.description}}</td>
      <td>{{this.hours}}</td>
      <td>€{{this.rate}}/h</td>
      <td>€{{this.amount}}</td>
    </tr>
    {{/each}}
    <tr class="total">
      <td colspan="3"><strong>Gesamt</strong></td>
      <td><strong>{{$json.totalHours.toFixed(2)}}h</strong></td>
      <td></td>
      <td><strong>€{{$json.totalAmount.toFixed(2)}}</strong></td>
    </tr>
  </table>
</html>

// 6. Send Email - Rechnung an Kunde
To: {{$json.name}}@example.com
Subject: Rechnung - Woche {{$now.week()}}
Anhänge: rechnung-{{$json.name}}.pdf
Nachricht: |
  Sehr geehrte/r {{$json.name}},
  
  anbei finden Sie Ihre Rechnung für diese Woche.
  
  Gesamtstunden: {{$json.totalHours.toFixed(2)}}
  Gesamtbetrag: €{{$json.totalAmount.toFixed(2)}}
  
  Mit freundlichen Grüßen
```

#### Beispiel 3: Projektbudget-Überwachung

```javascript
// Warnung, wenn Projekte Budgetgrenzen erreichen

// 1. Schedule Trigger - Täglich um 9 Uhr

// 2. HTTP Request - Alle Projekte abrufen
Methode: GET
URL: http://kimai:8001/api/projects
Header:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}

// 3. Loop Over Projects

// 4. HTTP Request - Projektstatistiken abrufen
Methode: GET
URL: http://kimai:8001/api/projects/{{$json.id}}/rates
Header:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}

// 5. Code Node - Budgetnutzung berechnen
const budget = $json.budget || 0;
const spent = $json.totalRate || 0;
const percentage = budget > 0 ? (spent / budget * 100).toFixed(1) : 0;

return {
  projectName: $json.name,
  budget: budget,
  spent: spent,
  remaining: budget - spent,
  percentage: percentage,
  alertNeeded: percentage >= 80
};

// 6. IF Node - Prüfen ob Warnung nötig
Bedingung: {{$json.alertNeeded}} ist true

// 7. Send Alert - Projektmanager
Kanal: #project-alerts
Nachricht: |
  ⚠️ Budget-Warnung: {{$json.projectName}}
  
  Budget: €{{$json.budget}}
  Verbraucht: €{{$json.spent}} ({{$json.percentage}}%)
  Verbleibend: €{{$json.remaining}}
  
  Handlung erforderlich: Projektumfang überprüfen oder Budgeterhöhung beantragen.
```

#### Beispiel 4: Cal.com Meeting-Zeiterfassung

```javascript
// Automatisch Zeit für abgeschlossene Meetings erfassen

// 1. Cal.com Webhook Trigger - booking.completed

// 2. HTTP Request - Kunde in Kimai finden oder erstellen
Methode: GET
URL: http://kimai:8001/api/customers
Header:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
Abfrage: name={{$json.attendees[0].email.split('@')[1]}}

// 3. IF Node - Kunde existiert nicht
Branch: {{$json.length === 0}}

// 4a. HTTP Request - Neuen Kunden erstellen
Methode: POST
URL: http://kimai:8001/api/customers
Body: {
  "name": "{{$json.attendees[0].email.split('@')[1]}}",
  "contact": "{{$json.attendees[0].name}}",
  "email": "{{$json.attendees[0].email}}"
}

// 5. Merge - Zweige zusammenführen

// 6. HTTP Request - Timesheet für Meeting erstellen
Methode: POST
URL: http://kimai:8001/api/timesheets
Body: {
  "begin": "{{$('Cal.com Trigger').json.startTime}}",
  "end": "{{$('Cal.com Trigger').json.endTime}}",
  "project": 1, // Standard-Meeting-Projekt-ID
  "activity": 2, // Meeting-Aktivitäts-ID
  "description": "Meeting: {{$('Cal.com Trigger').json.title}} mit {{$('Cal.com Trigger').json.attendees[0].name}}",
  "tags": "cal.com,meeting,{{$('Cal.com Trigger').json.eventType.slug}}"
}

// 7. Notification
Nachricht: |
  ✅ Meeting-Zeit erfasst:
  {{$('Cal.com Trigger').json.title}}
  Dauer: {{Math.round(($('Cal.com Trigger').json.endTime - $('Cal.com Trigger').json.startTime) / 3600000, 2)}}h
```

#### Beispiel 5: Tägliche Zeiterfassungs-Erinnerung

```javascript
// Erinnerungen zum Zeiterfassen senden

// 1. Schedule Trigger - Täglich um 17 Uhr

// 2. HTTP Request - Heutige Timesheets pro Benutzer abrufen
Methode: GET
URL: http://kimai:8001/api/timesheets
Abfrage: begin={{$now.startOf('day').toISO()}}

// 3. Code Node - Berechnen wer Erinnerungen braucht
const users = ['benutzer1@example.com', 'benutzer2@example.com'];
const entries = $json;
const tracked = new Set(entries.map(e => e.user.email));

const needsReminder = users.filter(u => !tracked.has(u));

return needsReminder.map(email => ({ email }));

// 4. Loop Over Users

// 5. Send Email - Erinnerung
To: {{$json.email}}
Subject: Vergiss nicht, deine Zeit zu erfassen!
Nachricht: |
  Hallo,
  
  nur eine freundliche Erinnerung, deine Zeit für heute zu erfassen.
  
  👉 https://time.deinedomain.com
  
  Danke!
```

### Mobile Apps-Integration

Kimai hat offizielle Mobile Apps für unterwegs:

**iOS:** [App Store - Kimai Mobile](https://apps.apple.com/app/kimai-mobile/id1463807227)  
**Android:** [Play Store - Kimai Mobile](https://play.google.com/store/apps/details?id=de.cloudrizon.kimai)

**Mobile App konfigurieren:**
1. Server-URL: `https://time.deinedomain.com`
2. API-Token-Authentifizierung verwenden
3. Offline-Zeiterfassung aktivieren
4. Automatisch synchronisieren wenn online

### Erweiterte Funktionen

**Team-Management:**
- Erster Benutzer wird automatisch Super Admin
- Rollen-Hierarchie: Benutzer → Teamleiter → Admin → Super-Admin
- Teams können eingeschränkten Zugriff auf bestimmte Kunden/Projekte haben
- Genehmigungsworkflow für Timesheets (benötigt Plugin)

**Rechnungsvorlagen:**
- Anpassbare Rechnungsvorlagen (Einstellungen → Rechnungsvorlagen)
- Unterstützt mehrere Sprachen
- Firmenlogo und benutzerdefinierte Felder einbinden
- Export zu PDF, Excel, CSV

**Zeit-Rundung:**
- Rundungsregeln konfigurieren (Einstellungen → Timesheet)
- Optionen: 1, 5, 10, 15, 30 Minuten
- Kann aufrunden, abrunden oder auf nächste runden
- Verhindert Zeitdiebstahl und sorgt für genaue Abrechnung

**API-Rate-Limits:**
- Standard: 1000 Anfragen pro Stunde pro Benutzer
- Kann in `local.yaml` Konfiguration angepasst werden
- Nutzung im Kimai Admin-Panel überwachen

### Fehlerbehebung

**API gibt 401 Unauthorized zurück:**

```bash
# 1. API-Token ist aktiv verifizieren
# Login zu Kimai → Profil → API-Zugriff → Token-Status prüfen

# 2. Authentifizierung testen
docker exec n8n curl -H "X-AUTH-USER: admin@example.com" \
  -H "X-AUTH-TOKEN: DEIN_TOKEN" \
  http://kimai:8001/api/version
# Sollte Kimai-Versionsnummer zurückgeben

# 3. Prüfen ob Benutzer existiert
docker exec kimai bin/console kimai:user:list

# 4. Token bei Bedarf neu generieren
# Kimai UI → Profil → API-Zugriff → Neuen Token erstellen
```

**Timesheet-Einträge werden nicht angezeigt:**

```bash
# 1. Kimai-Cache leeren
docker exec kimai bin/console cache:clear --env=prod
docker exec kimai bin/console cache:warmup --env=prod

# 2. Datenbankverbindung prüfen
docker exec kimai_db mysql -u kimai -p${KIMAI_DB_PASSWORD} -e "SELECT COUNT(*) FROM kimai2_timesheet;"

# 3. Projekt/Aktivitäts-IDs verifizieren existieren
docker exec kimai_db mysql -u kimai -p${KIMAI_DB_PASSWORD} kimai \
  -e "SELECT id, name FROM kimai2_projects;"
```

**Datenbankverbindungsprobleme:**

```bash
# 1. MySQL-Container-Status prüfen
docker ps | grep kimai_db
# Sollte zeigen: STATUS = Up

# 2. Datenbankverbindung testen
docker exec kimai_db mysql -u kimai -p${KIMAI_DB_PASSWORD} -e "SHOW DATABASES;"

# 3. Umgebungsvariablen prüfen
docker exec kimai env | grep DATABASE

# 4. Beide Container neu starten
docker compose restart kimai_db kimai
```

**Zeiteinträge haben falsche Zeitzone:**

```bash
# 1. Kimai-Zeitzoneneinstellung prüfen
# Einstellungen → System → Einstellungen → Zeitzone

# 2. Server-Zeitzone prüfen
docker exec kimai date
docker exec kimai cat /etc/timezone

# 3. Korrekte Zeitzone in docker-compose.yml setzen
environment:
  - TZ=Europe/Berlin
```

### Tipps für Kimai + n8n Integration

**Best Practices:**

1. **Interne URLs verwenden:** Immer `http://kimai:8001` von n8n verwenden (schneller, kein SSL-Overhead)
2. **API-Authentifizierung:** Beide Header `X-AUTH-USER` und `X-AUTH-TOKEN` sind erforderlich
3. **Zeitformat:** ISO 8601 Format für alle Datums-/Zeitfelder verwenden
4. **Tarif-Berechnung:** Kimai berechnet Tarife automatisch basierend auf Projekt-/Kundeneinstellungen
5. **Bulk-Operationen:** `/api/timesheets` mit Schleife für mehrere Einträge verwenden
6. **Keine Webhooks:** Kimai hat keine Webhooks - Schedule Triggers für Überwachung nutzen
7. **Export-Formate:** Kimai unterstützt Excel-, CSV-, PDF-Exporte über API

**Zeiterfassungs-Automatisierungs-Ideen:**

- Zeit automatisch erfassen beim Starten/Stoppen von Aufgaben in Projektmanagement-Tools
- Timesheets aus Kalender-Meetings erstellen
- Tägliche/wöchentliche Zeitberichte an Team senden
- Rechnungen automatisch aus erfasster Zeit generieren
- Warnen, wenn Team-Mitglieder vergessen Zeit zu erfassen
- Projektbudgets überwachen und Warnungen senden
- Zeitdaten in Buchhaltungssoftware exportieren

**DSGVO-Konformität:**

- Alle Zeitdaten in EU gespeichert (dein Server)
- Integrierte Datenexport-Funktionalität
- Benutzereinwilligung zur Datenverarbeitung
- Audit-Logs für alle Änderungen
- Recht auf Vergessenwerden-Unterstützung

### Ressourcen

- **Dokumentation:** https://www.kimai.org/documentation/
- **API-Referenz:** https://www.kimai.org/documentation/rest-api.html
- **Plugin-Store:** https://www.kimai.org/store/
- **GitHub:** https://github.com/kimai/kimai
- **Support-Forum:** https://github.com/kimai/kimai/discussions
- **Demo:** https://demo.kimai.org (vor Installation ausprobieren)
