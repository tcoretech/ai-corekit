# 🔎 Perplexica - KI-gestützte Suchmaschine

### Was ist Perplexica?

Perplexica ist eine Open-Source-KI-gestützte Suchmaschine, die Perplexity-AI-ähnliche Funktionalität für Tiefenrecherche und intelligente Informationsbeschaffung bietet. Im Gegensatz zu traditionellen Suchmaschinen nutzt Perplexica KI, um den Kontext deiner Anfrage zu verstehen, mehrere Quellen zu durchsuchen und umfassende Antworten mit Quellenangaben zu synthetisieren. Es kombiniert Web-Such-Fähigkeiten mit großen Sprachmodellen, um kontextuelle, gut recherchierte Antworten zu liefern - perfekt für Rechercheautomatisierung, Content-Generierung und Wissensentdeckung.

### Features

- **KI-gestützte Suche** - Nutzt LLMs zum Verstehen von Anfragen und Synthetisieren umfassender Antworten
- **Mehrere Fokus-Modi** - Websuche, wissenschaftliche Arbeiten, YouTube, Reddit, Schreibassistent, WolframAlpha
- **Quellenangaben** - Alle Antworten enthalten anklickbare Quellen und Referenzen
- **Chat-Oberfläche** - Konversationelle Suche mit Kontext-Erhaltung über Anfragen hinweg
- **RESTful API** - Vollständiger API-Zugriff für Automatisierung und n8n-Integration
- **SearXNG-Integration** - Nutzt dein selbst gehostetes SearXNG für datenschutzfreundliche Suche
- **Lokale LLM-Unterstützung** - Funktioniert mit Ollama für vollständig private, offline Recherche

### Ersteinrichtung

**Erster Zugriff auf Perplexica:**

1. Navigiere zu `https://perplexica.deinedomain.com`
2. Keine Anmeldung erforderlich - starte sofort mit der Suche
3. Probiere verschiedene Fokus-Modi aus:
   - **Websuche:** Allgemeine Internetsuche mit KI-Synthese
   - **Akademische Suche:** Wissenschaftliche Arbeiten und Forschung
   - **YouTube-Suche:** Video-Content-Entdeckung
   - **Reddit-Suche:** Community-Diskussionen und Meinungen
   - **Schreibassistent:** Hilfe bei der Content-Erstellung
   - **WolframAlpha:** Mathematische und rechnerische Anfragen
4. Chat-Verlauf wird in deinem Browser gespeichert (lokaler Speicher)

**LLM-Backend konfigurieren:**

Perplexica ist standardmäßig für die Nutzung von Ollama (lokal) vorkonfiguriert. Du kannst auch OpenAI oder andere Anbieter verwenden:

```bash
# Aktuelle Konfiguration prüfen
cd ~/ai-corekit
cat perplexica-config.toml

# Standard nutzt Ollama mit llama3.2
# Um OpenAI zu verwenden, Config bearbeiten und API-Key hinzufügen
nano perplexica-config.toml

# Perplexica neu starten
docker compose restart perplexica
```

### n8n-Integrationssetup

Perplexica bietet eine REST-API für programmatischen Zugriff von n8n.

**Interne URL:** `http://perplexica:3000`

**API-Endpunkte:**
- `POST /api/search` - KI-gestützte Suche durchführen
- `GET /api/models` - Verfügbare LLM-Modelle auflisten
- `GET /api/config` - Aktuelle Konfiguration abrufen

### Beispiel-Workflows

#### Beispiel 1: KI-Recherche-Assistent

