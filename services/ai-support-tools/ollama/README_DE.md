# 🦙 Ollama - Local LLMs

### Was ist Ollama?

Ollama ist ein Open-Source-Framework, das es dir ermöglicht, große Sprachmodelle (LLMs) lokal auf deiner eigenen Hardware mit minimalem Setup auszuführen. Stell es dir als "Docker für KI-Modelle" vor – es vereinfacht den komplexen Prozess des Herunterladens, Konfigurierens und Ausführens anspruchsvoller KI-Modelle wie Llama 3.3, Mistral, Qwen, DeepSeek, Phi und Dutzende anderer. Ollama eliminiert die Notwendigkeit teurer Cloud-API-Dienste, bietet vollständige Datenschutzkontrolle (deine Daten verlassen niemals deine Maschine) und stellt eine OpenAI-kompatible REST-API für nahtlose Integration mit anderen Tools bereit.

### Features

- **Einfache Modellverwaltung** - Lade Modelle herunter und führe sie mit einzelnen Befehlen aus: `ollama pull llama3.3`, `ollama run mistral`
- **Umfangreiche Modellbibliothek** - Über 100 vorkonfigurierte Modelle, darunter Llama 3.3 (70B), DeepSeek-R1, Qwen3, Phi-4, Mistral, Gemma, CodeLlama und mehr
- **OpenAI-kompatible API** - REST-API unter `http://localhost:11434` funktioniert als direkter Ersatz für die OpenAI-API
- **Quantisierungsunterstützung** - Führe große Modelle effizient mit GGUF-Quantisierung aus (Q4_0, Q8_0 Varianten)
- **Multimodale Funktionen** - Vision-Modelle wie LLaVA und Llama 3.2 Vision unterstützen Bild + Text Eingaben
- **Keine Cloud-Abhängigkeiten** - Vollständiger Datenschutz, null API-Kosten, funktioniert offline
- **GPU-Beschleunigung** - Automatische NVIDIA CUDA und Apple Metal Unterstützung für schnelle Inferenz
- **Benutzerdefinierte Modellunterstützung** - Importiere deine eigenen feinabgestimmten Modelle oder benutzerdefinierte Modelfiles
- **Leichtgewichtig & Schnell** - Minimale Installation, Modelle laden in Sekunden, geringer Speicherbedarf mit Quantisierung

### Ersteinrichtung

**Ollama ist im AI CoreKit vorkonfiguriert:**

Ollama läuft bereits und ist intern unter `http://ollama:11434` erreichbar. Du kannst sofort von n8n, Open WebUI und anderen Diensten damit interagieren.

**Lade dein erstes Modell:**

```bash
# SSH auf deinen Server
ssh user@deinedomain.com

# Lade ein leichtgewichtiges Modell (2GB, schnell)
docker exec ollama ollama pull llama3.2

# Lade ein leistungsstarkes Reasoning-Modell (4GB)
docker exec ollama ollama pull qwen2.5:7b

# Lade ein Code-Spezialist-Modell (4GB)
docker exec ollama ollama pull qwen2.5-coder:7b

# Lade ein Vision-Modell (5GB, unterstützt Bilder)
docker exec ollama ollama pull llama3.2-vision

# Liste installierte Modelle
docker exec ollama ollama list
```

**Teste Ollama von der Kommandozeile:**

```bash
# Einfacher Chat-Test
docker exec -it ollama ollama run llama3.2 "Erkläre Quantencomputing in einfachen Worten"

# Code-Generierungs-Test
docker exec -it ollama ollama run qwen2.5-coder:7b "Schreibe eine Python-Funktion zur Berechnung von Fibonacci-Zahlen"

# Vision-Test (wenn du llama3.2-vision hast)
docker exec -it ollama ollama run llama3.2-vision "Beschreibe dieses Bild: /pfad/zum/bild.jpg"
```

**Teste die Ollama-API:**

```bash
# Einfache Completion-Anfrage
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Warum ist der Himmel blau?"
}'

# Chat-Format-Anfrage (OpenAI-kompatibel)
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Hallo! Wer bist du?"}
  ]
}'
```

### Empfohlene Modelle für verschiedene Anwendungsfälle

**Allgemeiner Chat & Reasoning (Beste Qualität):**
```bash
docker exec ollama ollama pull qwen2.5:14b        # 8GB RAM, exzellentes Reasoning
docker exec ollama ollama pull llama3.3:70b       # 40GB RAM, GPT-4 Klassenqualität
docker exec ollama ollama pull deepseek-r1:7b     # 5GB RAM, starkes Reasoning
```

