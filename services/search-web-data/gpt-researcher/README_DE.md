# 📊 GPT Researcher - Autonomer Recherche-Agent

### Was ist GPT Researcher?

GPT Researcher ist ein autonomer Recherche-Agent, der umfassende 2000+ Wort-Berichte zu jedem Thema in Minuten erstellt. Im Gegensatz zu einfachen Web-Scrapern sucht er intelligent über mehrere Quellen, analysiert Inhalte, extrahiert relevante Informationen und generiert strukturierte Berichte mit ordnungsgemäßen Zitaten in akademischen Formaten (APA, MLA, Chicago). Er automatisiert den gesamten Rechercheprozess von der Anfrage-Formulierung über Multi-Quellen-Analyse bis zur finalen Berichtserstellung und ersetzt Stunden manueller Recherche durch ein paar API-Aufrufe.

### Features

- **🔬 Autonome Recherche**: Durchsucht automatisch das Web über 20+ Quellen mit intelligenter Anfrage-Generierung
- **📄 Umfassende Berichte**: Generiert 2000-5000 Wort-Berichte mit vollständiger Struktur und Analyse
- **📚 Mehrere Berichtstypen**: Recherche-Berichte, Gliederungen, Ressourcenlisten, Unterthemen-Analyse
- **🎓 Akademische Zitate**: Unterstützt APA-, MLA-, Chicago-Zitierformate mit ordnungsgemäßer Bibliographie
- **⚡ Schnell & Effizient**: Vollständige Recherche-Berichte in 2-5 Minuten statt Stunden
- **🌐 Multi-Quellen-Aggregation**: Synthetisiert Informationen aus diversen Web-Quellen
- **🔄 Iterative Verfeinerung**: Verfeinert Recherche basierend auf ersten Erkenntnissen für umfassende Abdeckung

### Ersteinrichtung

**Erster Zugriff auf GPT Researcher:**

1. **API-Gesundheit testen:**
```bash
curl http://gpt-researcher:8000/health
# Sollte zurückgeben: {"status": "healthy"}
```

2. **Einfache Recherche starten:**
```bash
curl -X POST http://gpt-researcher:8000/api/research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Latest trends in AI automation 2025",
    "report_type": "research_report"
  }'
```

Antwort enthält `task_id` für Status-Tracking.

3. **Recherche-Status prüfen:**
```bash
curl http://gpt-researcher:8000/api/status/{task_id}
```

4. **Web-Oberfläche (Optional):**
Zugriff über `https://research.deinedomain.com`
- Erfordert Basic Authentication (während Installation konfiguriert)
- Username/Passwort: `.env`-Datei prüfen

### API-Zugriff

GPT Researcher läuft als interner Service, der für andere Container zugänglich ist:

**Interner API-Endpunkt:**
```
http://gpt-researcher:8000
```

**Wichtige API-Endpunkte:**
- `POST /api/research` - Neue Recherche-Aufgabe starten
- `GET /api/status/{task_id}` - Recherche-Fortschritt prüfen
- `GET /api/result/{task_id}` - Fertigen Bericht abrufen
- `GET /health` - Service-Gesundheitsprüfung

### n8n-Integrationssetup

GPT Researcher hat keinen nativen n8n-Node - Integration erfolgt über HTTP-Request-Nodes.

**Interne URL:** `http://gpt-researcher:8000`

**Keine Credentials erforderlich** für internen Zugriff (Container-zu-Container-Kommunikation).

### Beispiel-Workflows

#### Beispiel 1: Automatisierte Recherche-Berichts-Generierung

Umfassende Recherche-Berichte auf Abruf oder nach Zeitplan generieren.

**Workflow-Struktur:**
1. **Webhook/Schedule Trigger**
   ```javascript
   Input: {
     "topic": "Impact of AI on healthcare 2025",
     "report_format": "APA"
   }
   ```

2. **HTTP Request Node - Recherche starten**
   ```javascript
   Methode: POST
   URL: http://gpt-researcher:8000/api/research
   Header:
     Content-Type: application/json
   Body: {
     "query": "{{ $json.topic }}",
     "report_type": "research_report",
     "max_iterations": 5,
     "report_format": "{{ $json.report_format }}",
     "total_words": 2000
   }
   
   // Antwort: { "task_id": "abc-123-xyz" }
   ```

