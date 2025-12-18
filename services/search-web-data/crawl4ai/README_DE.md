# 🕷️ Crawl4Ai - KI-optimierter Web-Crawler

### Was ist Crawl4AI?

Crawl4AI ist der #1 trendende Open-Source-Web-Crawler auf GitHub, speziell optimiert für große Sprachmodelle und KI-Agenten. Er liefert blitzschnelles, KI-bereites Web-Crawling, das 6x schneller ist als traditionelle Tools, mit integrierten Stealth-Fähigkeiten zum Umgehen von Bot-Erkennungssystemen wie Cloudflare und Akamai. Der Crawler gibt sauberes Markdown aus, das perfekt für RAG-Pipelines, Wissensdatenbanken und KI-Trainingsdaten ist.

Im Gegensatz zu einfachen Scrapern nutzt Crawl4AI intelligentes adaptives Crawling mit Information-Foraging-Algorithmen, um zu bestimmen, wann ausreichend Informationen gesammelt wurden, was ihn hocheffizient für großangelegte Datenextraktion macht.

### Features

- **KI-First-Architektur**: Gibt sauberes, strukturiertes Markdown aus, optimiert für LLMs, RAG-Systeme und Fine-Tuning
- **Blitzschnelle Performance**: 6x schneller als traditionelle Crawler mit asynchroner Architektur für parallele Verarbeitung
- **Stealth & Anti-Erkennung**: Unentdeckter Browser-Modus umgeht Cloudflare, Akamai und benutzerdefinierten Bot-Schutz
- **Deep-Crawling-Strategien**: DFS- und BFS-Algorithmen für umfassende mehrseitige Extraktion mit Tiefenkontrolle
- **Intelligente Content-Extraktion**: Heuristische Filterung, Lazy-Loaded-Content-Handling und adaptive Stopps
- **Session-Management**: Cookies, Proxys, benutzerdefinierte Header und JavaScript-Ausführungsunterstützung
- **Keine API-Keys erforderlich**: Vollständig selbst gehostet, keine Rate-Limits, komplette Datenkontrolle

### API-Zugriff

Crawl4AI läuft als interner Service und ist für andere Container zugänglich:

**Interner API-Endpunkt:**
```
http://crawl4ai:11235
```

**Service-Features:**
- RESTful API für Crawling-Operationen
- Asynchrones Crawling mit Job-Management
- Multi-URL-Batch-Verarbeitung
- Konfigurierbare Extraktionsstrategien
- Session-Persistenz über Anfragen hinweg

### n8n-Integrationssetup

Crawl4AI benötigt keine Credentials in n8n - der Zugriff erfolgt über HTTP-Request-Nodes zur internen API.

**Integrationsmethoden:**

1. **Basis-HTTP-Request (Einfaches Crawling)**

```javascript
// HTTP Request Node-Konfiguration
Methode: POST
URL: http://crawl4ai:11235/api/crawl
Body (JSON):
{
  "url": "https://example.com",
  "markdown": true,
  "remove_forms": true,
  "bypass_cache": false
}
```

2. **Erweitertes Crawling mit Extraktionsstrategie**

```javascript
// HTTP Request Node - Erweiterte Konfiguration
Methode: POST
URL: http://crawl4ai:11235/api/crawl/advanced
Body (JSON):
{
  "url": "https://example.com/docs",
  "extraction_strategy": {
    "type": "css",
    "selectors": {
      "title": "h1.title",
      "content": "div.content",
      "links": "a.internal"
    }
  },
  "markdown": true,
  "wait_for": "networkidle",
  "timeout": 30000
}
```

### Beispiel-Workflows

#### Beispiel 1: Dokumentations-Scraper für RAG

Dieser Workflow scrapt technische Dokumentation und bereitet sie für ein RAG-System vor.

**Workflow-Struktur:**
1. **Webhook/Schedule Trigger** - Crawling planmäßig oder auf Abruf auslösen
2. **HTTP Request** - Dokumentationsseite crawlen
   ```javascript
   // Node: Dokumentation crawlen
   Methode: POST
   URL: http://crawl4ai:11235/api/crawl
   Body:
   {
     "url": "{{ $json.documentationUrl }}",
     "markdown": true,
     "wait_for_images": true,
     "bypass_cache": true,
     "extraction_strategy": {
       "type": "markdown",
       "include_links": true,
       "include_images": false
     }
   }
   ```