```javascript
// Erstelle einen KI-gestützten Recherche-Assistenten mit tiefer Websuche

// 1. Chat Trigger Node
// Nutzer stellt eine Recherchefrage

// 2. HTTP Request Node - Perplexica-Suche
Methode: POST
URL: http://perplexica:3000/api/search
Header:
  Content-Type: application/json
Send Body: JSON
Body: {
  "query": "{{ $json.chatInput }}",
  "focusMode": "webSearch",
  "chatHistory": []
}

// Antwortformat:
{
  "message": "Umfassende KI-generierte Antwort...",
  "sources": [
    {
      "title": "Quellentitel",
      "url": "https://example.com",
      "snippet": "Relevanter Auszug..."
    }
  ]
}

// 3. Code Node - Antwort mit Quellen formatieren
const answer = $input.item.json.message;
const sources = $input.item.json.sources || [];

const formattedResponse = `${answer}\n\n**Quellen:**\n${sources.map((s, i) => 
  `${i + 1}. [${s.title}](${s.url})`
).join('\n')}`;

return {
  response: formattedResponse,
  sourceCount: sources.length
};

// 4. Chat Response Node
// Sende formatierte Antwort mit anklickbaren Quellen zurück an Nutzer
```

#### Beispiel 2: Akademischer Recherche-Aggregator

```javascript
// Automatisierte akademische Paper-Suche und Zusammenfassung

// 1. Schedule Trigger
Cron: 0 9 * * MON  // Jeden Montag um 9 Uhr

// 2. Set Node - Recherche-Themen
[
  "quantum computing error correction",
  "CRISPR gene therapy clinical trials",
  "carbon capture technologies 2025"
]

// 3. Loop Node - Jedes Thema recherchieren
Items: {{ $json }}

// 4. HTTP Request - Perplexica Akademische Suche
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.topic }} latest research papers",
  "focusMode": "academicSearch",  // Durchsucht arXiv, Scholar, PubMed
  "chatHistory": []
}

// 5. Code Node - Papers parsen und Metadaten extrahieren
const response = $input.item.json;
const sources = response.sources || [];

// Nach akademischen Quellen filtern
const papers = sources.filter(s => 
  s.url.includes('arxiv.org') || 
  s.url.includes('scholar.google') ||
  s.url.includes('pubmed')
).map(paper => ({
  title: paper.title,
  url: paper.url,
  snippet: paper.snippet,
  topic: $('Loop').item.json.topic,
  discovered: new Date().toISOString()
}));

return papers;

// 6. Loop Node - Jedes Paper verarbeiten
Items: {{ $json }}

// 7. HTTP Request - Vollständiges Abstract abrufen (falls verfügbar)
// Paper-URL oder DOI verwenden, um mehr Details zu erhalten

// 8. Qdrant Node - Paper-Embedding speichern
// Vektor-Embedding für semantische Suche später erstellen

// 9. Notion Node - Zur Recherche-Datenbank hinzufügen
Database: Academic Papers
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Abstract: {{ $json.snippet }}
  Topic: {{ $json.topic }}
  Date Added: {{ $json.discovered }}
  Status: "To Review"

// 10. Gmail Node - Wöchentliche Zusammenfassung
To: research-team@company.com
Subject: Wöchentliche Akademische Recherche-Zusammenfassung
Body: |
  Recherche-Ergebnisse dieser Woche über alle Themen:
  
  {{ $('Loop').itemCount }} neue Papers entdeckt
  
  Nach Thema:
  {{ groupedByTopic }}
  
  Vollständige Datenbank ansehen: [Notion Link]
```

#### Beispiel 3: Content-Recherche-Pipeline

