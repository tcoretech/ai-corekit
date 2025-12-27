# 💰 Invoice Ninja - Rechnungsplattform

### Was ist Invoice Ninja?

Invoice Ninja ist eine professionelle Rechnungs- und Zahlungsplattform, die über 40 Zahlungsgateways, Mehrwährungs-Abrechnung und ein Kundenportal unterstützt. Sie ist perfekt für Freelancer, Agenturen und kleine Unternehmen, die umfassende Abrechnungsautomatisierung mit DSGVO-Konformität benötigen.

### Funktionen

- **40+ Zahlungsgateways:** Stripe, PayPal, Braintree, Square, Authorize.net und viele mehr
- **Mehrwährungs-Unterstützung:** Rechnungen an Kunden in jeder Währung mit automatischer Umrechnung
- **Wiederkehrende Abrechnung:** Automatisierte Abonnement- und Retainer-Rechnungsstellung
- **Kundenportal:** Self-Service-Portal für Kunden zum Anzeigen/Bezahlen von Rechnungen
- **Ausgaben-Tracking:** Ausgaben in abrechenbare Rechnungen umwandeln
- **Native n8n Node:** Nahtlose Integration mit n8n-Workflows

### Erste Einrichtung

**Erster Login bei Invoice Ninja:**

1. Navigiere zu `https://invoices.deinedomain.com`
2. Login mit Admin-Zugangsdaten aus dem Installationsbericht:
   - **E-Mail:** Deine E-Mail-Adresse (während Installation festgelegt)
   - **Passwort:** Prüfe die `.env` Datei für `INVOICENINJA_ADMIN_PASSWORD`
3. Vervollständige die Ersteinrichtung:
   - Firmendetails und Logo (Einstellungen → Firmendetails)
   - Steuersätze und Rechnungsanpassung (Einstellungen → Steuereinstellungen)
   - Zahlungsgateway-Konfiguration (Einstellungen → Zahlungseinstellungen)
   - E-Mail-Vorlagen (Einstellungen → E-Mail-Einstellungen)
   - Rechnungsnummernformat (Einstellungen → Rechnungseinstellungen)

**⚠️ WICHTIG - APP_KEY:**

- Invoice Ninja benötigt einen Laravel APP_KEY für Verschlüsselung
- Dieser wird automatisch während der Installation generiert
- Falls fehlend, manuell generieren:
  ```bash
  docker run --rm invoiceninja/invoiceninja:5 php artisan key:generate --show
  # Komplette Ausgabe (inklusive "base64:") zur .env als INVOICENINJA_APP_KEY hinzufügen
  ```

**Sicherheit nach dem Setup:**

Nach dem ersten Login diese aus `.env` entfernen für Sicherheit:
- `IN_USER_EMAIL` Umgebungsvariable
- `IN_PASSWORD` Umgebungsvariable

Diese werden nur für die initiale Kontoerstellung benötigt.

### n8n Integration einrichten

Invoice Ninja hat **native n8n Node-Unterstützung** für nahtlose Integration!

**Invoice Ninja-Zugangsdaten in n8n erstellen:**

1. In n8n gehe zu Credentials → New → Invoice Ninja API
2. Konfiguriere:
   - **URL:** `http://invoiceninja:8000` (intern) oder `https://invoices.deinedomain.com` (extern)
   - **API-Token:** Generiere in Invoice Ninja (Einstellungen → Kontoverwaltung → API-Tokens)
   - **Secret** (optional): Für Webhook-Validierung

**API-Token in Invoice Ninja generieren:**

1. Login zu Invoice Ninja
2. Einstellungen → Kontoverwaltung → API-Tokens
3. Klicke auf "Neuer Token"
4. Name: "n8n Integration"
5. Wähle Berechtigungen (normalerweise "Alle")
6. Kopiere Token sofort (wird nur einmal angezeigt!)

**Interne URL für n8n:** `http://invoiceninja:8000`

### Beispiel-Workflows

#### Beispiel 1: Automatische Rechnungsgenerierung aus Kimai

