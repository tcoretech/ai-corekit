# 🧠 Open Notebook - KI-Wissensmanagement & Recherche-Plattform

### Was ist Open Notebook?

Open Notebook ist eine Open-Source, datenschutzorientierte Alternative zu Googles NotebookLM, die dir die vollständige Kontrolle über deine Recherche und dein Wissensmanagement gibt. Im Gegensatz zu NotebookLM, das dich in Googles Ökosystem und Modelle einschließt, unterstützt Open Notebook 16+ KI-Anbieter (OpenAI, Anthropic, Ollama, Google, Groq, Mistral, DeepSeek, xAI und mehr), läuft vollständig auf deiner Infrastruktur und verarbeitet multimodale Inhalte einschließlich PDFs, Videos, Audiodateien, Webseiten und Office-Dokumenten. Es kombiniert intelligente Dokumentenverarbeitung, KI-gestützten Chat, Vektorsuche und professionelle Podcast-Generierung zu einer umfassenden Recherche-Plattform - perfekt für Recherche-Automatisierung, Inhaltsanalyse, Wissensbank-Aufbau und KI-gestützte Notizenerstellung.

### Funktionen

- **Multimodale Inhaltsverarbeitung** - Upload von PDFs, Videos, Audio, Webseiten, YouTube-Links, Office-Dokumenten
- **16+ KI-Anbieter-Unterstützung** - OpenAI, Anthropic, Ollama, Google, Groq, Mistral, DeepSeek, xAI, OpenRouter, LM Studio
- **Erweiterte Podcast-Generierung** - Erstelle 1-4 Sprecher-Podcasts mit individuellen Profilen und Episoden-Profilen
- **Kontextbewusster Chat** - KI-Konversationen basierend auf deinen Recherchematerialien mit Quellenangaben
- **Intelligente Suche** - Volltext- und Vektorsuche über alle Inhalte
- **Inhaltstransformationen** - Integrierte und benutzerdefinierte Aktionen für Zusammenfassungen, Erkenntnisse, Extraktionen
- **Mehrere Notizbücher** - Organisiere Recherchen nach Projekt oder Thema
- **Vollständige REST-API** - Kompletter programmatischer Zugriff für n8n-Automatisierung
- **Eingebettete Datenbank** - SurrealDB inklusive, keine externen Abhängigkeiten
- **Datenschutz-zuerst** - Deine Daten verlassen niemals deinen Server

### Ersteinrichtung

**Erster Zugriff auf Open Notebook:**

1. Navigiere zu `https://notebook.yourdomain.com`
2. Gib das Passwort ein wenn aufgefordert (in `.env` als `OPENNOTEBOOK_PASSWORD` festgelegt)
3. Konfiguriere KI-Modelle in Einstellungen → Modelle:
   - **Sprachmodell:** Für Chat und Inhaltsgenerierung (z.B. gpt-4o-mini, claude-3.5-sonnet)
   - **Embedding-Modell:** Für Vektorsuche (z.B. text-embedding-3-small, nomic-embed-text)
   - **Text-zu-Sprache:** Für Podcast-Generierung (z.B. gpt-4o-mini-tts, eleven_turbo_v2_5)
   - **Sprache-zu-Text:** Für Audio-Transkription (z.B. whisper-1)
4. Erstelle dein erstes Notizbuch
5. Füge Quellen hinzu (Drag & Drop von Dateien oder URLs einfügen)

**Verwendung lokaler Modelle (Ollama):**

Open Notebook funktioniert nahtlos mit deiner Ollama-Installation:
```bash
# Open Notebook ist vorkonfiguriert um Ollama unter http://ollama:11434 zu nutzen
# Wähle einfach Ollama-Modelle in den Einstellungen:

# Sprachmodell: ollama/qwen2.5:7b-instruct-q4_K_M
# Embedding-Modell: nomic-embed-text
```

**Verwendung von Cloud-Modellen:**

API-Schlüssel werden automatisch aus deiner `.env`-Datei übernommen:
- `OPENAI_API_KEY` - Für OpenAI-Modelle
- `ANTHROPIC_API_KEY` - Für Claude-Modelle
- `GROQ_API_KEY` - Für Groq-Modelle

