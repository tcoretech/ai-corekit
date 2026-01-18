# 🔍 SearXNG - Privatsphäre-fokussierte Metasuchmaschine

### Was ist SearXNG?

SearXNG ist eine quelloffene, privatsphäre-respektierende Metasuchmaschine, die Ergebnisse von über 70 Suchmaschinen (einschließlich Google, Bing, DuckDuckGo, Wikipedia und mehr) aggregiert und dabei vollständige Benutzeranonymität gewährleistet. Im Gegensatz zu traditionellen Suchmaschinen verfolgt SearXNG keine Suchen, speichert keine IP-Adressen, erstellt keine Benutzerprofile und zeigt keine personalisierten Anzeigen. Es fungiert als Datenschutzschild zwischen dir und Suchmaschinen und ist damit perfekt für KI-Agenten, Recherche-Workflows und datenschutzbewusste Organisationen.

### Funktionen

- **70+ Suchmaschinen** - Aggregiert Ergebnisse von Google, Bing, DuckDuckGo, Wikipedia, GitHub, arXiv und vielen mehr
- **Vollständiger Datenschutz** - Kein Tracking, keine Cookies, keine Suchhistorie, keine Benutzerprofilierung
- **Kategoriebasierte Suche** - Filtern nach Allgemein, Bilder, Videos, Nachrichten, Dateien, IT, Karten, Musik, Wissenschaft, Soziale Medien
- **Anpassbar** - Wähle welche Engines zu verwenden sind, passe Themes an, konfiguriere SafeSearch-Level
- **JSON-API** - RESTful API für programmatischen Zugriff und Automatisierung
- **Selbst gehostet** - Volle Kontrolle über deine Suchinfrastruktur und Daten
- **Mehrsprachig** - 58 Übersetzungen und sprachspezifische Suchfähigkeiten

### Erste Einrichtung

**Erster Zugriff auf SearXNG:**

1. Navigiere zu `https://searxng.deinedomain.com`
2. Kein Login erforderlich - SearXNG ist standardmäßig öffentlich (kann über Caddy Auth eingeschränkt werden)
3. Erkunde die Oberfläche:
   - **Kategorien:** Allgemein, Bilder, Videos, Nachrichten, Dateien, IT, Wissenschaft, etc.
   - **Einstellungen:** Konfiguriere Standard-Engines, Themes, Sprache, SafeSearch
   - **Settings:** Passe an, welche Suchmaschinen verwendet werden sollen
4. Teste eine Suche um zu verifizieren, dass es funktioniert

**JSON-API aktivieren (Erforderlich für n8n):**

Die JSON-API ist **standardmäßig deaktiviert** und muss aktiviert werden:

```bash
# Navigiere zu deiner SearXNG-Konfiguration
cd ~/ai-corekit

# Bearbeite die settings.yml Datei
nano searxng/settings.yml

# Finde den 'search:' Abschnitt und füge 'json' zu formats hinzu:
search:
  formats:
    - html
    - json    # Diese Zeile hinzufügen um JSON-API zu aktivieren
    - csv
    - rss

# Speichern und SearXNG neu starten
docker compose restart searxng
```

**JSON-API testen:**

```bash
# Teste dass JSON-Format funktioniert
curl "https://searxng.deinedomain.com/search?q=test&format=json"

# Sollte JSON mit Suchergebnissen zurückgeben
```

### n8n-Integration einrichten

SearXNG hat **native n8n-Integration** mit eingebautem Tool-Node!

**Methode 1: SearXNG Tool-Node (Empfohlen für KI-Agenten)**

1. **SearXNG Tool**-Node zum Workflow hinzufügen
2. SearXNG-Anmeldedaten erstellen:
   - **Create New Credential** klicken
   - **API-URL:** `http://searxng:8080` (intern) oder `https://searxng.deinedomain.com` (extern)
   - Anmeldedaten speichern
3. Der Node ist jetzt bereit zur Verwendung mit KI-Agenten-Nodes!

**Methode 2: HTTP-Request-Node (Mehr Kontrolle)**

Verwende HTTP-Request für benutzerdefinierte Abfragen und erweiterte Parameter.

**Interne URL:** `http://searxng:8080`

**API-Endpunkt:** `GET /search` oder `GET /`

