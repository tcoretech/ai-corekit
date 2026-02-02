# 💬 Open WebUI - ChatGPT-Oberfläche

### Was ist Open WebUI?

Open WebUI ist eine selbst gehostete ChatGPT-ähnliche Oberfläche, die eine schöne, funktionsreiche Chat-Erfahrung für lokale und Remote-LLMs bietet. Sie integriert sich nahtlos mit Ollama für lokale Modelle, OpenAI API und andere Anbieter und bietet Konversationsverwaltung, Modellwechsel und erweiterte Funktionen wie RAG (Retrieval-Augmented Generation).

### Funktionen

- **ChatGPT-ähnliche Oberfläche** - Vertraute Chat-UI mit Markdown, Code-Highlighting und Streaming
- **Mehrere Modelle unterstützt** - Wechsle zwischen Ollama (lokal), OpenAI, Anthropic und anderen Anbietern
- **Konversationsverwaltung** - Speichere, durchsuche und organisiere Chat-Verläufe
- **RAG-Integration** - Lade Dokumente hoch und chatte mit deinen Daten über Vektorsuche
- **Multi-User-Unterstützung** - Benutzerkonten, Authentifizierung und rollenbasierter Zugriff
- **Modellbibliothek** - Durchsuche und lade Ollama-Modelle direkt aus der UI herunter

### Erste Einrichtung

**Erste Anmeldung bei Open WebUI:**

1. Navigiere zu `https://webui.deinedomain.com`
2. **Erster Benutzer wird Admin** - Erstelle dein Konto
3. Setze ein starkes Passwort
4. Einrichtung abgeschlossen!

**Ollama ist vorkonfiguriert** - Alle lokalen Modelle von Ollama sind automatisch verfügbar.

### Verbindung zu Ollama-Modellen

**Ollama ist bereits intern verbunden:**

- **Interne URL:** `http://ollama:11434`
- Alle Modelle, die in Ollama geladen sind, erscheinen automatisch in Open WebUI
- Keine zusätzliche Konfiguration erforderlich!

**Verfügbare Standardmodelle:**
- `llama3.2` - Schnell, universell einsetzbar (empfohlen)
- `mistral` - Hervorragend für Coding und Reasoning
- `llama3.2-vision` - Multimodal (Text + Bilder)
- `qwen2.5-coder` - Spezialisiert für Code-Generierung

### Zusätzliche Modelle herunterladen

**Option 1: Über Open WebUI (empfohlen)**

1. Klicke auf Einstellungen (Zahnrad-Symbol)
2. Gehe zum Tab **Modelle**
3. Durchsuche verfügbare Modelle
4. Klicke auf **Pull** zum Herunterladen

**Option 2: Über die Kommandozeile**

```bash
# Ein bestimmtes Modell herunterladen
docker exec ollama ollama pull llama3.2

# Installierte Modelle auflisten
docker exec ollama ollama list

# Ein Modell entfernen
docker exec ollama ollama rm modellname
```

**Beliebte Modell-Empfehlungen:**

| Modell | Größe | Am besten für | RAM erforderlich |
|-------|------|----------|--------------|
| `llama3.2` | 2GB | Allgemeiner Chat, schnell | 4GB |
| `llama3.2:70b` | 40GB | Beste Qualität | 64GB+ |
| `mistral` | 4GB | Coding, Reasoning | 8GB |
| `qwen2.5-coder:7b` | 4GB | Code-Generierung | 8GB |
| `llama3.2-vision` | 5GB | Bildverständnis | 8GB |
| `deepseek-r1:7b` | 4GB | Reasoning, Mathematik | 8GB |

### OpenAI API-Modelle hinzufügen

**Verbinde dich mit OpenAI für schnellere Antworten:**

1. Einstellungen → **Verbindungen**
2. Abschnitt **OpenAI API**
3. API-Schlüssel hinzufügen: `sk-your-key-here`
4. OpenAI-Modelle aktivieren

**Verfügbare Modelle:**
- `gpt-4o` - Am leistungsfähigsten (empfohlen)
- `gpt-4o-mini` - Schnell und kosteneffektiv
- `o1` - Fortgeschrittenes Reasoning

### RAG (Chatte mit deinen Dokumenten)

**Dokumente hochladen und damit chatten:**

1. Klicke auf das **+** Symbol im Chat
2. Wähle **Dateien hochladen**
3. Wähle PDF, DOCX, TXT oder andere Dokumente
4. Open WebUI erledigt automatisch:
   - Textextraktion
   - Erstellt Embeddings
   - Speichert in Vektordatenbank