```javascript
// Themen recherchieren und Content mit KI generieren

// 1. Webhook Trigger
// Input: { "topic": "sustainable packaging innovations", "contentType": "blog post" }

// 2. HTTP Request - Erste Recherche via Perplexica
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.topic }} comprehensive overview latest trends statistics",
  "focusMode": "webSearch",
  "chatHistory": []
}

// 3. Code Node - Kernpunkte und Unterthemen extrahieren
const research = $input.item.json.message;
const sources = $input.item.json.sources || [];

// KI-Antwort nach Überschriften/Struktur parsen
const sections = research.match(/###? (.+)/g) || [];
const keyPoints = sections.map(s => s.replace(/###? /, ''));

return {
  mainResearch: research,
  keyPoints: keyPoints.slice(0, 5),  // Top 5 Punkte
  sources: sources,
  originalTopic: $('Webhook').json.topic
};

// 4. Loop Node - Tiefer Tauchgang in jeden Kernpunkt
Items: {{ $json.keyPoints }}

// 5. HTTP Request - Jedes Unterthema recherchieren
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.item }} detailed information examples case studies",
  "focusMode": "webSearch",
  "chatHistory": [
    {
      "role": "user",
      "content": "{{ $('Code Node').json.originalTopic }}"
    },
    {
      "role": "assistant", 
      "content": "{{ $('Code Node').json.mainResearch }}"
    }
  ]  // Kontext über Suchen hinweg beibehalten!
}

// 6. Aggregate Node - Alle Recherchen kombinieren
const mainResearch = $('Code Node').json;
const deepDives = $input.all().map(x => x.json);

const completeResearch = {
  topic: mainResearch.originalTopic,
  overview: mainResearch.mainResearch,
  sections: mainResearch.keyPoints.map((point, i) => ({
    heading: point,
    content: deepDives[i]?.message || '',
    sources: deepDives[i]?.sources || []
  })),
  allSources: [
    ...mainResearch.sources,
    ...deepDives.flatMap(d => d.sources || [])
  ]
};

// Doppelte Quellen entfernen
completeResearch.allSources = [...new Map(
  completeResearch.allSources.map(s => [s.url, s])
).values()];

return completeResearch;

// 7. OpenAI Node - Strukturierten Artikel generieren
Modell: gpt-4o
System: "Du bist ein Experte für Content-Erstellung. Erstelle gut strukturierte, ansprechende Inhalte."
  Schreibe einen umfassenden {{ $('Webhook').json.contentType }} über:
  {{ $json.topic }}
  
  Nutze diese Recherche:
  Überblick: {{ $json.overview }}
  
  Zu behandelnde Abschnitte:
  {{ $json.sections.map(s => `- ${s.heading}: ${s.content.substring(0, 200)}...`).join('\n') }}
  
  Anforderungen:
  - 1500-2000 Wörter
  - Bereitgestellte Recherche genau verwenden
  - Relevante Statistiken und Beispiele einbeziehen
  - Professioneller aber ansprechender Ton
  - SEO-freundliche Struktur mit H2/H3-Überschriften

// 8. Code Node - Mit Zitaten formatieren
const article = $input.item.json.article;
const sources = $('Aggregate Node').json.allSources;

// Referenzen-Abschnitt hinzufügen
const references = sources.map((s, i) => 
  `${i + 1}. ${s.title} - ${s.url}`
).join('\n');

const completeArticle = `${article}\n\n---\n\n## Referenzen\n\n${references}`;

return {
  article: completeArticle,
  wordCount: article.split(' ').length,
  sourceCount: sources.length
};

// 9. WordPress/Ghost Node - Entwurf veröffentlichen
Title: {{ $('Webhook').json.topic }}
Inhalt: {{ $json.article }}
Status: Draft
Tags: [{{ $('Webhook').json.topic }}, Research-Based]

// 10. Slack Node - Content-Team benachrichtigen
Kanal: #content-team
Nachricht: |
  📝 Neuer Artikel-Entwurf zur Prüfung bereit
  
  **Thema:** {{ $('Webhook').json.topic }}
  **Wortanzahl:** {{ $json.wordCount }}
  **Quellen:** {{ $json.sourceCount }} Referenzen
  
  Prüfen unter: [WordPress Link]
```

#### Beispiel 4: Competitive-Intelligence-Monitor

```javascript
// Konkurrenten mit KI-gestützter Recherche überwachen

// 1. Schedule Trigger
Cron: 0 */6 * * *  // Alle 6 Stunden

// 2. Set Node - Konkurrenten-Liste
[
  "Competitor A",
  "Competitor B",
  "Competitor C"
]