```javascript
// Rechnungen automatisch aus erfasster Zeit erstellen

// 1. Schedule Trigger - Wöchentlich Freitags um 17 Uhr

// 2. HTTP Request - Zeiteinträge der Woche von Kimai abrufen
Methode: GET
URL: http://kimai:8001/api/timesheets
Header:
  X-AUTH-USER: admin@example.com
  X-AUTH-TOKEN: {{$credentials.kimaiToken}}
Query Parameter:
  begin: {{$now.startOf('week').toISO()}}
  end: {{$now.endOf('week').toISO()}}

// 3. Code Node - Nach Kunde gruppieren und Positionen formatieren
const entries = $json;
const byCustomer = {};

entries.forEach(entry => {
  const customerId = entry.project.customer.id;
  const customerName = entry.project.customer.name;
  
  if (!byCustomer[customerId]) {
    byCustomer[customerId] = {
      client_id: customerId,
      client_name: customerName,
      items: [],
      total: 0
    };
  }
  
  const hours = entry.duration / 3600; // Sekunden in Stunden umwandeln
  const rate = entry.hourlyRate || 0;
  const amount = hours * rate;
  
  byCustomer[customerId].items.push({
    product_key: entry.project.name,
    notes: entry.description,
    quantity: hours.toFixed(2),
    cost: rate,
    tax_name1: "MwSt",
    tax_rate1: 19 // Für deine Region anpassen
  });
  
  byCustomer[customerId].total += amount;
});

return Object.values(byCustomer);

// 4. Loop Over Customers

// 5. Invoice Ninja Node - Rechnung erstellen
Operation: Create
Resource: Invoice
Fields:
  client_id: {{$json.client_id}}
  line_items: {{$json.items}}
  due_date: {{$now.plus(30, 'days').toISO()}}
  public_notes: "Rechnung für Woche {{$now.week()}}"

// 6. Invoice Ninja Node - Rechnung senden
Operation: Send
Resource: Invoice
Invoice ID: {{$('Create Invoice').json.id}}

// 7. Slack-Benachrichtigung
Kanal: #invoicing
Nachricht: |
  📄 Rechnung erstellt und versendet
  
  Kunde: {{$json.client_name}}
  Betrag: €{{$json.total.toFixed(2)}}
  Rechnung: {{$('Create Invoice').json.number}}
```

#### Beispiel 2: Zahlungserinnerungs-Automatisierung

```javascript
// Automatische Erinnerungen für überfällige Rechnungen senden

// 1. Schedule Trigger - Täglich um 9 Uhr

// 2. Invoice Ninja Node - Überfällige Rechnungen abrufen
Operation: Get All
Resource: Invoice
Filters:
  status_id: 2 // Gesendet
  is_deleted: false

// 3. Code Node - Überfällige mit Saldo filtern
const invoices = $json;
const today = new Date();

const overdue = invoices.filter(inv => {
  const dueDate = new Date(inv.due_date);
  const balance = parseFloat(inv.balance);
  return dueDate < today && balance > 0;
});

return overdue.map(inv => ({
  ...inv,
  days_overdue: Math.floor((today - new Date(inv.due_date)) / (1000 * 60 * 60 * 24))
}));

// 4. Loop Over Invoices

// 5. IF Node - Überfällige Tage prüfen
Bedingung: {{$json.days_overdue >= 7}}

// 6. Invoice Ninja Node - Erinnerung senden
Operation: Send
Resource: Invoice
Invoice ID: {{$json.id}}
Template: reminder1 // oder reminder2, reminder3 je nach Tagen

// 7. Slack-Benachrichtigung
Kanal: #collections
Nachricht: |
  ⚠️ Erinnerung gesendet
  
  Rechnung: {{$json.number}}
  Kunde: {{$json.client.name}}
  Betrag: €{{$json.balance}}
  Tage überfällig: {{$json.days_overdue}}
```

#### Beispiel 3: Stripe-Zahlungs-Webhook-Verarbeitung

```javascript
// Erfolgreiche Zahlungen automatisch verarbeiten

// 1. Webhook Trigger - Stripe payment.succeeded

// 2. Code Node - Rechnungs-ID extrahieren
const invoiceId = $json.body.metadata.invoice_id;
const amount = $json.body.amount / 100; // Von Cents umrechnen
const stripeId = $json.body.id;

return {
  invoiceId: invoiceId,
  amount: amount,
  transactionReference: stripeId
};

// 3. Invoice Ninja Node - Rechnung abrufen
Operation: Get
Resource: Invoice
Invoice ID: {{$json.invoiceId}}

// 4. Invoice Ninja Node - Zahlung erstellen
Operation: Create
Resource: Payment
Fields:
  invoice_id: {{$json.invoiceId}}
  amount: {{$('Extract').json.amount}}
  payment_date: {{$now.toISO()}}
  transaction_reference: {{$('Extract').json.transactionReference}}
  type_id: 1 // Kreditkarte

// 5. Send Email - Zahlungsbestätigung
To: {{$('Get Invoice').json.client.email}}
Subject: Zahlung erhalten - Rechnung {{$('Get Invoice').json.number}}
Nachricht: |
  Sehr geehrte/r {{$('Get Invoice').json.client.name}},
  
  wir haben Ihre Zahlung von €{{$('Extract').json.amount}} erhalten.
  
  Rechnung: {{$('Get Invoice').json.number}}
  Transaktion: {{$('Extract').json.transactionReference}}
  
  Vielen Dank für Ihr Geschäft!

// 6. Slack Notification
Kanal: #payments
Nachricht: |
  💰 Zahlung erhalten!
  
  Kunde: {{$('Get Invoice').json.client.name}}
  Betrag: €{{$('Extract').json.amount}}
  Rechnung: {{$('Get Invoice').json.number}}
```