### n8n-Integrations-Setup

Open Notebook bietet eine umfassende REST-API für Automatisierung.

**Interne URL:** `http://opennotebook:5055`  
**API-Dokumentation:** `http://opennotebook:5055/docs` (Swagger UI)

**Authentifizierung:** Nicht erforderlich für internes Docker-Netzwerk (API-Port 5055 ist nicht extern exponiert)

**Wichtige API-Endpunkte:**
```javascript
// Notizbücher
GET    /api/notebooks           // Alle Notizbücher auflisten
POST   /api/notebooks           // Notizbuch erstellen
GET    /api/notebooks/{id}      // Notizbuch-Details abrufen
DELETE /api/notebooks/{id}      // Notizbuch löschen

// Quellen (Dokumente)
GET    /api/sources              // Quellen im Notizbuch auflisten
POST   /api/sources              // Quelle/Dokument hochladen
GET    /api/sources/{id}         // Quellen-Details abrufen
DELETE /api/sources/{id}         // Quelle löschen

// Chat
POST   /api/chat                 // Chat mit KI über deine Inhalte
GET    /api/chat/history/{id}    // Chat-Verlauf abrufen

// Notizen
GET    /api/notes                // Notizen auflisten
POST   /api/notes                // Notiz erstellen (manuell oder KI-generiert)

// Suche
POST   /api/search               // Vektor + Volltext-Suche

// Podcasts
POST   /api/podcasts             // Podcast aus Quellen generieren
GET    /api/podcasts/{id}        // Podcast-Status/Download abrufen
```

### Beispiel-Workflows

#### Beispiel 1: Automatisierte Verarbeitung von Recherche-Dokumenten
```javascript
// PDFs verarbeiten, Zusammenfassungen generieren und mit Inhalten chatten

// 1. Webhook Trigger
// Empfängt PDF-Upload-Benachrichtigung
// Input: { "file_path": "/data/shared/research/paper.pdf", "project": "KI Forschung" }

// 2. HTTP Request - Notizbuch erstellen
Method: POST
URL: http://opennotebook:5055/api/notebooks
Body: {
  "name": "{{ $json.project }} - {{ $now.format('YYYY-MM-DD') }}",
  "description": "Automatisiertes Recherche-Notizbuch"
}
// notebook_id aus Antwort speichern

// 3. HTTP Request - PDF zu Open Notebook hochladen
Method: POST
URL: http://opennotebook:5055/api/sources
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "file_path": "{{ $('Webhook').json.file_path }}",
  "transformations": ["summary", "key_points", "entities"]
}
// Open Notebook verarbeitet PDF, extrahiert Text, führt Transformationen aus

// 4. Wait Node (2 Minuten)
// Zeit für Verarbeitung und Transformationen lassen

// 5. HTTP Request - Quellen-Details abrufen
Method: GET
URL: http://opennotebook:5055/api/sources/{{ $('HTTP Request 1').json.source_id }}

// Antwort enthält verarbeiteten Inhalt und Transformationen:
{
  "id": "source_123",
  "title": "Titel des Forschungspapiers",
  "content": "Vollständig extrahierter Text...",
  "transformations": {
    "summary": "Dieses Papier diskutiert...",
    "key_points": ["Punkt 1", "Punkt 2", ...],
    "entities": ["Entität1", "Entität2", ...]
  },
  "metadata": {
    "pages": 12,
    "word_count": 5432
  }
}

// 6. HTTP Request - Chat zur Extraktion spezifischer Informationen
Method: POST
URL: http://opennotebook:5055/api/chat
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "message": "Was sind die Hauptergebnisse und die Methodik dieser Forschung?",
  "context_level": "full"  // Verwendet alle Quellen im Notizbuch
}

// 7. Code Node - Ergebnisse formatieren
const summary = $('HTTP Request 2').json.transformations.summary;
const keyPoints = $('HTTP Request 2').json.transformations.key_points;
const chatResponse = $('HTTP Request 3').json.message;

return {
  project: $('Webhook').json.project,
  document: $('HTTP Request 2').json.title,
  summary: summary,
  key_findings: keyPoints,
  detailed_analysis: chatResponse,
  notebook_url: `https://notebook.yourdomain.com/notebooks/${$('HTTP Request').json.id}`
};

