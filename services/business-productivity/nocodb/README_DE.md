# 📋 NocoDB - Airtable-Alternative

### Was ist NocoDB?

NocoDB verwandelt jede relationale Datenbank in eine intelligente Spreadsheet-Oberfläche und bietet eine Open-Source-Alternative zu Airtable. Im Gegensatz zu Baserow bietet NocoDB sowohl REST- als auch GraphQL-APIs, mehr Feldtypen (25+), erweiterte Formeln und 7 verschiedene Ansichtstypen einschließlich Kalender, Kanban und Gantt-Diagramme. Es ist leichtgewichtig, hochperformant und perfekt für komplexe Datenbeziehungen mit Viele-zu-Viele-Unterstützung.

### Funktionen

- **25+ Feldtypen:** Text, Nummer, Datum, Formel, Rollup, Lookup, Barcode/QR, Anhänge, Bewertung und mehr
- **Mehrere Ansichten:** Grid, Galerie, Kanban, Kalender, Formular, Gantt und mehr
- **Duale APIs:** Sowohl REST als auch GraphQL für maximale Flexibilität
- **Integrierte Webhooks:** Echtzeit-Trigger für n8n-Workflows
- **Erweiterte Formeln:** Excel-ähnliche Formeln mit 50+ Funktionen
- **Viele-zu-Viele-Beziehungen:** Unterstützung für komplexe Datenmodelle
- **Leichtgewichtig:** Nutzt minimale Ressourcen im Vergleich zu Alternativen
- **Datenbank-agnostisch:** Funktioniert mit MySQL, PostgreSQL, SQL Server, SQLite

### Erste Einrichtung

**Erster Login bei NocoDB:**

1. Navigiere zu `https://nocodb.deinedomain.com`
2. Login mit Admin-Zugangsdaten aus dem Installationsbericht:
   - E-Mail: Deine E-Mail-Adresse (während Installation festgelegt)
   - Passwort: Prüfe die `.env` Datei für `NOCODB_ADMIN_PASSWORD`
3. Erstelle deine erste Base (Datenbank)
4. Generiere API-Token:
   - Klicke auf dein Profil (oben rechts)
   - Gehe zu "Kontoeinstellungen"
   - Navigiere zu "API-Tokens"
   - Klicke auf "Neuen Token erstellen"
   - Benenne ihn "n8n Integration"
   - Kopiere den Token für die Verwendung in n8n

### n8n Integration einrichten

**Hinweis:** NocoDB hat keine native n8n Node. Verwende stattdessen HTTP Request Nodes.

**NocoDB-Zugangsdaten in n8n erstellen:**

1. In n8n, erstelle Zugangsdaten:
   - Typ: Header Auth
   - Name: NocoDB API Token
   - Header Name: `xc-token`
   - Header Wert: Dein generierter Token von NocoDB

**Interne URL für n8n:** `http://nocodb:8080`

### Beispiel-Workflows

#### Beispiel 1: Kundendaten-Pipeline

```javascript
// Kunden-Onboarding mit intelligentem Datenmanagement automatisieren

// 1. Webhook Trigger - Neue Kundenanmeldung empfangen

// 2. HTTP Request Node - Kunde in NocoDB erstellen
Methode: POST
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Authentication: NocoDB-Zugangsdaten verwenden
Header:
  Content-Type: application/json
Body (JSON):
{
  "Name": "{{$json.name}}",
  "Email": "{{$json.email}}",
  "Company": "{{$json.company}}",
  "Status": "Neu",
  "Created": "{{$now.toISO()}}"
}

// 3. HTTP Request Node - Verknüpften Projekt-Datensatz erstellen
Methode: POST
URL: http://nocodb:8080/api/v2/tables/{PROJECTS_TABLE_ID}/records
Body (JSON):
{
  "Customer": "{{$('Create Customer').json.Id}}",
  "ProjectName": "Onboarding - {{$json.company}}",
  "Status": "Aktiv",
  "StartDate": "{{$now.toISODate()}}"
}

// 4. Slack Notification
Kanal: #new-customers
Nachricht: |
  🎉 Neuer Kunde erfolgreich angelegt!
  
  Name: {{$('Create Customer').json.Name}}
  Firma: {{$('Create Customer').json.Company}}
  Projekt: Onboarding - {{$json.company}}
```

#### Beispiel 2: Formular zu Datenbank-Automatisierung

