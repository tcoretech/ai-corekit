# 🔗 LightRAG - Graph-basiertes RAG mit automatischer Entitätsextraktion

### Was ist LightRAG?

LightRAG ist ein graph-basiertes RAG-System (Retrieval-Augmented Generation), das automatisch Entitäten und Beziehungen aus Dokumenten extrahiert und in einem Wissensgraphen speichert. Im Gegensatz zu traditionellem Vektor-RAG, das nur nach semantischer Ähnlichkeit sucht, versteht LightRAG **Beziehungen zwischen Konzepten** und kann komplexe Abfragen beantworten, die Kontext über mehrere Entitäten hinweg erfordern. Perfekt für Unternehmens-Dokumentation, Forschungsarbeiten und komplexe Wissensbasen.

### Features

- **🕸️ Automatische Wissensgraph-Erstellung**: Extrahiert automatisch Entitäten und Beziehungen aus Text
- **🎯 Multi-Modus-Abfragen**: Local (spezifisch), Global (Überblick), Hybrid (kombiniert), Naive (einfach)
- **🧠 Beziehungsbewusstes Abrufen**: Findet Verbindungen zwischen Konzepten, nicht nur ähnliche Texte
- **🔄 Inkrementelle Updates**: Fügt neue Dokumente zum bestehenden Graph hinzu ohne Neuaufbau
- **⚡ Schnelle Graph-Abfragen**: Optimiert für schnelles Durchlaufen großer Wissensgraphen
- **🎨 Visuelle Graph-Exploration**: Optionales Neo4j-Backend für Visualisierung
- **🌐 Multiple LLM-Unterstützung**: Ollama (lokal, Standard), OpenAI (schneller) oder andere

### Initiales Setup

**Erster Zugriff auf LightRAG:**

1. **Zugriff über Web-UI:**
```
https://lightrag.deinedomain.com
```
Einfache UI zum Dokumenten-Upload und Abfragen.

2. **API-Health testen:**
```bash
curl http://lightrag:9621/health
# Sollte zurückgeben: {"status": "healthy"}
```

3. **Erstes Dokument einfügen:**
```bash
curl -X POST http://lightrag:9621/api/insert \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Alice arbeitet bei TechCorp als Software-Ingenieurin. Bob ist der CEO von TechCorp. Charlie kennt Alice von der Universität.",
    "metadata": {"source": "test_dokument"}
  }'
```

LightRAG extrahiert automatisch:
- **Entitäten**: Alice (Person), Bob (Person), Charlie (Person), TechCorp (Firma)
- **Beziehungen**: Alice-ARBEITET_BEI→TechCorp, Bob-CEO_VON→TechCorp, Charlie-KENNT→Alice

4. **Den Wissensgraphen abfragen:**
```bash
curl -X POST http://lightrag:9621/api/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Wer arbeitet bei TechCorp?",
    "mode": "local"
  }'
```

### Abfrage-Modi erklärt

LightRAG bietet 4 verschiedene Abfrage-Modi für unterschiedliche Anwendungsfälle:

| Modus | Anwendungsfall | Funktionsweise | Am besten für |
|------|----------|--------------|----------|
| **`local`** | Spezifische Entitäts-Information | Sucht nach direkten Entitätsbeziehungen | "Was ist Alices Rolle?" |
| **`global`** | High-Level-Überblick | Analysiert den gesamten Wissensgraphen | "Was sind die Hauptthemen?" |
| **`hybrid`** | Kombinierte Analyse | Kombiniert local + global | "Wie setzt TechCorp SDGs um?" |
| **`naive`** | Einfache Stichwortsuche | Traditionelle Vektor-Ähnlichkeit | "Finde 'Nachhaltigkeit'" |

**Modus-Vergleich Beispiele:**

```javascript
// Local-Modus - Spezifische Entitäts-Information
{
  "query": "Was ist die Rolle von Petra Hedorfer?",
  "mode": "local",
  "max_results": 5
}
// Gibt zurück: Direkte Informationen über Petra und ihre unmittelbaren Beziehungen

// Global-Modus - High-Level-Zusammenfassungen
{
  "query": "Was sind die Hauptnachhaltigkeitsinitiativen?",
  "mode": "global",
  "max_results": 10
}
// Gibt zurück: Übergreifende Themen und Muster über alle Dokumente

// Hybrid-Modus - Kombiniert beide Ansätze (EMPFOHLEN)
{
  "query": "Wie setzt DZT SDGs im Tourismus um?",
  "mode": "hybrid",
  "stream": false
}
// Gibt zurück: Spezifische Beispiele + übergeordneter Kontext

// Naive-Modus - Einfache Stichwortsuche
{
  "query": "Nachhaltigkeitsberichte",
  "mode": "naive"
}
// Gibt zurück: Dokumente, die mit Stichworten übereinstimmen (kein Graph-Reasoning)
```