**Schnell & Leichtgewichtig (Geringe Ressourcen):**
```bash
docker exec ollama ollama pull phi4:3.8b          # 2.3GB, Microsofts effizientes Modell
docker exec ollama ollama pull qwen2.5:3b         # 2GB, schnell und präzise
docker exec ollama ollama pull llama3.2:1b        # 1GB, ultra-leichtgewichtig
```

**Code-Generierung:**
```bash
docker exec ollama ollama pull qwen2.5-coder:7b   # Am besten für Coding
docker exec ollama ollama pull codellama:13b      # Metas Code-Spezialist
docker exec ollama ollama pull deepseek-coder:6.7b # Stark im Debugging
```

**Vision (Bild + Text):**
```bash
docker exec ollama ollama pull llama3.2-vision:11b # Bildverständnis
docker exec ollama ollama pull llava:13b           # Visuelle Fragenbeantwortung
```

**Embeddings (für RAG):**
```bash
docker exec ollama ollama pull nomic-embed-text    # 275M Parameter, schnelle Embeddings
docker exec ollama ollama pull mxbai-embed-large   # Höhere Qualität, langsamer
```

### n8n Integration Setup

**Ollama ist bereits intern verbunden:**

Ollama läuft unter `http://ollama:11434` innerhalb des Docker-Netzwerks. Du kannst es von n8n ohne Zugangsdaten oder Authentifizierung nutzen.

**Option 1: n8ns OpenAI-kompatible Nodes verwenden**

Ollamas API ist OpenAI-kompatibel, sodass du n8ns OpenAI-Nodes verwenden kannst, indem du sie auf Ollama zeigst:

1. Füge in n8n eine neue Zugangsdaten hinzu
2. Wähle **OpenAI API**
3. Konfiguriere:
   - **API Key:** `ollama` (jeder Wert funktioniert, Ollama prüft keine Auth)
   - **Base URL:** `http://ollama:11434/v1`
4. Speichere Zugangsdaten

Jetzt kannst du OpenAI-Nodes mit Ollama-Modellen verwenden!

**Option 2: HTTP Request Nodes verwenden (Flexibler)**

Für volle Kontrolle verwende HTTP Request Nodes, um Ollamas API direkt aufzurufen:

```javascript
// HTTP Request Node Konfiguration
Methode: POST
URL: http://ollama:11434/api/generate
Body (JSON):
{
  "model": "llama3.2",
  "prompt": "{{ $json.userMessage }}",
  "stream": false
}

// Antwort: $json.response enthält die KI-Antwort
```

**Option 3: Code Node mit Ollama SDK verwenden**

```javascript
// Installiere ollama-Paket in n8n (Settings > Community Nodes)
// oder verwende HTTP-Anfragen direkt

const model = 'qwen2.5:7b';
const prompt = $input.first().json.question;

const response = await fetch('http://ollama:11434/api/generate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: model,
    prompt: prompt,
    stream: false
  })
});

const result = await response.json();

return {
  json: {
    answer: result.response,
    model: model,
    prompt: prompt
  }
};
```

### Beispiel-Workflows

#### Beispiel 1: KI-E-Mail-Antwort-Assistent mit lokalem Datenschutz

Erstelle einen Workflow, der Gmail überwacht, Antworten mit Ollama generiert (100% privat) und Antworten sendet.

```javascript
// 1. Gmail Trigger Node
Trigger: On New Email
Label: Inbox
Polling Interval: Every 5 minutes

// 2. Code Node - Frage aus E-Mail extrahieren
const emailBody = $json.text || $json.snippet;
return {
  json: {
    from: $json.from,
    subject: $json.subject,
    question: emailBody
  }
};

// 3. HTTP Request Node - Ollama Generierung
Methode: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "qwen2.5:7b",
  "prompt": "Du bist ein hilfreicher E-Mail-Assistent. Antworte professionell auf diese E-Mail:\n\nVon: {{ $json.from }}\nBetreff: {{ $json.subject }}\n\nE-Mail-Inhalt:\n{{ $json.question }}\n\nDeine Antwort:",
  "stream": false,
  "temperature": 0.7
}

// 4. Code Node - Antwort formatieren
const response = $json.response;
return {
  json: {
    reply: response.trim(),
    original_from: $('Code Node').first().json.from,
    original_subject: $('Code Node').first().json.subject
  }
};

// 5. Gmail Node - Antwort senden
Operation: Send Email
To: {{ $json.original_from }}
Subject: Re: {{ $json.original_subject }}
Nachricht: {{ $json.reply }}

// Ergebnis: Automatisierte E-Mail-Antworten mit vollständigem Datenschutz
```