```javascript
// Öffentliche Formulare erstellen, die direkt in deine Datenbank einspeisen

// 1. NocoDB Form View
// Erstelle eine Formularansicht in der NocoDB UI für öffentliche Datenerfassung

// 2. NocoDB Webhook - In Tabelleneinstellungen konfiguriert
// Löst diesen n8n-Workflow bei Formularübermittlung aus

// 3. Code Node - Daten verarbeiten und validieren
const formData = $input.first().json;

// E-Mail validieren
if (!formData.email || !formData.email.includes('@')) {
  throw new Error('Ungültige E-Mail-Adresse');
}

// Telefonnummer validieren (grundlegende Prüfung)
if (formData.phone && !/^\+?[\d\s-()]+$/.test(formData.phone)) {
  throw new Error('Ungültiges Telefonnummernformat');
}

// Daten anreichern
return {
  json: {
    ...formData,
    source: 'nocodb_form',
    processed: true,
    timestamp: new Date().toISOString(),
    validation_passed: true
  }
};

// 4. HTTP Request Node - Datensatz mit Anreicherung aktualisieren
Methode: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body (JSON):
{
  "Id": "{{$json.Id}}",
  "ProcessedData": "{{JSON.stringify($json)}}",
  "Status": "Verarbeitet",
  "ValidationPassed": true
}

// 5. Send Email Node - Bestätigung an Benutzer
To: {{$json.email}}
Subject: "Vielen Dank für Ihre Übermittlung!"
Body: |
  Hallo {{$json.name}},
  
  Ihre Formularübermittlung wurde erfolgreich empfangen und verarbeitet.
  
  Referenz-ID: {{$json.Id}}
  Übermittlungsdatum: {{$json.timestamp}}
```

#### Beispiel 3: Mit externen Diensten synchronisieren

```javascript
// NocoDB mit anderen Systemen synchronisiert halten

// 1. Schedule Trigger - Jede Stunde

// 2. HTTP Request Node - Kürzlich geänderte NocoDB-Datensätze abrufen
Methode: GET
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Authentication: NocoDB-Zugangsdaten verwenden
Query Parameter:
  where: (UpdatedAt,gt,{{$now.minus({hours: 1}).toISO()}})
  limit: 100

// 3. Loop Over Records

// 4. Switch Node - Basierend auf Status synchronisieren

// Branch 1 - Neue Datensätze
// HTTP Request - In externem CRM erstellen
Methode: POST
URL: https://external-crm.com/api/customers
Body: {
  "name": "{{$json.Name}}",
  "email": "{{$json.Email}}",
  "company": "{{$json.Company}}",
  "source": "nocodb"
}

// HTTP Request - NocoDB mit externer ID aktualisieren
Methode: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body: {
  "Id": "{{$json.Id}}",
  "ExternalCRMId": "{{$('External CRM').json.id}}",
  "LastSynced": "{{$now.toISO()}}"
}

// Branch 2 - Aktualisierte Datensätze
// HTTP Request - Externes System aktualisieren
Methode: PUT
URL: https://external-crm.com/api/customers/{{$json.ExternalCRMId}}
Body: {
  "name": "{{$json.Name}}",
  "email": "{{$json.Email}}",
  "company": "{{$json.Company}}"
}

// HTTP Request - Sync-Zeitstempel protokollieren
Methode: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body: {
  "Id": "{{$json.Id}}",
  "LastSynced": "{{$now.toISO()}}",
  "SyncStatus": "Erfolg"
}

// Branch 3 - Gelöschte Datensätze (mit DeletedAt markiert)
// HTTP Request - Im externen System archivieren
Methode: DELETE
URL: https://external-crm.com/api/customers/{{$json.ExternalCRMId}}

// HTTP Request - Als synchronisiert markieren
Methode: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body: {
  "Id": "{{$json.Id}}",
  "SyncStatus": "Archiviert",
  "LastSynced": "{{$now.toISO()}}"
}
```

### NocoDB-Funktionen für Automatisierung

**Mehrere Ansichten (7 Typen):**
- **Grid-Ansicht:** Spreadsheet-ähnliche Oberfläche
- **Galerie-Ansicht:** Kartenbasierte Visualisierung
- **Kanban-Ansicht:** Drag-and-Drop Task-Management
- **Kalender-Ansicht:** Zeitbasierte Datenvisualisierung
- **Formular-Ansicht:** Öffentliche Datenerfassung
- **Gantt-Ansicht:** Projekt-Timeline-Visualisierung
- **Karten-Ansicht:** Geografische Datenvisualisierung

**Feldtypen (25+):**
- **LinkToAnotherRecord:** Viele-zu-Viele-Beziehungen
- **Lookup:** Daten aus verknüpften Tabellen abrufen
- **Rollup:** Aggregat-Berechnungen (Summe, Durchschnitt, Anzahl)
- **Formula:** Excel-ähnliche Formeln mit 50+ Funktionen
- **Barcode/QR Code:** Scannbare Codes generieren
- **Attachment:** Datei-Uploads mit Vorschau
- **Rating:** Sternebewertungen für Feedback
- **Duration:** Zeiterfassung
- **Currency:** Mehrwährungs-Unterstützung
- **Percent:** Fortschritts-Tracking
- **Geometry:** Geografische Koordinaten
- Und 14 weitere Typen...