// 8. Notion/Airtable Node - In Datenbank speichern
// Alle extrahierten Informationen für Team-Zugriff speichern

// 9. Slack/Email Node - Team benachrichtigen
Message: |
  📚 Neues Recherche-Dokument verarbeitet!
  
  Projekt: {{ $json.project }}
  Dokument: {{ $json.document }}
  
  Zusammenfassung: {{ $json.summary }}
  
  Hauptergebnisse:
  {{ $json.key_findings.join('\n- ') }}
  
  Vollständige Analyse ansehen: {{ $json.notebook_url }}
```

#### Beispiel 2: Podcast-Generierung aus Web-Artikeln
```javascript
// Artikel scrapen, analysieren und Mehrsprecher-Podcast generieren

// 1. Schedule Trigger
Cron: 0 8 * * *  // Täglich um 8 Uhr

// 2. HTTP Request - Tägliches News-Notizbuch erstellen
Method: POST
URL: http://opennotebook:5055/api/notebooks
Body: {
  "name": "Tägliche Tech News - {{ $now.format('YYYY-MM-DD') }}",
  "description": "Automatisierter täglicher Tech-News-Digest"
}

// 3. Set Node - News-Quellen
[
  "https://techcrunch.com/latest",
  "https://news.ycombinator.com/best",
  "https://arstechnica.com"
]

// 4. Loop Node - Jede Quelle verarbeiten
Items: {{ $json }}

// 5. HTTP Request - URL zu Open Notebook hinzufügen
Method: POST
URL: http://opennotebook:5055/api/sources
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "url": "{{ $json.item }}",
  "content_type": "url",
  "transformations": ["summary", "key_points"]
}
// Open Notebook lädt, verarbeitet und extrahiert Inhalte

// 6. Wait Node (5 Minuten)
// Verarbeitungszeit für alle Quellen lassen

// 7. HTTP Request - Podcast generieren
Method: POST
URL: http://opennotebook:5055/api/podcasts
Body: {
  "notebook_id": "{{ $('HTTP Request').json.id }}",
  "episode_profile": {
    "title": "Daily Tech Roundup",
    "description": "Aktuelle Tech-News in Podcast-Form",
    "style": "conversational",
    "duration": "10-15 Minuten"
  },
  "speakers": [
    {
      "name": "Host",
      "role": "Moderator",
      "voice": "nova",
      "personality": "Professionell und informativ"
    },
    {
      "name": "Analyst",
      "role": "Tech-Experte",
      "voice": "onyx",
      "personality": "Analytisch mit Branchenkenntnissen"
    }
  ]
}

// 8. Wait Node (10 Minuten)
// Podcast-Generierung dauert Zeit

// 9. HTTP Request - Podcast-Status prüfen
Method: GET
URL: http://opennotebook:5055/api/podcasts/{{ $('HTTP Request 2').json.podcast_id }}

// 10. IF Node - Status prüfen
{{ $json.status === "completed" }}

// 11a. HTTP Request - Podcast herunterladen
Method: GET
URL: http://opennotebook:5055/api/podcasts/{{ $('HTTP Request 2').json.podcast_id }}/download

// 11b. Code Node - Podcast in shared speichern
const fs = require('fs');
const buffer = Buffer.from($binary.data, 'base64');
const filename = `tech_news_${new Date().toISOString().split('T')[0]}.mp3`;
const filepath = `/data/shared/podcasts/${filename}`;

fs.writeFileSync(filepath, buffer);

return {
  filename: filename,
  filepath: filepath,
  notebook_url: `https://notebook.yourdomain.com/notebooks/${$('HTTP Request').json.id}`,
  podcast_url: `https://yourdomain.com/podcasts/${filename}`
};

// 12. Slack/Email Node - Podcast teilen
Message: |
  🎙️ Dein täglicher Tech-News-Podcast ist bereit!
  
  Titel: Daily Tech Roundup - {{ $now.format('DD.MM.YYYY') }}
  Dauer: ~12 Minuten
  
  Podcast anhören: {{ $json.podcast_url }}
  Quellen ansehen: {{ $json.notebook_url }}