// 3. Loop Node - Jeden Konkurrenten recherchieren
Items: {{ $json }}

// 4. HTTP Request - Aktuelle News-Suche
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.competitor }} latest news announcements funding product launches last 24 hours",
  "focusMode": "webSearch",
  "chatHistory": []
}

// 5. HTTP Request - Community-Sentiment
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.competitor }} reddit discussions reviews opinions sentiment",
  "focusMode": "redditSearch",  // Reddit-spezifische Suche
  "chatHistory": []
}

// 6. Code Node - Intelligence kombinieren
const competitor = $('Loop').item.json.competitor;
const news = $input.all()[0].json;
const sentiment = $input.all()[1].json;

return {
  competitor: competitor,
  newsFindings: news.message,
  newsSources: news.sources || [],
  sentimentAnalysis: sentiment.message,
  sentimentSources: sentiment.sources || [],
  timestamp: new Date().toISO()
};

// 7. OpenAI Node - Analysieren und zusammenfassen
Modell: gpt-4o-mini
Prompt: |
  Analysiere diese Competitive Intelligence:
  
  Konkurrent: {{ $json.competitor }}
  
  Aktuelle News:
  {{ $json.newsFindings }}
  
  Community-Sentiment:
  {{ $json.sentimentAnalysis }}
  
  Liefere:
  1. Zusammenfassung wichtiger Entwicklungen (2-3 Sätze)
  2. Sentiment-Score (-10 bis +10)
  3. Strategische Auswirkungen für uns
  4. Bedrohungslevel (Niedrig/Mittel/Hoch)
  5. Empfohlene Maßnahmen

// 8. PostgreSQL Node - Intelligence speichern
Table: competitive_intel
Fields:
  competitor: {{ $('Code Node').json.competitor }}
  news_summary: {{ $('OpenAI').json.summary }}
  sentiment_score: {{ $('OpenAI').json.sentiment }}
  threat_level: {{ $('OpenAI').json.threat }}
  raw_data: {{ $('Code Node').json }}
  analyzed_at: {{ $now }}

// 9. IF Node - Bei hochpriorisierter Intel warnen
Bedingung: {{ $('OpenAI').json.threat === 'High' }}

// 10. Slack Node - Alarm senden
Kanal: #competitive-intel
Priority: High
Nachricht: |
  🚨 Hochprioritäts-Intel-Alarm
  
  **Konkurrent:** {{ $('Code Node').json.competitor }}
  **Bedrohungslevel:** {{ $('OpenAI').json.threat }}
  
  **Wichtige Entwicklungen:**
  {{ $('OpenAI').json.summary }}
  
  **Empfohlene Maßnahmen:**
  {{ $('OpenAI').json.actions }}
  
  **Quellen:**
  {{ $('Code Node').json.newsSources.slice(0, 3).map(s => s.url).join('\n') }}
```

#### Beispiel 5: YouTube-Content-Kuratierung

```javascript
// YouTube-Content zu spezifischen Themen entdecken und kuratieren

// 1. Webhook Trigger
// Input: { "topic": "machine learning tutorials", "minViews": 10000 }

// 2. HTTP Request - YouTube-Suche via Perplexica
Methode: POST
URL: http://perplexica:3000/api/search
Body: {
  "query": "{{ $json.topic }} tutorial beginner to advanced comprehensive",
  "focusMode": "youtubeSearch",  // YouTube-spezifische Suche
  "chatHistory": []
}

// Antwort enthält YouTube-Video-Empfehlungen

// 3. Code Node - Video-Ergebnisse parsen
const response = $input.item.json;
const sources = response.sources || [];

// YouTube-Videos extrahieren
const videos = sources.filter(s => s.url.includes('youtube.com')).map(video => ({
  title: video.title,
  url: video.url,
  description: video.snippet,
  videoId: video.url.match(/watch\?v=(.+)/)?.[1],
  addedAt: new Date().toISO()
}));

