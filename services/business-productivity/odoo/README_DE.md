# 🏢 Odoo 18 - ERP/CRM

### Was ist Odoo 18?

Odoo 18 ist ein umfassendes Open-Source ERP (Enterprise Resource Planning) und CRM-System, das alle Geschäftsfunktionen in einer einheitlichen Plattform vereint. Odoo 18 wurde 2024 veröffentlicht und führt integrierte KI-Funktionen für Lead-Scoring, Content-Generierung und Verkaufsprognosen ein. Es ist eine vollständige Business-Management-Suite, die Vertrieb, CRM, Inventar, Buchhaltung, HR, Projekte und mehr abdeckt - alles mit nativer n8n-Integration für leistungsstarke Automatisierungs-Workflows.

### Funktionen

- **KI-gestütztes Lead-Scoring:** Bewertet Leads automatisch basierend auf Interaktionsverlauf und Datenmustern
- **KI-Content-Generierung:** Generiere E-Mails, Produktbeschreibungen und Verkaufsangebote mit KI
- **Vollständiges CRM:** Lead-Management, Opportunities, Pipeline-Visualisierung, Aktivitäts-Tracking
- **Verkaufsautomatisierung:** Angebote, Bestellungen, Rechnungsstellung, Zahlungs-Tracking
- **Inventarverwaltung:** Bestandskontrolle, Lagerverwaltung, Produktvarianten
- **Buchhaltung:** Rechnungsstellung, Ausgaben, Bankabstimmung, Finanzberichte
- **HR-Management:** Mitarbeiterakten, Freizeit, Rekrutierung, Beurteilungen
- **Projektmanagement:** Aufgaben, Zeiterfassung, Gantt-Diagramme, Ressourcenplanung
- **Fertigung:** Stücklisten, Arbeitsaufträge, Qualitätskontrolle
- **E-Commerce:** Online-Shop, Produktkatalog, Zahlungsintegration
- **Marketing:** E-Mail-Kampagnen, Events, Umfragen, Social Media
- **Multi-Company:** Verwalte mehrere Unternehmen von einer Instanz
- **Anpassbar:** 30.000+ Apps im App Store, Custom-Module-Support

### Erste Einrichtung

**Erster Login bei Odoo:**

1. Navigiere zu `https://odoo.deinedomain.com`
2. Erstelle deine Datenbank:
   - Datenbankname: `odoo` (oder dein Firmenname)
   - Master-Passwort: Prüfe `.env` Datei für `ODOO_MASTER_PASSWORD`
   - E-Mail: Deine Admin-E-Mail-Adresse
   - Passwort: Wähle ein starkes Admin-Passwort
   - Sprache: Wähle deine bevorzugte Sprache
   - Land: Wähle dein Land für Lokalisierung
3. Schließe den initialen Konfigurations-Assistenten ab:
   - Wähle Apps zur Installation (CRM, Sales, Inventory, Accounting, etc.)
   - Konfiguriere Firmendetails
   - Richte Benutzer und Berechtigungen ein
4. Gehe zu Settings → Technical → API Keys um API-Zugangsdaten zu generieren

**Wichtig:** Speichere deine Admin-Zugangsdaten und das Master-Passwort sicher!

### n8n Integration einrichten

**Native Odoo Node in n8n:**

n8n bietet eine native Odoo-Node für nahtlose Integration!

**Odoo-Zugangsdaten in n8n erstellen:**

1. In n8n, gehe zu Credentials → New → Odoo API
2. Konfiguriere:
   - **URL:** `http://odoo:8069` (intern) oder `https://odoo.deinedomain.com` (extern)
   - **Database:** `odoo` (dein Datenbankname aus dem Setup)
   - **Username:** Deine Admin-E-Mail
   - **API Key or Password:** Generiere API-Key in Odoo Settings → Technical → API Keys

**Interne URL für n8n:** `http://odoo:8069`

**Tipp:** Nutze API-Keys statt Passwörter für bessere Sicherheit und um Session-Timeouts zu vermeiden.

### Beispiel-Workflows

#### Beispiel 1: KI-erweitertes Lead-Management

Automatisiere Lead-Qualifizierung mit KI-Scoring und Firmenrecherche:

```javascript
// Qualifiziere neue Leads automatisch mit KI und reichere sie mit Firmendaten an

// 1. Schedule Trigger - Jede Stunde
// Oder: Webhook von Website-Formular-Einreichung

// 2. Odoo Node - Neue Leads abrufen
Operation: Get All
Resource: Lead/Opportunity
Filters:
  stage_id: 1  // Neue Leads-Phase
  probability: 0  // Noch nicht bewertet
Limit: 50

// 3. Loop Over Items

// 4. Perplexica Node - Firma recherchieren
Methode: POST
URL: http://perplexica:3000/api/search
Body (JSON):
{
  "query": "{{$json.partner_name}} Firmeninformationen Umsatz Mitarbeiter",
  "focusMode": "webSearch"
}

// 5. Code Node - Recherche parsen und für KI-Scoring vorbereiten
const lead = $input.first().json;
const research = $input.all()[1].json;

// Schlüsselinformationen extrahieren
const companyInfo = {
  name: lead.partner_name,
  industry: lead.industry_id?.name || 'Unbekannt',
  country: lead.country_id?.name || 'Unbekannt',
  employees: research.employees || 'Unbekannt',
  revenue: research.revenue || 'Unbekannt',
  recentNews: research.summary || '',
  website: lead.website || '',
  contactName: lead.contact_name || '',
  email: lead.email_from || '',
  phone: lead.phone || ''
};

return [{
  json: {
    leadId: lead.id,
    companyInfo: companyInfo,
    scoringPrompt: `Analysiere diesen B2B-Lead und bewerte von 0-100:
      
Firma: ${companyInfo.name}
Branche: ${companyInfo.industry}
Größe: ${companyInfo.employees} Mitarbeiter
Umsatz: ${companyInfo.revenue}
Standort: ${companyInfo.country}
Aktuelle News: ${companyInfo.recentNews}

Kontaktinfo:
- Name: ${companyInfo.contactName}
- E-Mail: ${companyInfo.email}
- Telefon: ${companyInfo.phone}

Berücksichtige:
1. Firmengröße und Umsatzpotenzial
2. Branchen-Fit für unsere Produkte
3. Wachstumsindikatoren aus aktuellen News
4. Kontaktqualität (Entscheidungsträger-Ebene)
5. Geografischer Fit

Antworte mit JSON: {"score": 0-100, "reasoning": "Erklärung", "priority": "low/medium/high"}`
  }
}];

// 6. OpenAI Node - KI Lead-Scoring
Modell: gpt-4o-mini
Prompt: {{$json.scoringPrompt}}
Response Format: JSON

// 7. Code Node - KI-Antwort parsen
const aiResponse = JSON.parse($json.choices[0].message.content);
const previousData = $input.all()[0].json;

return [{
  json: {
    leadId: previousData.leadId,
    score: aiResponse.score,
    reasoning: aiResponse.reasoning,
    priority: aiResponse.priority,
    companyInfo: previousData.companyInfo
  }
}];

// 8. Odoo Node - Lead mit KI-Score aktualisieren
Operation: Update
Resource: Lead/Opportunity
ID: {{$json.leadId}}
Fields:
  probability: {{$json.score}}
  priority: {{$json.priority === 'high' ? '3' : $json.priority === 'medium' ? '2' : '1'}}
  description: |
    KI Lead-Score: {{$json.score}}/100
    Priorität: {{$json.priority}}
    
    KI-Analyse:
    {{$json.reasoning}}
    
    Firmenrecherche:
    Mitarbeiter: {{$json.companyInfo.employees}}
    Umsatz: {{$json.companyInfo.revenue}}
    Branche: {{$json.companyInfo.industry}}
    Aktuelle News: {{$json.companyInfo.recentNews}}

// 9. IF Node - Prüfe ob hochpriorisierter Lead
Bedingung: {{$json.priority}} === 'high' AND {{$json.score}} >= 70

// IF TRUE - Hochprioritäts-Aktionen:

// 10a. Odoo Node - Sales Manager zuweisen
Operation: Update
Resource: Lead/Opportunity
ID: {{$json.leadId}}
Fields:
  user_id: 2  // Sales Manager Benutzer-ID

// 10b. Odoo Node - Aktivität erstellen (Follow-up-Anruf)
Operation: Create
Resource: Mail Activity
Fields:
  res_model: crm.lead
  res_id: {{$json.leadId}}
  activity_type_id: 2  // Anruf-Aktivitätstyp
  summary: "🔥 HEISSER LEAD - Prioritäts-Follow-up"
  note: |
    KI-Score: {{$json.score}}/100
    Begründung: {{$json.reasoning}}
    
    Aktion: Innerhalb von 24 Stunden anrufen
  date_deadline: {{$now.plus({days: 1}).toISO()}}
  user_id: 2  // Sales Manager zuweisen

// 10c. Slack Notification - Sales-Team benachrichtigen
Kanal: #sales
Nachricht: |
  🔥 **HEISSER LEAD ALARM** 🔥
  
  Firma: {{$json.companyInfo.name}}
  KI-Score: {{$json.score}}/100
  Priorität: {{$json.priority}}
  
  {{$json.reasoning}}
  
  Kontakt: {{$json.companyInfo.contactName}}
  E-Mail: {{$json.companyInfo.email}}
  
  [In Odoo ansehen](https://odoo.deinedomain.com/web#id={{$json.leadId}}&model=crm.lead&view_type=form)

// 10d. Send Email - An zugewiesenen Verkäufer
To: sales-manager@deinedomain.com
Subject: 🔥 Neuer heißer Lead: {{$json.companyInfo.name}}
Body: |
  Ein neuer hochpriorisierter Lead wurde dir zugewiesen:
  
  Firma: {{$json.companyInfo.name}}
  KI Lead-Score: {{$json.score}}/100
  
  KI-Analyse:
  {{$json.reasoning}}
  
  Firmendetails:
  - Branche: {{$json.companyInfo.industry}}
  - Größe: {{$json.companyInfo.employees}} Mitarbeiter
  - Standort: {{$json.companyInfo.country}}
  
  Kontakt:
  - Name: {{$json.companyInfo.contactName}}
  - E-Mail: {{$json.companyInfo.email}}
  - Telefon: {{$json.companyInfo.phone}}
  
  Nächste Schritte:
  - Lead in Odoo prüfen
  - Innerhalb von 24 Stunden anrufen
  - Personalisierten Pitch vorbereiten
  
  [In Odoo öffnen](https://odoo.deinedomain.com/web#id={{$json.leadId}}&model=crm.lead&view_type=form)

// IF FALSE - Normale Priorität:

// 11. Odoo Node - Zu Nurture-Kampagne hinzufügen
Operation: Update
Resource: Lead/Opportunity
ID: {{$json.leadId}}
Fields:
  stage_id: 2  // Qualifizierte Phase
  tag_ids: [[6, 0, [1]]]  // "Nurture Campaign" Tag hinzufügen
```