3. **Code Node** - Markdown verarbeiten und in Chunks aufteilen
   ```javascript
   // Markdown in Chunks für Vektor-Speicherung aufteilen
   const markdown = $json.markdown;
   const chunkSize = 1000;
   const chunks = [];
   
   const lines = markdown.split('\n');
   let currentChunk = '';
   
   for (const line of lines) {
     if (currentChunk.length + line.length > chunkSize && currentChunk.length > 0) {
       chunks.push({
         content: currentChunk.trim(),
         source: $json.url,
         timestamp: new Date().toISOString()
       });
       currentChunk = line;
     } else {
       currentChunk += line + '\n';
     }
   }
   
   if (currentChunk.length > 0) {
     chunks.push({
       content: currentChunk.trim(),
       source: $json.url,
       timestamp: new Date().toISOString()
     });
   }
   
   return chunks.map(chunk => ({ json: chunk }));
   ```
4. **Qdrant/Weaviate Node** - In Vektor-Datenbank speichern

**Anwendungsfall**: Halte deine KI-Wissensdatenbank automatisch mit der neuesten Dokumentation aktuell.

#### Beispiel 2: Competitive-Intelligence-Monitor

Konkurrenten-Websites überwachen und Produktinformationen extrahieren.

**Workflow-Struktur:**
1. **Schedule Trigger** - Täglich zur bestimmten Zeit ausführen
2. **HTTP Request** - Deep-Crawling der Konkurrenten-Seite
   ```javascript
   // Node: Deep Crawl Konkurrent
   Methode: POST
   URL: http://crawl4ai:11235/api/crawl/deep
   Body:
   {
     "url": "https://competitor.com/products",
     "strategy": "bfs",
     "max_depth": 2,
     "max_pages": 50,
     "include_external": false,
     "extraction_strategy": {
       "type": "json_css",
       "schema": {
         "product_name": ".product-title",
         "price": ".product-price",
         "description": ".product-description",
         "features": [".feature-list li"]
       }
     }
   }
   ```
3. **Code Node** - Mit vorherigen Daten vergleichen
   ```javascript
   // Preisänderungen und neue Produkte erkennen
   const currentProducts = $json.products;
   const previousData = $('Compare with Storage').first().json;
   
   const changes = {
     new_products: [],
     price_changes: [],
     discontinued: []
   };
   
   // Vergleichslogik
   currentProducts.forEach(product => {
     const previous = previousData.find(p => p.product_name === product.product_name);
     if (!previous) {
       changes.new_products.push(product);
     } else if (previous.price !== product.price) {
       changes.price_changes.push({
         name: product.product_name,
         old_price: previous.price,
         new_price: product.price
       });
     }
   });
   
   return [{ json: changes }];
   ```
4. **E-Mail/Slack senden** - Team über signifikante Änderungen benachrichtigen

#### Beispiel 3: Recherche-Datensammlung

Akademische Papers oder Artikel für Recherche-Analysen sammeln.

**Workflow-Struktur:**
1. **Manueller Trigger** - Mit Recherche-Anfrage starten
2. **HTTP Request** - Recherche-Quellen crawlen
   ```javascript
   Methode: POST
   URL: http://crawl4ai:11235/api/crawl
   Body:
   {
     "url": "{{ $json.searchUrl }}",
     "markdown": true,
     "javascript_enabled": true,
     "wait_for": "networkidle2",
     "extraction_strategy": {
       "type": "llm",
       "instruction": "Extrahiere akademische Paper-Titel, Autoren, Abstracts und Veröffentlichungsdaten. Fokus auf Papers zu künstlicher Intelligenz und maschinellem Lernen."
     }
   }
   ```
3. **Code Node** - Daten bereinigen und strukturieren
4. **Speichern** - In Datenbank speichern oder als CSV exportieren

### Fehlerbehebung

**Problem 1: Crawler wird von Zielseite blockiert**

Viele Seiten haben Anti-Bot-Schutz. Stealth-Modus und Proxys nutzen.

```bash
# Prüfen, ob Crawl4AI-Service läuft
docker compose -p localai ps | grep crawl4ai

# Crawl4AI-Logs auf Blockierungs-Indikatoren prüfen
docker compose -p localai logs crawl4ai | grep -i "blocked\|captcha\|403\|429"
```