### API-Zugriff

LightRAG läuft als interner Service, der für andere Container zugänglich ist:

**Interner API-Endpunkt:**
```
http://lightrag:9621
```

**Wichtige API-Endpunkte:**
- `POST /api/insert` - Dokument einfügen und Entitäten extrahieren
- `POST /api/query` - Wissensgraphen abfragen
- `GET /api/health` - Health-Check
- `DELETE /api/clear` - Wissensgraphen löschen (mit Vorsicht verwenden!)

### n8n Integration Setup

LightRAG hat keinen nativen n8n-Node - Integration erfolgt über HTTP Request Nodes.

**Interne URL:** `http://lightrag:9621`

**Keine Zugangsdaten erforderlich** für interne Container-zu-Container-Kommunikation.

### Beispiel-Workflows

#### Beispiel 1: Wissensgraph aus Dokumenten erstellen

Automatisch Wissensgraph aus hochgeladenen PDFs erstellen.

**Workflow-Struktur:**
1. **Google Drive Trigger** - Ordner auf neue PDFs überwachen
   ```javascript
   Folder: /Documents/KnowledgeBase
   Dateityp: PDF
   ```

2. **Read Binary File** - PDF-Inhalt abrufen

3. **HTTP Request** - Text aus PDF extrahieren
   ```javascript
   Methode: POST
   URL: http://gotenberg:3000/forms/pdfengines/convert
   // Oder nutze einen anderen PDF-zu-Text-Service
   ```

4. **Code Node - In Chunks aufteilen**
   ```javascript
   const text = $input.item.json.text;
   const chunkSize = 3000;  // Zeichen pro Chunk
   const chunks = [];
   
   for (let i = 0; i < text.length; i += chunkSize) {
     chunks.push({
       text: text.substring(i, i + chunkSize),
       chunk_index: Math.floor(i / chunkSize)
     });
   }
   
   return chunks.map(c => ({ json: c }));
   ```

5. **Loop Node** - Jeden Chunk verarbeiten

6. **HTTP Request - In LightRAG einfügen**
   ```javascript
   Methode: POST
   URL: http://lightrag:9621/api/insert
   Header:
     Content-Type: application/json
   Body: {
     "text": "{{ $json.text }}",
     "metadata": {
       "source": "{{ $('Google Drive Trigger').item.json.name }}",
       "chunk_index": {{ $json.chunk_index }},
       "timestamp": "{{ $now.toISO() }}"
     }
   }
   
   // LightRAG führt automatisch aus:
   // - Extrahiert Entitäten (Personen, Firmen, Konzepte)
   // - Identifiziert Beziehungen
   // - Baut Wissensgraph auf
   // - Erstellt Embeddings
   ```

7. **Wait Node**
   ```javascript
   Duration: 2 seconds  // Zeit für Verarbeitung geben
   ```

8. **Aggregate Results**
   ```javascript
   const processedChunks = $input.all().length;
   const document = $('Google Drive Trigger').item.json.name;
   
   return [{
     json: {
       document: document,
       chunks_processed: processedChunks,
       knowledge_graph_updated: true
     }
   }];
   ```

9. **Slack Notification**
   ```javascript
   Nachricht: |
     📚 Wissensgraph aktualisiert
     
     Dokument: {{ $json.document }}
     Chunks verarbeitet: {{ $json.chunks_processed }}
     
     Frage deinen Wissensgraphen ab unter https://lightrag.deinedomain.com
   ```

**Anwendungsfall**: Automatischer Aufbau einer Wissensbasis aus Unternehmens-Dokumentation.

#### Beispiel 2: Intelligente Dokumenten-Q&A

Fragen mit graph-basiertem Verständnis beantworten.

**Workflow-Struktur:**
1. **Webhook Trigger**
   ```javascript
   Input: {
     "question": "Was sind die Hauptnachhaltigkeitsinitiativen von TechCorp und wer leitet sie?",
     "query_mode": "hybrid"
   }
   ```

