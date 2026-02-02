# 🌐 Browser-use - Browser-Steuerung

### Was ist Browser-use?

Browser-use ist ein LLM-gesteuertes Browser-Automatisierungstool, das dir ermöglicht, einen Webbrowser mit natürlichsprachlichen Anweisungen zu steuern. Im Gegensatz zu traditionellen Automatisierungstools, die explizite Programmierung erfordern, nutzt Browser-use große Sprachmodelle (GPT-4, Claude oder lokale Modelle via Ollama), um Befehle wie "Gehe zu LinkedIn und extrahiere die ersten 10 KI-Ingenieur-Profile in Berlin" zu interpretieren und autonom die notwendigen Browser-Aktionen auszuführen.

Browser-use läuft auf Browserless (einer zentralisierten Chrome/Chromium-Instanz) und bietet eine leistungsstarke Kombination für Web-Scraping, Formular-Ausfüllung, Datenextraktion und automatisiertes Testen.

### Funktionen

- **Natürlichsprachliche Steuerung** - Steuere Browser mit einfachen englischen Befehlen
- **LLM-gesteuert** - Nutzt GPT-4, Claude oder Ollama für intelligente Aufgabeninterpretation
- **Mehrstufige Workflows** - Führe komplexe Sequenzen von Browser-Aktionen aus
- **Datenextraktion** - Extrahiere strukturierte Daten automatisch von Websites
- **Formular-Automatisierung** - Fülle Formulare aus, klicke Buttons, navigiere Seiten
- **WebSocket-Verbindung** - Integriert mit Browserless für zuverlässigen Browser-Zugriff
- **Headless oder sichtbar** - Laufe im Headless-Modus oder beobachte Automatisierung in Echtzeit
- **Session-Verwaltung** - Handhabe Cookies, Authentifizierung und Zustand
- **Fehlerwiederherstellung** - LLM passt sich an Seitenänderungen an und behandelt Fehler elegant
- **Keine Selector-Entwicklung** - Keine Notwendigkeit, CSS-Selektoren oder XPaths zu schreiben

### Ersteinrichtung

**Browser-use läuft als Teil der Browser-Automatisierungs-Suite:**

Browser-use ist kein eigenständiger Dienst mit Web-UI. Stattdessen ist es eine Python-Bibliothek, die du in Docker-Containern oder n8n-Workflows ausführst. Es verbindet sich mit dem **Browserless**-Dienst für die eigentliche Browser-Steuerung.

**Voraussetzungen:**
1. **Browserless muss laufen** - Browser-use benötigt eine Browserless-WebSocket-Verbindung
2. **LLM API-Key** - OpenAI, Anthropic oder Groq API-Key (oder nutze Ollama für kostenlose lokale Modelle)
3. **Python-Umgebung** - Verfügbar via Python-Runner-Container oder benutzerdefinierte Docker-Ausführung

**LLM-Anbieter konfigurieren:**

Füge deinen API-Key zur `.env`-Datei hinzu:

```bash
# Für OpenAI (empfohlen für beste Ergebnisse)
OPENAI_API_KEY=sk-...

# Für Anthropic Claude
ANTHROPIC_API_KEY=sk-ant-...

# Für Groq (schnell, kostenloses Tier verfügbar)
GROQ_API_KEY=gsk_...

# Für Ollama (lokal, kein API-Key nötig)
ENABLE_OLLAMA=true
OLLAMA_BASE_URL=http://ollama:11434
```

**Browserless-Verbindung verifizieren:**

```bash
# Prüfe ob Browserless läuft
docker ps | grep browserless

# Teste WebSocket-Verbindung
curl http://localhost:3000/json/version

# Sollte Chrome-Versionsinformationen zurückgeben
```

### n8n Integration Setup

**Browser-use via Python Execute Node:**

Browser-use hat keine native n8n-Node. Nutze den **Execute Command** oder **Python Runner**, um Browser-use-Skripte auszuführen.

**Methode 1: Execute Command Node (Direkt)**

```javascript
// 1. Code Node - Aufgabe vorbereiten
const task = {
  command: "Gehe zu example.com und extrahiere alle Produktpreise",
  browserless_url: "ws://browserless:3000",
  model: "gpt-4o-mini"
};

return { json: task };

// 2. Execute Command Node
Command:
docker exec browser-use python3 -c "
from browser_use import Browser, Agent
import asyncio

async def main():
    browser = Browser(websocket_url='{{ $json.browserless_url }}')
    agent = Agent(browser=browser, model='{{ $json.model }}')
    result = await agent.execute('{{ $json.command }}')
    print(result)

asyncio.run(main())
"

// 3. Code Node - Ausgabe parsen
const output = $input.first().json.stdout;
return { json: JSON.parse(output) };
```

**Methode 2: Python-Skript-Datei (Empfohlen)**

Erstelle ein Python-Skript im `/shared`-Verzeichnis:

```python
# Datei: /shared/browser_automation.py
from browser_use import Browser, Agent
import asyncio
import sys
import json

async def main():
    task = sys.argv[1] if len(sys.argv) > 1 else "Daten extrahieren"
    
    browser = Browser(
        websocket_url="ws://browserless:3000",
        headless=True
    )
    
    agent = Agent(
        browser=browser,
        model="gpt-4o-mini",  # oder "claude-3-5-sonnet-20241022"
        # model="ollama/llama3.2" für lokal
    )
    
    result = await agent.execute(task)
    
    # Als JSON zurückgeben
    print(json.dumps(result))

if __name__ == "__main__":
    asyncio.run(main())
```

**n8n Workflow:**

```javascript
// 1. Webhook Trigger - Automatisierungsanfrage empfangen

// 2. Execute Command Node
Command: python3 /data/shared/browser_automation.py "{{ $json.task }}"
Working Directory: /data

// 3. Code Node - Ergebnisse verarbeiten
const output = JSON.parse($input.first().json.stdout);
return { 
  json: {
    success: true,
    data: output,
    timestamp: new Date().toISOString()
  }
};
```

**Interne URLs:**
- **Browserless WebSocket:** `ws://browserless:3000`
- **Browserless HTTP:** `http://browserless:3000` (zum Debuggen)

### Beispiel-Workflows

#### Beispiel 1: LinkedIn-Profil-Scraper

Profile von LinkedIn mit natürlicher Sprache extrahieren:

```python
# Speichern als /shared/linkedin_scraper.py
from browser_use import Browser, Agent
import asyncio
import json

async def scrape_linkedin(search_query, count=10):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="gpt-4o")
    
    task = f"""
    Gehe zu LinkedIn und suche nach '{search_query}'.
    Extrahiere die ersten {count} Profile inklusive:
    - Name
    - Berufsbezeichnung
    - Unternehmen
    - Standort
    - Profil-URL
    
    Gib als strukturiertes JSON zurück.
    """
    
    result = await agent.execute(task)
    return result

# Ausführen
result = asyncio.run(scrape_linkedin("KI-Ingenieure in Berlin", 10))
print(json.dumps(result, indent=2))
```

**n8n Integration:**

```javascript
// 1. Schedule Trigger - Täglich um 9 Uhr

// 2. Parameter setzen
const searchQuery = "Machine-Learning-Ingenieure in München";
const profileCount = 20;

// 3. Execute Command
Command: python3 /data/shared/linkedin_scraper.py

// 4. Code Node - Ergebnisse parsen
const profiles = JSON.parse($input.first().json.stdout);

// 5. Loop - Jedes Profil verarbeiten
// 6. Supabase Node - In Datenbank speichern
// 7. Email Node - Tägliche Zusammenfassung senden
```