#### Beispiel 2: Automatisierte Rechnungsverarbeitung aus E-Mails

Lieferantenrechnungen automatisch aus E-Mail-Anhängen verarbeiten:

```javascript
// Rechnungsdaten aus PDFs extrahieren und Lieferantenrechnungen in Odoo erstellen

// 1. IMAP E-Mail-Trigger - Posteingang auf Rechnungen überwachen
Mailbox: INBOX
Suchkriterien:
  Betreff enthält: "rechnung" OR "invoice" OR "faktura"
  Hat Anhänge: true
  Ungelesen: true

// 2. Loop Over Attachments (Schleife über Anhänge)

// 3. IF Node - Prüfe ob PDF
Bedingung: {{$json.filename}} ends with ".pdf"

// 4. HTTP Request Node - OCR Service (Tesseract)
Methode: POST
URL: http://tesseract:8000/ocr
Body:
  Binary Daten: {{$binary.data}}
  Language: deu
Options:
  Response Type: JSON

// 5. Code Node - Rechnungsdaten parsen
const ocrText = $json.text;

// Rechnungsdetails mit Regex-Mustern extrahieren
const invoiceNumber = ocrText.match(/Rechnung\s*#?\s*:?\s*(\w+-?\d+)/i)?.[1] || 
                      ocrText.match(/Invoice\s*#?\s*:?\s*(\w+-?\d+)/i)?.[1] || '';
const invoiceDate = ocrText.match(/Datum\s*:?\s*([\d\/\-\.]+)/i)?.[1] || 
                    ocrText.match(/Date\s*:?\s*([\d\/\-\.]+)/i)?.[1] || '';
const vendorName = ocrText.match(/Von\s*:?\s*(.+?)\n/i)?.[1] || 
                   ocrText.match(/Lieferant\s*:?\s*(.+?)\n/i)?.[1] || 
                   ocrText.match(/From\s*:?\s*(.+?)\n/i)?.[1] || 
                   ocrText.match(/Vendor\s*:?\s*(.+?)\n/i)?.[1] || '';

// Gesamtbetrag extrahieren (verschiedene Muster suchen)
const totalPatterns = [
  /Gesamt\s*:?\s*€?\s?([\d,]+\.?\d*)/i,
  /Summe\s*:?\s*€?\s?([\d,]+\.?\d*)/i,
  /Total\s*:?\s*€?\s?([\d,]+\.?\d*)/i,
  /Betrag\s*:?\s*€?\s?([\d,]+\.?\d*)/i,
  /Amount\s*Due\s*:?\s*€?\s?([\d,]+\.?\d*)/i
];

let totalAmount = 0;
for (const pattern of totalPatterns) {
  const match = ocrText.match(pattern);
  if (match) {
    totalAmount = parseFloat(match[1].replace(',', '.'));
    break;
  }
}

// Einzelposten extrahieren
const lineItems = [];
const itemRegex = /(.+?)\s+(\d+)\s+€?([\d,]+\.?\d*)\s+€?([\d,]+\.?\d*)/g;
let itemMatch;

while ((itemMatch = itemRegex.exec(ocrText)) !== null) {
  lineItems.push({
    description: itemMatch[1].trim(),
    quantity: parseInt(itemMatch[2]),
    unit_price: parseFloat(itemMatch[3].replace(',', '.')),
    total: parseFloat(itemMatch[4].replace(',', '.'))
  });
}

return [{
  json: {
    vendor: vendorName.trim(),
    invoice_number: invoiceNumber,
    invoice_date: invoiceDate,
    total_amount: totalAmount,
    line_items: lineItems,
    raw_text: ocrText,
    original_filename: $input.first().json.filename
  }
}];

// 6. Odoo Node - Lieferant suchen
Operation: Get All
Resource: Contact
Filters:
  name: {{$json.vendor}}
  supplier_rank: [">", 0]  // Ist ein Lieferant
Limit: 1

// 7. IF Node - Lieferant existiert?
Bedingung: {{$json.id}} is not empty

// IF JA - Lieferant gefunden:

// 8a. Odoo Node - Lieferantenrechnung erstellen
Operation: Create
Resource: Vendor Bill
Fields:
  partner_id: {{$('Search Vendor').json.id}}
  ref: {{$('Parse Invoice').json.invoice_number}}
  invoice_date: {{$('Parse Invoice').json.invoice_date}}
  move_type: in_invoice
  state: draft

// 8b. Loop Over Line Items (Schleife über Rechnungspositionen)

// 8c. Odoo Node - Rechnungsposition hinzufügen
Operation: Create
Resource: Account Move Line
Fields:
  move_id: {{$('Create Vendor Bill').json.id}}
  name: {{$json.description}}
  quantity: {{$json.quantity}}
  price_unit: {{$json.unit_price}}
  account_id: 15  // Standard-Ausgabenkonto

// 8d. Odoo Node - Original-PDF anhängen
Operation: Create
Resource: Attachment
Fields:
  name: {{$('Parse Invoice').json.original_filename}}
  datas: {{$binary.data}}
  res_model: account.move
  res_id: {{$('Create Vendor Bill').json.id}}

// 8e. Slack Notification - Erfolg
Kanal: #buchhaltung
Nachricht: |
  ✅ **Rechnung erfolgreich verarbeitet**
  
  Lieferant: {{$('Parse Invoice').json.vendor}}
  Rechnungsnr.: {{$('Parse Invoice').json.invoice_number}}
  Betrag: €{{$('Parse Invoice').json.total_amount}}
  
  Rechnung in Odoo erstellt (Entwurfsstatus)
  [Rechnung prüfen](https://odoo.deinedomain.com/web#id={{$('Create Vendor Bill').json.id}}&model=account.move&view_type=form)

// IF NEIN - Lieferant nicht gefunden:

// 9. Odoo Node - Support-Ticket erstellen (Vikunja/Leantime)
Methode: POST
URL: http://vikunja:3456/api/v1/tasks
Body (JSON):
{
  "title": "Neuer Lieferant erforderlich: {{$('Parse Invoice').json.vendor}}",
  "description": |
    Rechnung von unbekanntem Lieferanten erhalten.
    
    Lieferant: {{$('Parse Invoice').json.vendor}}
    Rechnungsnr.: {{$('Parse Invoice').json.invoice_number}}
    Betrag: €{{$('Parse Invoice').json.total_amount}}
    
    Bitte:
    1. Lieferant in Odoo anlegen
    2. Lieferantenrechnung manuell erstellen
    3. Rechnungs-PDF anhängen
  "priority": 2,
  "project_id": 1,
  "labels": ["buchhaltung", "neuer-lieferant"]
}

// 10. Send Email - Buchhaltungsteam benachrichtigen
To: buchhaltung@deinedomain.com
Subject: Aktion erforderlich: Neue Lieferantenrechnung
Body: |
  Eine Rechnung von einem unbekannten Lieferanten wurde empfangen:
  
  Lieferant: {{$('Parse Invoice').json.vendor}}
  Rechnungsnr.: {{$('Parse Invoice').json.invoice_number}}
  Datum: {{$('Parse Invoice').json.invoice_date}}
  Betrag: €{{$('Parse Invoice').json.total_amount}}
  
  Bitte legen Sie diesen Lieferanten in Odoo an und verarbeiten Sie die Rechnung manuell.
  
  Aufgabe erstellt: [Aufgabe ansehen](https://vikunja.deinedomain.com/tasks/{{$json.id}})

Anhänge: Original PDF
```