2. **HTTP Request - LightRAG abfragen**
   ```javascript
   Methode: POST
   URL: http://lightrag:9621/api/query
   Header:
     Content-Type: application/json
   Body: {
     "query": "{{ $json.question }}",
     "mode": "{{ $json.query_mode }}",
     "max_results": 5,
     "stream": false
   }
   
   // Antwort enthält:
   {
     "answer": "Umfassende Antwort basierend auf Graph-Reasoning...",
     "entities": ["TechCorp", "Nachhaltigkeitsinitiative X", "Alice Smith"],
     "relationships": [
       {"from": "Alice Smith", "type": "LEITET", "to": "Nachhaltigkeitsinitiative X"},
       {"from": "Nachhaltigkeitsinitiative X", "type": "TEIL_VON", "to": "TechCorp"}
     ],
     "sources": [
       {"document": "Jahresbericht 2024", "relevance": 0.95}
     ]
   }
   ```

3. **Code Node - Antwort mit Graph-Kontext formatieren**
   ```javascript
   const answer = $input.item.json.answer;
   const entities = $input.item.json.entities || [];
   const relationships = $input.item.json.relationships || [];
   const sources = $input.item.json.sources || [];
   
   const formattedResponse = `
   **Antwort:**
   ${answer}
   
   **Schlüssel-Entitäten:**
   ${entities.map(e => `- ${e}`).join('\n')}
   
   **Gefundene Beziehungen:**
   ${relationships.map(r => `- ${r.from} ${r.type} ${r.to}`).join('\n')}
   
   **Quellen:**
   ${sources.map((s, i) => `${i+1}. ${s.document} (Relevanz: ${(s.relevance * 100).toFixed(0)}%)`).join('\n')}
   `;
   
   return [{
     json: {
       question: $('Webhook').item.json.question,
       response: formattedResponse,
       entities: entities,
       sources: sources
     }
   }];
   ```

4. **Antwort senden** - E-Mail, Slack oder API-Antwort

**Anwendungsfall**: Interner Wissensbasis-Assistent, Kundensupport-Automatisierung.

#### Beispiel 3: Naive vs. Graph-basiertes RAG vergleichen

Demonstriere die Leistungsfähigkeit von graph-basiertem Reasoning.

**Workflow-Struktur:**
1. **Manual Trigger**
   ```javascript
   Input: {
     "question": "Was ist die Verbindung zwischen Alice und dem Nachhaltigkeitsprojekt?"
   }
   ```

2. **Split in Batches** - Parallele Abfragen ausführen

3a. **HTTP Request - Naive RAG** (stichwort-basiert)
   ```javascript
   Methode: POST
   URL: http://lightrag:9621/api/query
   Body: {
     "query": "{{ $json.question }}",
     "mode": "naive"
   }
   ```

3b. **HTTP Request - Graph-basiertes RAG** (beziehungsbewusst)
   ```javascript
   Methode: POST
   URL: http://lightrag:9621/api/query
   Body: {
     "query": "{{ $json.question }}",
     "mode": "hybrid"
   }
   ```

4. **Aggregate & Compare**
   ```javascript
   const naiveAnswer = $item(0).json.answer;
   const graphAnswer = $item(1).json.answer;
   
   return [{
     json: {
       question: $('Manual Trigger').item.json.question,
       naive_rag: {
         answer: naiveAnswer,
         method: "Einfaches Stichwort-Matching"
       },
       graph_rag: {
         answer: graphAnswer,
         method: "Beziehungsdurchlauf + semantisches Verständnis",
         entities: $item(1).json.entities,
         relationships: $item(1).json.relationships
       },
       winner: graphAnswer.length > naiveAnswer.length ? "Graph RAG" : "Naive RAG"
     }
   }];
   
   // Typische Ergebnisse:
   // Naive: "Alice wird in Nachhaltigkeitsdokumenten erwähnt."
   // Graph: "Alice leitet das Green Initiative-Projekt, das Teil von TechCorps 
   //         Nachhaltigkeitsbemühungen ist. Sie berichtet an Bob, den CEO, und arbeitet 
   //         mit dem Umwelt-Team zusammen."
   ```

**Anwendungsfall**: Überlegenheit von graph-basiertem RAG für Beziehungsabfragen demonstrieren.

### Open WebUI Integration

**LightRAG als Chat-Modell in Open WebUI hinzufügen:**

LightRAG kann direkt in Open WebUI als Ollama-kompatibles Modell integriert werden!

**Setup-Schritte:**
1. **Open WebUI Einstellungen → Verbindungen**
2. **Neue Ollama-Verbindung hinzufügen:**
   - **URL:** `http://lightrag:9621`
   - **Modellname:** `lightrag:latest`
3. **LightRAG aus dem Modell-Dropdown im Chat auswählen**

**Jetzt kannst du direkt mit deinem Wissensgraphen chatten!**

