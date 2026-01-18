# 📚 RAGApp - RAG-Assistenten-Builder

### Was ist RAGApp?

RAGApp ist eine unternehmensreife Plattform zum Erstellen von Agentischen RAG (Retrieval-Augmented Generation) Anwendungen, basierend auf LlamaIndex. Es ist so einfach zu konfigurieren wie OpenAIs Custom GPTs, aber in deiner eigenen Cloud-Infrastruktur mit Docker bereitstellbar. RAGApp bietet eine vollständige Lösung mit Admin-UI, Chat-UI und REST-API, mit der du KI-Assistenten erstellen kannst, die intelligent über deine Dokumente und Daten nachdenken können.

### Funktionen

- **Agentisches RAG mit LlamaIndex** - Autonomer Agent, der über Anfragen nachdenken, sie in kleinere Aufgaben aufteilen, Tools dynamisch auswählen und mehrstufige Workflows ausführen kann
- **Mehrere KI-Anbieter-Unterstützung** - Funktioniert mit OpenAI, Google Gemini und lokalen Modellen über Ollama
- **Admin-UI** - Einfache Web-Oberfläche zum Konfigurieren deines RAG-Assistenten ohne Code
- **Chat-UI & REST-API** - Sofort einsatzbereite Chat-Oberfläche und API-Endpunkte für Integration
- **Dokumentenverwaltung** - Hochladen und Verarbeiten von PDFs, Office-Dokumenten, Textdateien und mehr
- **Tool-Integration** - Verbindung zu externen APIs und Wissensdatenbanken
- **Docker-basierte Bereitstellung** - Einfaches Container-basiertes Setup mit docker-compose

### Ersteinrichtung

**Erster Login bei RAGApp:**

1. Navigiere zu `https://ragapp.deinedomain.com/admin`
2. **KI-Anbieter konfigurieren:**
   - **Option A - OpenAI:** Füge deinen OpenAI API-Schlüssel hinzu
   - **Option B - Gemini:** Füge deinen Google AI API-Schlüssel hinzu
   - **Option C - Ollama:** Verwende `http://ollama:11434` (vorkonfiguriert)
3. **Dokumente hochladen:**
   - Klicke auf "Documents" in der Admin-UI
   - Lade deine PDFs, DOCX, TXT oder andere Dateien hoch
   - Dokumente werden automatisch verarbeitet und indexiert
4. **Assistenten konfigurieren:**
   - Setze System-Prompt und Anweisungen
   - Wähle aus, welche Tools aktiviert werden sollen
   - Konfiguriere Retrieval-Einstellungen (top-k, Ähnlichkeitsschwelle)
5. **In Chat-UI testen:**
   - Navigiere zu `https://ragapp.deinedomain.com`
   - Stelle Fragen zu deinen Dokumenten
   - Assistent nutzt agentisches Reasoning, um Antworten zu finden

**Vorkonfigurierte Integration:**
- **Interne Ollama-URL:** `http://ollama:11434` (bereits gesetzt)
- **Qdrant Vector Store:** `http://qdrant:6333` (wird für Embeddings verwendet)

### n8n Integration Setup

**Zugriff auf RAGApp API von n8n:**

- **Interne URL:** `http://ragapp:8000`
- **API-Docs:** `http://ragapp:8000/docs` (OpenAPI/Swagger)
- **Keine Authentifizierung** standardmäßig (konzipiert für internen Einsatz hinter API-Gateway)

#### Beispiel 1: Einfacher Dokumenten-Q&A-Workflow

Fragen zu hochgeladenen Dokumenten über n8n stellen:

```javascript
// 1. Webhook-Trigger - Frage vom externen System empfangen

// 2. HTTP Request: RAGApp abfragen
Methode: POST
URL: http://ragapp:8000/api/chat
Header:
  Content-Type: application/json
Body: {
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.question }}"
    }
  ],
  "stream": false
}

// 3. Code Node: Antwort extrahieren
const response = $json.choices[0].message.content;
const sources = $json.sources || [];
return {
  answer: response,
  sources: sources.map(s => s.metadata.file_name),
  confidence: $json.confidence_score
};

// 4. Antwort zurücksenden (Slack, E-Mail, etc.)
```