#### Beispiel 3: KI-Content-Generierung für Produkte

Produktbeschreibungen und Marketing-Inhalte automatisch generieren:

```javascript
// Ansprechende Produktbeschreibungen mit KI erstellen

// 1. Schedule Trigger - Täglich um Mitternacht
// Oder: Odoo Webhook wenn neues Produkt erstellt wird

// 2. Odoo Node - Produkte ohne Beschreibungen abrufen
Operation: Get All
Resource: Product
Filters:
  description_sale: false  // Keine Verkaufsbeschreibung
  type: product  // Nur physische Produkte
Limit: 20  // 20 pro Durchlauf verarbeiten

// 3. Loop Over Products (Schleife über Produkte)

// 4. Odoo Node - Produktdetails abrufen
Operation: Get
Resource: Product
ID: {{$json.id}}
Options:
  Include: category, attributes, variants, images

// 5. Code Node - KI-Prompt vorbereiten
const product = $json;

const prompt = `Erstelle professionelle, ansprechende Inhalte für dieses Produkt:

Produktname: ${product.name}
Kategorie: ${product.categ_id?.name || 'Allgemein'}
Typ: ${product.type}
Listenpreis: €${product.list_price}

${product.attribute_line_ids?.length > 0 ? `
Attribute:
${product.attribute_line_ids.map(attr => `- ${attr.display_name}`).join('\n')}
` : ''}