#### Beispiel 4: Ausgaben in Rechnungen umwandeln

```javascript
// Genehmigte Ausgaben in Kundenrechnungen umwandeln

// 1. Invoice Ninja Webhook Trigger - expense.approved
// Oder Schedule Trigger um nach neuen genehmigten Ausgaben zu suchen

// 2. Invoice Ninja Node - Ausgabe abrufen
Operation: Get
Resource: Expense
Expense ID: {{$json.id}}

// 3. Invoice Ninja Node - Kunde abrufen
Operation: Get
Resource: Client
Client ID: {{$json.client_id}}

// 4. Invoice Ninja Node - Rechnung aus Ausgabe erstellen
Operation: Create
Resource: Invoice
Fields:
  client_id: {{$json.client_id}}
  line_items: [{
    product_key: "AUSGABE",
    notes: "{{$('Get Expense').json.public_notes}}",
    quantity: 1,
    cost: {{$('Get Expense').json.amount}},
    tax_name1: "MwSt",
    tax_rate1: 19
  }]
  public_notes: "Erstattungsfähige Ausgabe vom {{$('Get Expense').json.date}}"

// 5. Invoice Ninja Node - Ausgabe als abgerechnet markieren
Operation: Update
Resource: Expense
Expense ID: {{$('Get Expense').json.id}}
Fields:
  invoice_id: {{$('Create Invoice').json.id}}
  should_be_invoiced: false

// 6. Invoice Ninja Node - Rechnung senden
Operation: Send
Resource: Invoice
Invoice ID: {{$('Create Invoice').json.id}}
```

#### Beispiel 5: Wiederkehrende Rechnungsüberwachung

```javascript
// Wiederkehrende Rechnungsprobleme überwachen und melden

// 1. Schedule Trigger - Täglich um 8 Uhr

// 2. Invoice Ninja Node - Wiederkehrende Rechnungen abrufen
Operation: Get All
Resource: Recurring Invoice
Filters:
  status_id: 2 // Aktiv

// 3. Code Node - Nach Problemen suchen
const recurring = $json;
const issues = [];

recurring.forEach(inv => {
  // Prüfen ob nächstes Sendedatum in der Vergangenheit liegt (Sendefehler)
  const nextSend = new Date(inv.next_send_date);
  const today = new Date();
  
  if (nextSend < today && inv.auto_bill === 'always') {
    issues.push({
      client: inv.client.name,
      invoice: inv.number,
      issue: 'Auto-Abrechnung fehlgeschlagen',
      nextSend: inv.next_send_date
    });
  }
  
  // Prüfen ob Zahlungsmethode abgelaufen
  if (inv.client.gateway_tokens?.length === 0) {
    issues.push({
      client: inv.client.name,
      invoice: inv.number,
      issue: 'Keine Zahlungsmethode hinterlegt'
    });
  }
});

return issues;

// 4. IF Node - Prüfen ob Probleme existieren
Bedingung: {{$json.length > 0}}

// 5. Slack Alert
Kanal: #billing-issues
Nachricht: |
  ⚠️ Wiederkehrende Rechnungsprobleme erkannt
  
  {{#each $json}}
  - {{this.client}}: {{this.issue}} (Rechnung: {{this.invoice}})
  {{/each}}
```

### Zahlungsgateway-Konfiguration

Invoice Ninja unterstützt über 40 Zahlungsgateways. Die beliebtesten:

**Stripe-Setup:**

