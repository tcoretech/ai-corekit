# 🧠 Dify - LLMOps Platform

### Was ist Dify?

Dify ist eine Open-Source LLMOps-Plattform (Large Language Model Operations), die entwickelt wurde, um die Entwicklung, Bereitstellung und Verwaltung von produktionsreifen KI-Anwendungen zu vereinfachen. Sie überbrückt die Lücke zwischen Prototyping und Produktion durch visuelle Workflow-Builder, RAG-Pipelines, Agenten-Funktionen und umfassende Monitoring-Tools. Betrachte es als "Backend-as-a-Service für KI" - ermöglicht Entwicklern den Aufbau anspruchsvoller KI-Anwendungen ohne komplexe Backend-Infrastruktur.

### Funktionen

- **Visueller Workflow-Builder** - Drag-and-Drop-Oberfläche (Chatflow- & Workflow-Modi) zum Erstellen von KI-Anwendungen
- **Mehrere Anwendungstypen** - Chatbots, Textgeneratoren, KI-Agenten und Automatisierungs-Workflows
- **Prompt-IDE** - Integrierter Prompt-Bearbeiteor mit Variablen, Versionierung und A/B-Testing
- **RAG-Engine** - Hochwertige Dokumentenverarbeitung, Embedding und Abruf mit mehreren Vektor-Datenbanken
- **Agenten-Funktionen** - Function-Calling, ReACT-Reasoning, über 50 integrierte Tools (Google Search, DALL·E, etc.)
- **Modellverwaltung** - Unterstützung für über 100 LLM-Anbieter (OpenAI, Anthropic, Ollama, Groq, etc.)
- **Backend-as-a-Service API** - Produktionsreife REST-APIs für alle Anwendungen
- **LLMOps & Observability** - Echtzeit-Monitoring, Logs, Annotationen und Performance-Tracking
- **Multi-Tenancy** - Workspace-Verwaltung für Teams und Organisationen
- **Dataset-Management** - Hochladen, Annotieren und Verwalten von Trainings-/Test-Datensätzen
- **Versionskontrolle** - Änderungen an Prompts, Workflows und Konfigurationen nachverfolgen
- **Human-in-the-Loop** - Annotations-Workflows für kontinuierliche Verbesserung

### Ersteinrichtung

**Erster Login bei Dify:**

1. Navigiere zu `https://dify.deinedomain.com`
2. **Erstelle Workspace-Owner-Account** (erster Benutzer wird Admin)
3. Setze starkes Passwort (mindestens 8 Zeichen)
4. Vervollständige Workspace-Einrichtung:
   - Workspace-Name: Name deiner Organisation
   - Sprache: Englisch, Chinesisch, Deutsch, etc.
5. Einrichtung abgeschlossen!

**LLM-Anbieter konfigurieren:**

1. Gehe zu **Einstellungen** → **Modellanbieter**
2. Füge deine KI-Anbieter hinzu:

**Für Ollama (lokal, kostenlos):**
```
Anbieter: Ollama
Base URL: http://ollama:11434
Modelle: Automatisch erkannt (llama3.2, mistral, qwen, etc.)
```

**Für OpenAI:**
```
Anbieter: OpenAI  
API Key: sk-...
Modelle: gpt-4o, gpt-4o-mini, gpt-4-turbo
```

**Für Anthropic:**
```
Anbieter: Anthropic
API Key: sk-ant-...
Modelle: claude-3-5-sonnet-20241022, claude-3-5-haiku-20241022
```

3. **Verbindung testen** - Klicke auf "Test"-Button für jeden Anbieter
4. Konfiguration speichern

**API-Key generieren (für n8n-Integration):**

1. Gehe zu **Einstellungen** → **API-Keys**
2. Klicke auf **API-Key erstellen**
3. Name: "n8n Integration" oder "Externe Dienste"
4. Wähle Berechtigungen aus:
   - `apps.read` - App-Konfigurationen lesen
   - `apps.write` - Apps erstellen und ändern
   - `datasets.read` - Zugriff auf Wissensdatenbanken
5. **Kopiere API-Key sofort** - du wirst ihn nicht nochmal sehen!
6. Speichere sicher im Passwort-Manager

### n8n Integration Setup

**Dify-Credentials in n8n erstellen:**

Dify hat keine native n8n-Node. Nutze HTTP-Request-Nodes mit Bearer-Token-Authentifizierung.

1. Erstelle in n8n Credentials:
   - Typ: **Header Auth**
   - Name: **Dify API**
   - Name (Header): `Authorization`
   - Wert: `Bearer DEIN_DIFY_API_KEY`

2. Verbindung testen:
   ```bash
   # Von n8n HTTP Request Node
   GET http://dify-api:5001/v1/parameters
   ```