Erstelle:
1. **Verkaufsbeschreibung** (150-200 Wörter):
   - Ansprechende Produktübersicht
   - Hauptvorteile und Funktionen
   - Anwendungsszenarien
   - Call-to-Action

2. **Website-Beschreibung** (250-300 Wörter):
   - SEO-optimierter Inhalt
   - Detaillierte Spezifikationen
   - Technische Details
   - Vergleichspunkte

3. **Meta-Keywords** (kommagetrennt):
   - 5-7 relevante SEO-Keywords

4. **Kurzbeschreibung** (1 Satz):
   - Eingängiger Slogan für Auflistungen

Formatiere Antwort als JSON:
{
  "sales_description": "...",
  "website_description": "...",
  "meta_keywords": "keyword1, keyword2, ...",
  "short_description": "..."
}`;

return [{
  json: {
    productId: product.id,
    productName: product.name,
    prompt: prompt
  }
}];

// 6. OpenAI Node - Inhalt generieren
Modell: gpt-4o
Temperature: 0.7  // Ausgewogene Kreativität
Prompt: {{$json.prompt}}
Response Format: JSON

// 7. Code Node - KI-Antwort parsen
const aiContent = JSON.parse($json.choices[0].message.content);
const productData = $input.first().json;

return [{
  json: {
    productId: productData.productId,
    productName: productData.productName,
    salesDescription: aiContent.sales_description,
    websiteDescription: aiContent.website_description,
    metaKeywords: aiContent.meta_keywords,
    shortDescription: aiContent.short_description
  }
}];

// 8. Odoo Node - Produkt aktualisieren
Operation: Update
Resource: Product
ID: {{$json.productId}}
Fields:
  description_sale: {{$json.salesDescription}}
  website_description: {{$json.websiteDescription}}
  website_meta_keywords: {{$json.metaKeywords}}
  description: {{$json.shortDescription}}

// 9. Odoo Node - Interne Notiz hinzufügen
Operation: Create
Resource: Mail Message
Fields:
  model: product.template
  res_id: {{$json.productId}}
  body: |
    <p><strong>KI-generierter Inhalt hinzugefügt</strong></p>
    <p>Produktbeschreibungen von KI generiert am {{$now.format('DD.MM.YYYY')}}</p>
    <p>Vor Veröffentlichung prüfen und bei Bedarf anpassen.</p>
  message_type: comment

// 10. After Loop - Zusammenfassungs-Benachrichtigung

// 11. Code Node - Zusammenfassung generieren
const products = $input.all();
const successCount = products.length;

return [{
  json: {
    count: successCount,
    products: products.map(p => p.json.productName)
  }
}];

// 12. Slack Notification
Kanal: #marketing
Nachricht: |
  ✨ **KI-Produktbeschreibungen generiert**
  
  {{$json.count}} Produkte mit KI-generierten Inhalten aktualisiert.
  
  Produkte:
  {{$json.products.map(name => `• ${name}`).join('\n')}}
  
  Bitte Inhalte in Odoo prüfen bevor sie auf der Website veröffentlicht werden.
```

#### Beispiel 4: Verkaufsautomatisierungs-Workflow

Follow-ups und Aufgabenerstellung für das Verkaufsteam automatisieren:

```javascript
// Vertriebsaktivitäten und Follow-ups basierend auf Opportunity-Phasen automatisieren

// 1. Schedule Trigger - Täglich um 9 Uhr

// 2. Odoo Node - Opportunities abrufen die Follow-up benötigen
Operation: Get All
Resource: Lead/Opportunity
Filters:
  probability: [">", 50]  // Qualifizierte Leads
  activity_date_deadline: ["<", "{{$now.plus({days: 3}).toISO()}}"]  // Aktivität bald fällig
  stage_id: ["in", [2, 3, 4]]  // Qualifizierte, Angebots-, Verhandlungsphasen
Limit: 100

// 3. Loop Over Opportunities (Schleife über Opportunities)

// 4. Code Node - Aktion basierend auf Phase bestimmen
const opp = $json;
const daysUntilDeadline = Math.ceil(
  (new Date(opp.activity_date_deadline) - new Date()) / (1000 * 60 * 60 * 24)
);

let action, priority, message;

if (daysUntilDeadline <= 0) {
  action = 'overdue';
  priority = 'high';
  message = '🚨 Überfällige Aktivität';
} else if (daysUntilDeadline === 1) {
  action = 'urgent';
  priority = 'high';
  message = '⚠️ Aktivität morgen fällig';
} else {
  action = 'reminder';
  priority = 'normal';
  message = '📅 Aktivität fällig in ' + daysUntilDeadline + ' Tagen';
}

return [{
  json: {
    oppId: opp.id,
    oppName: opp.name,
    partner: opp.partner_id?.name || 'Unbekannt',
    stage: opp.stage_id?.name || 'Unbekannt',
    expectedRevenue: opp.expected_revenue,
    probability: opp.probability,
    assignedUser: opp.user_id?.name || 'Nicht zugewiesen',
    assignedEmail: opp.user_id?.email || '',
    action: action,
    priority: priority,
    message: message,
    deadline: opp.activity_date_deadline,
    activitySummary: opp.activity_summary || 'Follow-up'
  }
}];

// 5. Odoo Node - Neue Aktivität erstellen
Operation: Create
Resource: Mail Activity
Fields:
  res_model: crm.lead
  res_id: {{$json.oppId}}
  activity_type_id: 2  // Anruf
  summary: "{{$json.message}} - {{$json.activitySummary}}"
  note: |
    Automatische Erinnerung für Opportunity: {{$json.oppName}}
    Kunde: {{$json.partner}}
    Erwarteter Umsatz: €{{$json.expectedRevenue}}
    Wahrscheinlichkeit: {{$json.probability}}%
    
    Vorherige Aktivitätsfrist war: {{$json.deadline}}
  date_deadline: {{$now.plus({days: 1}).toISO()}}
  user_id: {{$json.user_id}}

// 6. IF Node - Hohe Priorität?
Bedingung: {{$json.priority}} === 'high'

// IF JA:

// 7a. Send Email - An zugewiesenen Verkäufer
To: {{$json.assignedEmail}}
Subject: {{$json.message}}: {{$json.oppName}}
Body: |
  Hallo {{$json.assignedUser}},
  
  {{$json.message}} für Opportunity: {{$json.oppName}}
  
  Opportunity-Details:
  - Kunde: {{$json.partner}}
  - Phase: {{$json.stage}}
  - Erwarteter Umsatz: €{{$json.expectedRevenue}}
  - Gewinnwahrscheinlichkeit: {{$json.probability}}%
  - Aktivität: {{$json.activitySummary}}
  - Ursprüngliche Frist: {{$json.deadline}}
  
  Eine neue Follow-up-Aktivität wurde für morgen erstellt.
  
  [In Odoo öffnen](https://odoo.deinedomain.com/web#id={{$json.oppId}}&model=crm.lead&view_type=form)
  
  Beste Grüße,
  Verkaufsautomatisierungssystem

// 7b. Slack Notification
Kanal: #vertrieb
Nachricht: |
  {{$json.message}}
  
  Opportunity: {{$json.oppName}}
  Kunde: {{$json.partner}}
  Wert: €{{$json.expectedRevenue}}
  Zugewiesen: {{$json.assignedUser}}
  
  [Ansehen](https://odoo.deinedomain.com/web#id={{$json.oppId}}&model=crm.lead&view_type=form)

// IF NEIN - Normale Priorität:

// 8. Odoo Node - Interne Notiz protokollieren
Operation: Create
Resource: Mail Message
Fields:
  model: crm.lead
  res_id: {{$json.oppId}}
  body: |
    <p>Automatische Follow-up-Erinnerung erstellt.</p>
    <p>Aktivität für morgen geplant.</p>
  message_type: comment
```

### Odoo 18 KI-Funktionen

Nutze Odoos integrierte KI-Funktionen in deinen Workflows:

**1. KI-Lead-Scoring:**
- Bewertet Leads automatisch basierend auf Interaktionsverlauf
- Machine-Learning-Modelle auf deinen Daten trainiert
- Aktualisiert Wahrscheinlichkeits-Scores in Echtzeit
- Identifiziert hochwertige Opportunities