```

#### Beispiel 3: Wissensbank-Aufbau mit automatischer Indizierung
```javascript
// Automatische Verarbeitung neuer Unternehmensdokumente

// 1. Webhook Trigger
// Wird ausgelöst wenn neue Dokumente in shared/documents/ hochgeladen werden
// Input: { "file_path": "/data/shared/documents/new_doc.pdf", "category": "HR" }

// 2. HTTP Request - Haupt-Wissensbank-Notizbuch abrufen oder erstellen
Method: GET
URL: http://opennotebook:5055/api/notebooks?name=Unternehmens-Wissensbank

// 3. IF Node - Prüfen ob Notizbuch existiert
{{ $json.notebooks.length > 0 }}

// Falls nicht, erstellen:
// 3a. HTTP Request - Notizbuch erstellen
Method: POST
URL: http://opennotebook:5055/api/notebooks
Body: {
  "name": "Unternehmens-Wissensbank",
  "description": "Zentrale Wissensbank für alle Unternehmensdokumente"
}

// 4. HTTP Request - Dokument hochladen und verarbeiten
Method: POST
URL: http://opennotebook:5055/api/sources
Body: {
  "notebook_id": "{{ $('HTTP Request').json.notebooks[0].id }}",
  "file_path": "{{ $('Webhook').json.file_path }}",
  "tags": ["{{ $('Webhook').json.category }}"],
  "transformations": ["summary", "key_points", "entities", "action_items"]
}

// 5. Wait Node (2 Minuten)
// Verarbeitung abwarten

// 6. HTTP Request - Chat-basierte FAQ-Generierung
Method: POST
URL: http://opennotebook:5055/api/chat
Body: {
  "notebook_id": "{{ $('HTTP Request 1').json.notebooks[0].id }}",
  "message": "Erstelle eine FAQ-Liste der 5 wichtigsten Fragen die aus diesem Dokument beantwortet werden können, mit kurzen Antworten.",
  "context_sources": ["{{ $('HTTP Request 2').json.source_id }}"]
}

// 7. HTTP Request - Notiz mit FAQ erstellen
Method: POST
URL: http://opennotebook:5055/api/notes
Body: {
  "notebook_id": "{{ $('HTTP Request 1').json.notebooks[0].id }}",
  "title": "FAQ - {{ $('HTTP Request 2').json.title }}",
  "content": "{{ $('HTTP Request 3').json.message }}",
  "source_ids": ["{{ $('HTTP Request 2').json.source_id }}"]
}

// 8. PostgreSQL Node - Metadata speichern
INSERT INTO documents_index (
  source_id,
  title,
  category,
  summary,
  indexed_at,
  notebook_url
)
VALUES (
  '{{ $('HTTP Request 2').json.source_id }}',
  '{{ $('HTTP Request 2').json.title }}',
  '{{ $('Webhook').json.category }}',
  '{{ $('HTTP Request 2').json.transformations.summary }}',
  NOW(),
  'https://notebook.yourdomain.com/sources/{{ $('HTTP Request 2').json.source_id }}'
);

// 9. Slack Node - Team benachrichtigen
Message: |
  📄 Neues Dokument zur Wissensbank hinzugefügt!
  
  Kategorie: {{ $('Webhook').json.category }}
  Titel: {{ $('HTTP Request 2').json.title }}
  
  Zusammenfassung: {{ $('HTTP Request 2').json.transformations.summary }}
  
  FAQ wurde automatisch erstellt.
  Im Notizbuch ansehen: https://notebook.yourdomain.com
```

### Fehlerbehebung

**Problem 1: Open Notebook startet nicht**
```bash
# Container-Logs prüfen
docker logs opennotebook

# Häufige Probleme:
# - Port-Konflikt: Prüfen ob Port 5055 belegt ist
sudo lsof -i :5055

# - Speicherplatz: Mindestens 5GB freier Speicher erforderlich
df -h

# - Docker-Netzwerk: Sicherstellen dass das Projekt-Netzwerk existiert (z.B. localai_default)
docker network ls | grep ${PROJECT_NAME:-localai}

# Container neu starten
docker restart opennotebook