**Lösung:**
- Stealth-Modus in deiner API-Anfrage aktivieren:
  ```json
  {
    "url": "https://protected-site.com",
    "stealth_mode": true,
    "user_agent": "custom-agent-string"
  }
  ```
- Verzögerungen zwischen Anfragen hinzufügen, um Rate-Limiting zu vermeiden
- Proxy-Rotation nutzen, wenn im großen Maßstab gecrawlt wird

**Problem 2: JavaScript-lastige Seite lädt nicht vollständig**

Moderne SPAs benötigen möglicherweise Zeit für JavaScript-Ausführung.

```bash
# Crawler-Logs auf Timeout-Fehler prüfen
docker compose -p localai logs crawl4ai --tail 100
```

**Lösung:**
- Wartezeit erhöhen und geeignete Wartebedingungen nutzen:
  ```json
  {
    "url": "https://spa-site.com",
    "wait_for": "networkidle",
    "wait_for_images": true,
    "timeout": 60000,
    "page_load_delay": 3000
  }
  ```
- Für spezifische Elemente: `"wait_for_selector": ".content-loaded"`

**Problem 3: Extrahierter Content ist unvollständig oder falsch**

Die Standard-Extraktion funktioniert möglicherweise nicht für alle Seitenstrukturen.

**Diagnose:**
```bash
# Crawl direkt testen, um rohe Ausgabe zu sehen
curl -X POST http://localhost:11235/api/crawl \
  -H "Content-Type: application/json" \
  -d '{"url": "https://target-site.com", "markdown": true}'
```

**Lösung:**
- CSS-Selektoren für präzise Extraktion nutzen:
  ```json
  {
    "extraction_strategy": {
      "type": "css",
      "selectors": {
        "main_content": "article.main",
        "title": "h1",
        "metadata": ".post-meta"
      }
    }
  }
  ```
- Für komplexe Seiten die LLM-Extraktionsstrategie mit spezifischen Anweisungen nutzen

**Problem 4: Container-Ressourcen-Probleme**

Das gleichzeitige Crawlen vieler Seiten kann ressourcenintensiv sein.

```bash
# Container-Ressourcennutzung prüfen
docker stats crawl4ai

# Verfügbaren Speicher prüfen
docker compose -p localai exec crawl4ai free -h
```

**Lösung:**
- Gleichzeitige Crawls in deinem Workflow begrenzen
- Verzögerungen zwischen großen Batch-Operationen hinzufügen
- Container-Ressourcen in `docker-compose.yml` bei Bedarf erhöhen:
  ```yaml
  crawl4ai:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
  ```

### Erweiterte Features

**Multi-URL-Batch-Verarbeitung:**
Mehrere URLs mit unterschiedlichen Strategien in einer Anfrage verarbeiten.

```json
{
  "urls": [
    {
      "url": "https://site1.com",
      "strategy": "fast",
      "markdown": true
    },
    {
      "url": "https://site2.com/docs",
      "strategy": "deep",
      "max_depth": 2
    }
  ]
}
```

**Session-Management:**
Status über mehrere Anfragen hinweg beibehalten (nützlich für Seiten, die Anmeldung erfordern).

```json
{
  "url": "https://members.site.com/content",
  "session_id": "my-session-123",
  "cookies": [
    {"name": "auth_token", "value": "xxx", "domain": ".site.com"}
  ]
}
```

**Benutzerdefinierte JavaScript-Ausführung:**
JavaScript auf der Seite vor Extraktion ausführen.

```json
{
  "url": "https://dynamic-site.com",
  "js_code": "document.querySelector('.load-more-button').click();",
  "wait_after_js": 2000
}
```

### Ressourcen

- **Offizielle Dokumentation**: https://docs.crawl4ai.com/
- **GitHub Repository**: https://github.com/unclecode/crawl4ai
- **Discord Community**: https://discord.gg/jP8KfhDhyN
- **Interne API**: `http://crawl4ai:11235`
- **API-Dokumentation**: `http://crawl4ai:11235/docs` (Swagger UI)
- **Beispiel-Notebooks**: https://github.com/unclecode/crawl4ai/tree/main/docs/examples

**Verwandte Services:**
- Mit **SearXNG** für initiale URL-Entdeckung nutzen
- Extrahierten Content an **Qdrant** oder **Weaviate** für Vektorsuche weiterleiten
- Mit **Ollama** für Content-Analyse verarbeiten
- Strukturierte Daten in **Supabase** oder **PostgreSQL** speichern