**2. Content-Generierung:**
- Generiert professionelle E-Mails
- Erstellt Produktbeschreibungen
- Schreibt Verkaufsangebote
- Entwirft Meeting-Zusammenfassungen

**3. Verkaufsprognosen:**
- ML-basierte Pipeline-Vorhersagen
- Umsatzprognosen pro Zeitraum
- Gewinnwahrscheinlichkeits-Berechnungen
- Trendanalyse

**4. Spesenabrechnung:**
- OCR für Beleg-Scanning
- Automatische Ausgaben-Kategorisierung
- Duplikat-Erkennung
- Richtlinien-Compliance-Prüfung

**5. Dokumentenanalyse:**
- Datenextraktion aus PDFs
- Rechnungsdaten-Extraktion
- Vertrags-Parsing
- Automatisierte Dateneingabe

### Fortgeschritten: Odoo XML-RPC API

Für Operationen die nicht in der nativen Node verfügbar sind, nutze XML-RPC:

```javascript
// HTTP Request Node - Authentifizieren
Methode: POST
URL: http://odoo:8069/web/session/authenticate
Body (JSON):
{
  "jsonrpc": "2.0",
  "params": {
    "db": "odoo",
    "login": "admin@example.com",
    "password": "dein-passwort"
  }
}

// Antwort enthält session_id in Cookies
// Für nachfolgende Anfragen speichern

// HTTP Request Node - Model-Methode aufrufen
Methode: POST
URL: http://odoo:8069/web/dataset/call_kw
Header:
  Cookie: session_id={{$json.session_id}}
  Content-Type: application/json
Body (JSON):
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "model": "res.partner",
    "method": "create",
    "args": [{
      "name": "Neuer Kunde",
      "email": "kunde@example.com",
      "phone": "+491234567890",
      "is_company": true
    }],
    "kwargs": {}
  }
}

// Datensätze suchen
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "model": "crm.lead",
    "method": "search_read",
    "args": [[["probability", ">", 70]]],
    "kwargs": {
      "fields": ["name", "partner_name", "expected_revenue"],
      "limit": 10
    }
  }
}
```

### Tipps für Odoo + n8n Integration

1. **Interne URLs verwenden:** Nutze immer `http://odoo:8069` von n8n für schnellere Performance
2. **API-Keys:** Verwende API-Keys statt Passwörtern um Session-Timeouts zu vermeiden
3. **Batch-Operationen:** Verarbeite mehrere Datensätze in Schleifen um API-Aufrufe zu reduzieren
4. **Fehlerbehandlung:** Füge Try/Catch-Nodes für robuste Workflows hinzu (Odoo API kann komplexe Fehler zurückgeben)
5. **Caching:** Speichere häufig abgerufene Daten (wie Produktlisten, Benutzer-IDs) in n8n-Variablen
6. **Webhooks:** Richte Odoo-Automatisierungsaktionen ein um n8n-Workflows bei Datensatzänderungen auszulösen
7. **Custom Fields:** Erstelle Custom-Felder in Odoo um KI-generierte Inhalte oder externe Daten zu speichern
8. **Datensatz-IDs:** Speichere und verwende immer Odoo-Datensatz-IDs für zuverlässige Datenaktualisierungen
9. **Feldnamen:** Verwende technische Feldnamen (name, partner_id) nicht Display-Namen
10. **Testing:** Teste Workflows zuerst in Odoos Test-Datenbank bevor du sie in Produktion nimmst

### Odoo Apps-Ökosystem

**Beliebte Apps für Automatisierung:**
- **REST API:** Vollständiger REST-API-Zugriff für einfachere Integration
- **Webhooks:** Echtzeit-Benachrichtigungen an n8n
- **AI Chat:** Chatbot-Integration
- **Document Management:** DMS mit Automatisierung
- **Advanced Inventory:** Barcode, Batch-Tracking
- **HR Analytics:** Mitarbeiter-Performance-Metriken

**Apps über Odoo UI installieren:**
1. Apps-Menü → Nach App suchen
2. Installieren → Konfigurieren
3. Zugriff über n8n mit Modellnamen

### Problembehandlung

#### Odoo Container startet nicht

```bash
# 1. Logs prüfen
docker logs odoo --tail 100

# 2. Häufiges Problem: Datenbankverbindung
docker ps | grep postgres
# Sicherstellen dass PostgreSQL läuft

# 3. Odoo-Konfiguration prüfen
docker exec odoo cat /etc/odoo/odoo.conf

# 4. Odoo-Datenbank zurücksetzen (VORSICHT - verliert Daten!)
docker exec postgres psql -U postgres -c "DROP DATABASE odoo;"
docker compose restart odoo
# Zugriff auf https://odoo.deinedomain.com um neue Datenbank zu erstellen

# 5. Speicherplatz prüfen
df -h
```