3. **Wait Node**
   ```javascript
   Duration: 180 seconds  // Zeit für Recherche geben (typisch 2-5 Min)
   ```

4. **HTTP Request Node - Status prüfen**
   ```javascript
   Methode: GET
   URL: http://gpt-researcher:8000/api/status/{{ $json.task_id }}
   
   // Gibt zurück: { "status": "completed", "progress": 100 }
   ```

5. **IF Node - Prüfen ob fertig**
   ```javascript
   Bedingung: {{ $json.status }} === "completed"
   ```

6. **HTTP Request Node - Bericht abrufen**
   ```javascript
   Methode: GET
   URL: http://gpt-researcher:8000/api/result/{{ $('Start Research').json.task_id }}
   
   // Gibt vollständigen Bericht mit Quellen zurück
   ```

7. **Code Node - Bericht verarbeiten**
   ```javascript
   // Bericht extrahieren und formatieren
   const report = $json.report;
   const sources = $json.sources;
   
   return [{
     json: {
       title: $json.query,
       content: report,
       wordCount: report.split(' ').length,
       sourceCount: sources.length,
       sources: sources.map(s => ({
         title: s.title,
         url: s.url,
         relevance: s.relevance_score
       })),
       generatedAt: new Date().toISOString()
     }
   }];
   ```

8. **Action Nodes** - Bericht senden (E-Mail, Slack, auf Drive speichern)

**Anwendungsfall**: Automatisierte Marktforschung, Wettbewerbsanalyse, Technologie-Trend-Berichte.

#### Beispiel 2: Multi-Themen-Batch-Recherche

Mehrere Themen in einem einzigen Workflow-Durchlauf recherchieren.

**Workflow-Struktur:**
1. **Schedule Trigger**
   ```javascript
   Cron: 0 9 * * *  // Täglich um 9 Uhr
   ```

2. **Code Node - Recherche-Themen definieren**
   ```javascript
   return [
     { topic: "AI automation trends 2025" },
     { topic: "LLM cost optimization strategies" },
     { topic: "Enterprise RAG implementations" },
     { topic: "Open-source AI tools comparison" }
   ];
   ```

3. **Loop Over Items**
   ```javascript
   Items: {{ $json }}
   ```

4. **HTTP Request Node - Recherche starten (Innerhalb Loop)**
   ```javascript
   Methode: POST
   URL: http://gpt-researcher:8000/api/research
   Body: {
     "query": "{{ $json.item.topic }}",
     "report_type": "outline_report",  // Schneller für Batch
     "max_iterations": 3,
     "total_words": 1000
   }
   ```

5. **Wait Node**
   ```javascript
   Duration: 120 seconds per topic
   ```

6. **HTTP Request - Ergebnisse abrufen**
   ```javascript
   Methode: GET
   URL: http://gpt-researcher:8000/api/result/{{ $json.task_id }}
   ```