Dies ermöglicht:
- Natürliche Unterhaltung mit dem Wissensgraphen
- Automatische Entitäts- und Beziehungserkennung
- Graph-basierte Antworten anstelle von nur Vektorsuche
- Visualisierung von Entitätsbeziehungen

### Von Ollama zu OpenAI wechseln (Optional)

LightRAG nutzt standardmäßig lokale Ollama-Modelle. Für bessere Performance mit großen Dokumenten wechsle zu OpenAI:

**Warum zu OpenAI wechseln?**
- ⚡ **10-100x schneller** als CPU-basiertes Ollama
- 📄 **Große Dokumente**: PDFs mit 50+ Seiten ohne Timeouts verarbeiten
- 🎯 **Bessere Qualität**: Genauere Entitäts- und Beziehungsextraktion
- 💰 **Kosteneffizient**: gpt-4o-mini kostet ~$0.15 pro Million Tokens

**Konfigurations-Schritte:**

1. **OpenAI API Key zu .env hinzufügen:**
```bash
cd /root/ai-corekit
nano .env

# Hinzufügen oder aktualisieren:
OPENAI_API_KEY=sk-proj-DEIN-API-KEY-HIER
```

2. **docker-compose.yml aktualisieren:**
```yaml
lightrag:
  environment:
    - OPENAI_API_KEY=${OPENAI_API_KEY}
    - LLM_BINDING=openai                           # Geändert von ollama
    - LLM_BINDING_HOST=https://api.openai.com/v1   # OpenAI Endpunkt
    - LLM_MODEL=gpt-4o-mini                        # Kosteneffizientes Modell
    - EMBEDDING_BINDING=openai                     # Geändert von ollama
    - EMBEDDING_BINDING_HOST=https://api.openai.com/v1
    - EMBEDDING_MODEL=text-embedding-3-small       # OpenAI Embeddings
    - EMBEDDING_DIM=1536                           # OpenAI Dimension (nicht 768!)
```

3. **LightRAG neu starten:**
```bash
corekit restart lightrag
```

**Performance-Vergleich:**

| Metrik | Ollama (CPU) | OpenAI API |
|--------|--------------|------------|
| Entitätsextraktion (10-Seiten-PDF) | 2-5 Minuten | 10-30 Sekunden |
| Abfrage-Antwort | 5-15 Sekunden | 1-3 Sekunden |
| Kosten (1M Tokens) | Kostenlos (lokal) | ~$0.15-0.60 |
| Qualität | Gut | Exzellent |

### Fehlerbehebung

**Problem 1: Langsame Entitätsextraktion**

```bash
# Prüfen ob Ollama (langsam) oder OpenAI (schnell) verwendet wird
corekit logs lightrag | grep -E "LLM_BINDING|EMBEDDING_BINDING"

# Falls Ollama auf CPU verwendet wird:
# Lösung 1: Zu OpenAI wechseln (siehe oben)
# Lösung 2: Kleinere Dokumente verwenden (< 5 Seiten auf einmal)
# Lösung 3: Chunk-Größe im Preprocessing reduzieren

# Prüfen ob Ollama läuft
corekit ps | grep ollama
curl http://ollama:11434/api/tags
```

**Lösung:**
- Zu OpenAI für Produktionslasten wechseln
- Dokumente in kleineren Batches verarbeiten
- `hybrid`-Modus anstelle von `global` für schnellere Abfragen verwenden

**Problem 2: Abfrage gibt keine Ergebnisse zurück**

```bash
# Prüfen ob Dokumente eingefügt wurden
curl http://lightrag:9621/api/health

# Wissensgraphen auf Daten verifizieren
corekit logs lightrag | grep "entities extracted"

# Mit einfacher Abfrage testen
curl -X POST http://lightrag:9621/api/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "mode": "naive"}'
```

**Lösung:**
- Wissensgraph könnte leer sein - Dokumente erneut einfügen
- Zuerst `naive`-Modus versuchen, um zu prüfen ob Dokumente existieren
- Prüfen ob Entitäten tatsächlich extrahiert wurden (Logs anzeigen)

**Problem 3: Authentifizierungsfehler in Open WebUI**

```bash
# Prüfen ob LightRAG-Port erreichbar ist
corekit exec open-webui curl http://lightrag:9621/health

# Ollama-kompatible API verifizieren
curl http://lightrag:9621/v1/models
# Sollte Modellliste zurückgeben

# Open WebUI neu starten
corekit restart open-webui
```

