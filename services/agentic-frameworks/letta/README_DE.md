# 💾 Letta - Zustandsbehaftete KI-Agenten-Plattform

### Was ist Letta?

Letta (ehemals MemGPT) ist eine fortschrittliche Plattform zum Erstellen zustandsbehafteter KI-Agenten mit persistentem Langzeitgedächtnis, die im Laufe der Zeit lernen und sich weiterentwickeln. Im Gegensatz zu traditionellen LLMs, die zustandslos arbeiten und bei denen jede Interaktion isoliert stattfindet, bewahren Letta-Agenten ein kontinuierliches Gedächtnis über Sitzungen hinweg und bilden aktiv Erinnerungen basierend auf gesammelter Erfahrung. Entwickelt von KI-Forschern der UC Berkeley, die MemGPT erschaffen haben, bietet Letta eine Agent Development Environment zur Visualisierung und Verwaltung von Agenten-Gedächtnis, Reasoning-Schritten und Tool-Aufrufen. Agenten existieren weiter und behalten ihren Zustand auch wenn deine Anwendung nicht läuft, wobei die Berechnung auf dem Server stattfindet und alle Erinnerungen, Kontext und Tool-Verbindungen vom Letta-Server verwaltet werden.

### Funktionen

- **Zustandsbehaftete Agenten** - Agenten mit dauerhaftem (unendlichem) Nachrichtenverlauf, der über Sitzungen hinweg bestehen bleibt
- **Fortgeschrittenes Speichersystem** - Selbstbearbeitende Speicherblöcke (Persona, Mensch, Archiv), die sich im Laufe der Zeit weiterentwickeln
- **Agent Development Environment (ADE)** - No-Code-UI zum Erstellen, Testen und Debuggen von Agenten mit vollständiger Sichtbarkeit in Gedächtnis und Reasoning
- **Modell-agnostisch** - Funktioniert mit jedem LLM (OpenAI, Anthropic, Groq, Ollama, lokale Modelle)
- **Sleep-Time-Agenten** - Hintergrund-Agenten, die Gedächtnis während Ausfallzeiten verarbeiten und verfeinern
- **Agent File (.af)** - Offenes Dateiformat zum Serialisieren und Teilen zustandsbehafteter Agenten
- **Multi-Agenten-Speicher-Sharing** - Einzelne Speicherblöcke können an mehrere Agenten angehängt werden
- **Tool-Integration** - Integrierte Unterstützung für Composio, LangChain, CrewAI-Tools und MCP-Server
- **Vollständige API & SDKs** - REST-API mit nativen Python- und TypeScript-SDKs
- **Letta Cloud oder Self-Hosted** - Stelle Agenten in der Cloud bereit oder betreibe deinen eigenen Server

### Ersteinrichtung

**Erster Login bei Letta:**

1. Navigiere zu `https://letta.deinedomain.com`
2. **Standardmäßig keine Authentifizierung** - Die Agent Development Environment (ADE) öffnet sich direkt
3. Falls du Passwortschutz in `.env` aktiviert hast, nutze deine konfigurierten Zugangsdaten
4. Du siehst die ADE-Oberfläche mit Optionen zum Erstellen von Agenten, Anzeigen des Gedächtnisses und Testen von Tools

**LLM-Anbieter konfigurieren:**

1. Klicke in der ADE auf **Einstellungen** → **Modelle**
2. Füge deine KI-Modellanbieter hinzu:

**Für Ollama (lokal, kostenlos):**
```
Anbietertyp: Ollama
Base URL: http://ollama:11434
Modelle: Automatisch erkannt (llama3.2, mistral, qwen2.5)
```

**Für OpenAI:**
```
Anbietertyp: OpenAI
API Key: sk-...
Modelle: gpt-4.1, gpt-4.o-mini, o1-preview
Embedding: text-embedding-3-small
```

**Für Anthropic:**
```
Anbietertyp: Anthropic
API Key: sk-ant-...
Modelle: claude-4.5-sonnet-20250929
```

**Für Groq (schnelle Inferenz):**
```
Anbietertyp: Groq
API Key: gsk-...
Modelle: llama-3.1-70b-versatile, mixtral-8x7b
```