#### Beispiel 2: Dokumenten-Upload & Verarbeitungs-Pipeline

Dokumente automatisch hochladen und verarbeiten:

```javascript
// 1. E-Mail-Trigger: PDF-Anhang empfangen

// 2. HTTP Request: Dokument zu RAGApp hochladen
Methode: POST
URL: http://ragapp:8000/api/documents
Header:
  Content-Type: multipart/form-data
Body:
  - Datei: {{ $binary.data }}
  - metadata: {
      "source": "email",
      "processed_date": "{{ $now.format('YYYY-MM-DD') }}"
    }

// 3. Wait Node: Zeit zum Verarbeiten geben (30 Sekunden)

// 4. HTTP Request: Dokumentenstatus prüfen
Methode: GET
URL: http://ragapp:8000/api/documents/{{ $json.document_id }}

// 5. Condition Node: Wenn Verarbeitung abgeschlossen
If: {{ $json.status === 'completed' }}
Then: Bestätigungs-E-Mail senden
Else: Fehler protokollieren und wiederholen
```

#### Beispiel 3: Agentischer Recherche-Workflow

RAGApps agentische Fähigkeiten nutzen, um mehrstufige Recherchen über mehrere Dokumente durchzuführen:

```javascript
// 1. Schedule Trigger: Tägliche Recherche-Aufgabe

// 2. HTTP Request: Komplexe Recherche-Anfrage
Methode: POST
URL: http://ragapp:8000/api/chat
Body: {
  "messages": [
    {
      "role": "user",
      "content": "Analysiere alle Quartalsberichte von 2024 und fasse wichtige finanzielle Trends zusammen. Vergleiche Umsatzwachstum über Q1-Q4."
    }
  ],
  "agent_config": {
    "tools": ["document_search", "summarize", "compare"],
    "max_steps": 10,
    "reasoning": true
  }
}

// Der Agent wird:
// - Anfrage in Teilaufgaben aufteilen
// - Relevante Quartalsberichte suchen
// - Finanzdaten extrahieren
// - Über Quartale hinweg vergleichen
// - Umfassende Zusammenfassung synthetisieren

// 3. Code Node: Recherche-Bericht formatieren
const report = {
  title: "Q1-Q4 2024 Finanzanalyse",
  summary: $json.choices[0].message.content,
  sources: $json.sources,
  reasoning_steps: $json.agent_steps,
  generated_at: new Date().toISOString()
};

// 4. HTTP Request: In Supabase speichern
// 5. E-Mail: Bericht an Stakeholder senden
```

#### Beispiel 4: Multi-Quellen-Wissens-Integration

RAGApp mit externen APIs kombinieren für umfassende Antworten:

```javascript
// 1. Webhook: Kundensupport-Frage empfangen

// 2. HTTP Request: Interne Docs durchsuchen (RAGApp)
URL: http://ragapp:8000/api/chat
Body: {
  "messages": [{"role": "user", "content": "{{ $json.question }}"}]
}

// 3. Bedingung: Wenn RAGApp nicht vollständig antworten kann
If: {{ $json.confidence_score < 0.7 }}

// 4a. HTTP Request: Web durchsuchen (SearXNG)
URL: http://searxng:8080/search
Abfrage: {{ $json.question }}

// 4b. HTTP Request: Produktdatenbank abfragen
// Neueste Produktinformationen abrufen

// 5. Code Node: Ergebnisse zusammenführen
const answer = {
  primary_answer: $('RAGApp').first().json.response,
  confidence: $('RAGApp').first().json.confidence_score,
  additional_context: $('SearXNG').first().json.results.slice(0, 3),
  product_info: $('ProductDB').first().json
};

// 6. HTTP Request: Zurück an RAGApp für finale Synthese
URL: http://ragapp:8000/api/chat
Body: {
  "messages": [
    {
      "role": "system",
      "content": "Synthetisiere die folgenden Informationen zu einer umfassenden Antwort..."
    },
    {
      "role": "user",
      "content": JSON.stringify(answer)
    }
  ]
}

// 7. Finale Antwort an Kunden senden
```