#### Beispiel 2: Dokumenten-Zusammenfassungs-Pipeline

Verarbeite PDFs/Dokumente und erstelle Zusammenfassungen mit lokalen Ollama-Modellen.

```javascript
// 1. Webhook Trigger
Methode: POST
Pfad: /summarize
Authentication: None (oder nach Bedarf konfigurieren)

// 2. Extract from File Node (falls PDF hochgeladen)
Binary Property: data
Format: Text

// 3. Code Node - Text in Chunks aufteilen (wenn Dokument groß ist)
const text = $json.data;
const chunkSize = 3000; // Ollama Kontextfenster
const chunks = [];

for (let i = 0; i < text.length; i += chunkSize) {
  chunks.push({
    chunk: text.slice(i, i + chunkSize),
    index: Math.floor(i / chunkSize)
  });
}

return chunks.map(c => ({ json: c }));

// 4. Loop Over Items (für jeden Chunk)
// 5. HTTP Request - Ollama Zusammenfassung
Methode: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "qwen2.5:7b",
  "prompt": "Fasse diesen Text prägnant zusammen:\n\n{{ $json.chunk }}",
  "stream": false
}

// 6. Code Node - Zusammenfassungen kombinieren
const summaries = $input.all().map(item => item.json.response);
const finalSummary = summaries.join('\n\n');

return {
  json: {
    summary: finalSummary,
    chunks_processed: summaries.length
  }
};

// 7. Respond to Webhook
Statuscode: 200
Body: {{ $json.summary }}
```

#### Beispiel 3: Code-Review-Assistent

Automatisches Review von Pull Requests oder Code-Snippets mit lokalem LLM.

```javascript
// 1. Webhook/Manual Trigger
// Code-Snippet als Input akzeptieren

// 2. Set Node - Code zum Review definieren
code = """
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total
"""

// 3. HTTP Request - Ollama Code Review
Methode: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "qwen2.5-coder:7b",
  "prompt": "Überprüfe diesen Code auf Bugs, Performance-Probleme und Best Practices:\n\n```python\n{{ $json.code }}\n```\n\nGib spezifische Vorschläge.",
  "stream": false
}

// 4. Code Node - Review-Ergebnisse parsen
const review = $json.response;

return {
  json: {
    code_reviewed: $('Set').first().json.code,
    review_feedback: review,
    model: 'qwen2.5-coder:7b',
    timestamp: new Date().toISOString()
  }
};

// 5. Slack/Email Node - Review senden
Kanal: #code-review
Nachricht: |
  🤖 *Automatisiertes Code Review*
  
  *Modell:* {{ $json.model }}
  
  *Feedback:*
  {{ $json.review_feedback }}
```

#### Beispiel 4: Multi-Modell-Vergleich

Vergleiche Antworten verschiedener Ollama-Modelle, um die beste Antwort zu finden.

```javascript
// 1. Manual/Webhook Trigger
question = "Erkläre den Unterschied zwischen async/await und Promises in JavaScript"

// 2. Code Node - Modell-Array erstellen
const models = ['llama3.2', 'qwen2.5:7b', 'deepseek-r1:7b'];

return models.map(model => ({
  json: {
    model: model,
    question: $json.question
  }
}));

// 3. Loop Over Items
// 4. HTTP Request - Jedes Modell abfragen
Methode: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "{{ $json.model }}",
  "prompt": "{{ $json.question }}",
  "stream": false,
  "temperature": 0.3
}

// 5. Code Node - Ergebnisse aggregieren
const responses = $input.all().map(item => ({
  model: item.json.model,
  answer: item.json.response
}));

return {
  json: {
    question: $('Manual Trigger').first().json.question,
    responses: responses,
    comparison_complete: true
  }
};

// 6. Output formatieren (Markdown/Slack/Email)
```

#### Beispiel 5: Vision-gestützte Bildanalyse

Nutze Ollamas Vision-Modelle zur Bildanalyse (erfordert llama3.2-vision oder llava).