#### Beispiel 2: E-Commerce Preis-Monitor

Wettbewerberpreise automatisch überwachen:

```python
# Speichern als /shared/price_monitor.py
from browser_use import Browser, Agent
import asyncio

async def monitor_prices(competitor_urls):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="gpt-4o-mini")
    
    results = []
    for url in competitor_urls:
        task = f"""
        Navigiere zu {url}
        Finde den Produktpreis
        Extrahiere: Produktname, aktueller Preis, Währung
        Prüfe ob es ein Rabatt- oder Sale-Banner gibt
        """
        
        result = await agent.execute(task)
        results.append(result)
    
    return results

# Verwendung
urls = [
    "https://competitor1.com/product-a",
    "https://competitor2.com/product-a"
]

prices = asyncio.run(monitor_prices(urls))
print(prices)
```

**n8n Workflow:**

```javascript
// 1. Schedule Trigger - Alle 6 Stunden

// 2. HTTP Request - Wettbewerber-URLs aus Datenbank holen

// 3. Loop - Für jede URL

// 4. Execute Command
Command: python3 /data/shared/price_monitor.py

// 5. Code Node - Mit gestrigen Preisen vergleichen
const today = $json.price;
const yesterday = $('Database').item.json.last_price;

if (today < yesterday) {
  return {
    json: {
      alert: true,
      product: $json.product_name,
      price_drop: yesterday - today,
      url: $json.url
    }
  };
}

// 6. IF Node - Preis gefallen?
// 7. Alert-E-Mail senden
// 8. Datenbank aktualisieren
```

#### Beispiel 3: Formular-Ausfüllung-Automatisierung

Formulare automatisch über mehrere Websites ausfüllen:

```python
# Speichern als /shared/form_filler.py
from browser_use import Browser, Agent
import asyncio

async def fill_form(url, form_data):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="claude-3-5-sonnet-20241022")
    
    task = f"""
    Navigiere zu {url}
    Fülle das Formular mit diesen Informationen aus:
    - Name: {form_data['name']}
    - E-Mail: {form_data['email']}
    - Unternehmen: {form_data['company']}
    - Nachricht: {form_data['message']}
    
    Sende das Formular ab
    Warte auf Bestätigungsnachricht
    Gib zurück: Erfolgsstatus und Bestätigungstext
    """
    
    result = await agent.execute(task)
    return result

# Verwendung
data = {
    "name": "Max Mustermann",
    "email": "max@beispiel.de",
    "company": "Acme GmbH",
    "message": "Interessiert an Ihren Dienstleistungen"
}

result = asyncio.run(fill_form("https://example.com/kontakt", data))
print(result)
```

#### Beispiel 4: Recherche & Datensammlung

Informationen aus mehreren Quellen sammeln:

```python
# Speichern als /shared/research_agent.py
from browser_use import Browser, Agent
import asyncio

async def research_topic(topic, sources):
    browser = Browser(websocket_url="ws://browserless:3000")
    agent = Agent(browser=browser, model="gpt-4o")
    
    task = f"""
    Recherchiere das Thema: {topic}
    
    Besuche diese Quellen:
    {', '.join(sources)}
    
    Für jede Quelle:
    1. Extrahiere Schlüsselinformationen
    2. Identifiziere Hauptargumente
    3. Finde Statistiken oder Datenpunkte
    
    Erstelle eine umfassende Zusammenfassung mit Zitaten.
    """
    
    result = await agent.execute(task)
    return result

# Verwendung
topic = "Auswirkungen von KI auf Beschäftigung 2025"
sources = [
    "https://www.mckinsey.com",
    "https://www.weforum.org",
    "https://news.ycombinator.com"
]

research = asyncio.run(research_topic(topic, sources))
print(research)
```

### Fehlerbehebung

**Keine Verbindung zu Browserless:**

```bash
# 1. Prüfe ob Browserless läuft
docker ps | grep browserless
# Sollte browserless Container auf Port 3000 zeigen

# 2. Teste WebSocket-Verbindung
curl http://localhost:3000/json/version

# 3. Prüfe Browser-use Container-Logs
docker logs browser-use --tail 50

# 4. Verifiziere Netzwerkverbindung
docker exec browser-use ping browserless
# Sollte Antworten erhalten

# 5. Neustarten falls nötig
docker compose restart browserless browser-use
```

**LLM versteht Aufgaben nicht:**

```bash
# 1. Nutze spezifischere Anweisungen
# Schlecht:  "Hole Daten von Website"
# Gut: "Navigiere zu example.com, finde die Preistabelle, extrahiere alle Plan-Namen und Preise"

# 2. Wechsle zu besserem Modell
# GPT-4o > GPT-4o-mini > Claude > Ollama (für Genauigkeit)

# 3. Teile komplexe Aufgaben in Schritte auf
# Statt einer langen Aufgabe, erstelle mehrere kleinere agent.execute()-Aufrufe

# 4. Füge explizite Wartezeiten hinzu
task = "Gehe zur URL, warte 3 Sekunden auf Seitenladevorgang, dann extrahiere Daten"
```

**Session/Cookie-Probleme:**

```python
# Cookies für authentifizierte Sitzungen speichern
from browser_use import Browser, Agent

browser = Browser(
    websocket_url="ws://browserless:3000",
    persistent_context=True  # Behält Cookies zwischen Durchläufen
)

# Erster Durchlauf: Login
agent = Agent(browser=browser, model="gpt-4o")
await agent.execute("Melde dich bei example.com mit Benutzername X und Passwort Y an")

# Zweiter Durchlauf: Authentifizierte Aktion (Cookies erhalten)
await agent.execute("Navigiere zum Dashboard und extrahiere Benutzerdaten")
```

**Langsame Ausführung:**

```bash
# 1. Wechsle zu schnelleren Modellen
# Groq (llama-3.1-70b) - Sehr schnell
# GPT-4o-mini - Ausgewogen
# GPT-4o - Langsam aber genau

# 2. Aktiviere Headless-Modus
browser = Browser(websocket_url="ws://browserless:3000", headless=True)

# 3. Erhöhe Browserless-Concurrent-Limit
# In .env-Datei:
BROWSERLESS_CONCURRENT=5  # Erlaube mehr parallele Sitzungen

# 4. Nutze einfachere Selektoren in Anweisungen
# "Klicke den roten Button" vs "Klicke den Button mit Klasse .primary-btn-submit"
```

**Out-of-Memory-Fehler:**

```bash
# 1. Prüfe Container-Ressourcen
docker stats browserless browser-use

# 2. Limitiere gleichzeitige Sitzungen
# Reduziere BROWSERLESS_CONCURRENT in .env

# 3. Schließe Browser nach Verwendung
await browser.close()

# 4. Erhöhe Container-Speicher
# In docker-compose.yml:
deploy:
  resources:
    limits:
      memory: 4G  # Von Standard erhöhen
```

### Konfigurationsoptionen

**LLM-Modelle (nach Genauigkeit geordnet):**

1. **GPT-4o** - Beste Genauigkeit, langsamer, teurer
2. **Claude 3.5 Sonnet** - Exzellentes Reasoning, gut für komplexe Aufgaben
3. **GPT-4o-mini** - Ausgewogene Geschwindigkeit und Genauigkeit
4. **Groq (llama-3.1-70b)** - Sehr schnell, gut für einfache Aufgaben
5. **Ollama (llama3.2)** - Lokal, kostenlos, niedrigere Genauigkeit

**Browser-Konfiguration:**