### Erweiterte Konfiguration

#### RAG-Performance optimieren

**Chunking-Strategie:**
```yaml
# In Admin UI > Settings > Retrieval
chunk_size: 1024  # Kleiner für präzises Retrieval
chunk_overlap: 128  # 10-20% Überlappung empfohlen
```

**Retrieval-Einstellungen:**
```yaml
top_k: 5  # Anzahl der abzurufenden Chunks
similarity_threshold: 0.7  # Minimaler Ähnlichkeitsscore (0-1)
rerank: true  # Reranking für bessere Ergebnisse aktivieren
```

**Embedding-Modelle:**
- **OpenAI:** `text-embedding-3-small` (schnell, kosteneffizient)
- **OpenAI:** `text-embedding-3-large` (beste Qualität)
- **Ollama:** `nomic-embed-text` (lokal, kostenlos)

#### Benutzerdefinierte System-Prompts verwenden

Konfiguriere das Verhalten deines Assistenten in der Admin-UI:

```
Du bist ein Finanzanalyse-Assistent, spezialisiert auf Quartalsberichte.

Beim Beantworten von Fragen:
1. Zitiere immer spezifische Abschnitte und Seitenzahlen aus Dokumenten
2. Vergleiche Daten über verschiedene Zeiträume hinweg, wenn relevant
3. Hebe signifikante Trends oder Anomalien hervor
4. Wenn Daten fehlen oder unklar sind, gib dies explizit an

Formatiere deine Antworten mit:
- Executive Summary (2-3 Sätze)
- Detaillierte Analyse (mit Zitaten)
- Wichtige Erkenntnisse (Aufzählungspunkte)
```

#### Tool-Konfiguration

Zusätzliche Tools für agentisches Reasoning aktivieren:

- **Dokumentensuche:** Semantische Suche über hochgeladene Dokumente
- **Zusammenfassung:** Erstelle Zusammenfassungen langer Dokumente
- **Vergleich:** Vergleiche mehrere Dokumente oder Datenpunkte
- **Externe APIs:** Verbindung zu externen Datenquellen
- **Code-Ausführung:** Python-Code für Datenanalyse ausführen (Enterprise-Feature)

### Fehlerbehebung

**Dokumente werden nicht indexiert:**

```bash
# 1. RAGApp-Logs prüfen
docker logs ragapp --tail 50

# 2. Prüfen ob Qdrant läuft
docker ps | grep qdrant
curl http://localhost:6333/health

# 3. Dokumentenformat prüfen
# Unterstützt: PDF, DOCX, TXT, MD, HTML, CSV
# Nicht unterstützte oder beschädigte Dateien werden übersprungen

# 4. Verfügbaren Speicherplatz prüfen
df -h
# Dokumente und Indizes benötigen Speicher

# 5. Dokument erneut hochladen
# Löschen und erneut hochladen, wenn Verarbeitung fehlgeschlagen ist
```

**Niedrige Antwortqualität:**

```bash
# 1. Ähnlichkeitsschwelle prüfen
# Schwelle senken, wenn keine Ergebnisse gefunden werden (versuche 0.5-0.6)

# 2. top_k-Wert erhöhen
# Versuche mehr Chunks abzurufen (10-15 statt 5)

# 3. Embedding-Modell prüfen
# In Admin UI: Settings > Models > Embedding Model
# Stelle sicher, dass Modell geladen ist und funktioniert

# 4. Embeddings direkt testen
curl -X POST http://ragapp:8000/api/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "test query"}'
# Sollte Embedding-Vektor zurückgeben

# 5. Dokumentenqualität überprüfen
# Stelle sicher, dass Dokumente klare Struktur haben
# Entferne gescannte PDFs niedriger Qualität
# Verwende OCR für bildbasierte Dokumente
```

**API-Verbindungsprobleme:**