7. **Aggregate Node - Alle Berichte kombinieren**
   ```javascript
   const allReports = $input.all();
   const completed = allReports
     .filter(r => r.json.status === 'completed')
     .map(r => ({
       topic: r.json.query,
       summary: r.json.report.substring(0, 500) + '...',
       fullReport: r.json.report,
       sourceCount: r.json.sources.length,
       url: `https://research.deinedomain.com/reports/${r.json.task_id}`
     }));
   
   return [{
     json: {
       date: new Date().toISOString().split('T')[0],
       reportsGenerated: completed.length,
       reports: completed
     }
   }];
   ```

8. **Slack/E-Mail - Zusammenfassung senden**
   ```javascript
   Nachricht: |
     📊 Tägliche Recherche-Zusammenfassung - {{ $json.date }}
     
     {{ $json.reportsGenerated }} Berichte generiert:
     
     {{ $json.reports.map(r => `• ${r.topic} (${r.sourceCount} Quellen)`).join('\n') }}
     
     Vollständige Berichte im gemeinsamen Ordner verfügbar.
   ```

**Anwendungsfall**: Tägliche Intelligence-Briefings, Marktüberwachung, Wettbewerbs-Tracking.

#### Beispiel 3: Competitive-Analysis-Workflow

Tiefenrecherche zu Konkurrenten mit vergleichender Analyse.

**Workflow-Struktur:**
1. **Manueller Trigger**
   ```javascript
   Input: {
     "competitors": ["OpenAI GPT-4", "Anthropic Claude", "Google Gemini"],
     "focus_area": "pricing and features"
   }
   ```

2. **Loop Over Competitors**

3. **HTTP Request - Jeden Konkurrenten recherchieren**
   ```javascript
   Methode: POST
   URL: http://gpt-researcher:8000/api/research
   Body: {
     "query": "{{ $json.item }} {{ $('Manual Trigger').item.json.focus_area }} 2025",
     "report_type": "resource_report",
     "max_iterations": 4
   }
   ```

4. **Wait & Fetch (wie vorherige Beispiele)**

5. **Konkurrenten-Daten aggregieren**
   ```javascript
   const reports = $input.all().map(r => r.json);
   return [{
     json: {
       competitors: reports,
       comparisonDatum: new Date().toISOString()
     }
   }];
   ```

6. **OpenAI Node - Vergleich generieren**
   ```javascript
   Modell: gpt-4o
   System: "Du bist ein Business-Analyst. Erstelle eine Vergleichstabelle."
   Prompt: |
     Basierend auf diesen Recherche-Berichten:
     
     {{ $json.competitors.map(c => c.report).join('\n\n---\n\n') }}
     
     Erstelle eine detaillierte Vergleichstabelle mit:
     - Preis-Stufen
     - Hauptfeatures
     - API-Fähigkeiten
     - Limitierungen
     - Beste Anwendungsfälle
   ```

7. **Vergleich speichern** - In Dokument oder Datenbank

**Anwendungsfall**: Competitive Intelligence, Produktpositionierung, Marktanalyse.

### Fehlerbehebung

**Problem 1: Recherche dauert zu lange**

```bash
# Prüfen, ob Service läuft
corekit ps | grep gpt-researcher

# Service-Logs prüfen
corekit logs gpt-researcher --tail 100

# Aktive Recherche-Aufgaben überwachen
curl http://gpt-researcher:8000/api/tasks/active
```

**Lösung:**
- `max_iterations` reduzieren (3 statt 5 versuchen)
- `outline_report`-Typ für schnellere Ergebnisse nutzen
- Prüfen, ob externe Such-APIs reagieren
- Timeout in n8n-Workflow implementieren (5-10 Min max)

**Problem 2: Niedrige Qualität oder unvollständige Berichte**

```bash
# Quellen-Qualität in Ergebnissen prüfen
curl http://gpt-researcher:8000/api/result/{task_id} | jq '.sources'
```

**Lösung:**
- `max_iterations` auf 5-7 erhöhen für gründlichere Recherche
- Spezifischere Anfragen nutzen: "AI automation in healthcare 2025" vs "AI"
- `total_words` höher setzen (3000-4000) für detaillierte Berichte
- `research_report`-Typ statt `outline_report` nutzen

**Problem 3: API-Verbindungsfehler von n8n**

```bash
# Interne Konnektivität testen
corekit exec n8n curl http://gpt-researcher:8000/health

# Docker-Netzwerk prüfen
docker network inspect ai-corekit_default | grep gpt-researcher
```

**Lösung:**
- Service-Name verifizieren: `http://gpt-researcher:8000` (nicht localhost)
- Prüfen, ob Service im gleichen Docker-Netzwerk ist
- Beide Services neu starten:
  ```bash
  corekit restart gpt-researcher n8n
  ```

**Problem 4: Task-Status zeigt "Failed"**

```bash
# Detaillierte Fehler-Logs prüfen
corekit logs gpt-researcher | grep ERROR

# Task-Status mit Fehlerdetails prüfen
curl http://gpt-researcher:8000/api/status/{task_id}
```