5. Stelle Fragen zu deinen Dokumenten!

**Beispiel-Anfragen:**
```
"Fasse die wichtigsten Erkenntnisse aus dem hochgeladenen Bericht zusammen"
"Was sagt der Vertrag über die Kündigung?"
"Extrahiere alle Aktionspunkte aus den Meeting-Notizen"
```

### n8n-Integration

**HTTP-Request an Open WebUI API:**

```javascript
// HTTP Request Node Konfiguration
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Authentication: Bearer Token
  Token: [Dein Open WebUI API Key]
  
Body (JSON):
{
  "model": "llama3.2",
  "messages": [
    {
      "role": "system",
      "content": "Du bist ein hilfreicher Assistent"
    },
    {
      "role": "user",
      "content": "{{$json.user_question}}"
    }
  ],
  "stream": false
}

// Antwort:
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "KI-Antwort hier..."
      }
    }
  ]
}
```

**API-Schlüssel in Open WebUI generieren:**
1. Einstellungen → **Konto** → **API-Schlüssel**
2. Klicke auf **Neuen API-Schlüssel erstellen**
3. Kopieren und sicher speichern

### Beispiel-Workflows

#### Beispiel 1: Kundensupport-Automatisierung

```javascript
// 1. Webhook Trigger - Support-Ticket empfangen
// Input: { "customer": "John", "question": "Wie setze ich mein Passwort zurück?" }

// 2. HTTP Request - Open WebUI abfragen
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Header:
  Authorization: Bearer {{$env.OPENWEBUI_API_KEY}}
Body: {
  "model": "llama3.2",
  "messages": [
    {
      "role": "system",
      "content": "Du bist ein Kundensupport-Assistent. Gib klare, hilfreiche Antworten basierend auf unserer Wissensdatenbank."
    },
    {
      "role": "user",
      "content": "{{$json.question}}"
    }
  ]
}

// 3. Code Node - Antwort formatieren
const response = $json.choices[0].message.content;
return {
  customer: $('Webhook').item.json.customer,
  question: $('Webhook').item.json.question,
  ai_response: response,
  timestamp: new Date().toISOString()
};

// 4. E-Mail senden - Kunde antworten
To: {{$json.customer}}@company.com
Subject: Re: {{$json.question}}
Nachricht: |
  Hallo {{$json.customer}},
  
  {{$json.ai_response}}
  
  Mit freundlichen Grüßen,
  Support-Team

// 5. Baserow Node - Interaktion protokollieren
Table: support_tickets
Fields: {
  customer: {{$json.customer}},
  question: {{$json.question}},
  ai_response: {{$json.ai_response}},
  resolved: true
}
```

#### Beispiel 2: Dokumenten-Analyse-Pipeline

```javascript
// 1. Schedule Trigger - Täglich um 9 Uhr
// 2. Google Drive - Neue PDFs abrufen
Folder: /Documents/ToProcess
Dateityp: PDF

// 3. HTTP Request - An Open WebUI mit RAG hochladen
Methode: POST
URL: http://open-webui:8080/api/documents/upload
Header:
  Authorization: Bearer {{$env.OPENWEBUI_API_KEY}}
Body (Form Data):
  Datei: {{$binary.data}}

// 4. HTTP Request - Dokument abfragen
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "llama3.2",
  "messages": [
    {
      "role": "user",
      "content": "Analysiere dieses Dokument und extrahiere: 1) Hauptthemen, 2) Aktionspunkte, 3) Fristen"
    }
  ],
  "files": ["{{$json.document_id}}"]
}

// 5. Code Node - Ergebnisse strukturieren
const analysis = JSON.parse($json.choices[0].message.content);
return {
  document: $('Google Drive').item.json.name,
  key_topics: analysis.key_topics,
  action_items: analysis.action_items,
  deadlines: analysis.deadlines
};

// 6. Notion - Seite mit Analyse erstellen
Database: Project Docs
Properties: {
  title: {{$json.document}},
  topics: {{$json.key_topics}},
  actions: {{$json.action_items}},
  due_dates: {{$json.deadlines}}
}
```

#### Beispiel 3: Multi-Modell-Vergleich