3. **Verbindung testen** - Klicke auf "Test", um jeden Anbieter zu verifizieren
4. **Standard-Modell festlegen** - Wähle, welches Modell standardmäßig für neue Agenten verwendet werden soll

**Erstelle deinen ersten Agenten:**

1. Klicke auf **Agent erstellen** in der ADE
2. Konfiguriere Agenten-Speicherblöcke:
   - **Persona-Block**: "Mein Name ist Sam, ein hilfreicher KI-Assistent..."
   - **Human-Block**: "Der Name des Menschen ist [Benutzer]..."
3. Wähle dein LLM-Modell und Embedding-Modell
4. Füge Tools hinzu (optional): web_search, calculator, send_email, etc.
5. Klicke auf **Erstellen** - dein zustandsbehafteter Agent läuft jetzt!
6. Sende eine Nachricht zum Testen - der Agent wird sich für immer an diese Konversation erinnern

**API-Key generieren (für n8n/externe Integration):**

1. **Bei Nutzung von Letta Cloud:** Hole API-Key von `https://app.letta.com/settings`
2. **Bei Self-Hosted ohne Passwort:** Kein API-Key erforderlich, nutze Base-URL direkt
3. **Bei Self-Hosted mit Passwort:** Nutze dein konfiguriertes Passwort als Token
4. Speichere diesen Key sicher für die Nutzung in n8n-Workflows

### n8n Integration Setup

**Letta-Credentials in n8n erstellen:**

Letta hat keine native n8n-Node. Nutze HTTP-Request-Nodes mit der Letta REST-API.

1. Erstelle in n8n Credentials (nur bei Verwendung von Authentifizierung):
   - Typ: **Header Auth**
   - Name: **Letta API**
   - Header-Name: `Authorization`
   - Wert: `Bearer DEIN_LETTA_API_KEY` (für Letta Cloud) oder nur `DEIN_PASSWORT` (für Self-Hosted mit Passwort)

2. Für Self-Hosted ohne Authentifizierung werden keine Credentials benötigt

**Interne URL:** `http://letta:8283`  
**Externe URL:** `https://letta.deinedomain.com`
**ADE Web-UI:** `https://letta.deinedomain.com` (Agent Development Environment)

### Letta's Speichersystem verstehen

**Speicherblöcke:**

Letta-Agenten verwalten Gedächtnis durch bearbeitbare "Speicherblöcke":

- **Kern-Speicherblöcke:**
  - `human` - Informationen über den Benutzer
  - `persona` - Persönlichkeit und Rolle des Agenten
  
- **Archiv-Speicher:**
  - Unendlich großer Speicher für Fakten und Wissen
  - Durchsuchbar mit embedding-basiertem Abruf
  
- **Recall-Speicher:**
  - Konversationshistorie gespeichert als durchsuchbare Datenbank
  - Agenten können vergangene Interaktionen durchsuchen

**Wie es funktioniert:**

1. Agent empfängt Nachricht
2. Prüft aktuelle Speicherblöcke im Kontextfenster
3. Kann Archiv- oder Recall-Speicher bei Bedarf durchsuchen
4. Kann eigene Speicherblöcke mit Tools bearbeiten
5. Zustand wird nach jedem Schritt automatisch gespeichert

### Beispiel-Workflows

#### Beispiel 1: Zustandsbehafteten Agenten via n8n erstellen

Erstelle einen persistenten Agenten, der sich an alle vergangenen Konversationen erinnert:

```javascript
// n8n Workflow: Letta-Agent erstellen

// 1. HTTP Request Node - Agent erstellen
Methode: POST
URL: http://letta:8283/v1/agents
Authentifizierung: Nutze Letta-Credentials (falls passwortgeschützt)
Header:
  Content-Type: application/json
Body:
{
  "name": "Kundensupport-Agent",
  "model": "openai/gpt-4.1",
  "embedding": "openai/text-embedding-3-small",
  "memory_blocks": [
    {
      "label": "human",
      "value": "Kundenname: Neuer Kunde\nKonto-Stufe: Kostenlos\nPräferenzen: Unbekannt"
    },
    {
      "label": "persona",
      "value": "Ich bin ein hilfreicher Kundensupport-Agent. Ich erinnere mich an alle vergangenen Interaktionen und lerne im Laufe der Zeit über Kundenpräferenzen. Ich pflege professionelle, freundliche Kommunikation."
    }
  ],
  "tools": ["send_message", "core_memory_append", "core_memory_replace", "archival_memory_insert", "conversation_search"]
}

// Response enthält agent.id
// Beispiel: "agent-d9be2c54-1234-5678-9abc-def012345678"

// 2. PostgreSQL Node - Agent ID speichern (optional)
Operation: Einfügen
Table: letta_agents
Daten:
  agent_id: {{ $json.id }}
  customer_email: {{ $('Trigger').json.email }}
  created_at: {{ new Date().toISOString() }}

// Agent ist jetzt erstellt und wird unbegrenzt bestehen bleiben
```