1. Einstellungen → Zahlungseinstellungen → Gateways konfigurieren
2. Stripe auswählen → Konfigurieren
3. API-Schlüssel vom Stripe Dashboard hinzufügen
4. Zahlungsmethoden aktivieren (Karten, ACH, SEPA, etc.)
5. Webhook konfigurieren: `https://invoices.deinedomain.com/stripe/webhook`
6. Im Stripe Dashboard Webhook-URL hinzufügen und Events auswählen

**PayPal-Setup:**

1. Einstellungen → Zahlungseinstellungen → Gateways konfigurieren
2. PayPal auswählen → Konfigurieren
3. Client ID und Secret von PayPal Developer hinzufügen
4. Return-URL setzen: `https://invoices.deinedomain.com/paypal/completed`
5. Zuerst im Sandbox-Modus testen

**Webhook-Sicherheit:**

- Jedes Gateway bietet Webhook-Endpunkte
- Webhook-Secrets für Validierung in n8n verwenden
- Zuerst mit Stripe CLI oder PayPal Sandbox testen

### Kundenportal-Funktionen

Das Kundenportal ermöglicht Kunden:

- Rechnungen online anzeigen und bezahlen
- Rechnungen und Belege als PDF herunterladen
- Zahlungshistorie einsehen
- Kontaktinformationen aktualisieren
- Angebote genehmigen
- Zugriff ohne separate Registrierung (Magic Link)

**Portal-URL:** `https://invoices.deinedomain.com/client/login`

**Anpassung:**

1. Einstellungen → Kundenportal
2. Funktionen aktivieren/deaktivieren
3. AGB und Datenschutzerklärung anpassen
4. Zahlungsmethoden für Kunden festlegen
5. Eigenes Logo und Farben hochladen

### Erweiterte API-Nutzung

Für Operationen, die nicht im nativen Node verfügbar sind, HTTP Request verwenden:

```javascript
// Bulk-Rechnungsaktionen
Methode: POST
URL: http://invoiceninja:8000/api/v1/invoices/bulk
Header:
  X-API-TOKEN: {{$credentials.apiToken}}
  Content-Type: application/json
Body: {
  "ids": [1, 2, 3],
  "action": "send" // oder "download", "archive", "delete"
}

// Benutzerdefinierte Berichte
Methode: GET
URL: http://invoiceninja:8000/api/v1/reports/clients
Header:
  X-API-TOKEN: {{$credentials.apiToken}}
Abfrage: {
  "date_range": "this_year",
  "report_keys": ["name", "balance", "paid_to_date"]
}

// Verwaltung wiederkehrender Rechnungen
Methode: POST
URL: http://invoiceninja:8000/api/v1/recurring_invoices
Header:
  X-API-TOKEN: {{$credentials.apiToken}}
Body: {
  "client_id": 1,
  "frequency_id": 4, // Monatlich
  "auto_bill": "always",
  "line_items": {{$json.items}}
}
```

### Mehrsprachigkeit & Lokalisierung

Invoice Ninja unterstützt über 30 Sprachen:

```javascript
// Rechnungssprache pro Kunde festlegen
Invoice Ninja Node: Update Client
Fields: {
  settings: {
    language_id: "2", // Deutsch (de)
    currency_id: "2", // EUR
    country_id: "276" // Deutschland
  }
}
```

**Verfügbare Sprachen:** Englisch, Deutsch, Französisch, Spanisch, Italienisch, Niederländisch, Portugiesisch und 20+ weitere

### Migration von anderen Systemen

Invoice Ninja kann importieren von:

- QuickBooks
- FreshBooks
- Wave
- Zoho Invoice
- CSV-Dateien

**Import-Prozess:**

1. Einstellungen → Import
2. Quellsystem auswählen
3. Export-Datei hochladen
4. Felder zuordnen
5. Überprüfen und bestätigen

### Fehlerbehebung

**500 Internal Server Fehler:**

```bash
# 1. Datenbank-Migrationen ausführen
docker exec invoiceninja php artisan migrate --force

# 2. Cache leeren
docker exec invoiceninja php artisan optimize:clear
docker exec invoiceninja php artisan optimize

# 3. Logs prüfen
docker logs invoiceninja --tail 100

# 4. .env Datei prüfen
docker exec invoiceninja cat .env | grep APP_KEY
# Sollte zeigen: APP_KEY=base64:...
```

**PDFs werden nicht generiert:**

```bash
# 1. PDF-Generator prüfen
docker exec invoiceninja php artisan ninja:check-pdf

# 2. Chromium testen (Standard-PDF-Generator)
docker exec invoiceninja which chromium-browser

# 3. Bei anhaltenden Problemen zu PhantomJS wechseln
# In .env: PDF_GENERATOR=phantom

# 4. Container neu starten
docker compose restart invoiceninja
```