#### Kann mich nicht in Odoo einloggen

```bash
# 1. Master-Passwort verifizieren
grep ODOO_MASTER_PASSWORD .env

# 2. Admin-Passwort zurücksetzen
docker exec -it postgres psql -U postgres -d odoo
UPDATE res_users SET password = 'neuespasswort' WHERE login = 'admin';
\q

# 3. Prüfen ob Datenbank existiert
docker exec postgres psql -U postgres -l | grep odoo

# 4. Browser-Cache und Cookies löschen
```

#### API-Authentifizierungsfehler in n8n

```bash
# 1. Zugangsdaten in n8n verifizieren
# E-Mail verwenden (nicht Benutzername) für Login

# 2. Neuen API-Key in Odoo generieren
# Settings → Technical → API Keys → Create

# 3. API-Zugriff manuell testen
curl -X POST http://odoo:8069/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","params":{"db":"odoo","login":"admin@example.com","password":"deinpasswort"}}'

# 4. Odoo-Logs auf Auth-Fehler prüfen
docker logs odoo | grep -i auth
```

#### Workflow schlägt fehl mit "Record Not Found"

```bash
# 1. Verifizieren dass Datensatz-ID existiert
# Datensatz-IDs können sich nach Datenbank-Resets ändern

# 2. Zuerst Search-Operation verwenden
# Dann zurückgegebene ID für update/delete nutzen

# 3. Fehlerbehandlung in n8n hinzufügen
# Try-Node verwenden um fehlende Datensätze abzufangen

# 4. Prüfen ob Modellname korrekt ist
# Technischen Namen verwenden: crm.lead nicht "Lead"
```

#### Langsame Odoo-Performance

```bash
# 1. Ressourcennutzung prüfen
docker stats odoo

# 2. Odoo Workers in .env erhöhen
# ODOO_WORKERS=4 (Standard: 2)

# 3. Datenbank-Indexierung aktivieren
# Odoo UI → Settings → Technical → Database Structure

# 4. Alte Datensätze aufräumen
# Alte Opportunities, Leads, E-Mails archivieren

# 5. PostgreSQL optimieren
docker exec postgres psql -U postgres -d odoo -c "VACUUM ANALYZE;"
```

### Ressourcen

- **Dokumentation:** https://www.odoo.com/documentation/18.0/
- **API-Referenz:** https://www.odoo.com/documentation/18.0/developer/reference/external_api.html
- **Apps Store:** https://apps.odoo.com
- **Community Forum:** https://www.odoo.com/forum
- **GitHub:** https://github.com/odoo/odoo
- **Video-Tutorials:** https://www.odoo.com/slides
- **Developer Docs:** https://www.odoo.com/documentation/18.0/developer.html

### Best Practices

**Datenmanagement:**
- Verwende Phasen zur Organisation der Sales-Pipeline
- Archiviere alte Datensätze regelmäßig
- Richte ordnungsgemäße Benutzerberechtigungen ein
- Erstelle Custom-Felder für Integrationen
- Nutze Tags zur Kategorisierung
- Regelmäßige Datenbank-Backups

**Workflow-Automatisierung:**
- Starte mit einfachen Workflows, füge Komplexität schrittweise hinzu
- Teste zuerst in Odoo-Test-Datenbank
- Verwende geplante Aktionen für wiederkehrende Aufgaben
- Richte E-Mail-Vorlagen für Konsistenz ein
- Überwache Workflow-Performance in n8n
- Dokumentiere Custom-Automatisierungen

**Verkaufsprozess:**
- Definiere klare Phasen-Kriterien
- Richte Aktivitätstypen für jede Phase ein
- Nutze Wahrscheinlichkeits-Scoring konsistent
- Konfiguriere E-Mail-Vorlagen
- Richte automatische Erinnerungen ein
- Verfolge KPIs in Dashboards

**Team-Zusammenarbeit:**
- Nutze interne Notizen für Team-Kommunikation
- Richte ordnungsgemäße Benachrichtigungsregeln ein
- Erstelle geteilte Dashboards
- Regelmäßiges Team-Training zu Odoo-Funktionen
- Dokumentiere unternehmensspezifische Prozesse
- Nutze Odoos integrierten Chat für schnelle Fragen

**Sicherheit:**
- Verwende API-Keys statt Passwörter
- Richte Zwei-Faktor-Authentifizierung ein
- Regelmäßige Sicherheitsupdates
- Begrenze externen API-Zugriff
- Überwache Benutzer-Aktivitätsprotokolle
- Regelmäßiger Passwort-Wechsel