**Erforderliche Parameter:**
- `q`: Suchabfrage (erforderlich)
- `format`: Muss `json` sein für API-Nutzung

### Beispiel-Workflows

#### Beispiel 1: KI-Recherche-Assistent mit Web-Suche

```javascript
// Baue einen KI-Agenten mit Echtzeit-Web-Suchfähigkeiten

// 1. Chat-Trigger-Node
// Benutzer stellt eine Frage

// 2. AI Agent-Node (OpenAI oder Claude)
Modell: gpt-4o-mini
System Prompt: Du bist ein Recherche-Assistent. Verwende Web-Suche wenn nötig, um genaue und aktuelle Informationen zu liefern.

// 3. SearXNG Tool-Node zum Agenten hinzufügen
// Der Tool-Node ist automatisch für den Agenten verfügbar
Credential: SearXNG (http://searxng:8080)

// 4. Agent ruft SearXNG automatisch bei Bedarf auf!
// Benutzer: "Was sind die neuesten Entwicklungen im Quantencomputing?"
// Agent: *Durchsucht SearXNG* → *Synthetisiert Ergebnisse* → Gibt Antwort

// Der Agent wird automatisch:
// - Bestimmen wann Web-Suche benötigt wird
// - Suchen über SearXNG ausführen
// - Ergebnisse in Antworten integrieren
```

#### Beispiel 2: Competitive-Intelligence-Monitoring

```javascript
// Automatisierte tägliche Wettbewerber-Recherche

// 1. Schedule-Trigger-Node
Cron: 0 9 * * *  // Jeden Tag um 9 Uhr

// 2. HTTP-Request-Node - Nach Wettbewerber-News suchen
Methode: GET
URL: http://searxng:8080/search
Query Parameter:
  q: "wettbewerber-name" AND ("finanzierung" OR "produktstart" OR "übernahme")
  format: json
  categories: news
  time_range: day  // Nur Ergebnisse der letzten 24 Stunden
  engines: google,bing,duckduckgo
  language: de

// Antwortformat:
{
  "results": [
    {
      "title": "Wettbewerber erhält 50M€ Series B",
      "url": "https://techcrunch.com/...",
      "content": "Kurze Beschreibung...",
      "engine": "google",
      "category": "news",
      "publishedDate": "2024-01-15"
    }
  ],
  "number_of_results": 15
}

// 3. IF-Node - Prüfe ob Ergebnisse gefunden wurden
Bedingung: {{ $json.number_of_results > 0 }}

// 4. Loop-Node - Jedes Ergebnis verarbeiten
Items: {{ $json.results }}

// 5. Code-Node - Relevante News filtern
const result = $input.item.json;

// Prüfe ob wirklich relevant
const relevantKeywords = ['finanzierung', 'übernahme', 'produkt', 'start', 'partnerschaft'];
const isRelevant = relevantKeywords.some(keyword => 
  result.title.toLowerCase().includes(keyword) ||
  result.content.toLowerCase().includes(keyword)
);

if (!isRelevant) return null;  // Diesen Punkt überspringen

return {
  title: result.title,
  url: result.url,
  summary: result.content,
  source: result.engine,
  date: result.publishedDate
};

// 6. OpenAI-Node - Intelligence-Zusammenfassung generieren
Modell: gpt-4o-mini
Prompt: |
  Analysiere diese Wettbewerber-News und liefere:
  1. Strategische Auswirkungen für unser Geschäft
  2. Potenzielle Bedrohungen oder Chancen
  3. Empfohlene Maßnahmen
  
  News: {{ $json.title }}
  Details: {{ $json.summary }}

// 7. Notion-Node - Zur Intelligence-Datenbank hinzufügen
Database: Competitive Intelligence
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Datum: {{ $json.date }}
  Source: {{ $json.source }}
  Analysis: {{ $('OpenAI').json.analysis }}
  Threat Level: {{ $('OpenAI').json.threat_level }}

// 8. Slack-Node - Tägliche Zusammenfassung
Kanal: #competitive-intel
Nachricht: |
  📊 Täglicher Wettbewerber-Intelligence-Bericht
  
  **Neue Erkenntnisse:** {{ $('Loop').itemCount }} Artikel
  
  🔴 Hohe Priorität:
  {{ $('Loop').all().filter(x => x.json.threat_level === 'high').map(x => x.json.title).join('\n- ') }}
  
  Vollständigen Bericht in Notion anzeigen
```