#### Beispiel 2: Chat mit zustandsbehaftetem Agenten

Interagiere mit einem persistenten Agenten, der sich Kontext über Sitzungen hinweg merkt:

```javascript
// n8n Workflow: Chat mit Letta-Agent

// 1. Webhook Trigger - Benutzernachricht empfangen
POST /webhook/letta-chat
Body: { "agent_id": "agent-...", "message": "Hallo, erinnerst du dich an mich?" }

// 2. HTTP Request Node - Nachricht an Agent senden
Methode: POST
URL: http://letta:8283/v1/agents/{{ $json.agent_id }}/messages
Header:
  Content-Type: application/json
Body:
{
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.message }}"
    }
  ],
  "stream": false
}

// 3. Code Node - Antwort extrahieren
const response = $input.first().json;

// Assistenten-Nachricht finden (Antwort des Agenten an Benutzer)
const assistantMessage = response.messages.find(
  msg => msg.message_type === 'assistant_message'
);

// Reasoning-Nachrichten finden (innere Gedanken des Agenten)
const reasoning = response.messages.filter(
  msg => msg.message_type === 'reasoning_message'
);

// Tool-Aufrufe finden (Speicher-Bearbeitungen, Suchen)
const toolCalls = response.messages.filter(
  msg => msg.message_type === 'tool_call_message'
);

return {
  json: {
    agent_reply: assistantMessage?.content || "Keine Antwort",
    agent_thoughts: reasoning.map(r => r.content),
    memory_edits: toolCalls.map(t => ({
      tool: t.tool_call?.name,
      args: t.tool_call?.arguments
    })),
    usage: response.usage
  }
};

// 4. Benutzer antworten Node
Antwort:
  reply: {{ $json.agent_reply }}
  
// Der Agent hat automatisch den gesamten Kontext gespeichert - beim nächsten Chat
// wird sich der Agent an die gesamte Konversation erinnern
```

#### Beispiel 3: Agent mit benutzerdefinierten Tools

Erstelle einen Agenten mit Zugriff auf externe APIs und Tools:

```javascript
// n8n Workflow: Letta-Agent mit benutzerdefinierten Tools

// 1. HTTP Request - Agent mit Tools erstellen
Methode: POST
URL: http://letta:8283/v1/agents
Body:
{
  "name": "Recherche-Assistent",
  "model": "anthropic/claude-4.5-sonnet-20250929",
  "embedding": "openai/text-embedding-3-small",
  "memory_blocks": [
    {
      "label": "human",
      "value": "Forscher arbeitet an KI-Sicherheit"
    },
    {
      "label": "persona",
      "value": "Ich bin ein Recherche-Assistent, spezialisiert auf KI-Sicherheit. Ich kann im Web suchen, Papiere lesen und umfassende Notizen zu Forschungsthemen pflegen."
    }
  ],
  "tools": [
    "send_message",
    "core_memory_replace",
    "archival_memory_insert",
    "archival_memory_search",
    "web_search",
    "read_arxiv_paper",
    "save_research_notes"
  ]
}

// Hinweis: Benutzerdefinierte Tools (web_search, read_arxiv_paper, save_research_notes)
// müssen zuerst im Letta-Server registriert werden

// 2. Benutzer sendet: "Finde aktuelle Papiere zu Claude 4 und fasse wichtige Erkenntnisse zusammen"

// 3. Agent wird:
// - web_search Tool nutzen, um Papiere zu finden
// - read_arxiv_paper nutzen, um Inhalte zu extrahieren
// - Erkenntnisse mit archival_memory_insert speichern
// - Mit Zusammenfassung über send_message antworten

// 4. Später fragt Benutzer: "Was haben wir über Claude 4 gefunden?"

// 5. Agent wird:
// - archival_memory_search nutzen, um vergangene Erkenntnisse abzurufen
// - Umfassende Antwort basierend auf gespeicherter Recherche geben
// - Keine erneute Web-Suche nötig - es ist im Gedächtnis des Agenten
```