```javascript
// 1. Webhook Trigger - Empfängt Bild
Methode: POST
Pfad: /analyze-image

// 2. Code Node - Bild zu Base64 kodieren
const imageBuffer = Buffer.from($binary.data.data);
const base64Image = imageBuffer.toString('base64');

return {
  json: {
    image_base64: base64Image
  }
};

// 3. HTTP Request - Ollama Vision Analyse
Methode: POST
URL: http://ollama:11434/api/generate
Body:
{
  "model": "llama3.2-vision",
  "prompt": "Beschreibe dieses Bild im Detail. Welche Objekte, Personen und Aktivitäten siehst du?",
  "images": ["{{ $json.image_base64 }}"],
  "stream": false
}

// 4. Code Node - Antwort formatieren
const description = $json.response;

return {
  json: {
    image_description: description,
    analysis_timestamp: new Date().toISOString(),
    model: 'llama3.2-vision'
  }
};

// 5. Auf Webhook antworten oder in Datenbank speichern
```

### Fehlerbehebung

**Modell nicht gefunden:**
```bash
# Installierte Modelle prüfen
docker exec ollama ollama list

# Erforderliches Modell laden
docker exec ollama ollama pull llama3.2

# Prüfe ob Modellname exakt übereinstimmt (groß-/kleinschreibungsempfindlich)
# Korrekt: "llama3.2"
# Falsch: "llama3.2:latest" oder "Llama3.2"
```

**Ollama-Service antwortet nicht:**
```bash
# Prüfe ob Ollama-Container läuft
docker ps | grep ollama

# Prüfe Ollama-Logs
docker logs ollama --tail 100

# Starte Ollama-Service neu
docker compose restart ollama

# Teste Verbindung
curl http://localhost:11434/api/tags
```

**Out-of-Memory-Fehler:**
```bash
# Verwende kleinere/quantisierte Modelle
docker exec ollama ollama pull qwen2.5:3b        # Statt 7b
docker exec ollama ollama pull llama3.2:1b       # Ultra-leichtgewichtig

# Verwende Q4_0 quantisierte Versionen (halber Speicher)
docker exec ollama ollama pull llama3.2:7b-q4_0

# Prüfe aktuelle Speichernutzung
docker stats ollama

# Gib Festplattenspeicher frei durch Entfernen ungenutzter Modelle
docker exec ollama ollama rm <modell-name>
```

**Langsame Generierungsgeschwindigkeit:**
```bash
# Prüfe ob GPU verwendet wird (viel schneller als CPU)
docker exec ollama nvidia-smi  # Für NVIDIA GPUs

# Prüfe ob GPU zugänglich ist
docker exec ollama ollama run llama3.2 --verbose "test"
# Suche nach "using GPU" in der Ausgabe

# Verwende schnellere Modelle
docker exec ollama ollama pull phi4:3.8b         # Sehr schnell, klein
docker exec ollama ollama pull qwen2.5:3b        # Schnelle Generierung

# Reduziere max_tokens in API-Anfragen
{
  "model": "llama3.2",
  "prompt": "...",
  "options": {
    "num_predict": 128  # Begrenze Antwortlänge
  }
}
```

**n8n Timeout-Fehler:**
```bash
# Erhöhe n8n Timeout-Einstellung
# n8n > Settings > Workflows > Execution Timeout: 300 Sekunden

# Verwende streaming: false für synchrone Antworten
{
  "model": "qwen2.5:7b",
  "prompt": "...",
  "stream": false  # Warte auf vollständige Antwort
}

# Verwende kürzere Prompts
# Lange Prompts = langsamere Generierung
```

**Verbindung von n8n abgelehnt:**
```bash
# Prüfe Docker-Netzwerk
docker network inspect ai-corekit_default
# Verifiziere dass ollama und n8n im selben Netzwerk sind

# Teste interne URL
docker exec n8n curl http://ollama:11434/api/tags

# Falls es fehlschlägt, starte beide Services neu
docker compose restart ollama n8n
```

### Ressourcen

- **Offizielle Website:** https://ollama.com
- **Modellbibliothek:** https://ollama.com/library (Durchsuche 100+ Modelle)
- **GitHub Repository:** https://github.com/ollama/ollama
- **API-Dokumentation:** https://github.com/ollama/ollama/blob/main/docs/api.md
- **Modelfile-Referenz:** https://github.com/ollama/ollama/blob/main/docs/modelfile.md
- **Discord Community:** https://discord.gg/ollama
- **Blog & Tutorials:** https://ollama.com/blog
- **Vergleich mit Cloud-APIs:** https://ollama.com/blog/openai-compatibility

### Best Practices