**API-Funktionen:**
- **REST API:** Auto-generiert, vollständig dokumentiert
- **GraphQL API:** Query-Flexibilität, verschachtelte Beziehungen
- **Webhooks:** Echtzeit-Trigger bei CRUD-Operationen
- **Bulk-Operationen:** Batch-Erstellen/Aktualisieren/Löschen
- **Filterung:** Komplexe Abfragen mit Operatoren
- **Sortierung:** Mehrspalten-Sortierung
- **Paginierung:** Effiziente Handhabung großer Datensätze
- **Authentifizierung:** API-Tokens mit granularen Berechtigungen

### NocoDB API-Beispiele

#### Tabellendatensätze mit Filtern abrufen

```javascript
// HTTP Request Node
Methode: GET
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Query Parameter:
  where: (Status,eq,Aktiv)~and(CreatedAt,gt,2025-01-01)
  sort: -CreatedAt
  limit: 50
  offset: 0
```

#### Datensatz mit verknüpften Daten erstellen

```javascript
// HTTP Request Node
Methode: POST
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body (JSON):
{
  "CustomerName": "Max Mustermann",
  "Email": "max@beispiel.de",
  "Projects": ["rec123", "rec456"],  // Link zu bestehenden Projekt-Datensätzen
  "Status": "Aktiv"
}
```

#### Bulk-Update von Datensätzen

```javascript
// HTTP Request Node
Methode: PATCH
URL: http://nocodb:8080/api/v2/tables/{TABLE_ID}/records
Body (JSON):
[
  {
    "Id": "rec001",
    "Status": "Abgeschlossen"
  },
  {
    "Id": "rec002",
    "Status": "Abgeschlossen"
  }
]
```

#### Webhooks in NocoDB verwenden

Webhooks in NocoDB UI konfigurieren (Tabelleneinstellungen → Webhooks):

```javascript
// NocoDB Webhook-Konfiguration:
Trigger: After Insert, After Update, After Delete
URL: https://n8n.deinedomain.com/webhook/nocodb-changes
Methode: POST
Header:
  x-webhook-secret: dein-geheimer-schlüssel

// n8n Webhook Trigger empfängt:
{
  "type": "after.insert",
  "data": {
    "table_name": "customers",
    "record": {
      "Id": "rec123",
      "Name": "Max Mustermann",
      "Email": "max@beispiel.de"
    }
  }
}
```

### Tipps für NocoDB + n8n Integration

1. **Interne URLs verwenden:** Nutze immer `http://nocodb:8080` von n8n (schneller, kein SSL-Overhead)
2. **API-Token-Sicherheit:** Speichere Tokens in n8n-Zugangsdaten, niemals im Code
3. **Webhook-Konfiguration:** Richte Webhooks in den Tabelleneinstellungen für Echtzeit-Trigger ein
4. **Bulk-Operationen:** Nutze Bulk-Endpunkte für bessere Performance bei großen Datensätzen
5. **Feldverweise:** Verwende Feldnamen genau so, wie sie in NocoDB erscheinen
6. **Beziehungen:** Nutze LinkToAnotherRecord für komplexe Datenmodelle (Viele-zu-Viele-Unterstützung!)
7. **Ansichten-API:** Verschiedene Ansichten können unterschiedliche API-Endpunkte haben
8. **Formelfelder:** Verwende diese für berechnete Werte, die sich automatisch aktualisieren
9. **GraphQL-Vorteil:** Nutze GraphQL für verschachtelte Datenabfragen (effizienter als mehrere REST-Aufrufe)
10. **Lookup & Rollup:** Diese Felder ziehen automatisch Daten aus verknüpften Tabellen

### NocoDB vs Baserow Vergleich

| Funktion | NocoDB | Baserow |
|---------|--------|---------|
| **API** | REST + GraphQL | Nur REST |
| **Webhooks** | Integriert | Via n8n |
| **Feldtypen** | 25+ Typen | 15+ Typen |
| **Formel-Unterstützung** | Erweitert (50+ Funktionen) | Grundlegend |
| **Ansichten** | 7 Typen (Grid, Galerie, Kanban, Kalender, Formular, Gantt, Karte) | 3 Typen (Grid, Galerie, Formular) |
| **Beziehungen** | Viele-zu-Viele | Eins-zu-Viele |
| **Performance** | Ausgezeichnet | Ausgezeichnet |
| **Ressourcenverbrauch** | Leichtgewichtig | Moderat |
| **Native n8n Node** | ❌ Nein (nur HTTP Request) | ✅ Ja |
| **Papierkorb/Wiederherstellen** | ❌ Nein | ✅ Ja |
| **Datenbank-Unterstützung** | MySQL, PostgreSQL, SQL Server, SQLite | Nur PostgreSQL |
| **Self-Hosting** | Sehr einfach | Sehr einfach |
| **Lernkurve** | Moderat | Einfach |