#### Beispiel 4: Multi-Agent mit gemeinsam genutztem Speicher

Erstelle mehrere Agenten, die denselben Speicherblock teilen:

```javascript
// n8n Workflow: Multi-Agent-System

// 1. HTTP Request - Gemeinsamen Speicherblock erstellen
Methode: POST
URL: http://letta:8283/v1/blocks
Body:
{
  "label": "project_knowledge",
  "value": "Projekt: AI CoreKit\nStatus: Aktiv\nTeammitglieder: Alice, Bob\nSchlüsselentscheidungen: ..."
}

// Antwort: { "id": "block-shared-123" }

// 2. HTTP Request - Agent 1 erstellen (Developer)
Methode: POST
URL: http://letta:8283/v1/agents
Body:
{
  "name": "Developer Agent",
  "model": "openai/gpt-4.1",
  "memory_blocks": [
    { "label": "persona", "value": "Ich bin ein Entwickler-Agent, fokussiert auf Code-Implementierung." },
    { "id": "block-shared-123" }  // Referenz auf gemeinsamen Block
  ],
  "tools": ["send_message", "core_memory_replace", "run_code", "git_commit"]
}

// 3. HTTP Request - Agent 2 erstellen (Product Manager)
Methode: POST
URL: http://letta:8283/v1/agents
Body:
{
  "name": "PM Agent",
  "model": "openai/gpt-4.1",
  "memory_blocks": [
    { "label": "persona", "value": "Ich bin ein Product-Manager-Agent, fokussiert auf Anforderungen und Planung." },
    { "id": "block-shared-123" }  // Derselbe gemeinsame Block
  ],
  "tools": ["send_message", "core_memory_replace", "create_task", "update_roadmap"]
}

// Jetzt teilen beide Agenten den "project_knowledge" Speicherblock
// Wenn ein Agent ihn aktualisiert, sieht der andere Agent die Änderungen
// Perfekt für koordinierte Multi-Agent-Workflows
```

#### Beispiel 5: Agenten exportieren und importieren (.af-Dateien)

Checkpoint-Agenten erstellen und zwischen Servern verschieben:

```javascript
// n8n Workflow: Agenten sichern und wiederherstellen

// 1. HTTP Request - Agent in .af-Datei exportieren
Methode: GET
URL: http://letta:8283/v1/agents/{{ $json.agent_id }}/export
Response Format: File

// .af-Datei im Speicher ablegen (Google Drive, S3, etc.)

// 2. Später: Agent aus .af-Datei importieren
Methode: POST
URL: http://letta:8283/v1/agents/import
Header:
  Content-Type: multipart/form-data
Body:
  Datei: {{ $binary.data }}

// Agent wird mit vollständigem Zustand wiederhergestellt:
// - Alle Speicherblöcke
// - Vollständiger Konversationsverlauf
// - Tool-Konfigurationen
// - Exakt dieselbe Persönlichkeit

// Anwendungsfälle:
// - Kritische Agenten sichern
// - Agenten zwischen Letta Cloud und Self-Hosted verschieben
// - Versionskontrolle für Agenten-Entwicklung
// - Agenten mit Teammitgliedern teilen
```

### Fehlerbehebung

**Problem 1: Letta-Server startet nicht**

```bash
# Letta-Container-Logs prüfen
docker logs letta --tail 100

# Häufige Fehler:
# 1. "Could not connect to PostgreSQL"
# Lösung: Stelle sicher, dass PostgreSQL läuft
docker ps | grep postgres

# 2. "Invalid model configuration"
# Lösung: Prüfe .env-Datei auf gültige Modell-Endpoints
grep LETTA_ .env

# 3. Port 8283 bereits in Verwendung
# Lösung: Ändere Port in docker-compose.yml oder beende Prozess, der Port nutzt
sudo lsof -i :8283
docker compose restart letta
```

**Problem 2: Agent erinnert sich nicht an vergangene Konversationen**