```python
browser = Browser(
    websocket_url="ws://browserless:3000",
    headless=True,           # Keine GUI (schneller)
    persistent_context=True, # Cookies/Sessions behalten
    timeout=60000,          # 60 Sekunden Timeout
    viewport={"width": 1920, "height": 1080}
)
```

**Agenten-Konfiguration:**

```python
agent = Agent(
    browser=browser,
    model="gpt-4o-mini",
    max_actions=50,          # Max Schritte vor Aufgabe
    verbose=True,            # Alle Aktionen loggen
    screenshot_on_error=True # Screenshot speichern bei Fehler
)
```

### Integration mit AI CoreKit Diensten

**Browser-use + Qdrant:**
- Scrape Websites und speichere Embeddings in Qdrant
- Baue durchsuchbare Wissensdatenbank aus Web-Daten

**Browser-use + Supabase:**
- Speichere gescrapte Daten in Supabase-Datenbank
- Verfolge Scraping-Jobs und Ergebnisse

**Browser-use + n8n:**
- Plane wiederkehrende Scraping-Jobs
- Löse Browser-Automatisierung von Webhooks aus
- Verkette Browser-Aufgaben mit anderen n8n-Nodes

**Browser-use + Ollama:**
- Nutze lokale LLMs für Browser-Steuerung (kostenlos!)
- Keine API-Kosten für Entwicklung/Testing
- Datenschutzfokussierte Automatisierung

**Browser-use + Flowise/Dify:**
- Integriere Browser-Automatisierung in KI-Agenten
- Agenten können Web durchsuchen und Daten on-demand extrahieren

### Ressourcen

- **GitHub:** https://github.com/browser-use/browser-use
- **Dokumentation:** https://docs.browser-use.com/
- **Python SDK:** `pip install browser-use`
- **Beispiele:** https://github.com/browser-use/browser-use/tree/main/examples
- **Community:** Discord (Link im GitHub README)
- **Browserless Docs:** https://www.browserless.io/docs

### Best Practices

**Aufgabenschreiben:**
- Sei spezifisch: "Extrahiere Produktpreise" → "Extrahiere alle Preise aus der Preistabelle mit Plan-Namen"
- Füge Wartebedingungen hinzu: "Warte bis Seite vollständig geladen ist, bevor extrahiert wird"
- Spezifiziere Ausgabeformat: "Gib als JSON zurück mit Feldern: Name, Preis, URL"

**Fehlerbehandlung:**
- Nutze immer try/except in Python-Skripten
- Setze vernünftige Timeouts (30-60 Sekunden)
- Logge alle Aktionen zum Debuggen
- Speichere Screenshots bei Fehlern

**Performance:**
- Nutze Headless-Modus für Produktion
- Schließe Browser nach Abschluss der Aufgaben
- Limitiere gleichzeitige Sitzungen basierend auf Server-Ressourcen
- Cache Ergebnisse wenn möglich

**Sicherheit:**
- Hardcode niemals Zugangsdaten in Skripten
- Speichere API-Keys in Umgebungsvariablen
- Sei respektvoll gegenüber Websites (überlade nicht mit Anfragen)
- Befolge robots.txt und Nutzungsbedingungen


---

# 👁️ Skyvern - Vision-Automatisierung

### Was ist Skyvern?

Skyvern ist eine KI-gesteuerte Browser-Automatisierungsplattform, die Computer Vision und große Sprachmodelle nutzt, um mit Websites zu interagieren, ohne vordefinierte Selektoren oder Skripte zu benötigen. Im Gegensatz zu traditionellen Automatisierungstools, die brechen, wenn Websites ihre HTML-Struktur ändern, "sieht" Skyvern Webseiten wie ein Mensch und passt sich automatisch an Layout-Änderungen an. Dies macht es ideal für die Automatisierung komplexer Workflows auf dynamischen Websites, CAPTCHA-Behandlung und Navigation auf Sites, die schwer zu skripten sind.

Skyvern läuft auf Browserless und ist für Aufgaben konzipiert, bei denen traditionelle Automatisierung versagt: visuelle Verifizierung, dynamische Inhalte, Anti-Bot-Erkennung und Workflows, die Kontextverständnis statt nur vordefinierte Pfade erfordern.

### Funktionen

- **Computer-Vision-basiert** - Nutzt KI-Vision um Webseiten visuell zu verstehen, keine CSS-Selektoren nötig
- **Selbstheilende Automatisierung** - Passt sich automatisch an Website-Änderungen an, keine Skript-Wartung
- **CAPTCHA-Behandlung** - Kann visuelle CAPTCHAs lösen und Anti-Bot-Schutz navigieren
- **Natürlichsprachliche Ziele** - Definiere Automatisierungsaufgaben in einfachem Englisch
- **Mehrstufige Workflows** - Führe komplexe Sequenzen mit Verzweigungslogik aus
- **Datenextraktion** - Extrahiere strukturierte Daten aus visuell komplexen Layouts
- **Formular-Ausfüllung** - Fülle Formulare intelligent basierend auf Feldbezeichnungen und Kontext aus
- **Screenshot-Validierung** - Visuelle Verifizierung der Aufgabenvollendung
- **Proxy-Unterstützung** - Rotiere IPs und verwalte Session-Isolation
- **Webhook-Callbacks** - Echtzeit-Aktualisierungen des Aufgabenstatus

### Ersteinrichtung

**Skyvern läuft als Teil der Browser-Automatisierungs-Suite:**

Skyvern ist kein eigenständiger Dienst mit Web-UI. Es ist ein API-Dienst, den du von n8n-Workflows oder anderen Anwendungen aufrufst. Es verbindet sich mit **Browserless** für Browser-Steuerung.

**Voraussetzungen:**
1. **Browserless muss laufen** - Skyvern benötigt Browserless für Browser-Automatisierung
2. **API-Key konfiguriert** - Wird während Installation in `.env`-Datei gesetzt

**Setup verifizieren:**

```bash
# Prüfe ob Skyvern läuft
docker ps | grep skyvern
# Sollte skyvern Container auf Port 8000 zeigen

# Prüfe Browserless-Verbindung
docker exec skyvern curl http://browserless:3000/json/version

# Teste API-Endpoint
curl http://localhost:8000/v1/health
```

**API-Key holen:**

Dein Skyvern API-Key wird automatisch während der Installation generiert und in `.env` gespeichert:

```bash
# Zeige deinen API-Key
grep SKYVERN_API_KEY .env
```

### n8n Integration Setup

**HTTP-Request-Nodes verwenden:**

Skyvern hat keine native n8n-Node. Nutze **HTTP-Request**-Nodes zur Interaktion mit der Skyvern-API.

**Skyvern-Credentials in n8n erstellen:**

1. Erstelle in n8n Credentials:
   - Typ: **Header Auth**
   - Name: **Skyvern API**
   - Header-Name: `X-API-Key`
   - Header-Wert: Dein `SKYVERN_API_KEY` aus `.env`

**Interne URL:** `http://skyvern:8000`

**API-Endpoints:**
- Aufgabe ausführen: `POST /v1/execute`
- Aufgabenstatus abrufen: `GET /v1/tasks/{task_id}`
- Aufgabenergebnis abrufen: `GET /v1/tasks/{task_id}/result`
- Aufgaben auflisten: `GET /v1/tasks`

### Beispiel-Workflows

#### Beispiel 1: Formular-Automatisierung mit visueller Intelligenz

Komplexe Formulare auf jeder Website automatisch ausfüllen:

```javascript
// Intelligentes Formular-Ausfüllen, das sich an verschiedene Layouts anpasst

// 1. Webhook Trigger - Formular-Einreichungsanfrage empfangen

// 2. Code Node - Aufgabe vorbereiten
const taskData = {
  url: $json.target_url || "https://example.com/kontaktformular",
  navigation_goal: "Fülle das Kontaktformular mit den bereitgestellten Informationen aus und sende es ab",
  data: {
    name: $json.customer_name || "Max Mustermann",
    email: $json.customer_email || "max@beispiel.de",
    company: $json.company_name || "Acme GmbH",
    phone: $json.phone || "+49 123 456789",
    message: $json.message || "Ich bin an Ihren Dienstleistungen interessiert"
  },
  wait_for: "Vielen Dank für Ihre Nachricht",  // Warte auf diesen Text
  timeout: 60000,  // 60 Sekunden
  screenshot: true  // Screenshot nach Abschluss machen
};

return { json: taskData };

// 3. HTTP Request - Skyvern-Aufgabe ausführen
Methode: POST
URL: http://skyvern:8000/v1/execute
Authentication: Skyvern API (Header Auth)
Body:
{
  "url": "{{ $json.url }}",
  "navigation_goal": "{{ $json.navigation_goal }}",
  "data": {{ $json.data }},
  "wait_for": "{{ $json.wait_for }}",
  "timeout": {{ $json.timeout }},
  "screenshot": {{ $json.screenshot }}
}

// 4. Set Variable - Task ID speichern
task_id: {{ $json.task_id }}

// 5. Wait - Initiale Verarbeitungszeit
Betrag: 5 Sekunden

// 6. Loop - Auf Abschluss pollen (max 12 Mal = 60 Sekunden)
For: 12 Iterationen

// 7. HTTP Request - Status prüfen
Methode: GET
URL: http://skyvern:8000/v1/tasks/{{ $('Set Variable').item.json.task_id }}
Authentication: Skyvern API

// 8. IF Node - Prüfe ob abgeschlossen
Bedingung: {{ $json.status }} === "completed"

// Branch: Abgeschlossen
// 9a. HTTP Request - Ergebnisse abrufen
Methode: GET
URL: http://skyvern:8000/v1/tasks/{{ $('Set Variable').item.json.task_id }}/result

// 10a. Code Node - Ergebnisse verarbeiten
const result = $json;

return {
  json: {
    success: result.success,
    url: result.final_url,
    screenshot_url: result.screenshot_url,
    extracted_data: result.extracted_data,
    execution_time: result.execution_time_ms
  }
};

// 11a. Email Node - Erfolgsbenachrichtigung senden

// Branch: Nicht abgeschlossen
// 9b. Wait - 5 Sekunden vor nächstem Poll
// 10b. Loop fortsetzen

// Branch: Fehlgeschlagen/Timeout
// 9c. Error Handler - Loggen und benachrichtigen
```

#### Beispiel 2: Datenextraktion von dynamischen Websites

Produktinformationen von E-Commerce-Sites extrahieren:

```javascript
// Extrahiere strukturierte Daten von visuell komplexen Seiten

// 1. Schedule Trigger - Täglich um 6 Uhr

// 2. Spreadsheet/Database - Wettbewerber-URLs laden
// Liste von Produktseiten zum Scrapen lesen

// 3. Loop - Für jede URL

// 4. HTTP Request - Skyvern-Extraktion ausführen
Methode: POST
URL: http://skyvern:8000/v1/execute
Authentication: Skyvern API
Body:
{
  "url": "{{ $json.product_url }}",
  "navigation_goal": "Extrahiere alle Produktinformationen inklusive Name, Preis, Beschreibung, Spezifikationen, Verfügbarkeit und Kundenbewertungen",
  "data_extraction": {
    "product_name": "text",
    "current_price": "number",
    "original_price": "number",
    "currency": "text",
    "in_stock": "boolean",
    "product_description": "text",
    "specifications": "object",
    "rating": "number",
    "review_count": "number",
    "image_urls": "array"
  },
  "screenshot": true,
  "timeout": 90000
}

// 5. Wait - Verarbeitungszeit
Betrag: 10 Sekunden

// 6. HTTP Request - Ergebnisse abrufen
Methode: GET
URL: http://skyvern:8000/v1/tasks/{{ $('Execute Skyvern').json.task_id }}/result

// 7. Code Node - Daten strukturieren
const extracted = $json.extracted_data;
const product = {
  url: $('Loop').item.json.product_url,
  name: extracted.product_name,
  current_price: extracted.current_price,
  original_price: extracted.original_price,
  discount_percentage: extracted.original_price > 0 
    ? ((extracted.original_price - extracted.current_price) / extracted.original_price * 100).toFixed(2)
    : 0,
  in_stock: extracted.in_stock,
  rating: extracted.rating,
  review_count: extracted.review_count,
  scraped_at: new Date().toISOString(),
  screenshot: $json.screenshot_url
};

return { json: product };

// 8. Supabase/Database Node - Daten speichern

// 9. IF Node - Preis gefallen?
Bedingung: {{ $json.discount_percentage }} > 20

// 10. Alert senden - Signifikanter Rabatt gefunden
```

#### Beispiel 3: CAPTCHA-Lösung & Anti-Bot-Navigation

Geschützte Sites navigieren und CAPTCHAs lösen:

```javascript
// Skyvern kann visuelle CAPTCHAs automatisch behandeln

// 1. Webhook Trigger - Automatisierungsanfrage

// 2. HTTP Request - Geschützte Site navigieren
Methode: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "url": "https://geschuetzte-site.de/login",
  "navigation_goal": "Melde dich auf der Website mit den bereitgestellten Zugangsdaten an, löse jedes CAPTCHA falls vorhanden, und navigiere zum Dashboard",
  "data": {
    "username": "{{ $json.username }}",
    "password": "{{ $json.password }}"
  },
  "handle_captcha": true,
  "wait_for": "Dashboard",
  "timeout": 120000,  // 2 Minuten für CAPTCHA
  "screenshot": true
}

// 3. Wait & Poll auf Abschluss (ähnlich zu Beispiel 1)

// 4. IF Node - Login-Erfolg prüfen
Bedingung: {{ $json.success }} === true

// Branch: Erfolg
// 5a. HTTP Request - Post-Login-Aktionen ausführen
Methode: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "session_id": "{{ $('Login').json.session_id }}",  // Dieselbe Session fortsetzen
  "navigation_goal": "Navigiere zum Berichts-Bereich und lade den neuesten Monatsbericht herunter",
  "timeout": 60000
}

// 6a. Bericht herunterladen und verarbeiten

// Branch: Fehlgeschlagen
// 5b. Retry Node - Erneut versuchen (max 3 Versuche)
// 6b. Admin benachrichtigen falls alle Versuche fehlschlagen
```

#### Beispiel 4: Mehrstufiger Kaufablauf

Vollständige Checkout-Prozesse automatisieren:

```javascript
// Komplexe mehrseitige Workflows mit Entscheidungslogik

// 1. Webhook Trigger - Bestellung empfangen

// 2. HTTP Request - Shopping-Flow starten
Methode: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "url": "https://lieferanten-website.de",
  "navigation_goal": "Suche nach Produkt '{{ $json.product_sku }}', füge es mit Menge {{ $json.quantity }} zum Warenkorb hinzu, gehe zur Kasse",
  "data": {
    "search_term": "{{ $json.product_sku }}",
    "quantity": {{ $json.quantity }}
  },
  "wait_for": "Warenkorb",
  "screenshot": true
}

// 3. Wait & Poll

// 4. HTTP Request - Checkout abschließen
Methode: POST
URL: http://skyvern:8000/v1/execute
Body:
{
  "session_id": "{{ $('Start Shopping').json.session_id }}",
  "navigation_goal": "Schließe Checkout mit bereitgestellten Rechnungs- und Versandinformationen ab, wähle Standard-Versand, und bestätige Bestellung",
  "data": {
    "billing_name": "{{ $json.billing_name }}",
    "billing_address": "{{ $json.billing_address }}",
    "billing_city": "{{ $json.billing_city }}",
    "billing_zip": "{{ $json.billing_zip }}",
    "card_number": "{{ $json.card_number }}",
    "card_expiry": "{{ $json.card_expiry }}",
    "card_cvv": "{{ $json.card_cvv }}"
  },
  "wait_for": "Bestellung bestätigt",
  "extract": {
    "order_number": "text",
    "order_total": "number",
    "estimated_delivery": "date"
  }
}

// 5. Bestelldetails in Datenbank speichern

// 6. Bestätigungs-E-Mail mit Bestellnummer senden
```

### Aufgabenkonfigurationsoptionen

**Basis-Aufgabe:**
```json
{
  "url": "https://example.com",
  "navigation_goal": "Was zu erreichen ist",
  "timeout": 60000
}
```

**Erweiterte Aufgabe mit Daten:**
```json
{
  "url": "https://example.com/formular",
  "navigation_goal": "Formular ausfüllen und absenden",
  "data": {
    "field1": "wert1",
    "field2": "wert2"
  },
  "wait_for": "Erfolgsnachricht",
  "screenshot": true,
  "handle_captcha": true,
  "extract": {
    "confirmation_number": "text",
    "status": "text"
  },
  "timeout": 120000
}
```

**Session-Fortsetzung:**
```json
{
  "session_id": "vorherige_aufgaben_session_id",
  "navigation_goal": "Vorherige Session fortsetzen und X tun",
  "timeout": 60000
}
```

### Fehlerbehebung

**Aufgabe-Timeout oder Fehler:**

```bash
# 1. Skyvern-Logs prüfen
docker logs skyvern --tail 100

# 2. Browserless-Verbindung verifizieren
docker exec skyvern curl http://browserless:3000/json/version

# 3. Timeout für komplexe Aufgaben erhöhen
# Im Aufgaben-Body: "timeout": 180000  (3 Minuten)

# 4. Prüfe ob Website Anti-Bot-Schutz hat
# Einige Sites können Headless-Browser blockieren
# Versuche mit "stealth_mode": true in Aufgabe

# 5. Teste Aufgabe manuell zuerst
curl -X POST http://localhost:8000/v1/execute \
  -H "X-API-Key: DEIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "navigation_goal": "Test-Aufgabe",
    "screenshot": true
  }'
```

**CAPTCHA löst sich nicht:**

```bash
# 1. Stelle sicher handle_captcha aktiviert ist
"handle_captcha": true

# 2. Erhöhe Timeout (CAPTCHAs dauern länger)
"timeout": 120000  # 2 Minuten minimum

# 3. Prüfe CAPTCHA-Typ-Unterstützung
# Skyvern behandelt:
# - reCAPTCHA v2 (Bildauswahl)
# - hCaptcha
# - Basis-Bild-CAPTCHAs
# 
# Behandelt NICHT:
# - reCAPTCHA v3 (unsichtbar, score-basiert)
# - Audio-CAPTCHAs

# 4. Einige Sites nutzen erweiterte Bot-Erkennung
# Erwäge Nutzung von Residential-Proxies falls verfügbar
```

**Datenextraktion unvollständig:**

```bash
# 1. Sei spezifisch in navigation_goal
# Schlecht:  "Extrahiere Produktinfo"
# Gut: "Extrahiere Produktname, Preis aus Preis-Bereich, Beschreibung aus Übersichts-Tab, und Kundenbewertung"

# 2. Definiere Extraktions-Schema
"extract": {
  "product_name": "text",
  "price": "number",
  "in_stock": "boolean"
}

# 3. Füge Wartebedingungen hinzu
"wait_for": "Preis geladen"  # Warte auf dynamischen Inhalt

# 4. Mache Screenshots zum Debuggen
"screenshot": true
# Prüfe Screenshot im Aufgabenergebnis um zu sehen, was Skyvern sieht
```

**Hohe Ressourcennutzung:**

```bash
# 1. Prüfe gleichzeitige Aufgaben
docker stats skyvern browserless

# 2. Limitiere gleichzeitige Ausführungen
# In .env-Datei:
BROWSERLESS_CONCURRENT=3  # Von Standard 10 reduzieren

# 3. Reduziere Screenshot-Qualität/Häufigkeit
# Aktiviere Screenshots nur beim Debuggen

# 4. Räume alte Sessions auf
curl -X DELETE http://localhost:8000/v1/tasks/old  # Alte Aufgabendaten löschen
```

### Best Practices

**Aufgaben-Design:**
- **Sei spezifisch:** "Klicke den blauen 'Absenden'-Button unten rechts" vs "Formular absenden"
- **Füge Kontext hinzu:** Füge visuelle Beschreibungen für komplexe Seiten hinzu
- **Setze realistische Timeouts:** 60s für einfache Aufgaben, 120s+ für komplexe Flows
- **Nutze wait_for:** Spezifiziere Text/Elemente, die Aufgabenvollendung anzeigen

**Datenextraktion:**
- Definiere klares Extraktions-Schema mit Feldtypen
- Nutze beschreibende Feldnamen passend zu sichtbaren Labels
- Extrahiere aus spezifischen Seitenbereichen für Genauigkeit
- Validiere extrahierte Daten vor Weiterverarbeitung

**Fehlerbehandlung:**
- Implementiere immer Polling für Aufgabenstatus
- Setze maximale Wiederholungsversuche
- Speichere Screenshots bei Fehlern zum Debuggen
- Logge Task-IDs zur Fehlerbehebung

**Performance:**
- Wiederverwendung von Sessions für mehrstufige Workflows
- Deaktiviere Screenshots in Produktion (schneller)
- Batch ähnliche Aufgaben zusammen
- Überwache Browserless-Ressourcennutzung

**Sicherheit:**
- Logge niemals Zugangsdaten in Aufgabenbeschreibungen
- Speichere API-Keys sicher in Umgebungsvariablen
- Nutze separate API-Keys pro Umgebung
- Rotiere API-Keys regelmäßig

### Integration mit AI CoreKit Diensten

**Skyvern + Browser-use:**
- Nutze Skyvern für komplexe visuelle Aufgaben (CAPTCHAs, dynamische Inhalte)
- Nutze Browser-use für einfachere geskriptete Automatisierung
- Kombiniere beide für robuste Automatisierungs-Pipelines

**Skyvern + Supabase:**
- Speichere gescrapte Daten in Supabase-Datenbank
- Verfolge Aufgabenverlauf und Ergebnisse
- Baue Dashboards für Monitoring

**Skyvern + n8n:**
- Plane wiederkehrende Automatisierungsaufgaben
- Verkette Skyvern mit Datenverarbeitungs-Workflows
- Implementiere Retry-Logik und Fehlerbehandlung

**Skyvern + Flowise/Dify:**
- KI-Agenten können Skyvern für Web-Interaktionen auslösen
- Extrahiere Daten für RAG-Wissensdatenbanken
- Automatisiere Recherche und Datensammlung

### Ressourcen