#### Beispiel 3: Akademischer Recherche-Aggregator

```javascript
// Mehrere akademische Datenbanken gleichzeitig durchsuchen

// 1. Webhook-Trigger - Recherche-Anfrage
// Input: { "topic": "maschinelles lernen fairness", "year": "2024" }

// 2. HTTP-Request - Akademische Quellen durchsuchen
Methode: GET
URL: http://searxng:8080/search
Query Parameter:
  q: "{{ $json.topic }}" {{ $json.year }}
  format: json
  categories: science  // Nur wissenschaftliche Artikel
  engines: arxiv,google scholar,semantic scholar,pubmed
  pageno: 1

// 3. Code-Node - Ergebnisse parsen und deduplizieren
const results = $input.item.json.results;

// Duplikate nach DOI oder URL entfernen
const uniqueResults = [];
const seenUrls = new Set();

for (const result of results) {
  const url = result.url;
  if (!seenUrls.has(url)) {
    seenUrls.add(url);
    uniqueResults.push({
      title: result.title,
      url: result.url,
      abstract: result.content,
      source: result.engine,
      published: result.publishedDate || 'Unbekannt'
    });
  }
}

return uniqueResults;

// 4. Loop-Node - Jedes Paper verarbeiten
Items: {{ $json }}

// 5. HTTP-Request - Vollständige Paper-Metadaten abrufen
// DOI oder API verwenden um mehr Details zu erhalten

// 6. Qdrant-Node - Paper-Embeddings speichern
// Vektor-Embeddings für semantische Suche erstellen

// 7. Notion-Node - Recherche-Datenbank erstellen
Database: Research Papers
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Abstract: {{ $json.abstract }}
  Source: {{ $json.source }}
  Published: {{ $json.published }}
  Tags: [{{ $json.topic }}]

// 8. Gmail-Node - Digest senden
To: researcher@university.edu
Subject: Recherche-Digest - {{ $json.topic }}
Body: |
  {{ $('Code Node').itemCount }} Papers zu {{ $json.topic }} gefunden:
  
  {{ $('Loop').all().map(x => `- ${x.json.title}\n  ${x.json.url}`).join('\n\n') }}
```

#### Beispiel 4: Multi-Engine-Bildsuche

```javascript
// Bilder über mehrere Engines durchsuchen

// 1. Webhook-Trigger
// Input: { "query": "minimalistisches bürodesign" }

// 2. HTTP-Request - Bildsuche
Methode: GET
URL: http://searxng:8080/search
Query Parameter:
  q: {{ $json.query }}
  format: json
  categories: images  // Nur Bilder
  engines: google images,bing images,flickr,unsplash
  safesearch: 1  // Moderate SafeSearch
  pageno: 1

// Antwort enthält Bildergebnisse:
{
  "results": [
    {
      "title": "Minimalistisches Büro-Setup",
      "url": "https://example.com/image.jpg",
      "thumbnail_src": "https://example.com/thumb.jpg",
      "img_src": "https://example.com/full.jpg",
      "engine": "google images",
      "resolution": "1920x1080"
    }
  ]
}

// 3. Code-Node - Hochauflösende Bilder filtern
const images = $input.item.json.results;

const highRes = images.filter(img => {
  if (!img.resolution) return false;
  const [width, height] = img.resolution.split('x').map(Number);
  return width >= 1920 && height >= 1080;  // Full HD oder höher
});

return highRes.slice(0, 20);  // Top 20 Ergebnisse

// 4. Loop-Node - Bilder herunterladen
Items: {{ $json }}

// 5. HTTP-Request - Bild herunterladen
Methode: GET
URL: {{ $json.img_src }}
Response Format: File

// 6. Google Drive-Node - In Ordner hochladen
Folder: /Design Inspiration/{{ $('Webhook').json.query }}
File: {{ $binary.data }}
```

#### Beispiel 5: News-Aggregation mit Sentiment-Analyse