return videos;

// 4. Loop Node - Jedes Video anreichern
Items: {{ $json }}

// 5. HTTP Request - Video-Metadaten abrufen (YouTube API Alternative)
// Oder Video-Seite für Aufrufzahlen, Dauer, etc. scrapen

// 6. IF Node - Nach Kriterien filtern
Bedingung: {{ $json.viewCount >= $('Webhook').json.minViews }}

// 7. Notion Node - Zur Content-Bibliothek hinzufügen
Database: Video Library
Properties:
  Title: {{ $json.title }}
  URL: {{ $json.url }}
  Topic: {{ $('Webhook').json.topic }}
  Views: {{ $json.viewCount }}
  Duration: {{ $json.duration }}
  Added: {{ $json.addedAt }}
  Status: "To Review"

// 8. Discord/Slack - Mit Team teilen
Kanal: #learning-resources
Nachricht: |
  📺 Neue Videos kuratiert für: {{ $('Webhook').json.topic }}
  
  {{ $('Loop').itemCount }} qualitativ hochwertige Videos gefunden:
  {{ $('Loop').all().map(v => `- ${v.json.title}\n  ${v.json.url}`).join('\n\n') }}
```

### Fokus-Modi-Referenz

Perplexica unterstützt verschiedene Fokus-Modi für spezialisierte Suchen:

| Fokus-Modus | Beschreibung | Am besten für | Beispiel-Anfrage |
|------------|-------------|----------|---------------|
| **webSearch** | Allgemeine Websuche über alle Quellen | Breite Recherche, aktuelle Ereignisse | "Latest AI developments 2025" |
| **academicSearch** | Wissenschaftliche Arbeiten (arXiv, Scholar, PubMed) | Forschungsarbeiten, akademische Arbeit | "CRISPR gene editing clinical trials" |
| **youtubeSearch** | Video-Content-Entdeckung | Tutorials, Vorträge, visuelles Lernen | "React hooks tutorial explained" |
| **redditSearch** | Community-Diskussionen | Meinungen, Erfahrungen, Bewertungen | "Best VPS provider recommendations" |
| **writingAssistant** | Hilfe bei Content-Erstellung | Entwürfe, Bearbeitung, Ideenfindung | "Write introduction about blockchain" |
| **wolframAlphaSearch** | Mathematische & rechnerische Anfragen | Berechnungen, Datenanalyse | "Solve differential equation x^2 + 3x" |

### API-Request-Format

**Basis-Suchanfrage:**
```json
POST http://perplexica:3000/api/search
Content-Type: application/json

{
  "query": "Deine Suchanfrage hier",
  "focusMode": "webSearch",
  "chatHistory": []
}
```

**Mit Chat-Verlauf (Kontextuelle Suche):**
```json
{
  "query": "Erzähl mir mehr über den zweiten Punkt",
  "focusMode": "webSearch",
  "chatHistory": [
    {
      "role": "user",
      "content": "Was ist Quantencomputing?"
    },
    {
      "role": "assistant",
      "content": "Quantencomputing ist..."
    }
  ]
}
```

**Antwortformat:**
```json
{
  "message": "KI-generierte umfassende Antwort mit Kontext...",
  "sources": [
    {
      "title": "Artikeltitel",
      "url": "https://example.com/artikel",
      "snippet": "Relevanter Auszug aus der Quelle..."
    }
  ]
}
```

### Fehlerbehebung

**Problem 1: Perplexica antwortet nicht**

```bash
# Prüfen, ob Perplexica läuft
docker ps | grep perplexica

# Logs auf Fehler prüfen
docker logs perplexica --tail 100

# Perplexica neu starten
docker compose restart perplexica