- **Offizielle Website:** https://www.skyvern.com/
- **Dokumentation:** https://docs.skyvern.com/
- **GitHub:** https://github.com/Skyvern-AI/skyvern
- **API-Referenz:** https://docs.skyvern.com/api-reference
- **Community:** Discord (Link auf Website)
- **Beispiele:** https://github.com/Skyvern-AI/skyvern/tree/main/examples

### Wann Skyvern nutzen

**Nutze Skyvern für:**
- ✅ Websites, die häufig ihr Layout ändern
- ✅ Komplexe Formulare mit bedingten Feldern
- ✅ Sites mit CAPTCHA-Schutz
- ✅ Visuelle Verifizierungsaufgaben
- ✅ Datenextraktion aus komplexen Layouts
- ✅ Mehrstufige Workflows mit Verzweigungslogik
- ✅ Sites mit Anti-Bot-Schutz

**Nutze stattdessen Browser-use für:**
- ❌ Einfache, stabile Websites
- ❌ Wenn schnellste Ausführung benötigt wird
- ❌ Wenn Website-Struktur konsistent ist
- ❌ Basis-Formular-Ausfüllung ohne CAPTCHAs
- ❌ Wenn Kosten primäres Anliegen sind (Skyvern nutzt mehr Ressourcen)

**Nutze traditionelles Puppeteer/Selenium für:**
- ❌ Hochvolumen-Automatisierung (1000+ Durchläufe/Tag)
- ❌ Wenn vollständige Website-Dokumentation vorhanden
- ❌ Performance-kritische Anwendungen
- ❌ Wenn sich Websites nie ändern


---

# 🖥️ Browserless - Headless Chrome

### Was ist Browserless?

Browserless ist ein Headless-Chrome/Chromium-Dienst, der eine zentralisierte, skalierbare Browser-Laufzeitumgebung für Automatisierungstools bereitstellt. Anstatt dass jedes Tool seine eigenen Browser-Instanzen verwaltet, fungiert Browserless als gemeinsamer "Browser-Hub", mit dem sich mehrere Dienste (Browser-use, Skyvern, Puppeteer, Playwright) via WebSocket verbinden. Diese Architektur bietet bessere Ressourcenverwaltung, gleichzeitiges Session-Handling und vereinfachtes Browser-Lifecycle-Management.

Betrachte Browserless als den "Browser-Maschinenraum" deiner Automatisierungsinfrastruktur - es handhabt die gesamte Komplexität des Betriebs von Chrome-Instanzen, während andere Tools sich auf ihre spezifische Automatisierungslogik konzentrieren.

### Funktionen

- **Zentralisierte Chrome-Laufzeit** - Ein Dienst verwaltet alle Browser-Instanzen
- **WebSocket-API** - Saubere Schnittstelle für Puppeteer/Playwright-Verbindungen
- **Gleichzeitige Sessions** - Handhabe 10+ parallele Browser-Sitzungen
- **Ressourcenverwaltung** - Automatische Bereinigung und Speicherlimits
- **HTTP-APIs** - REST-Endpoints für Screenshots, PDFs und Inhalte
- **Session-Aufzeichnung** - Debug mit Video-Aufzeichnungen von Automatisierungsläufen
- **Stealth-Modus** - Umgehung von Anti-Bot-Erkennung
- **Proxy-Unterstützung** - Leite Browser-Traffic durch Proxies
- **Container-Isolation** - Jede Session läuft in isolierter Umgebung
- **Gesundheits-Monitoring** - Integrierte Health-Checks und Metriken

### Ersteinrichtung

**Browserless läuft automatisch mit der Browser-Automatisierungs-Suite:**

Browserless hat keine Web-UI - es ist ein Backend-Dienst, mit dem sich andere Tools verbinden. Es startet automatisch, wenn du Browser-use oder Skyvern installierst.

**Setup verifizieren:**

```bash
# Prüfe ob Browserless läuft
docker ps | grep browserless
# Sollte browserless Container auf Port 3000 zeigen

# Teste HTTP-Endpoint
curl http://localhost:3000/json/version
# Sollte Chrome-Versionsinformationen zurückgeben

# Prüfe WebSocket-Gesundheit
curl http://localhost:3000/pressure
# Zeigt aktuelle Session-Last
```

**Konfiguration:**

Browserless wird via Umgebungsvariablen in `.env` konfiguriert:

```bash
# Zeige Browserless-Einstellungen
grep BROWSERLESS .env

# Schlüssel-Einstellungen:
BROWSERLESS_CONCURRENT=10        # Max gleichzeitige Sessions
BROWSERLESS_TIMEOUT=30000       # Session-Timeout (ms)
BROWSERLESS_DEBUGGER=false      # Chrome DevTools aktivieren
BROWSERLESS_TOKEN=dein_token    # Authentifizierungs-Token
```

### Interner Zugriff

**WebSocket-URL (für Automatisierungstools):**
```
ws://browserless:3000
```

**Mit Authentifizierung:**
```
ws://browserless:3000?token=DEIN_TOKEN
```

**HTTP-API Base-URL:**
```
http://browserless:3000
```

### n8n Integration Setup

Browserless wird primär durch andere Tools (Browser-use, Skyvern) genutzt, aber du kannst es auch direkt mit Puppeteer-Nodes verwenden.

**Methode 1: Puppeteer Community Node**

1. Community-Node installieren:
   - Gehe zu n8n Einstellungen → **Community Nodes**
   - Suche: `n8n-nodes-puppeteer`
   - Klicke **Install**
   - Starte n8n neu: `docker compose restart n8n`

2. Puppeteer-Node konfigurieren:
   ```javascript
   // In Puppeteer-Node-Einstellungen:
   WebSocket URL: ws://browserless:3000
   Executable Pfad: (leer lassen)
   Launch Options:
   {
     "headless": true,
     "args": [
       "--no-sandbox",
       "--disable-setuid-sandbox",
       "--disable-dev-shm-usage"
     ]
   }
   ```

**Methode 2: HTTP-API (Direkt)**

Nutze HTTP-Request-Nodes um Browserless-APIs aufzurufen:

```javascript
// Screenshot-API
Methode: POST
URL: http://browserless:3000/screenshot
Header:
  Content-Type: application/json
Body:
{
  "url": "https://example.com",
  "options": {
    "fullPage": true,
    "type": "png"
  }
}

// PDF-API
Methode: POST
URL: http://browserless:3000/pdf
Body:
{
  "url": "https://example.com",
  "options": {
    "format": "A4",
    "printBackground": true
  }
}

// Content-API (HTML-Extraktion)
Methode: POST
URL: http://browserless:3000/content
Body:
{
  "url": "https://example.com",
  "waitForSelector": ".main-content"
}
```

### Beispiel-Workflows

#### Beispiel 1: Massen-Screenshot-Generierung

Screenshots von mehreren Websites generieren:

```javascript
// Effizienter Massen-Screenshot-Workflow

// 1. Spreadsheet Node - URLs laden
// Tabelle mit Spalten: url, name

// 2. Loop Over Items

// 3. HTTP Request - Screenshot generieren
Methode: POST
URL: http://browserless:3000/screenshot
Header:
  Content-Type: application/json
Body:
{
  "url": "{{ $json.url }}",
  "options": {
    "fullPage": true,
    "type": "png",
    "quality": 90
  },
  "gotoOptions": {
    "waitUntil": "networkidle2",
    "timeout": 30000
  }
}
Response Format: File

// 4. Move Binary - Screenshot umbenennen
From Property: data
To Property: screenshot
New File Name: {{ $json.name }}_{{ $now.format('YYYY-MM-DD') }}.png

// 5. Google Drive Node - Hochladen
Operation: Upload
File: {{ $binary.screenshot }}
Folder: Website Screenshots
Name: {{ $json.name }}.png

// 6. Supabase Node - Metadaten speichern
Table: screenshots
Daten:
  website: {{ $json.url }}
  name: {{ $json.name }}
  screenshot_url: {{ $('Google Drive').json.webViewLink }}
  created_at: {{ $now.toISO() }}
```