```javascript
// Vergleiche Antworten von verschiedenen Modellen

// 1. Webhook Trigger - Frage empfangen

// 2. Split in Batches (parallele Ausführung)

// 3a. HTTP Request - Ollama (Llama)
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "llama3.2",
  "messages": [{"role": "user", "content": "{{$json.question}}"}]
}

// 3b. HTTP Request - OpenAI (GPT-4)
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o",
  "messages": [{"role": "user", "content": "{{$json.question}}"}]
}

// 3c. HTTP Request - Mistral
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "mistral",
  "messages": [{"role": "user", "content": "{{$json.question}}"}]
}

// 4. Aggregate Results
// Alle Antworten kombinieren

// 5. Code Node - Vergleichen und bewerten
const responses = [
  { model: "llama3.2", answer: $item(0).json.choices[0].message.content },
  { model: "gpt-4o", answer: $item(1).json.choices[0].message.content },
  { model: "mistral", answer: $item(2).json.choices[0].message.content }
];

// Beste Antwort basierend auf Länge, Klarheit, etc. zurückgeben
return responses;
```

### LightRAG-Integration

**LightRAG als Modell in Open WebUI hinzufügen:**

1. Einstellungen → **Verbindungen**
2. Neue Ollama-Verbindung hinzufügen:
   - **URL:** `http://lightrag:9621`
   - **Modellname:** `lightrag:latest`
3. LightRAG aus dem Modell-Dropdown auswählen

**Jetzt kannst du direkt mit deinem Wissensgraph chatten!**

### Benutzerverwaltung

**Admin-Funktionen:**

1. Einstellungen → **Admin-Panel**
2. Benutzer, Rollen, Berechtigungen verwalten
3. Modellzugriff pro Benutzer steuern
4. Nutzungsstatistiken anzeigen

**Zusätzliche Benutzer erstellen:**

1. Admin-Panel → **Benutzer** → **Benutzer hinzufügen**
2. Benutzername, E-Mail, Passwort festlegen
3. Rolle zuweisen: Admin, Benutzer oder Ausstehend
4. Benutzer können sich auch selbst registrieren, falls aktiviert

### Fehlerbehebung

**Modelle werden nicht angezeigt:**

```bash
# Prüfe ob Ollama läuft
docker ps | grep ollama

# Verbindung von Open WebUI überprüfen
docker exec open-webui curl http://ollama:11434/api/tags

# Open WebUI neu starten
docker compose restart open-webui
```

**Langsame Antworten:**

```bash
# Serverressourcen überprüfen
docker stats ollama

# Modell könnte zu groß für RAM sein
# Zu kleinerem Modell wechseln:
# llama3.2 (2GB) statt llama3.2:70b (40GB)

# CPU-Zuweisung in docker-compose.yml erhöhen
```

**RAG funktioniert nicht:**

```bash
# Vektordatenbank überprüfen
docker logs open-webui | grep vector

# Embeddings löschen und neu aufbauen
# Einstellungen → Admin → Vektordatenbank zurücksetzen

# Ausreichend Speicherplatz sicherstellen
df -h
```

**API-Authentifizierung fehlgeschlagen:**

```bash
# API-Schlüssel in Open WebUI neu generieren
# Einstellungen → Konto → API-Schlüssel → Neu erstellen

# n8n-Credential aktualisieren
# Alten Schlüssel durch neuen ersetzen
```

### Ressourcen

- **Offizielle Dokumentation:** https://docs.openwebui.com/
- **GitHub:** https://github.com/open-webui/open-webui
- **API-Referenz:** https://docs.openwebui.com/api/
- **Modellbibliothek:** https://ollama.com/library
- **Community Discord:** https://discord.gg/open-webui

### Best Practices

**Modellauswahl:**
- Verwende `llama3.2` für allgemeine Aufgaben (schnell, 2GB)
- Verwende `gpt-4o-mini` für bessere Qualität, wenn Geschwindigkeit wichtig ist
- Verwende `qwen2.5-coder` für code-lastige Aufgaben
- Verwende Vision-Modelle für Bildanalyse

**Performance:**
- Behalte 2-3 häufig verwendete Modelle heruntergeladen
- Entferne ungenutzte Modelle um Speicherplatz zu sparen
- Verwende OpenAI API für Produktion (schneller, zuverlässiger)
- Verwende Ollama für datenschutzsensible Daten

**Sicherheit:**
- Ändere das Standard-Admin-Passwort sofort
- Deaktiviere Selbstregistrierung in Produktion
- Verwende rollenbasierten Zugriff für Team-Deployments
- Sichere regelmäßig die Konversationsverläufe

**RAG-Optimierung:**
- Lade Dokumente in unterstützten Formaten hoch (PDF, DOCX, TXT)
- Halte Dokumente unter 10MB für beste Performance
- Verwende klare, beschreibende Fragen
- Kombiniere mehrere verwandte Dokumente für besseren Kontext