```bash
# Prüfe ob Agent richtige Speicherblöcke hat
curl http://letta:8283/v1/agents/{agent_id} | jq '.memory_blocks'

# Verifiziere, dass PostgreSQL-Persistenz aktiviert ist
docker exec letta env | grep DATABASE_URL

# Prüfe ob Agenten-Zustand gespeichert wird
curl http://letta:8283/v1/agents/{agent_id}/messages | jq '.messages | length'
# Sollte alle vergangenen Nachrichten zeigen

# Falls Gedächtnis verloren: Agent wurde wahrscheinlich neu erstellt statt wiederverwendet
# Speichere immer agent_id und verwende denselben Agenten für persistentes Gedächtnis
```

**Problem 3: API gibt 401 Unauthorized zurück**

```bash
# Für Self-Hosted mit Passwort:
# Verifiziere, dass Passwort korrekt ist
grep LETTA_SERVER_PASS .env

# Teste Authentifizierung
curl -H "Authorization: Bearer DEIN_PASSWORT" \
  http://letta:8283/v1/agents

# Für Letta Cloud:
# Verifiziere, dass API-Key gültig ist
curl -H "Authorization: Bearer LETTA_API_KEY" \
  https://api.letta.com/v1/agents
```

**Problem 4: Agenten-Antworten sind langsam**

```bash
# Prüfe welches LLM-Modell verwendet wird
# Schnellere Modelle: gpt-4.o-mini, claude-haiku, llama-3.1-8b (via Groq)
# Langsamere Modelle: o1-preview, gpt-4, claude-opus

# Prüfe ob lokales Ollama verwendet wird
docker exec letta curl http://ollama:11434/api/tags

# Für schnellere Inferenz: Nutze Groq mit Llama-Modellen
# In ADE: Einstellungen → Modelle → Groq-Anbieter hinzufügen

# Überwache Token-Nutzung
docker logs letta | grep "tokens"
# Hohe Token-Anzahl = langsamere Antworten
```

**Problem 5: Speicherblöcke aktualisieren sich nicht**

```bash
# Verifiziere, dass Agent die richtigen Tools aktiviert hat
curl http://letta:8283/v1/agents/{agent_id} | jq '.tools'

# Sollte enthalten: core_memory_append, core_memory_replace

# Prüfe ob Agent die Tools tatsächlich nutzt
curl http://letta:8283/v1/agents/{agent_id}/messages | jq '.messages[] | select(.message_type=="tool_call_message")'

# Falls keine Tool-Aufrufe: Agent benötigt möglicherweise besseres Prompting oder anderes Modell
# Versuche ein leistungsfähigeres Modell (gpt-4.1, claude-4.5-sonnet)
```

**Problem 6: Kein Zugriff auf Agent Development Environment**

```bash
# Prüfe ob Letta läuft
docker ps | grep letta

# Teste ADE-Endpoint
curl http://localhost:8283/
# Sollte HTML zurückgeben

# Prüfe Caddy-Proxy-Konfiguration
docker exec caddy cat /etc/caddy/Caddyfile | grep letta

# Starte beide Dienste neu
docker compose restart letta caddy
```

### Ressourcen

- **Offizielle Website:** https://www.letta.com
- **Dokumentation:** https://docs.letta.com
- **GitHub Repository:** https://github.com/letta-ai/letta
- **Agent Development Environment (ADE):** https://docs.letta.com/ade
- **API-Referenz:** https://docs.letta.com/api-reference
- **Python SDK:** https://github.com/letta-ai/letta-python
- **TypeScript SDK:** https://github.com/letta-ai/letta-node
- **Agent File Format (.af):** https://github.com/letta-ai/agent-file
- **Letta Cloud (Hosted):** https://app.letta.com
- **Quickstart Tutorial:** https://docs.letta.com/quickstart
- **Speichersystem-Leitfaden:** https://docs.letta.com/guides/agents/memory
- **Tool-Integration:** https://docs.letta.com/guides/agents/tools
- **Discord Community:** https://discord.gg/letta-ai
- **Blog (Stateful Agents):** https://www.letta.com/blog/stateful-agents
- **Forschungspapier (MemGPT):** https://arxiv.org/abs/2310.08560

### Schlüsselkonzepte