```javascript
// Multi-Source-News-Monitoring mit KI-Analyse

// 1. Schedule-Trigger
Cron: 0 */6 * * *  // Alle 6 Stunden

// 2. Set-Node - Themen definieren
[
  "künstliche intelligenz regulierung",
  "klimawandel politik",
  "kryptowährung markt"
]

// 3. Loop-Node - Jedes Thema durchsuchen
Items: {{ $json }}

// 4. HTTP-Request - News durchsuchen
Methode: GET
URL: http://searxng:8080/search
Query Parameter:
  q: {{ $json.topic }}
  format: json
  categories: news
  engines: google news,bing news,yahoo news
  time_range: day  // Letzte 24 Stunden
  language: de

// 5. Code-Node - Ergebnisse extrahieren und bereinigen
const articles = $input.item.json.results;

return articles.map(article => ({
  topic: $('Loop').item.json.topic,
  title: article.title,
  url: article.url,
  snippet: article.content,
  source: article.engine,
  published: article.publishedDate
}));

// 6. OpenAI-Node - Sentiment-Analyse
Modell: gpt-4o-mini
Prompt: |
  Analysiere das Sentiment dieses Nachrichtenartikels:
  Titel: {{ $json.title }}
  Ausschnitt: {{ $json.snippet }}
  
  Gib JSON zurück:
  {
    "sentiment": "positive/neutral/negative",
    "confidence": 0.0-1.0,
    "key_points": ["Punkt 1", "Punkt 2"],
    "impact": "low/medium/high"
  }

// 7. PostgreSQL-Node - Ergebnisse speichern
Table: news_monitoring
Fields:
  topic: {{ $json.topic }}
  title: {{ $json.title }}
  url: {{ $json.url }}
  sentiment: {{ $('OpenAI').json.sentiment }}
  impact: {{ $('OpenAI').json.impact }}
  key_points: {{ $('OpenAI').json.key_points }}
  monitored_at: {{ $now }}

// 8. IF-Node - Bei negativen News mit hoher Auswirkung alarmieren
If: {{ $('OpenAI').json.sentiment === 'negative' && $('OpenAI').json.impact === 'high' }}

// 9. Slack-Node - Alarm senden
Kanal: #alerts
Nachricht: |
  ⚠️ Negative News mit hoher Auswirkung
  
  **Thema:** {{ $json.topic }}
  **Schlagzeile:** {{ $json.title }}
  **Sentiment:** {{ $('OpenAI').json.sentiment }} ({{ $('OpenAI').json.confidence * 100 }}% sicher)
  **Auswirkung:** {{ $('OpenAI').json.impact }}
  
  **Hauptpunkte:**
  {{ $('OpenAI').json.key_points.join('\n- ') }}
  
  Mehr lesen: {{ $json.url }}
```

### API-Parameter-Referenz

**Such-Endpunkt:** `GET /search` oder `GET /`

**Erforderliche Parameter:**
- `q`: Such-Abfrage-String

**Optionale Parameter:**
- `format`: Ausgabeformat (`json`, `csv`, `rss`, `html`) - **Erforderlich für API: `json`**
- `categories`: Komma-getrennte Liste (`general`, `images`, `videos`, `news`, `files`, `it`, `maps`, `music`, `science`, `social_media`)
- `engines`: Komma-getrennte Liste (`google`, `bing`, `duckduckgo`, `wikipedia`, `github`, etc.)
- `language`: Sprachcode (`en`, `de`, `fr`, `es`, `it`, etc.)
- `pageno`: Seitennummer (Standard: 1)
- `time_range`: Nach Zeit filtern (`day`, `week`, `month`, `year`)
- `safesearch`: SafeSearch-Level (`0`=aus, `1`=moderat, `2`=streng)

**Beispiel-Anfrage:**
```bash
curl "http://searxng:8080/search?q=n8n+automatisierung&format=json&categories=general&engines=google,bing&language=de&time_range=month"
```

**Antwortformat:**
```json
{
  "query": "n8n automatisierung",
  "number_of_results": 42,
  "results": [
    {
      "url": "https://example.com",
      "title": "Ergebnis-Titel",
      "content": "Beschreibungsausschnitt...",
      "engine": "google",
      "category": "general",
      "publishedDate": "2024-01-15"
    }
  ],
  "infoboxes": [],
  "suggestions": ["n8n workflow", "n8n tutorial"]
}
```

### Fehlerbehebung

**Problem 1: JSON-API gibt HTML statt JSON zurück**