# Logs live verfolgen
docker logs -f opennotebook
```

**Lösung:**
- Stelle ausreichend Speicherplatz sicher (>5GB empfohlen)
- Prüfe auf Port-Konflikte (Port 5055 muss frei sein)
- Verifiziere Docker-Netzwerk-Konnektivität
- Bei persistenten Problemen: Container vollständig neu erstellen

**Problem 2: Kann nicht von Browser auf Web-UI zugreifen**
```bash
# Caddy-Konfiguration prüfen
cat ~/ai-corekit/Caddyfile | grep -A 5 "notebook."

# Caddy-Logs prüfen
docker logs caddy | grep notebook

# DNS-Auflösung testen
nslookup notebook.yourdomain.com

# Direkter Container-Zugriff testen (sollte funktionieren)
curl http://localhost:5055

# HTTPS-Zertifikat prüfen
docker exec caddy caddy list-certificates
```

**Lösung:**
- Verifiziere dass DNS auf deinen Server zeigt
- Prüfe Caddyfile-Syntax (keine Tippfehler in Domain)
- Caddy neu laden: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
- Firewall-Regeln prüfen (Ports 80, 443 offen)

**Problem 3: KI-Modelle funktionieren nicht**
```bash
# Modell-Konfiguration prüfen
# In Web-UI: Einstellungen → Modelle

# API-Schlüssel prüfen (.env Datei)
grep -E "OPENAI_API_KEY|ANTHROPIC_API_KEY|GROQ_API_KEY" ~/ai-corekit/.env

# Ollama-Verbindung testen (für lokale Modelle)
docker exec opennotebook curl http://ollama:11434/api/tags

# Modell-Endpoints in Logs prüfen
docker logs opennotebook | grep -i "model\|api"
```

**Lösung:**
- Konfiguriere Modelle über Web-UI Einstellungen
- API-Schlüssel müssen in `.env` gesetzt sein
- Für Ollama: Stelle sicher dass Ollama-Container läuft
- Mindestens Sprachmodell und Embedding-Modell erforderlich
- TTS/STT-Modelle optional (nur für Podcast/Transkription)

**Problem 4: Datei-Upload schlägt fehl**
```bash
# Speicherplatz prüfen
df -h

# Open Notebook Speicherverzeichnis prüfen
du -sh ~/ai-corekit/opennotebook/

# Dateiberechtigungen prüfen
ls -la ~/ai-corekit/opennotebook/
chmod -R 755 ~/ai-corekit/opennotebook/

# Docker-Volume prüfen
docker volume inspect ${PROJECT_NAME:-localai}_opennotebook_data
```

**Lösung:**
- Stelle ausreichend Speicherplatz sicher (>5GB empfohlen)
- Prüfe Dateigrößen-Limits (Standard 100MB via Caddy)
- Volume-Berechtigungen verifizieren
- Für große Dateien: In kleinere Teile aufteilen oder Limits erhöhen

**Problem 5: Podcast-Generierung hängt**
```bash
# TTS-Service-Status prüfen
docker logs opennotebook | grep -i "tts\|podcast"

# TTS-Modell konfiguriert verifizieren
# Einstellungen → Modelle → Text-zu-Sprache

# Verfügbare TTS-Anbieter prüfen
curl http://opennotebook:5055/api/models/tts
```

**Lösung:**
- Podcast-Generierung erfordert TTS-Modell (OpenAI, Google oder ElevenLabs)
- Verarbeitungszeit variiert: 2-5 Minuten für kurze Podcasts, 10-20 Minuten für lange Inhalte
- Überwache Logs auf spezifische Fehler
- Inhaltslänge reduzieren falls Timeouts auftreten

**Problem 6: Suche gibt keine Ergebnisse zurück**
```bash
# Prüfe ob Quellen indiziert sind
curl http://opennotebook:5055/api/sources?notebook_id=DEINE_ID

# Embedding-Modell konfiguriert verifizieren
# Einstellungen → Modelle → Embedding-Modell

# Embedding-Service testen
docker logs opennotebook | grep -i "embedding"
```

**Lösung:**
- Embedding-Modell für Vektorsuche erforderlich
- Quellen müssen vollständig verarbeitet sein bevor sie durchsuchbar sind (Status prüfen)
- Nutze Volltext-Suche wenn Embedding nicht konfiguriert
- Quellen bei Bedarf neu indizieren (löschen und neu hochladen)

**Problem 7: Kein Zugriff von n8n möglich**
```bash
# API-Konnektivität von n8n testen
docker exec n8n curl http://opennotebook:5055/docs