# Prüfen, ob SearXNG erreichbar ist (Perplexica hängt davon ab)
docker exec perplexica curl http://searxng:8080/
```

**Lösung:**
- Perplexica benötigt laufendes SearXNG mit aktivierter JSON-API
- SearXNG-Konfiguration prüfen (siehe SearXNG-Abschnitt oben)
- Verifizieren, dass Ollama läuft, falls lokale LLMs genutzt werden
- Docker-Netzwerk-Konnektivität prüfen

**Problem 2: Langsame Antwortzeiten**

```bash
# Prüfen, welches LLM-Backend konfiguriert ist
docker exec perplexica cat /app/config.toml | grep -A5 "CHAT"

# Falls Ollama genutzt wird, prüfen ob Modell heruntergeladen ist
docker exec ollama ollama list

# Bei Bedarf kleineres/schnelleres Modell laden
docker exec ollama ollama pull llama3.2:3b  # Kleineres, schnelleres Modell
```

**Lösung:**
- Schnellere LLM-Modelle nutzen (llama3.2:3b statt llama3.2:70b)
- Suchtiefe/Quellen in Config reduzieren
- webSearch-Modus statt academicSearch nutzen (schneller)
- Sicherstellen, dass Ollama ausreichend RAM zugewiesen hat

**Problem 3: Keine Quellen in der Antwort**

```bash
# SearXNG-Integration prüfen
docker logs perplexica | grep -i "searxng\|search"

# SearXNG direkt testen
curl "http://searxng:8080/search?q=test&format=json"

# Falls SearXNG keine Ergebnisse liefert, SearXNG-Logs prüfen
docker logs searxng --tail 50
```

**Lösung:**
- Verifizieren, dass SearXNG JSON-API aktiviert ist (siehe SearXNG-Abschnitt)
- Prüfen, ob Suchmaschinen in SearXNG funktionieren
- Andere Suchanfrage ausprobieren
- Netzwerk-Konnektivität zwischen Perplexica und SearXNG verifizieren

**Problem 4: "Out of Memory"-Fehler**

```bash
# Ollama-Speicherverbrauch prüfen
docker stats ollama --no-stream

# Perplexica-Speicherverbrauch prüfen
docker stats perplexica --no-stream

# RAM freigeben durch Stoppen ungenutzter Services
docker compose stop <unused-service>
```

**Lösung:**
- Kleinere LLM-Modelle verwenden (3B statt 7B oder 13B Parameter)
- Docker-Speicherlimits in docker-compose.yml erhöhen
- Andere schwergewichtige Services temporär schließen
- Bei speicherbeschränkten Systemen OpenAI-API statt lokalem Ollama nutzen

**Problem 5: Kein Zugriff von n8n**

```bash
# Konnektivität vom n8n-Container testen
docker exec n8n curl http://perplexica:3000/

# Sollte HTML-Seite zurückgeben

# API-Endpunkt testen
docker exec n8n curl -X POST http://perplexica:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test","focusMode":"webSearch","chatHistory":[]}'

# Prüfen, ob beide Container im gleichen Netzwerk sind
docker network inspect ${PROJECT_NAME:-localai}_default | grep -E "perplexica|n8n"
```

**Lösung:**
- Interne URL verwenden: `http://perplexica:3000` (nicht localhost)
- Verifizieren, dass beide Container laufen
- Docker-Netzwerk-Konfiguration prüfen
- Sicherstellen, dass API-Endpunkt-Pfad korrekt ist: `/api/search`

### Konfigurationsoptionen

**Modellauswahl:**

`~/ai-corekit/perplexica-config.toml` bearbeiten:

```toml
[CHAT]
# Ollama verwenden (lokal, privat)
provider = "ollama"
model = "llama3.2"  # oder: llama3.2:3b, mistral, etc.

# Oder OpenAI verwenden (schneller, aber extern)
# provider = "openai"
# model = "gpt-4o-mini"
# api_key = "your-api-key"
```

**Such-Konfiguration:**

```toml
[SEARXNG]
# SearXNG-Instanz-URL
url = "http://searxng:8080"

# Maximale Anzahl der Suchergebnisse
max_results = 10

# Such-Timeout (Sekunden)
timeout = 30
```