```bash
# 1. Prüfen ob RAGApp von n8n aus erreichbar ist
docker exec n8n curl http://ragapp:8000/health
# Sollte zurückgeben: {"status": "healthy"}

# 2. API-Endpunkt prüfen
# Admin UI: Settings > API > Base URL
# Sollte sein: http://ragapp:8000

# 3. API direkt testen
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hallo"}
    ]
  }'

# 4. Docker-Netzwerk prüfen
docker network inspect ai-corekit_default
# Prüfen ob ragapp und n8n im selben Netzwerk sind

# 5. RAGApp bei Bedarf neu starten
docker compose restart ragapp
```

**Ollama-Modell nicht gefunden:**

```bash
# 1. Prüfen ob Ollama läuft
docker ps | grep ollama

# 2. Prüfen welche Modelle verfügbar sind
docker exec ollama ollama list

# 3. Benötigtes Modell herunterladen
docker exec ollama ollama pull llama3.2

# 4. RAGApp-Konfiguration aktualisieren
# Admin UI > Settings > Models > LLM Model
# Wählen: ollama/llama3.2

# 5. Verbindung testen
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3.2", "prompt": "test"}'
```

### Best Practices

**Dokumentenvorbereitung:**
- Dokumente vor dem Hochladen bereinigen und strukturieren
- Konsistente Formatierung verwenden (Überschriften, Abschnitte)
- Metadaten in Dateinamen einbeziehen (Datum, Autor, Version)
- Unnötige Seiten entfernen (Cover, leere Seiten)
- Für gescannte Dokumente zuerst OCR verwenden

**Prompt-Engineering:**
- Sei spezifisch, welche Informationen du benötigst
- Referenziere Dokumenttypen oder Abschnitte wenn möglich
- Stelle Nachfragen, um Antworten zu verfeinern
- Verwende Beispiele in deinem System-Prompt

**Performance-Optimierung:**
- Beginne mit weniger Dokumenten und skaliere
- Überwache Embedding-Kosten (bei OpenAI-Nutzung)
- Verwende lokales Ollama für Entwicklung/Testing
- Cache häufige Anfragen wo möglich
- Verarbeite Dokumente in Batches außerhalb der Hauptzeiten

**Sicherheit:**
- Hinter API-Gateway für Authentifizierung bereitstellen
- Umgebungsvariablen für API-Schlüssel verwenden
- HTTPS in Produktion aktivieren
- Rate Limiting implementieren
- Dokumentenzugriffs-Logs prüfen

### Integration mit anderen AI CoreKit Services

**RAGApp + Qdrant:**
- Qdrant ist als Vector Store vorkonfiguriert
- Alle Embeddings in `http://qdrant:6333` gespeichert
- Verwende Qdrant-UI zum Durchsuchen von Collections und Inspizieren von Vektoren

**RAGApp + Flowise:**
- Verwende Flowise für komplexe Multi-Agenten-Workflows
- RAGApp übernimmt Dokumenten-Q&A
- Flowise orchestriert die gesamte Agenten-Logik
- Beispiel: Recherche-Agent, der RAGApp abfragt → zusammenfasst → nächste Aktion entscheidet

**RAGApp + Open WebUI:**
- Erstelle benutzerdefinierten OpenAI-kompatiblen API-Wrapper um RAGApp
- Benutzer können auf RAGApp-Wissen über vertraute ChatGPT-Oberfläche zugreifen
- Kombiniere beide UIs: RAGApp für dokumentenfokussierte Arbeit, Open WebUI für allgemeinen Chat

**RAGApp + n8n:**
- Automatisiere Dokumenten-Ingestion-Pipelines
- Plane regelmäßige Anfragen und Berichte
- Integriere in Business-Workflows (E-Mail, Slack, CRM)
- Erstelle Self-Service-Wissensportale

### Ressourcen

- **Offizielle Website:** https://www.ragapp.dev/
- **Dokumentation:** https://docs.ragapp.dev/
- **GitHub:** https://github.com/ragapp/ragapp
- **LlamaIndex Docs:** https://docs.llamaindex.ai/
- **API-Referenz:** `http://ragapp.deinedomain.com/docs` (OpenAPI)
- **Community:** LlamaIndex Discord
