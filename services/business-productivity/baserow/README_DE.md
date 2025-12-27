# 📊 Baserow - Airtable-Alternative

### Was ist Baserow?

Baserow ist eine Open-Source Airtable-Alternative mit Echtzeit-Zusammenarbeit, die perfekt für Datenverwaltungs-Workflows in n8n ist. Mit seiner intuitiven spreadsheet-ähnlichen Oberfläche, REST API und nativer n8n-Integration ist es ideal zum Erstellen von Datenbanken, CRM-Systemen, Projekt-Trackern und mehr.

### Funktionen

- **Echtzeit-Zusammenarbeit:** Mehrere Benutzer können gleichzeitig bearbeiten mit sofortigen Updates
- **Spreadsheet-ähnliche Oberfläche:** Vertraute Grid-Ansicht mit Drag-and-Drop-Funktionalität
- **Mehrere Ansichtstypen:** Grid, Galerie, Formular-Ansichten für verschiedene Datenvisualisierungsbedürfnisse
- **Feldtypen:** Text, Nummer, Datum, Auswahl, Datei, URL, Formel und mehr
- **REST API:** Auto-generierte API für jede Tabelle mit vollständigen CRUD-Operationen
- **Native n8n Node:** Nahtlose Integration mit n8n-Workflows
- **Papierkorb/Rückgängig:** Integrierte Datensicherheit mit Papierkorb und Rückgängig-Funktion

### Erste Einrichtung

**Erster Login bei Baserow:**

1. Navigiere zu `https://baserow.deinedomain.com`
2. Klicke auf "Registrieren" um dein Konto zu erstellen
3. Erster registrierter Benutzer wird automatisch Admin
4. Erstelle deinen ersten Workspace
5. Erstelle deine erste Datenbank und Tabelle
6. Generiere API-Token:
   - Klicke auf dein Profil (oben rechts)
   - Gehe zu Einstellungen → API-Tokens
   - Klicke auf "Neuen Token erstellen"
   - Benenne ihn "n8n Integration"
   - Kopiere den Token für die Verwendung in n8n

### n8n Integration einrichten

**Native Baserow Node in n8n:**

n8n bietet eine native Baserow Node für nahtlose Integration!

**Baserow-Zugangsdaten in n8n erstellen:**

1. In n8n gehe zu Credentials → New → Baserow API
2. Konfiguriere:
   - **Host:** `http://baserow:80` (intern) oder `https://baserow.deinedomain.com` (extern)
   - **Database ID:** Aus Datenbank-URL abrufen (z.B. `/database/123` → ID ist 123)
   - **Token:** Dein generierter Token aus Baserow-Einstellungen

**Interne URL für n8n:** `http://baserow:80`

### Beispiel-Workflows

#### Beispiel 1: Kundendaten-Management-Pipeline

```javascript
// Kundendatenerfassung und -anreicherung automatisieren

// 1. Webhook Trigger - Neue Kundendaten empfangen

// 2. Baserow Node - Neuen Kundeneintrag erstellen
Operation: Create
Database: Customers
Table ID: 1 (aus Tabellen-URL abrufen)
Fields:
  Name: {{$json.name}}
  Email: {{$json.email}}
  Company: {{$json.company}}
  Status: Neuer Lead
  Created: {{$now.toISO()}}

// 3. HTTP Request - Firma recherchieren (optional)
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{$json.company}} Firmeninformationen",
  "focusMode": "webSearch"
}

// 4. Baserow Node - Kunde mit Recherche aktualisieren
Operation: Update
Database: Customers
Row ID: {{$('Create Customer').json.id}}
Fields:
  Company Info: {{$json.research_summary}}
  Industry: {{$json.detected_industry}}
  Status: Recherchiert

// 5. Slack Notification
Kanal: #new-customers
Nachricht: |
  🎉 Neuer Kunde hinzugefügt!
  
  Name: {{$('Create Customer').json.Name}}
  Firma: {{$('Create Customer').json.Company}}
  Status: Recherchiert
```

#### Beispiel 2: Projekt-Task-Management