```bash
# Prüfe ob JSON-Format aktiviert ist
docker exec searxng cat /etc/searxng/settings.yml | grep -A5 "formats:"

# Sollte zeigen:
# formats:
#   - html
#   - json    # Muss vorhanden sein

# Falls fehlend, zu settings.yml hinzufügen
nano ~/ai-corekit/searxng/settings.yml

# json zu formats-Abschnitt hinzufügen, speichern und neu starten
docker compose restart searxng
```

**Lösung:**
- JSON-Format ist standardmäßig in SearXNG deaktiviert
- Muss manuell in `settings.yml`-Datei aktiviert werden
- Container nach Änderungen neu starten
- Testen mit `curl "http://searxng:8080/search?q=test&format=json"`

**Problem 2: Leere oder wenige Suchergebnisse**

```bash
# Prüfe welche Engines aktiviert sind
curl "http://searxng:8080/config" | jq '.engines[] | select(.enabled==true)'

# Teste spezifische Engine
curl "http://searxng:8080/search?q=test&format=json&engines=google"

# Prüfe SearXNG-Logs
docker logs searxng --tail 100 | grep -i "error\|failed"
```

**Lösung:**
- Manche Engines können rate-limited oder blockiert sein
- Versuche andere Engines: `engines=google,bing,duckduckgo`
- Erhöhe Timeout in settings.yml
- Manche Engines benötigen API-Keys (in settings.yml konfigurieren)
- Verwende `categories=general` für breitere Ergebnisse

**Problem 3: Rate-Limiting / CAPTCHA-Herausforderungen**

```bash
# Prüfe auf Rate-Limit-Fehler in Logs
docker logs searxng | grep -i "rate\|captcha\|429"

# SearXNG kann von Suchmaschinen rate-limited werden
# Lösung: Mehr Engines aktivieren um Last zu verteilen
```

**Lösung:**
- Verwende mehrere Engines gleichzeitig um Rate-Limits auf einzelnen Engines zu vermeiden
- Konfiguriere Request-Delays in settings.yml
- Erwäge Tor oder Proxy für zusätzliche Anonymität (hilft auch bei Rate-Limits)
- Reduziere Häufigkeit automatisierter Suchen
- Verwende öffentliche SearXNG-Instanzen zum Testen (searx.space)

**Problem 4: Spezifische Engine funktioniert nicht**

```bash
# Teste individuelle Engine
curl "http://searxng:8080/search?q=test&format=json&engines=google"

# Prüfe Engine-Status in Einstellungen
# Besuche: https://searxng.deinedomain.com/preferences

# Manche Engines benötigen Konfiguration
docker exec searxng cat /etc/searxng/settings.yml | grep -A10 "engines:"
```

**Lösung:**
- Nicht alle 70+ Engines funktionieren out of the box
- Manche benötigen API-Keys (Google Custom Search, Bing API, etc.)
- Konfiguriere erforderliche Engines in settings.yml
- Prüfe offizielle SearXNG-Docs für engine-spezifisches Setup
- Verwende Engines ohne API-Anforderungen: duckduckgo, wikipedia, github

**Problem 5: Kein Zugriff von n8n**

```bash
# Teste Konnektivität vom n8n-Container
docker exec n8n curl http://searxng:8080/

# Sollte HTML-Seite zurückgeben

# Teste JSON-API
docker exec n8n curl "http://searxng:8080/search?q=test&format=json"

# Prüfe ob beide Container im gleichen Netzwerk sind
docker network inspect ${PROJECT_NAME:-localai}_default | grep -E "searxng|n8n"
```

**Lösung:**
- Verwende interne URL: `http://searxng:8080` (nicht localhost oder externe Domain)
- Stelle sicher dass JSON-Format aktiviert ist (siehe Problem 1)
- Prüfe Docker-Netzwerk-Konnektivität
- Verifiziere dass searxng-Container läuft: `docker ps | grep searxng`

### Verfügbare Suchmaschinen

SearXNG unterstützt **70+ Suchmaschinen**. Hier sind die nützlichsten:

**Allgemein:**
- Google, Bing, DuckDuckGo, Yahoo, Brave Search, Startpage, Qwant

**Akademisch/Wissenschaft:**
- arXiv, Google Scholar, Semantic Scholar, PubMed, BASE, Springer

**Code/Tech:**
- GitHub, StackOverflow, npm, PyPI, Docker Hub, GitLab