# Docker-Netzwerk prüfen
docker network inspect ${PROJECT_NAME:-localai}_default | grep -E "opennotebook|n8n"

# Spezifischen Endpoint testen
docker exec n8n curl -X POST http://opennotebook:5055/api/notebooks \
  -H "Content-Type: application/json" \
  -d '{"name":"test"}'
```

**Lösung:**
- Verwende interne URL: `http://opennotebook:5055` (nicht localhost oder externe Domain)
- Verifiziere dass beide Container laufen
- Prüfe Netzwerk-Konfiguration
- Keine Authentifizierung für internen API-Zugriff erforderlich

### Konfigurations-Optionen

**KI-Anbieter-Konfiguration:**

Open Notebook unterstützt 16+ KI-Anbieter. Konfiguriere sie in der Web-UI (Einstellungen → Modelle) oder via Umgebungsvariablen.

**Unterstützte Anbieter:**
- OpenAI (`OPENAI_API_KEY`)
- Anthropic (`ANTHROPIC_API_KEY`)
- Groq (`GROQ_API_KEY`)
- Google Gemini
- Ollama (http://ollama:11434)
- Mistral
- DeepSeek
- xAI
- OpenRouter
- LM Studio
- Azure OpenAI
- Vertex AI
- Perplexity
- ElevenLabs (TTS)
- Voyage (Embeddings)

**Speicher-Konfiguration:**
```bash
# Datenverzeichnisse (relativ zu ~/ai-corekit)
./opennotebook/notebook_data/  # Notizbücher und Inhalte
./opennotebook/surreal_data/   # Eingebettete SurrealDB
./shared/                      # Geteilt mit anderen Services
```

**Passwort-Schutz:**
```bash
# In .env Datei
OPENNOTEBOOK_PASSWORD=dein_sicheres_passwort

# Leer lassen für rein lokale Deployments (kein Passwort erforderlich)
OPENNOTEBOOK_PASSWORD=
```

**Modell-Standards (empfohlen):**
```
Sprache: gpt-4o-mini (OpenAI) oder claude-3.5-sonnet (Anthropic)
Embedding: text-embedding-3-small (OpenAI) oder nomic-embed-text (Ollama)
TTS: gpt-4o-mini-tts (OpenAI) oder eleven_turbo_v2_5 (ElevenLabs)
STT: whisper-1 (OpenAI) oder groq/whisper-large-v3 (Groq)
```

### Ressourcen

- **GitHub:** https://github.com/lfnovo/open-notebook
- **Dokumentation:** https://www.open-notebook.ai
- **Web-Interface:** `https://notebook.yourdomain.com`
- **API-Endpunkt:** `http://opennotebook:5055`
- **API-Docs (Swagger):** `http://opennotebook:5055/docs`
- **Discord Community:** https://discord.gg/open-notebook
- **NotebookLM-Vergleich:** https://www.open-notebook.ai/comparison

### Best Practices

**Für Recherche-Workflows:**
- Erstelle separate Notizbücher für jedes Projekt/Thema
- Nutze Inhaltstransformationen (Zusammenfassungen, Kernpunkte) beim Upload
- Tagge und organisiere Quellen systematisch
- Verwende Vektorsuche für semantische Abfragen, Volltext für exakte Treffer
- Exportiere wichtige Erkenntnisse in externe Wissensbank (Notion, Obsidian)

**Für Podcast-Erstellung:**
- Beginne mit 2 Sprechern (Host + Gast), erweitere auf 3-4 für Panel-Diskussionen
- Definiere klare Sprecher-Rollen und Persönlichkeiten für Konsistenz
- Episoden-Profile verbessern die Output-Qualität dramatisch
- Teste zuerst mit kürzerem Inhalt (5-10 Min) bevor du längere Episoden erstellst
- Nutze hochwertige TTS-Modelle (OpenAI, ElevenLabs) für Produktions-Podcasts

**Für Wissensmanagement:**
- Baue ein "Master"-Notizbuch pro Bereich auf (z.B. Unternehmens-Wissensbank)
- Regelmäßige Inhaltsüberprüfung und Aufräumen (alte/irrelevante Quellen archivieren)
- Nutze Chat-Verlauf um FAQs aus häufigen Fragen zu erstellen
- Kombiniere mit Vektordatenbank (Qdrant) für Notizbuch-übergreifende Suche
- Richte automatisierte Workflows für neue Dokumentenaufnahme ein

**Für n8n-Integration:**
- Verwende interne API-URL (`http://opennotebook:5055`) für alle Anfragen
- Keine Authentifizierung für internes Netzwerk erforderlich
- Implementiere Retry-Logik für langläufige Operationen (Podcast-Generierung)
- Cache häufige Abfragen in Redis oder PostgreSQL
- Nutze Webhooks um Workflows bei neuen Inhalten auszulösen

**Performance-Tipps:**
- Verwende kleinere LLM-Modelle für schnellere Antworten (gpt-4o-mini vs gpt-4)
- Begrenze Quellengröße für Notizbücher (<100 Quellen für optimale Performance)
- Nutze Inhaltstransformationen strategisch (nicht bei jedem Upload)
- Speichere verarbeitete Inhalte in externer Datenbank für komplexe Analysen
- Überwache Speichernutzung (Embeddings können mit vielen Quellen groß werden)

**Datenschutz-Überlegungen:**
- Mit Ollama: Komplett lokale Verarbeitung, keine externen API-Aufrufe
- API-Schlüssel lokal gespeichert, niemals zu Open Notebook-Servern übertragen
- Nativer Passwort-Schutz für öffentliche Deployments
- Alle Daten gespeichert in `./opennotebook/` Verzeichnis (einfaches Backup/Migration)
- Für maximalen Datenschutz: Nutze Ollama für alle Modelle (LLM, Embedding, TTS)

### Wann Open Notebook verwenden

**✅ Perfekt für:**
- Forschungs-Projektmanagement und Wissenskompilation
- Multimodale Inhaltsanalyse (PDFs + Videos + Audio)
- Aufbau durchsuchbarer Wissensbanken mit KI-Q&A
- Podcast-Generierung aus geschriebenen Inhalten
- Akademische Forschung mit Zitaten und Quellenverfolgung
- Inhalts-Recherche und Zusammenfassung im großen Maßstab
- Team-Wissensaustausch und Dokumentation
- NotebookLM-Alternative mit mehr Flexibilität
- Private KI-gestützte Notizenerstellung

**❌ Nicht ideal für:**
- Echtzeit-Zusammenarbeit (kein simultanes Bearbeiten)
- Einfache Notizenerstellung ohne KI-Features (nutze stattdessen Notion)
- Wenn du Googles spezifische Gemini-Modelle benötigst
- Video/Audio-Bearbeitung (Open Notebook extrahiert Inhalte, bearbeitet nicht)
- Wenn Bandbreite extrem begrenzt ist (große Uploads erforderlich)

**Open Notebook vs NotebookLM:**
- ✅ 16+ KI-Anbieter vs nur Google-Modelle
- ✅ Self-hosted (komplette Datenkontrolle)
- ✅ 1-4 Podcast-Sprecher vs nur 2
- ✅ Vollständige REST-API für Automatisierung
- ✅ Kein Vendor Lock-in
- ❌ Erfordert Self-Hosting-Setup
- ❌ Keine Google Workspace-Integration

**Open Notebook vs Obsidian:**
- ✅ KI-gestützter Chat und Analyse
- ✅ Multimodale Inhaltsunterstützung
- ✅ Automatische Inhaltstransformationen
- ✅ Podcast-Generierung
- ❌ Nicht Markdown-nativ
- ❌ Weniger Community-Plugins
- ❌ Web-basiertes Interface (keine Desktop-App)

**Open Notebook vs RAGapp:**
- ✅ Bessere UI/UX für Endbenutzer
- ✅ Podcast-Generierungs-Feature
- ✅ Multi-Notizbuch-Organisation
- ✅ Mehr KI-Anbieter-Unterstützung
- ❌ RAGapp entwickler-fokussierter
- ❌ RAGapp besser für reine RAG-Implementierungen