```javascript
// Projektaufgaben synchronisieren und Erinnerungen senden

// 1. Schedule Trigger - Täglich um 9 Uhr

// 2. Baserow Node - Ausstehende Aufgaben abrufen
Operation: List
Database: Projects
Table ID: 2
Filters:
  Status__equal: Ausstehend
  Due Date__date_before: {{$now.plus(3, 'days').toISODate()}}

// 3. Loop Over Items

// 4. Slack Node - Erinnerung an Zugewiesenen senden
Kanal: {{$json['Assignee Slack ID']}}
Nachricht: |
  ⏰ Aufgabe fällig in 3 Tagen
  
  Aufgabe: {{$json['Task Name']}}
  Projekt: {{$json['Project']}}
  Fällig: {{$json['Due Date']}}

// 5. Baserow Node - Aufgabenstatus aktualisieren
Operation: Update
Row ID: {{$json.id}}
Fields:
  Reminder Sent: true
  Last Notified: {{$now.toISO()}}
```

#### Beispiel 3: Datenanreicherung mit KI

```javascript
// Bestehende Einträge mit KI-generierten Inhalten erweitern

// 1. Baserow Node - Einträge ohne Beschreibungen abrufen
Operation: List
Database: Products
Table ID: 3
Filters:
  Description__empty: true
Limit: 10

// 2. Loop Over Items

// 3. OpenAI Node - Produktbeschreibung generieren
Modell: gpt-4o-mini
System Nachricht: "Du bist ein Produkt-Marketing-Texter."
User Nachricht: |
  Erstelle eine überzeugende Produktbeschreibung für:
  
  Produkt: {{$json['Product Name']}}
  Eigenschaften: {{$json['Features']}}
  Zielgruppe: {{$json['Target Market']}}
  
  Mache sie ansprechend und SEO-freundlich (100-150 Wörter).

// 4. Baserow Node - Mit generiertem Inhalt aktualisieren
Operation: Update
Row ID: {{$json.id}}
Fields:
  Description: {{$('OpenAI').json.choices[0].message.content}}
  SEO Keywords: {{$('OpenAI').json.suggested_keywords}}
  Last Updated: {{$now.toISO()}}
  Updated By: KI-Assistent
```

#### Beispiel 4: Echtzeit-Zusammenarbeits-Trigger

```javascript
// Auf Änderungen in Baserow mit Webhooks reagieren

// 1. Webhook Trigger - Baserow Webhook
// Konfiguriere in Baserow: Tabelleneinstellungen → Webhooks → Webhook hinzufügen
// URL: https://n8n.deinedomain.com/webhook/baserow-changes

// 2. Code Node - Webhook-Daten parsen
const action = $json.action; // created, updated, deleted
const tableName = $json.table.name;
const rowData = $json.items;

return {
  action: action,
  table: tableName,
  data: rowData
};

// 3. Switch Node - Basierend auf Aktionstyp routen

// Branch 1: Zeile erstellt
// 4a. Send Email - Willkommens-E-Mail für neue Kunden
To: {{$json.data.Email}}
Subject: Willkommen bei {{$json.data.Company}}!
Nachricht: Benutzerdefinierte Willkommens-E-Mail...

// 4b. Aufgaben im Projektmanagementsystem erstellen

// Branch 2: Zeile aktualisiert
// 5a. Auf Statusänderungen prüfen
// 5b. Team-Mitglieder über Updates benachrichtigen

// Branch 3: Zeile gelöscht
// 6a. Zugehörige Daten archivieren
// 6b. Benachrichtigung an Admin senden

// 7. Baserow Node - Aktionsverlauf protokollieren
Operation: Create
Database: Activity Log
Fields:
  Action: {{$json.action}}
  Table: {{$json.table}}
  User: {{$json.user_name}}
  Timestamp: {{$now.toISO()}}
```

#### Beispiel 5: Formular-zu-Datenbank-Automatisierung

```javascript
// Öffentliche Formularübermittlungen direkt in Datenbank

// 1. Baserow Form View - Öffentliches Formular erstellen
// In Baserow: Formular-Ansicht erstellen → Öffentlich teilen

// 2. Webhook von Baserow - Bei Formularübermittlung
// Formularübermittlungen lösen Webhook automatisch aus

// 3. Code Node - Daten verarbeiten und validieren
const formData = $json;

// E-Mail validieren
if (!formData.email || !formData.email.includes('@')) {
  throw new Error('Ungültige E-Mail-Adresse');
}

// Daten anreichern
return {
  ...formData,
  source: 'baserow_form',
  validated: true,
  processed_at: new Date().toISOString(),
  ip_address: $json.metadata?.ip_address
};

// 4. IF Node - Prüfen ob Lead qualifiziert
Bedingung: {{$json.score >= 70}}

// 5. Cal.com Node - Demo-Anruf planen (wenn qualifiziert)
Operation: Create Booking
Event Type: Produkt-Demo
// Automatisch basierend auf Verfügbarkeit planen

// 6. Send Email - Bestätigung
To: {{$json.email}}
Subject: Vielen Dank für Ihr Interesse!
Nachricht: |
  Hallo {{$json.name}},
  
  Vielen Dank für die Übermittlung Ihrer Informationen!
  {{#if $json.score >= 70}}
  Wir haben einen Demo-Anruf für Sie geplant.
  {{else}}
  Wir werden Ihre Übermittlung prüfen und uns bald bei Ihnen melden.
  {{/if}}
```