**Interne URL:** `http://dify-api:5001` (API-Server)  
**Externe URL:** `https://dify.deinedomain.com/v1`
**Web-UI:** `https://dify.deinedomain.com` (zum visuellen Erstellen von Apps)

### Beispiel-Workflows

#### Beispiel 1: Kunden-Support-Chatbot mit RAG

Erstelle einen KI-Support-Agenten, der aus deiner Dokumentation antwortet. Vollständiges Workflow-Beispiel verfügbar im Projektwissen unter [Name des Workflow-Beispiels].

#### Beispiel 2: Massen-Content-Generierung

Nutze Dify für automatisierte Content-Erstellung im großen Maßstab. Siehe Projektwissen für vollständige Implementierung.

#### Beispiel 3: KI-Agent mit Tools

Erstelle intelligente Agenten, die externe Tools und APIs nutzen. Siehe Dify-Dokumentation für Agenten-Konfiguration.

### Dify-Anwendungstypen

**Chatbot (Chatflow):**
- Multi-Turn-Konversationen mit Gedächtnis
- Kundenservice, semantische Suche
- Nutzt `chat-messages` API-Endpoint
- Kontinuierliche Kontexterhaltung

**Textgenerator (Completion):**
- Single-Turn-Textgenerierung
- Schreiben, Übersetzung, Klassifizierung
- Nutzt `completion-messages` API-Endpoint
- Formular-Eingabe + Ergebnis-Ausgabe

**Agent:**
- Autonome Aufgabenausführung
- Function-Calling mit Tools
- ReACT-Reasoning-Pattern
- Kann sowohl Chat- als auch Completion-APIs nutzen

**Workflow:**
- Visuelle Orchestrierungs-Plattform
- Automatisierung und Batch-Verarbeitung
- Komplexe mehrstufige Logik
- Nutzt `workflows/run` API-Endpoint

### Fehlerbehebung

**Verbindung abgelehnt:**

```bash
# 1. Prüfe ob Dify-Services laufen
docker ps | grep dify

# Du solltest sehen:
# - dify-api (Port 5001)
# - dify-web (Port 3000)
# - dify-worker
# - dify-db (PostgreSQL)
# - dify-redis

# 2. Teste API-Konnektivität
curl http://localhost:5001/v1/parameters

# 3. Prüfe Dify-Logs
docker logs dify-api --tail 50
docker logs dify-worker --tail 50

# 4. Neustarten falls nötig
docker compose restart dify-api dify-worker
```

**API-Authentifizierung schlägt fehl:**

```bash
# 1. Überprüfe API-Key-Format
# Muss sein: Authorization: Bearer app-xxxxxxxxxxxx

# 2. Teste mit curl
curl -X POST http://localhost:5001/v1/chat-messages \
  -H "Authorization: Bearer DEIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"inputs": {}, "query": "test", "response_mode": "blocking", "user": "test"}'
```

**RAG gibt keine relevanten Dokumente zurück:**

```bash
# 1. Prüfe ob Wissensdatenbank korrekt verarbeitet wurde
# Dify UI → Wissen → Deine KB → Verarbeitungsstatus

# 2. Passe Abruf-Einstellungen an:
# - Top K: Erhöhe auf 5-10
# - Score-Schwellenwert: Senke auf 0.3-0.5
# - Aktiviere Reranking für bessere Relevanz

# 3. Indiziere Wissensdatenbank neu falls nötig
```

### Ressourcen

- **Offizielle Website:** https://dify.ai/
- **Dokumentation:** https://docs.dify.ai/
- **GitHub:** https://github.com/langgenius/dify
- **API-Referenz:** https://docs.dify.ai/api-reference
- **Community:** https://github.com/langgenius/dify/discussions
- **Blog:** https://dify.ai/blog

### Best Practices

**Anwendungsdesign:**
- Beginne einfach, iteriere basierend auf Ergebnissen
- Nutze Chatflow für Konversationen, Workflow für Automatisierung
- Teste mit vielfältigen Eingaben vor Produktiveinsatz
- Implementiere Human-in-the-Loop für kritische Anwendungen

**RAG-Optimierung:**
- Chunk-Größe: 500-1000 Zeichen
- Nutze Metadaten-Filterung für Präzision
- Aktiviere Reranking für Relevanz
- Regelmäßige Wissensdatenbank-Updates

**Produktion:**
- Nutze API-Keys pro Umgebung
- Überwache Token-Nutzung und Kosten
- Implementiere Rate-Limiting
- Logge Interaktionen für Qualitätsprüfung

**Sicherheit:**
- Exponiere niemals API-Keys im Frontend
- Rotiere regelmäßig API-Keys
- Implementiere Input-Validierung
- Nutze Dify's integrierte Benutzerverwaltung