**E-Mail-Zustellungsprobleme:**

```bash
# 1. Mail-Konfiguration testen
docker exec invoiceninja php artisan tinker
>>> Mail::raw('Test', function($m) { $m->to('test@example.com')->subject('Test'); });

# 2. Mail-Einstellungen in .env prüfen
docker exec invoiceninja env | grep MAIL

# 3. Mailpit/Docker-Mailserver-Logs prüfen
docker logs mailpit --tail 50
# oder
docker logs mailserver --tail 50

# 4. SMTP-Zugangsdaten verifizieren
```

**API gibt 401 Unauthorized zurück:**

```bash
# 1. API-Token verifizieren
# Login zu Invoice Ninja → Einstellungen → API-Tokens

# 2. Token-Berechtigungen prüfen

# 3. API-Verbindung testen
curl -H "X-API-TOKEN: DEIN_TOKEN" \
  http://invoiceninja:8000/api/v1/clients

# 4. Token bei Bedarf neu generieren
```

**Datenbankverbindungsfehler:**

```bash
# 1. MySQL-Container prüfen
docker ps | grep invoiceninja_db

# 2. Datenbankverbindung testen
docker exec invoiceninja_db mysql -u invoiceninja \
  -p${INVOICENINJA_DB_PASSWORD} invoiceninja -e "SHOW TABLES;"

# 3. .env Datenbankeinstellungen prüfen
docker exec invoiceninja env | grep DB

# 4. Beide Container neu starten
docker compose restart invoiceninja_db invoiceninja
```

### Tipps für Invoice Ninja + n8n Integration

**Best Practices:**

1. **Interne URLs verwenden:** Von n8n `http://invoiceninja:8000` nutzen (schneller, kein SSL-Overhead)
2. **API-Rate-Limits:** Standard 300 Anfragen pro Minute - Verzögerungen für Bulk-Operationen hinzufügen
3. **Webhook-Events:** In Einstellungen → Kontoverwaltung → Webhooks aktivieren
4. **PDF-Generierung:** Nutzt Chromium intern, kann 1-2 Sekunden pro Rechnung benötigen
5. **Währungsbehandlung:** Immer currency_id für Mehrwährungs-Setups angeben
6. **Steuerberechnungen:** Steuersätze vor Rechnungserstellung konfigurieren
7. **Backup:** Regelmäßige Datenbank-Backups für Finanzdaten empfohlen

**Häufige Automatisierungsmuster:**

- Zeiterfassung → Rechnungsgenerierung
- Zahlung erhalten → Buchhaltungssoftware aktualisieren
- Überfällige Rechnungen → Eskalierende Erinnerungen
- Ausgabengenehmigung → Kundenabrechnung
- Wiederkehrende Rechnungen → Zahlungs-Wiederholungslogik
- Rechnung erstellt → Zu CRM-Pipeline hinzufügen

**Datensicherheit:**

- APP_KEY verschlüsselt sensible Daten
- Regelmäßige Datenbank-Backups essentiell
- Starke API-Tokens verwenden
- Webhook-Signatur-Validierung
- DSGVO-konforme Datenbehandlung

### Performance-Optimierung

Für großangelegte Operationen:

```yaml
# PHP-Speicher in docker-compose.yml erhöhen
environment:
  - PHP_MEMORY_LIMIT=512M
  
# Redis-Caching aktivieren (bereits konfiguriert)
  - CACHE_DRIVER=redis
  - SESSION_DRIVER=redis
  - QUEUE_CONNECTION=redis
```

**Queue-Verarbeitung:**

- Invoice Ninja nutzt Queues für E-Mails und PDFs
- Überwachen mit: `docker exec invoiceninja php artisan queue:work --stop-when-empty`
- Für Produktion: Queue Worker als Daemon einrichten

### Ressourcen

- **Dokumentation:** https://invoiceninja.github.io/
- **API-Referenz:** https://api-docs.invoicing.co/
- **Forum:** https://forum.invoiceninja.com/
- **GitHub:** https://github.com/invoiceninja/invoiceninja
- **YouTube:** [Invoice Ninja Channel](https://www.youtube.com/channel/UCXjmYgQdCTpvHZSQ0x6VFRA)
- **n8n Node-Docs:** Suche "Invoice Ninja" in n8n Node-Bibliothek