**Bilder:**
- Google Images, Bing Images, Flickr, Unsplash, Pixabay, DeviantArt

**Videos:**
- YouTube, Vimeo, Dailymotion, PeerTube

**Nachrichten:**
- Google News, Bing News, Yahoo News, Reddit, Hacker News

**Dateien:**
- The Pirate Bay, Archive.org, Torrentz, Anna's Archive

**Karten:**
- OpenStreetMap, Google Maps, Bing Maps

**Sozial:**
- Reddit, Mastodon, Lemmy, Twitter (via Nitter)

Vollständige Liste verfügbar unter: https://docs.searxng.org/admin/engines/configured_engines.html

### Ressourcen

- **Offizielle Dokumentation:** https://docs.searxng.org/
- **GitHub:** https://github.com/searxng/searxng
- **Such-API-Docs:** https://docs.searxng.org/dev/search_api.html
- **Öffentliche Instanzen:** https://searx.space
- **Engine-Konfiguration:** https://docs.searxng.org/admin/engines/index.html
- **n8n-Integration:** https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.toolsearxng/

### Best Practices

**Für KI-Agenten:**
- Verwende SearXNG Tool-Node - er ist speziell für Agenten-Integration konzipiert
- Agent entscheidet automatisch wann zu suchen ist
- Liefere klare System-Prompts darüber wann Web-Suche benötigt wird
- Kombiniere mit RAG für beste Ergebnisse (SearXNG für frische Daten, Vektor-DB für historische)

**Für Recherche-Workflows:**
- Verwende Kategoriefilter (`categories=science`) für fokussierte Ergebnisse
- Spezifiziere mehrere Engines für umfassende Abdeckung
- Filtere nach time_range für aktuelle Informationen
- Dedupliziere Ergebnisse über Engines hinweg

**Für Produktion:**
- Aktiviere nur notwendige Engines um Latenz zu reduzieren
- Konfiguriere Rate-Limiting um Blocks zu vermeiden
- Verwende Ergebnis-Caching (Redis) für häufig gesuchte Begriffe
- Überwache Engine-Verfügbarkeit und passe Workflow an

**Datenschutz-Überlegungen:**
- SearXNG verbirgt deine IP vor Suchmaschinen
- Keine Cookies oder Tracking
- Ergebnisse sind nicht personalisiert (gleiche Abfrage = gleiche Ergebnisse für alle)
- Für maximale Anonymität, kombiniere mit Tor oder VPN
- Selbst gehostete Instanz = vollständige Kontrolle über Logs und Daten

**Leistungsoptimierung:**
- Aktiviere nur Engines die du tatsächlich benötigst (schnellere Ergebnisse)
- Verwende spezifische Kategorien statt alle zu durchsuchen
- Implementiere Caching für wiederholte Abfragen
- Begrenze Anzahl der Ergebnisse mit `pageno`-Parameter
- Erwäge Deaktivierung langsamer/unzuverlässiger Engines

### Wann SearXNG verwenden

**✅ Perfekt für:**
- KI-Agenten die Web-Suchfähigkeiten benötigen
- Datenschutzbewusste Such-Anwendungen
- Recherche-Aggregations-Workflows
- Competitive-Intelligence-Monitoring
- News-Monitoring und -Aggregation
- Akademische Paper-Suche
- Multi-Engine-Ergebnisvergleich
- Internes Unternehmens-Suchportal
- Alternative zu bezahlten Such-APIs (Google, Bing)

**❌ Nicht ideal für:**
- Echtzeit-Aktienkurse (verwende dedizierte Finanz-APIs)
- Hochpersonalisierte Suche (SearXNG ist absichtlich nicht-personalisiert)
- Video-Streaming (SearXNG findet Videos aber streamt sie nicht)
- Wenn du Google-Qualitäts-Ranking benötigst (Ergebnisse sind gemischt aus vielen Engines)

**SearXNG vs Google Custom Search API:**
- ✅ Kostenlos (keine API-Kosten)
- ✅ Mehr datenschutzfokussiert
- ✅ Kombiniert mehrere Engines
- ✅ Keine API-Rate-Limits (außer was Engines auferlegen)
- ❌ Etwas langsamer (fragt mehrere Engines ab)
- ❌ Weniger genaues Ranking als Google allein
- ❌ Benötigt Self-Hosting