**Lösung:**
- Prüfen, ob LLM-API-Keys konfiguriert sind (OpenAI, etc.)
- Internetverbindung vom Container verifizieren
- Rate-Limits auf Such-APIs prüfen
- Anfrage auf ungültige Zeichen oder Formatierung überprüfen

### Konfigurationsparameter

**Vollständige Request-Struktur:**

```json
{
  "query": "Dein research topic or question",
  "report_type": "research_report",
  "max_iterations": 5,
  "report_format": "APA",
  "total_words": 2000,
  "language": "english",
  "tone": "objective",
  "sources_min": 10,
  "sources_max": 20
}
```

**Parameter-Referenz:**

| Parameter | Typ | Standard | Beschreibung |
|-----------|------|---------|-------------|
| `query` | string | Erforderlich | Recherche-Thema oder Frage |
| `report_type` | string | `research_report` | Berichtsformat (siehe Typen unten) |
| `max_iterations` | integer | `5` | Such-Tiefe (1-10) |
| `report_format` | string | `APA` | Zitier-Stil (APA/MLA/Chicago) |
| `total_words` | integer | `2000` | Ziel-Wortanzahl (1000-5000) |
| `language` | string | `english` | Berichtssprache |
| `tone` | string | `objective` | Schreibton (objektiv/analytisch) |
| `sources_min` | integer | `10` | Mindestquellen zum Konsultieren |
| `sources_max` | integer | `20` | Maximalquellen zum Konsultieren |

**Berichtstypen:**
- `research_report` - Umfassende Recherche mit Analyse (Standard)
- `outline_report` - Strukturierte Gliederung ohne Volltext
- `resource_report` - Kuratierte Liste von Quellen mit Zusammenfassungen
- `subtopic_report` - Fokussierte Analyse zu spezifischem Unterthema

### Tipps & Best Practices

**Anfrage-Optimierung:**
- **Sei spezifisch**: "AI automation in healthcare 2025" > "AI"
- **Kontext einbeziehen**: Jahr, Branche oder geografischen Fokus hinzufügen
- **Mehrdeutigkeit vermeiden**: Akronyme und technische Begriffe klären

**Performance-Tuning:**
- Mit `outline_report` für schnelle Übersicht starten
- 3-5 `max_iterations` für ausgewogene Ergebnisse nutzen
- Realistische `total_words` setzen (1000-3000 typisch)
- Verzögerungen zwischen Batch-Anfragen implementieren

**Integrationsmuster:**
- **Schnell + Tief**: GPT Researcher Übersicht → Local Deep Research zur Verifizierung
- **Multi-Quellen**: Mit Perplexica, SearXNG zur Validierung kombinieren
- **Automatisierte Pipelines**: Wiederkehrende Recherche zu Schlüsselthemen planen
- **Nachbearbeitung**: OpenAI/Ollama zum Zusammenfassen oder Umstrukturieren nutzen

**Fehlerbehandlung:**
- Immer Timeout-Logik implementieren (5-10 Min max)
- `task_id` für späteres Abrufen speichern
- Status vor Abrufen der Ergebnisse prüfen
- Fehlgeschlagene Anfragen für manuelle Überprüfung protokollieren

### Ressourcen

- **Offizielle Dokumentation**: https://docs.gptr.dev/
- **GitHub Repository**: https://github.com/assafelovic/gpt-researcher
- **Web-Oberfläche**: `https://research.deinedomain.com` (Basic Auth erforderlich)
- **API-Referenz**: https://docs.gptr.dev/api
- **Beispiele & Tutorials**: https://docs.gptr.dev/examples
- **Interne API**: `http://gpt-researcher:8000`

**Verwandte Services:**
- Mit **SearXNG** für benutzerdefinierte Such-Integration nutzen
- Ergebnisse an **Qdrant/Weaviate** für Wissensdatenbank weiterleiten
- Mit **Ollama** für Zusammenfassung verarbeiten
- Berichte in **Supabase** oder **PostgreSQL** speichern
- Mit **Local Deep Research** für Faktenprüfung vergleichen