**Wähle NocoDB wenn du brauchst:**
- GraphQL-API-Unterstützung für effiziente verschachtelte Abfragen
- Erweiterte Formelfelder mit 50+ Funktionen
- Mehr Ansichtstypen (Kalender, Gantt, Kanban, Karte)
- Viele-zu-Viele-Beziehungen für komplexe Datenmodelle
- Geringeren Ressourcenverbrauch
- Unterstützung für mehrere Datenbank-Typen
- Erweiterte Datenmodellierungs-Funktionen

**Wähle Baserow wenn du brauchst:**
- Native n8n-Node für einfachere Workflows (keine HTTP-Request-Konfiguration)
- Einfachere, intuitivere Benutzeroberfläche
- Fokus auf Echtzeit-Zusammenarbeit
- Papierkorb/Wiederherstellungs-Funktionalität
- Schnellere Lernkurve für nicht-technische Benutzer
- Integrierte Benutzerverwaltung

### Fehlerbehebung

#### Connection Refused Error

```bash
# NocoDB-Verfügbarkeit testen
docker exec -it n8n curl http://nocodb:8080/api/v2/meta/tables

# NocoDB-Logs prüfen
docker logs nocodb --tail 100

# NocoDB neu starten
docker compose restart nocodb
```

#### API Token Invalid

```bash
# Token in .env überprüfen
grep NOCODB_API_TOKEN .env

# Token in NocoDB UI neu generieren:
# Profil → Kontoeinstellungen → API-Tokens → Neuen Token erstellen

# n8n-Zugangsdaten mit neuem Token aktualisieren
```

#### Webhook Not Triggering

```bash
# Webhook-Konfiguration in NocoDB UI überprüfen
# Tabelleneinstellungen → Webhooks → URL und Trigger überprüfen

# Webhook manuell testen
curl -X POST https://n8n.deinedomain.com/webhook/nocodb-test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# n8n Webhook-Logs prüfen
docker logs n8n --tail 100 | grep webhook
```

#### Slow Query Performance

```bash
# Indizes zu häufig abgefragten Feldern in NocoDB UI hinzufügen
# Tabelleneinstellungen → Felder → Feld auswählen → Index aktivieren

# Paginierung für große Datensätze verwenden
# Query-Parameter: limit=100&offset=0

# NocoDB-Performance überwachen
docker stats nocodb
```

#### Import/Export Issues

```bash
# Base als CSV/JSON exportieren
# NocoDB UI → Base → Export

# Via API importieren
curl -X POST http://nocodb:8080/api/v2/tables/{TABLE_ID}/records \
  -H "xc-token: DEIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @import.json

# Import-Logs prüfen
docker logs nocodb --tail 50
```

### Ressourcen

- **Dokumentation:** https://docs.nocodb.com
- **API-Referenz:** https://docs.nocodb.com/developer-resources/rest-apis
- **GraphQL API:** https://docs.nocodb.com/developer-resources/graphql-apis
- **GitHub:** https://github.com/nocodb/nocodb
- **Forum:** https://community.nocodb.com
- **Examples:** https://github.com/nocodb/nocodb/tree/develop/packages/nocodb/tests

### Best Practices

**Data Modeling:**
- Use LinkToAnotherRecord for relationships
- Leverage Lookup fields to display related data
- Use Rollup for aggregations (sum, avg, count)
- Formula fields for calculated values
- Keep table names descriptive and consistent

**API Usage:**
- Use GraphQL for nested data (more efficient)
- Implement pagination for large datasets
- Cache frequently accessed data
- Use bulk operations for batch updates
- Handle rate limits gracefully

**Automation:**
- Set up webhooks for real-time updates
- Use n8n for complex workflows
- Implement error handling and retries
- Log all automation activities
- Test webhooks thoroughly before production

**Sicherheit:**
- Rotate API tokens regularly
- Use different tokens for different integrations
- Set up proper table permissions
- Enable 2FA for admin accounts
- Review audit logs regularly

**Performance:**
- Index frequently queried fields
- Limit number of fields per table (<50 recommended)
- Use views to organize data
- Paginate large result sets
- Monitor resource usage