#### Beispiel 2: PDF-Berichtsgenerierung

Webseiten in professionelle PDFs konvertieren:

```javascript
// PDF-Berichte aus Webseiten generieren

// 1. Webhook Trigger - Berichtsanfrage empfangen
// Payload: { "url": "https://example.com/bericht", "filename": "monatsbericht" }

// 2. HTTP Request - PDF generieren
Methode: POST
URL: http://browserless:3000/pdf
Header:
  Content-Type: application/json
Body:
{
  "url": "{{ $json.url }}",
  "options": {
    "format": "A4",
    "printBackground": true,
    "margin": {
      "top": "1cm",
      "right": "1cm",
      "bottom": "1cm",
      "left": "1cm"
    },
    "displayHeaderFooter": true,
    "headerTemplate": "<div style='font-size:10px; text-align:center; width:100%'>Firmenbericht</div>",
    "footerTemplate": "<div style='font-size:10px; text-align:center; width:100%'>Seite <span class='pageNumber'></span> von <span class='totalPages'></span></div>"
  },
  "gotoOptions": {
    "waitUntil": "networkidle0"
  }
}
Response Format: File

// 3. Move Binary - PDF umbenennen
To Property: pdf_report
New File Name: {{ $json.filename }}_{{ $now.format('YYYY-MM-DD') }}.pdf

// 4. Email Node - Bericht senden
Anhänge: {{ $binary.pdf_report }}
To: {{ $json.recipient_email }}
Subject: Monatsbericht - {{ $now.format('MMMM YYYY') }}
Nachricht: Anbei finden Sie den Monatsbericht.

// 5. S3/Cloudflare R2 - Archivieren
Bucket: firmen-berichte
Key: berichte/{{ $now.format('YYYY/MM') }}/{{ $json.filename }}.pdf
File: {{ $binary.pdf_report }}
```

#### Beispiel 3: Erweitertes Web-Scraping mit Puppeteer

Nutze Puppeteer-Node für komplexe Interaktionen:

```javascript
// Mehrstufiges Scraping mit JavaScript-Ausführung

// 1. Schedule Trigger - Täglich um 6 Uhr

// 2. Puppeteer Node - Browser starten
Action: Launch Browser
WebSocket URL: ws://browserless:3000

// 3. Puppeteer Node - Navigieren
Action: Navigate
URL: https://example.com/produkte
Browser Connection: {{ $('Launch Browser').json }}

// 4. Puppeteer Node - Auf Selector warten
Action: Wait for Selector
Selector: .product-list
Browser Connection: {{ $('Launch Browser').json }}

// 5. Puppeteer Node - JavaScript ausführen
Action: Evaluate
JavaScript Code:
```
```javascript
// Produktdaten extrahieren
const products = [];
const items = document.querySelectorAll('.product-item');

items.forEach(item => {
  products.push({
    name: item.querySelector('.product-name')?.textContent.trim(),
    price: item.querySelector('.product-price')?.textContent.trim(),
    image: item.querySelector('.product-image')?.src,
    url: item.querySelector('a')?.href
  });
});

return products;
```
```javascript

// 6. Code Node - Ergebnisse verarbeiten
const products = $json;
return products.map(p => ({ json: p }));

// 7. Loop Over Products

// 8. Puppeteer Node - Zu Produktseite navigieren
Action: Navigate
URL: {{ $json.url }}

// 9. Puppeteer Node - Screenshot machen
Action: Screenshot
Full Page: true

// 10. Supabase Node - Produkt speichern
Table: products
Daten: {{ $json }}

// 11. Puppeteer Node - Browser schließen (nach Loop)
Action: Close Browser
```

#### Beispiel 4: Performance-Testing

Website-Ladezeiten überwachen:

```javascript
// Automatisiertes Performance-Monitoring

// 1. Schedule Trigger - Alle 15 Minuten

// 2. HTTP Request - Performance-Metriken
Methode: POST
URL: http://browserless:3000/performance
Body:
{
  "url": "{{ $json.website_url }}",
  "metrics": [
    "firstContentfulPaint",
    "largestContentfulPaint",
    "totalBlockingTime",
    "cumulativeLayoutShift",
    "timeToInteractive"
  ]
}

// 3. Code Node - Performance bewerten
const metrics = $json;
const score = {
  fcp: metrics.firstContentfulPaint < 1800 ? "gut" : "schlecht",
  lcp: metrics.largestContentfulPaint < 2500 ? "gut" : "schlecht",
  tbt: metrics.totalBlockingTime < 200 ? "gut" : "schlecht",
  cls: metrics.cumulativeLayoutShift < 0.1 ? "gut" : "schlecht",
  tti: metrics.timeToInteractive < 3800 ? "gut" : "schlecht"
};

const overallScore = Object.values(score).filter(s => s === "gut").length;

return {
  json: {
    website: $('Schedule Trigger').json.website_url,
    metrics: metrics,
    scores: score,
    overall: `${overallScore}/5`,
    timestamp: new Date().toISOString()
  }
};

// 4. IF Node - Performance verschlechtert?
Bedingung: {{ $json.overall }} < "4/5"

// Branch: Alert
// 5a. Slack Node - Alert senden
Kanal: #monitoring
Nachricht: |
  ⚠️ Performance-Verschlechterung erkannt!
  
  Website: {{ $json.website }}
  Score: {{ $json.overall }}
  
  Probleme:
  {{#each $json.scores}}
  - {{@key}}: {{this}}
  {{/each}}

// Branch: OK
// 5b. InfluxDB/Prometheus - Metriken loggen
```

### HTTP-API-Endpoints

**Screenshot:**
```bash
POST /screenshot
{
  "url": "https://example.com",
  "options": {
    "fullPage": true,
    "type": "png",
    "quality": 90,
    "omitBackground": false
  }
}
```

**PDF:**
```bash
POST /pdf
{
  "url": "https://example.com",
  "options": {
    "format": "A4",
    "landscape": false,
    "printBackground": true,
    "scale": 1
  }
}
```

**Content (HTML):**
```bash
POST /content
{
  "url": "https://example.com",
  "waitForSelector": "#main-content",
  "waitForTimeout": 5000
}
```

**Function (JavaScript ausführen):**
```bash
POST /function
{
  "code": "return document.title;"
}
```

**Performance:**
```bash
POST /performance
{
  "url": "https://example.com",
  "metrics": ["firstContentfulPaint", "domContentLoaded"]
}
```

### Konfigurationsoptionen

**Umgebungsvariablen (.env):**

```bash
# Maximale gleichzeitige Browser-Sessions
BROWSERLESS_CONCURRENT=10

# Session-Timeout in Millisekunden
BROWSERLESS_TIMEOUT=30000

# Chrome DevTools Debugger aktivieren
BROWSERLESS_DEBUGGER=false

# Authentifizierungs-Token
BROWSERLESS_TOKEN=dein-sicherer-token

# Maximale Warteschlangenlänge
BROWSERLESS_MAX_QUEUE_LENGTH=100

# Session-Aufzeichnungen aktivieren
BROWSERLESS_ENABLE_RECORDING=false

# Proxy-Konfiguration
BROWSERLESS_PROXY_URL=http://proxy.example.com:8080

# Speicherlimit pro Session
BROWSERLESS_MAX_MEMORY_MB=512
```