**Modellauswahl:**
- Starte mit leichtgewichtigen Modellen (3B-7B Parameter) zum Testen
- Verwende 13B+ Modelle nur wenn du höhere Qualität benötigst und 16GB+ RAM hast
- Für Coding-Aufgaben: `qwen2.5-coder:7b` oder `deepseek-coder:6.7b`
- Für Reasoning: `qwen2.5:14b` oder `deepseek-r1:7b`
- Für Vision: `llama3.2-vision:11b`
- Für Embeddings (RAG): `nomic-embed-text`

**Performance-Optimierung:**
- Verwende immer GPU-Beschleunigung wenn verfügbar (10-100x schneller als CPU)
- Nutze quantisierte Modelle (Q4_0 Varianten) um Speichernutzung um 50% zu reduzieren
- Setze `num_predict` Limit um unnötig lange Antworten zu vermeiden
- Cache häufig genutzte Modelle im Speicher (Ollama hält kürzlich genutzte Modelle geladen)
- Verwende `temperature: 0.3` für faktische Aufgaben, `0.7` für kreative Aufgaben

**Datenschutz & Sicherheit:**
- Alle Daten bleiben auf deinem Server - perfekt für DSGVO-Konformität
- Keine API-Schlüssel benötigt, kein Usage-Tracking
- Ideal für die Verarbeitung sensibler Dokumente, Code oder Kundendaten
- Nutze Ollama für Entwicklung, wechsle zu OpenAI für Produktion wenn nötig

**Integrationsmuster:**
- Nutze Ollama für Prototyping (kostenlos, schnelle Iteration)
- Wechsle zu OpenAI API für Produktion wenn du garantierte Verfügbarkeit brauchst
- Führe Ollama + OpenAI parallel: Ollama für datenschutzsensible Aufgaben, OpenAI für komplexes Reasoning
- Kombiniere Ollama mit RAG: Nutze `nomic-embed-text` für Embeddings + `qwen2.5:7b` für Generierung

**Ressourcenverwaltung:**
- Überwache Festplattenspeicher: Modelle können 2-40GB groß sein
- Entferne ungenutzte Modelle regelmäßig: `docker exec ollama ollama rm <modell>`
- Halte nur 3-5 Modelle gleichzeitig aktiv
- Nutze kleinere Modelle für hochvolumige Aufgaben (APIs, Batch-Verarbeitung)
- Nutze größere Modelle für gelegentliche Tiefenanalysen

**Kostenoptimierung:**
- Ollama = 0€/Monat für unbegrenzte Nutzung
- Vergleich zu OpenAI: 1M Tokens ≈ 2-20€ (je nach Modell)
- Wenn >1M Tokens/Monat verarbeitet werden, amortisiert sich Ollama schnell
- Bester ROI: Nutze Ollama für hochvolumige, wenig kritische Aufgaben

### Integration mit AI CoreKit Services

**Ollama + Open WebUI:**
- Open WebUI erkennt alle Ollama-Modelle automatisch
- Wechsle sofort zwischen Modellen in der UI
- Keine Konfiguration nötig - funktioniert out of the box

**Ollama + Dify:**
- Füge Ollama als LLM-Provider hinzu: `http://ollama:11434`
- Nutze für RAG-Workflows, Agenten und Chatbots
- Null API-Kosten für unbegrenzte Konversationen

**Ollama + Letta (MemGPT):**
- Konfiguriere als LLM-Provider für zustandsbehaftete Agenten
- Agenten erinnern sich an Konversationen über Sessions hinweg
- Vollständig privater Speicher

**Ollama + RAGApp:**
- Nutze `nomic-embed-text` für Dokumenten-Embeddings
- Nutze `qwen2.5:7b` für Fragenbeantwortung
- Baue private Wissensdatenbanken ohne Cloud-Abhängigkeiten

**Ollama + Flowise:**
- Drag-and-Drop Ollama-Nodes im visuellen Builder
- Kombiniere mit anderen Tools (Web Scraping, Datenbanken)
- Baue komplexe KI-Agenten ohne Code

**Ollama + ComfyUI:**
- Einige ComfyUI-Nodes unterstützen Ollama für Bildbeschreibungen
- Nutze Vision-Modelle zur Analyse generierter Bilder
- Beschrifte Bilder automatisch

**Ollama + bolt.diy:**
- Setze Ollama als Code-Generierungs-Backend (experimentell)
- Datenschutz-erste Entwicklung mit lokalen LLMs
- Keine API-Kosten für Prototyping