**Zustandsbehaftet vs. Zustandslos:**
- Traditionelle LLMs: Zustandslos, vergessen nach Sitzungsende
- Letta-Agenten: Zustandsbehaftet, dauerhaftes Gedächtnis über alle Sitzungen hinweg

**Speicher-Hierarchie:**
- Kern-Speicher: Immer im Kontextfenster (Persona-, Human-Blöcke)
- Archiv-Speicher: Unendlicher Speicher, durchsuchbar mit Embeddings
- Recall-Speicher: Alle vergangenen Konversationen, durchsuchbare Datenbank

**Agenten-Persistenz:**
- Agenten existieren dauerhaft auf Letta-Server
- Gesamter Zustand wird automatisch in PostgreSQL gespeichert
- Agenten existieren weiter, auch wenn deine App nicht läuft

**Tool-basierte Speicherverwaltung:**
- Agenten kontrollieren ihr eigenes Gedächtnis via Tools
- core_memory_append: Zu Speicherblöcken hinzufügen
- core_memory_replace: Speicherblöcke aktualisieren
- archival_memory_insert: In Langzeitspeicher speichern
- conversation_search: Vergangene Nachrichten durchsuchen

**Model Context Protocol (MCP) Unterstützung:**
- Mit MCP-Servern für vorgefertigte Tools verbinden
- Standardisierte Tool-Bibliotheken nutzen
- Nahtlose Integration mit MCP-Ökosystem

```

### Best Practices für Speicherverwaltung

**Kern-Speicher:**
- Halte es prägnant (2000-4000 Zeichen pro Block)
- Nutze strukturiertes Format (Name: X\nRolle: Y)
- Aktualisiere regelmäßig während Agent lernt
- Nutze `core_memory_replace` für Korrekturen

**Archiv-Speicher:**
- Speichere Fakten, die nicht in Kern-Speicher passen
- Nutze für Wissensdatenbank-Artikel
- Füge Metadaten für bessere Suche hinzu
- Regelmäßige Bereinigung veralteter Informationen

**Recall-Speicher:**
- Speichert automatisch alle Konversationen
- Nutze `conversation_search` um vergangene Interaktionen zu finden
- Hilfreich für wiederkehrende Kunden
- Keine manuelle Verwaltung nötig

### Fehlerbehebung

**Agent speichert Gedächtnis nicht:**

```bash
# 1. Prüfe ob Agent erfolgreich erstellt wurde
curl http://letta:8283/v1/agents/{agent_id}

# 2. Verifiziere, dass Speicherblöcke existieren
curl http://letta:8283/v1/agents/{agent_id}/memory

# 3. Prüfe ob Agent Speicher-Tools aktiviert hat
# Agent benötigt: core_memory_append, core_memory_replace

# 4. Zeige vollständigen Agenten-Zustand
# In ADE: Agent öffnen → Memory-Tab anzeigen

# 5. Prüfe Datenbank-Persistenz
docker logs letta | grep "checkpoint"
```

**Verbindung abgelehnt:**

```bash
# 1. Prüfe ob Letta-Server läuft
docker ps | grep letta

# Sollte zeigen: letta Container auf Port 8283

# 2. Teste API-Endpoint
curl http://localhost:8283/v1/health
# Sollte zurückgeben: {"status": "ok"}

# 3. Prüfe Logs
docker logs letta --tail 50

# 4. Verifiziere internes DNS in n8n
docker exec n8n ping letta

# 5. Neustarten falls nötig
docker compose restart letta
```

**Agenten-Antworten sind langsam:**

```bash
# 1. Prüfe welches Modell verwendet wird
# Größere Modelle (gpt-4o) sind langsamer als kleinere (gpt-4o-mini)

# 2. Wechsle zu schnellerem Modell
# Aktualisiere Agenten-Modell via ADE oder API:
curl -X PATCH http://letta:8283/v1/agents/{agent_id} \
  -d '{"llm_config": {"model": "openai/gpt-4o-mini"}}'

# 3. Nutze lokales Ollama für schnellste Antworten
# Modell: ollama/llama3.2

# 4. Prüfe ob Agent zu viel Gedächtnis durchsucht
# Reduziere Archiv-Speicher-Größe oder optimiere Suchen