### Erweiterte API-Nutzung

Für Operationen, die nicht in der nativen Node verfügbar sind, HTTP Request verwenden:

```javascript
// Datenbank-Schema-Informationen abrufen
Methode: GET
URL: http://baserow:80/api/database/tables/{{$json.table_id}}/fields/
Header:
  Authorization: Token dein-api-token

// Batch-Operationen
Methode: PATCH
URL: http://baserow:80/api/database/rows/table/{{$json.table_id}}/batch/
Header:
  Authorization: Token dein-api-token
  Content-Type: application/json
Body: {
  "items": [
    {"id": 1, "field_123": "aktualisierter_wert1"},
    {"id": 2, "field_123": "aktualisierter_wert2"}
  ]
}

// Datei-Uploads
Methode: POST
URL: http://baserow:80/api/database/rows/table/{{$json.table_id}}/{{$json.row_id}}/upload-file/{{$json.field_id}}/
Header:
  Authorization: Token dein-api-token
Body: Binäre Dateidaten
```

### Baserow-Funktionen Highlights

**Echtzeit-Zusammenarbeit:**
- Mehrere Benutzer können gleichzeitig bearbeiten
- Änderungen erscheinen sofort für alle Benutzer
- Integrierte Konfliktlösung
- Aktivitäts-Zeitleiste zeigt wer was geändert hat

**Datensicherheit:**
- Rückgängig/Wiederherstellen-Funktionalität für alle Aktionen
- Papierkorb für gelöschte Zeilen (30-Tage-Aufbewahrung)
- Zeilen-Versionsverlauf
- Feld-Level-Berechtigungen (Enterprise)

**Vorlagen und Ansichten:**
- 50+ fertige Vorlagen (CRM, Projektmanager, etc.)
- Mehrere Ansichtstypen: Grid (Spreadsheet), Galerie (Karten), Formular (öffentliche Formulare)
- Benutzerdefinierte Filter und Sortierung pro Ansicht
- Öffentliches Teilen mit Passwortschutz

**Feldtypen:**
- Text (einzeilig, mehrzeilig)
- Nummer (Ganzzahl, Dezimal)
- Datum (Datum, Datum-Zeit)
- Boolean (Checkbox)
- Einfach-/Mehrfachauswahl (Dropdown)
- Datei (Anhänge, Bilder)
- URL, E-Mail, Telefon
- Formel (berechnete Felder)
- Link zu anderem Datensatz (Beziehungen)

### Fehlerbehebung

**Kann keine Verbindung zu Baserow herstellen:**

```bash
# 1. Baserow-Container-Status prüfen
docker ps | grep baserow
# Sollte zeigen: STATUS = Up

# 2. Baserow-Logs prüfen
docker logs baserow --tail 100

# 3. Interne Verbindung von n8n testen
docker exec n8n curl http://baserow:80/api/applications/
# Sollte JSON mit Anwendungen zurückgeben

# 4. API-Token verifizieren
# Bei Bedarf in Baserow neu generieren
```

**API-Authentifizierungsfehler:**

```bash
# 1. Token-Format verifizieren
# Header sollte sein: Authorization: Token DEIN_TOKEN
# NICHT: Bearer DEIN_TOKEN

# 2. Token-Berechtigungen in Baserow prüfen
# Einstellungen → API-Tokens → Prüfen ob Token aktiv ist

# 3. Token testen
curl -H "Authorization: Token DEIN_TOKEN" \
  http://baserow:80/api/applications/

# 4. Token neu generieren wenn abgelaufen
```

**Felder werden nicht aktualisiert:**

```bash
# 1. Feldnamen exakt prüfen (Groß-/Kleinschreibung beachten)
# Feld "Name" ≠ "name"

# 2. Feld-IDs in Tabelle verifizieren
curl -H "Authorization: Token DEIN_TOKEN" \
  http://baserow:80/api/database/tables/TABLE_ID/fields/

# 3. Feldtypen mit Daten abgleichen
# Nummernfeld kann keine Textwerte akzeptieren

# 4. Baserow-Logs auf Fehler prüfen
docker logs baserow | grep ERROR
```