### Ressourcen

- **GitHub:** https://github.com/ItzCrazyKns/Perplexica
- **Web-Oberfläche:** `https://perplexica.deinedomain.com`
- **API-Endpunkt:** `http://perplexica:3000/api/search`
- **Perplexity AI (Inspiration):** https://www.perplexity.ai
- **SearXNG-Integration:** Siehe SearXNG-Abschnitt oben

### Best Practices

**Für Recherche-Workflows:**
- `chatHistory`-Parameter nutzen, um Kontext über mehrere Suchen hinweg zu erhalten
- Mit `webSearch` beginnen, dann `academicSearch` für tieferen Tauchgang nutzen
- Quellen extrahieren und in Vektor-Datenbank (Qdrant) für zukünftige Referenz speichern
- Mit LightRAG oder Neo4j kombinieren, um Wissensgraphen aus Recherche zu erstellen

**Für Content-Generierung:**
- Thema zuerst mit Perplexica recherchieren
- Umfassende Antwort als Kontext für Content-Generierung nutzen (OpenAI, Claude)
- Immer Quellenangaben im finalen Content einbeziehen
- Fakten aus mehreren Perplexica-Suchen verifizieren

**Für Competitive Intelligence:**
- Regelmäßige Suchen planen (alle 6-12 Stunden)
- Mehrere Fokus-Modi nutzen (webSearch + redditSearch) für umfassende Sicht
- Ergebnisse in Datenbank für Trendanalyse speichern
- Alarme für signifikante Änderungen oder neue Entwicklungen einrichten

**Performance-Tipps:**
- Häufige Anfragen in Redis oder PostgreSQL cachen
- Kleinere LLM-Modelle für schnellere Antworten nutzen
- Request-Queuing für hochvolumige Workflows implementieren
- Rate-Limiting in Betracht ziehen, um SearXNG nicht zu überlasten

**Datenschutz-Überlegungen:**
- Perplexica nutzt dein selbst gehostetes SearXNG (datenschutzfreundlich)
- Mit Ollama-Backend: vollständig privat, keine externen API-Aufrufe
- Chat-Verlauf lokal im Browser gespeichert, nicht auf Server
- Für maximalen Datenschutz: lokale LLMs + selbst gehostetes SearXNG nutzen

### Wann Perplexica nutzen

**✅ Perfekt für:**
- Tiefenrecherche mit KI-Synthese
- Akademische Paper-Entdeckung und Analyse
- Content-Recherche und Faktenprüfung
- Competitive-Intelligence-Sammlung
- Multi-Quellen-Informations-Aggregation
- YouTube-Content-Kuratierung
- Reddit-Sentiment-Analyse
- Schreibassistenz mit aktuellen Informationen
- Mathematische Anfragen (WolframAlpha-Modus)

**❌ Nicht ideal für:**
- Einfache Keyword-Suchen (stattdessen SearXNG direkt nutzen)
- Echtzeit-Daten-Updates (dedizierte APIs nutzen)
- Wenn rohe Suchergebnisse ohne KI-Interpretation benötigt werden
- Hochzeitempfindliche Anfragen (Perplexica fügt Verarbeitungszeit hinzu)

**Perplexica vs SearXNG:**
- **Perplexica:** KI-synthetisierte Antworten mit Quellen, langsamer, kontextuell
- **SearXNG:** Rohe Suchergebnisse, schneller, keine KI-Verarbeitung
- **Beide nutzen:** SearXNG für schnelle Lookups, Perplexica für Recherche

**Perplexica vs ChatGPT/Claude:**
- ✅ Enthält immer Quellenangaben
- ✅ Nutzt Echtzeit-Websuche (nicht Trainingsdaten)
- ✅ Vollständig selbst gehostet und privat
- ❌ Langsamer als reine LLM-Anfragen
- ❌ Benötigt SearXNG-Abhängigkeit