**Ressourcen-Limits:**

```yaml
# In docker-compose.yml
browserless:
  deploy:
    resources:
      limits:
        cpus: '2.0'
        memory: 4G
      reservations:
        cpus: '1.0'
        memory: 2G
```

### Fehlerbehebung

**Sessions laufen ab:**

```bash
# 1. Prüfe aktuelle Session-Last
curl http://localhost:3000/pressure
# Zeigt: { "running": 5, "queued": 2, "maxConcurrent": 10 }

# 2. Erhöhe Concurrent-Limit
# In .env-Datei:
BROWSERLESS_CONCURRENT=15

# 3. Erhöhe Timeout für langsame Sites
BROWSERLESS_TIMEOUT=60000  # 60 Sekunden

# 4. Starte Browserless neu
docker compose restart browserless
```

**Out-of-Memory-Fehler:**

```bash
# 1. Prüfe Speichernutzung
docker stats browserless

# 2. Erhöhe Container-Speicherlimit
# In docker-compose.yml:
deploy:
  resources:
    limits:
      memory: 6G

# 3. Reduziere gleichzeitige Sessions
BROWSERLESS_CONCURRENT=5

# 4. Aktiviere automatische Bereinigung
# Füge zu docker-compose.yml environment hinzu:
BROWSERLESS_MAX_MEMORY_PERCENT=90
```

**WebSocket-Verbindung fehlgeschlagen:**

```bash
# 1. Verifiziere Browserless läuft
docker ps | grep browserless

# 2. Teste WebSocket-Endpoint
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  http://localhost:3000

# Sollte zurückgeben: 101 Switching Protocols

# 3. Prüfe Netzwerkverbindung
docker exec browser-use ping browserless

# 4. Verifiziere Token falls Authentifizierung verwendet
# In Verbindungs-String: ws://browserless:3000?token=DEIN_TOKEN
```

**Chrome stürzt ab:**

```bash
# 1. Prüfe Chrome-Logs
docker logs browserless --tail 100 | grep -i "chrome"

# 2. Füge mehr Speicher hinzu
# Siehe "Out-of-Memory-Fehler" oben

# 3. Deaktiviere GPU-Beschleunigung
# In .env, füge hinzu:
BROWSERLESS_CHROME_ARGS=--disable-gpu,--no-sandbox,--disable-dev-shm-usage

# 4. Aktiviere Shared Memory
# In docker-compose.yml:
volumes:
  - /dev/shm:/dev/shm

# 5. Reduziere Seitenkomplexität
# Nutze: { "waitUntil": "domcontentloaded" } statt "networkidle0"
```

**Langsame Performance:**

```bash
# 1. Prüfe CPU-Nutzung
docker stats browserless

# 2. Reduziere gleichzeitige Sessions
BROWSERLESS_CONCURRENT=5

# 3. Aktiviere Headless-Modus (sollte Standard sein)
# In Puppeteer-Optionen: "headless": true

# 4. Deaktiviere unnötige Features
BROWSERLESS_ENABLE_RECORDING=false
BROWSERLESS_DEBUGGER=false

# 5. Nutze leichtere Warte-Strategien
# "waitUntil": "domcontentloaded" statt "networkidle2"
```

### Best Practices

**Ressourcenverwaltung:**
- Setze `BROWSERLESS_CONCURRENT` basierend auf Server-RAM (2GB RAM pro Session)
- Nutze Timeouts um hängende Sessions zu verhindern
- Überwache mit `/pressure`-Endpoint
- Schließe Browser explizit nach Verwendung

**Performance:**
- Nutze `domcontentloaded` für schnelle Seiten
- Nutze `networkidle0` nur wenn nötig
- Wiederverwendung von Browser-Kontexten wenn möglich
- Aktiviere Headless-Modus (schneller)

**Zuverlässigkeit:**
- Implementiere Retry-Logik in Workflows
- Setze vernünftige Timeouts (30-60s)
- Handhabe Browser-Abstürze elegant
- Logge Session-IDs zum Debuggen

**Sicherheit:**
- Nutze `BROWSERLESS_TOKEN` für Authentifizierung
- Limitiere gleichzeitige Sessions um Missbrauch zu verhindern
- Führe kein nicht vertrauenswürdiges JavaScript aus
- Laufe in isoliertem Docker-Netzwerk

**Debugging:**
- Aktiviere `BROWSERLESS_DEBUGGER=true` zur Fehlerbehebung
- Nutze Session-Aufzeichnungen (`BROWSERLESS_ENABLE_RECORDING=true`)
- Prüfe `/metrics`-Endpoint für Diagnostik
- Speichere Screenshots bei Fehlern

### Integration mit AI CoreKit Diensten

**Browserless + Browser-use:**
- Browser-use verbindet via WebSocket: `ws://browserless:3000`
- Zentralisierte Browser-Verwaltung
- Ressourcen-Sharing über Automatisierungsaufgaben

**Browserless + Skyvern:**
- Skyvern nutzt Browserless für visuelle Automatisierung
- Behandelt CAPTCHA und dynamische Inhalte
- Computer Vision über gemeinsamen Browser

**Browserless + n8n Puppeteer:**
- Native Puppeteer-Node-Integration
- Visueller Workflow-Aufbau
- Einfaches Debugging mit Node-UI

**Browserless + Gotenberg:**
- Browserless: Interaktive Screenshots, Scraping
- Gotenberg: Statische Dokumentenkonvertierung
- Nutze beide für vollständigen Dokumenten-Workflow

### Monitoring & Metriken

**Health Check:**
```bash
curl http://localhost:3000/json/version
```

**Druck/Last:**
```bash
curl http://localhost:3000/pressure
# Gibt zurück: {"running": 3, "queued": 0, "maxConcurrent": 10}
```

**Metriken (Prometheus-Format):**
```bash
curl http://localhost:3000/metrics
```

**Aktive Sessions:**
```bash
curl http://localhost:3000/json/list
# Listet alle aktiven Browser-Sessions auf
```

### Ressourcen

- **Offizielle Website:** https://www.browserless.io/
- **Dokumentation:** https://docs.browserless.io/
- **GitHub:** https://github.com/browserless/chrome
- **API-Referenz:** https://docs.browserless.io/docs/api-reference
- **Docker Hub:** https://hub.docker.com/r/browserless/chrome
- **Community:** Discord (Link auf Website)

### Wann Browserless direkt vs andere Tools nutzen

**Nutze Browserless HTTP-API für:**
- ✅ Einfache Screenshots
- ✅ PDF-Generierung
- ✅ Schnelle Content-Extraktion
- ✅ Performance-Testing
- ✅ Wenn REST-Schnittstelle benötigt wird

**Nutze Puppeteer Node (via Browserless) für:**
- ✅ Komplexe mehrstufige Automatisierung
- ✅ Benutzerdefinierte JavaScript-Ausführung
- ✅ Formular-Interaktionen
- ✅ Wenn vollständige Browser-Steuerung benötigt wird

**Nutze Browser-use (via Browserless) für:**
- ✅ Natürlichsprachliche Automatisierung
- ✅ Dynamisches Website-Scraping
- ✅ LLM-gesteuerte Datenextraktion

**Nutze Skyvern (via Browserless) für:**
- ✅ Visuelle-basierte Automatisierung
- ✅ CAPTCHA-Lösung
- ✅ Anti-Bot-Navigation
- ✅ Selbstheilende Workflows