**Webhooks werden nicht ausgelöst:**

```bash
# 1. Webhook ist in Baserow aktiv verifizieren
# Tabelleneinstellungen → Webhooks → Status prüfen

# 2. Prüfen ob Webhook-URL erreichbar ist
# Muss öffentlich erreichbare HTTPS-URL sein

# 3. Webhook manuell testen
# Baserow → Webhooks → Webhook testen

# 4. n8n-Webhook-Logs prüfen
# n8n UI → Executions → Nach Webhook-Triggern suchen
```

### Tipps für Baserow + n8n Integration

**Best Practices:**

1. **Interne URLs verwenden:** Immer `http://baserow:80` von n8n verwenden (schneller, kein SSL-Overhead)
2. **Token-Authentifizierung:** API-Tokens statt Benutzername/Passwort verwenden
3. **Feld-Benennung:** Exakte Feldnamen verwenden (Groß-/Kleinschreibung beachten), Sonderzeichen vermeiden
4. **Batch-Operationen:** HTTP Request Node für Bulk-Updates verwenden um Rate-Limits zu vermeiden
5. **Webhooks:** Baserow-Webhooks für Echtzeit-Trigger einrichten
6. **Fehlerbehandlung:** Try/Catch-Nodes für robuste Workflows hinzufügen
7. **Feldtypen:** Baserow-Feldtypen beim Erstellen/Aktualisieren von Datensätzen beachten
8. **Datenbankstruktur:** Mehrere Tabellen mit Beziehungen für komplexe Daten verwenden

**Häufige Automatisierungsmuster:**

- Formularübermittlungen → Datenbank + E-Mail-Benachrichtigung
- Datenbankänderungen → Mit externem CRM synchronisieren
- Geplante Aufgaben → Datenbereinigung/-anreicherung
- API-Daten → In Baserow-Tabellen importieren
- Baserow → Berichte/Rechnungen generieren
- Kundendaten → Automatisierte Onboarding-Workflows

**Datenorganisation:**

- Workspaces verwenden um Projekte/Kunden zu trennen
- Vorlagen für wiederkehrende Datenbankstrukturen erstellen
- Ansichten verwenden um Daten zu filtern und zu organisieren
- Konsistente Benennungskonventionen anwenden
- Feldzwecke in Beschreibungen dokumentieren

### Baserow vs NocoDB Vergleich

| Funktion | Baserow | NocoDB |
|---------|---------|--------|
| **API** | Nur REST | REST + GraphQL |
| **Webhooks** | Über n8n | Integriert |
| **Feldtypen** | 15+ Typen | 25+ Typen |
| **Formel-Unterstützung** | Basis | Erweitert |
| **Ansichten** | 3 Typen (Grid, Galerie, Formular) | 7 Typen (inkl. Kalender, Kanban, Gantt) |
| **Beziehungen** | Eins-zu-Viele | Viele-zu-Viele |
| **Performance** | Hervorragend | Hervorragend |
| **Ressourcenverbrauch** | Moderat | Leichtgewichtig |
| **Native n8n Node** | ✅ Ja | ❌ Nein (nur HTTP Request) |
| **Papierkorb/Wiederherstellen** | ✅ Ja | ❌ Nein |

**Wähle Baserow wenn du brauchst:**
- Native n8n Node für einfachere Workflows
- Einfachere, intuitivere Oberfläche
- Fokus auf Echtzeit-Zusammenarbeit
- Papierkorb/Wiederherstellen-Funktionalität
- Formular-Ansichten für öffentliche Datenerfassung

**Wähle NocoDB wenn du brauchst:**
- GraphQL API-Unterstützung
- Erweiterte Formelfelder
- Mehr Ansichtstypen (Kalender, Gantt, Kanban)
- Viele-zu-Viele-Beziehungen
- Geringeren Ressourcenverbrauch

### Ressourcen

- **Dokumentation:** https://baserow.io/docs
- **API-Referenz:** https://baserow.io/docs/apis/rest-api
- **GitHub:** https://github.com/bram2w/baserow
- **Forum:** https://community.baserow.io/
- **Vorlagen:** https://baserow.io/templates
- **n8n Node-Docs:** Suche "Baserow" in n8n Node-Bibliothek