**Lösung:**
- Interne DNS-Auflösung zwischen Containern verifizieren
- Docker-Netzwerk prüfen: `docker network inspect ai-corekit_default`
- Sicherstellen, dass LightRAG-Container läuft

**Problem 4: Zu wenig Speicher-Fehler**

```bash
# Speichernutzung prüfen
docker stats lightrag --no-stream

# LightRAG kann mit großen Graphen speicherintensiv sein
```

**Lösung:**
- Docker-Speicherlimit in `docker-compose.yml` erhöhen:
  ```yaml
  lightrag:
    deploy:
      resources:
        limits:
          memory: 4G  # Von 2G erhöhen
  ```
- Alten Wissensgraphen löschen: `curl -X DELETE http://lightrag:9621/api/clear`
- OpenAI anstelle von Ollama verwenden (weniger RAM benötigt)

**Problem 5: Container startet nicht**

```bash
# Container-Status prüfen
corekit ps -a | grep lightrag

# Logs anzeigen
corekit logs lightrag

# Häufige Probleme:
# - Fehlende LLM-Konfiguration
# - Ollama läuft nicht
# - Port 9621 bereits in Verwendung
```

**Lösung:**
- Verifizieren, dass Ollama läuft: `docker ps | grep ollama`
- Port-Konflikte prüfen: `netstat -tulpn | grep 9621`
- Mit Abhängigkeiten neu starten: `corekit restart ollama lightrag`

### Best Practices

**Dokumenten-Verarbeitung:**
- **Chunk-Größe**: 2000-4000 Zeichen für optimale Entitätsextraktion
- **Überlappung**: Nicht erforderlich (LightRAG verarbeitet Kontext intern)
- **Metadaten**: Immer Quelle, Zeitstempel, Dokumenttyp einbeziehen
- **Inkrementelle Updates**: Neue Dokumente kontinuierlich einfügen, kein Neuaufbau erforderlich

**Abfrage-Optimierung:**
- **`hybrid`-Modus verwenden** für die meisten Abfragen (beste Balance)
- **`local`-Modus verwenden** für spezifische Entitätsfragen
- **`global`-Modus verwenden** für Überblick/Zusammenfassungsfragen
- **`naive`-Modus verwenden** nur für einfache Stichwortsuchen

**Entitätsextraktions-Qualität:**
- **OpenAI verwenden** für Produktion (10x besser als Ollama)
- **Dokumente vorverarbeiten**: Kopf-/Fußzeilen entfernen, Formatierung bereinigen
- **Domänenspezifische Prompts**: Entitätstypen bei Bedarf anpassen
- **Extraktionen validieren**: Beispiel-Entitäten nach erstem Batch überprüfen

**Performance-Tipps:**
- Dokumente in **Batches von 10-20** gleichzeitig verarbeiten
- **Parallele Verarbeitung** in n8n für große Dokumentensets verwenden
- **Häufige Abfragen cachen** in Redis oder PostgreSQL
- **Graph-Größe überwachen**: Große Graphen (>100K Entitäten) benötigen möglicherweise Optimierung

**Integrations-Muster:**

```javascript
// Muster 1: RAG-Pipeline
Dokumenten-Upload → LightRAG Insert → Abfrage mit Kontext

// Muster 2: Hybrid-Suche
LightRAG (graph-basiert) + Qdrant (vektor-basiert) → Ergebnisse kombinieren

// Muster 3: Entitäts-Anreicherung
Entitäten mit LightRAG extrahieren → Mit externen APIs anreichern → Graph aktualisieren

// Muster 4: Wissensgraph-Visualisierung
LightRAG (Speicherung) → Export zu Neo4j (Visualisierung)
```

### Ressourcen

- **Offizielle Dokumentation**: https://github.com/HKUDS/LightRAG
- **GitHub Repository**: https://github.com/HKUDS/LightRAG
- **Forschungsarbeit**: [LightRAG: Simple and Fast Retrieval-Augmented Generation](https://arxiv.org/abs/2410.05779)
- **Web-UI**: `https://lightrag.deinedomain.com`
- **Interne API**: `http://lightrag:9621`
- **OpenAPI Docs**: `http://lightrag:9621/docs`

**Verwandte Services:**
- Mit **Neo4j** verwenden für Graph-Visualisierung
- Kombinieren mit **Qdrant/Weaviate** für hybride Vektor+Graph-Suche
- Dokumente mit **Gotenberg** verarbeiten (PDF zu Text)
- Aus **Open WebUI** abfragen für konversationelle Schnittstelle
- Mit **Ollama** (lokal) oder **OpenAI** (schnell) analysieren