# 5. Überwache Ressourcen-Nutzung
docker stats letta
```

**Speicherblöcke aktualisieren sich nicht:**

```bash
# 1. Verifiziere, dass Agent richtige Tools hat
curl http://letta:8283/v1/agents/{agent_id}/tools

# Sollte enthalten:
# - core_memory_append
# - core_memory_replace

# 2. Prüfe System-Prompt des Agenten
# Muss Agent anweisen, Speicher-Tools zu nutzen

# 3. Zeige Reasoning des Agenten
# In ADE: Prüfe "inner monologue" um zu sehen, ob Agent versuchte Gedächtnis zu bearbeiten

# 4. Teste Speicher-Bearbeitung direkt
curl -X POST http://letta:8283/v1/agents/{agent_id}/memory/core \
  -d '{"human": "Aktualisierte Informationen..."}'

# 5. Prüfe Speicherblock-Limits
# Falls Block voll ist (Limit erreicht), könnten Bearbeitungen fehlschlagen
```

**Agent vergisst über Sitzungen hinweg:**

```bash
# Das sollte bei Letta NICHT passieren - das ist der ganze Sinn!

# Falls doch:
# 1. Verifiziere, dass du dieselbe agent_id nutzt
echo "Agent ID: {agent_id}"

# 2. Prüfe ob Agent noch existiert
curl http://letta:8283/v1/agents/{agent_id}

# 3. Zeige Agenten-Gedächtnis nach Neustart
curl http://letta:8283/v1/agents/{agent_id}/memory

# 4. Prüfe Datenbank-Persistenz
# Letta nutzt standardmäßig PostgreSQL
docker exec letta-db psql -U letta -d letta -c "SELECT id, name FROM agents;"

# 5. Verifiziere, dass Docker-Volumes persistiert sind
docker volume ls | grep letta
```

### Ressourcen

- **Offizielle Website:** https://www.letta.com/
- **Dokumentation:** https://docs.letta.com/
- **GitHub:** https://github.com/letta-ai/letta
- **Python SDK:** https://github.com/letta-ai/letta-python
- **TypeScript SDK:** https://github.com/letta-ai/letta-typescript
- **Agent File Format:** https://github.com/letta-ai/agent-file
- **Discord Community:** https://discord.gg/letta
- **Blog:** https://www.letta.com/blog
- **Forschungspapier (MemGPT):** https://arxiv.org/abs/2310.08560

### Hauptunterschiede zu anderen Frameworks

**Letta vs. LangChain:**
- LangChain: Zustandslose Bibliothek, erfordert externe Zustandsverwaltung
- Letta: Zustandsbehafteter Dienst, verwaltet Gedächtnis automatisch

**Letta vs. AutoGPT:**
- AutoGPT: Aufgabenfokussiert, begrenztes Gedächtnis
- Letta: Sitzungspersistent, sich entwickelndes Gedächtnis

**Letta vs. OpenAI Assistants:**
- OpenAI: Vendor-Lock-in, geschlossenes System
- Letta: Modell-agnostisch, volle Transparenz, selbst hostbar

**Letta vs. Traditionelle Chatbots:**
- Traditionell: Vergessen nach Kontextfenster-Füllung
- Letta: Erinnern sich unbegrenzt, bearbeiten Gedächtnis selbst

### Erweiterte Funktionen

**Sleep-Time Compute:**
- Agenten können "denken" während Leerlauf
- Gedächtnis während Ausfallzeiten verfeinern
- Antworten für häufige Anfragen vorberechnen
- Multi-Modell-Setups (günstiges Modell für Reflexion, teures für Antworten)

**Agenten-Vorlagen:**
- Wiederverwendbare Agenten-Konfigurationen erstellen
- Vorlagen anwenden, um schnell neue Agenten zu spawnen
- Agenten-Designs versionieren und upgraden
- Auf vorherige Versionen zurückrollen

**Tool-Regeln:**
- Agenten-Verhalten explizit einschränken
- Definieren, welche Tools wann genutzt werden können
- Deterministische oder autonome Agenten erstellen
- Zuverlässigkeit und Flexibilität ausbalancieren

**Model Context Protocol (MCP) Unterstützung:**
- Mit MCP-Servern für vorgefertigte Tools verbinden
- Standardisierte Tool-Bibliotheken nutzen
- Nahtlose Integration mit MCP-Ökosystem
