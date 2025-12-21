# 🔬 Local Deep Research - Iterative Recherche mit Reflexion

### Was ist Local Deep Research?

Local Deep Research ist LangChains iteratives Tiefenrecherche-Tool, das ~95% Genauigkeit durch Recherche-Schleifen mit Reflexion und Selbstkritik erreicht. Im Gegensatz zu einfachen Web-Suchen führt Local Deep Research mehrere Iterationen durch, validiert Informationen gegen mehrere Quellen, identifiziert Widersprüche und verfeinert kontinuierlich Ergebnisse. Perfekt für Faktenprüfung, detaillierte Analysen und Situationen, die höchste Genauigkeit erfordern.

Das Tool nutzt einen iterativen Ansatz: es recherchiert, reflektiert über das Gefundene, identifiziert Lücken oder Inkonsistenzen und führt dann zusätzliche Recherchen durch, um diese Lücken zu füllen - wiederholt bis das Vertrauen hoch ist oder das Iterations-Limit erreicht wird.

### Features

- **🎯 Höchste Genauigkeit**: ~95% Genauigkeit durch iterative Validierung und Reflexion
- **🔄 Recherche-Schleifen**: Mehrere Recherche-Durchgänge mit kontinuierlicher Verfeinerung
- **🧠 Selbst-Reflexion**: Identifiziert Lücken, Widersprüche und unzureichende Informationen
- **✅ Faktenprüfung**: Multi-Quellen-Validierung für maximale Zuverlässigkeit
- **📊 Konfidenz-Scoring**: Jede Aussage mit Konfidenz-Score und Quellenangaben
- **🌐 Multi-Such-Backend**: Unterstützt SearXNG, Tavily und andere Suchmaschinen
- **⏱️ Tiefenanalyse**: 10-20 Minuten für umfassende Recherche (vs. 2-5 Min für GPT Researcher)

### Ersteinrichtung

**Erster Zugriff auf Local Deep Research:**

1. **API-Gesundheit testen:**
```bash
curl http://local-deep-research:2024/health
# Sollte zurückgeben: {"status": "healthy", "version": "1.0"}
```

2. **Einfache Recherche starten:**
```bash
curl -X POST http://local-deep-research:2024/api/research \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Is quantum computing viable for commercial use in 2025?",
    "iterations": 3
  }'
```

Antwort enthält `task_id` und `websocket_url` für Echtzeit-Updates.

3. **Recherche-Fortschritt prüfen:**
```bash
curl http://local-deep-research:2024/api/status/{task_id}
```

4. **WebSocket für Live-Updates (Optional):**
```bash
wscat -c ws://local-deep-research:2024/ws/{task_id}
# Echtzeit-Fortschritt-Updates empfangen
```

**Wichtig:** Local Deep Research läuft nur intern (keine HTTPS-Subdomain) für n8n/interne Services.

### API-Zugriff

Local Deep Research läuft als interner Service, der für andere Container zugänglich ist:

**Interner API-Endpunkt:**
```
http://local-deep-research:2024
```

**Wichtige API-Endpunkte:**
- `POST /api/research` - Iterative Recherche starten
- `POST /api/verify` - Spezifische Behauptung faktenprüfen
- `GET /api/status/{task_id}` - Fortschritt prüfen
- `GET /api/result/{task_id}` - Finale Analyse abrufen
- `GET /health` - Service-Gesundheitsprüfung

### n8n-Integrationssetup

Local Deep Research hat keinen nativen n8n-Node - Integration erfolgt über HTTP-Request-Nodes.

**Interne URL:** `http://local-deep-research:2024`

**Keine Credentials erforderlich** für interne Container-zu-Container-Kommunikation.

### Beispiel-Workflows

#### Beispiel 1: Hochgenaue Faktenprüfung

Behauptungen mit Multi-Quellen-Validierung und Reflexion verifizieren.

**Workflow-Struktur:**
1. **Webhook/Manueller Trigger**
   ```javascript
   Input: {
     "claim": "Quantum computers can break RSA-2048 encryption today",
     "confidence_required": 0.9
   }
   ```

2. **HTTP Request Node - Faktencheck mit Local Deep Research**
   ```javascript
   Methode: POST
   URL: http://local-deep-research:2024/api/verify
   Header:
     Content-Type: application/json
   Body: {
     "statement": "{{ $json.claim }}",
     "confidence_threshold": {{ $json.confidence_required }},
     "sources_required": 3,
     "iterations": 5
   }
   
   // Antwort: { "task_id": "xyz-789", "websocket_url": "ws://..." }
   ```

3. **Wait Node**
   ```javascript
   Duration: 300 seconds  // 5 Minuten für Tiefenanalyse
   ```

4. **Code Node - Auf Fertigstellung pollen**
   ```javascript
   const taskId = $('HTTP Request').item.json.task_id;
   const maxAttempts = 20;
   let attempts = 0;
   
   while (attempts < maxAttempts) {
     const status = await $http.request({
       method: 'GET',
       url: `http://local-deep-research:2024/api/status/${taskId}`
     });
     
     if (status.status === 'completed') {
       return { taskId, ready: true };
     }
     
     if (status.status === 'failed') {
       throw new Error('Research failed: ' + status.error);
     }
     
     // 30 Sekunden zwischen Checks warten
     await new Promise(resolve => setTimeout(resolve, 30000));
     attempts++;
   }
   
   throw new Error('Research timeout after 10 minutes');
   ```

5. **HTTP Request Node - Verifizierungs-Ergebnis abrufen**
   ```javascript
   Methode: GET
   URL: http://local-deep-research:2024/api/result/{{ $json.taskId }}
   ```

6. **Code Node - Verifizierung parsen**
   ```javascript
   const result = $input.item.json;
   
   return [{
     json: {
       claim: $('Webhook').item.json.claim,
       verdict: result.verified ? 'TRUE' : 'FALSE',
       confidence: result.confidence_score,
       reasoning: result.reasoning,
       sources: result.sources,
       contradictions: result.contradictions_found || [],
       iterations_used: result.iterations_completed,
       warnings: result.warnings || []
     }
   }];
   ```

7. **IF Node - Konfidenz prüfen**
   ```javascript
   Bedingung: {{ $json.confidence }} >= {{ $('Webhook').item.json.confidence_required }}
   ```

8. **Action Nodes**
   - **Hohe Konfidenz-Pfad**: Ergebnis akzeptieren und speichern
   - **Niedrige Konfidenz-Pfad**: An menschliche Überprüfung mit allen Quellen eskalieren

**Anwendungsfall**: Marketing-Behauptungen verifizieren, Statistiken für Berichte validieren, Artikel faktenprüfen.

#### Beispiel 2: Kombinierte Schnell + Tief-Recherche-Strategie

GPT Researcher für Überblick, Local Deep Research für Genauigkeits-Verifizierung nutzen.

**Workflow-Struktur:**
1. **Webhook Trigger**
   ```javascript
   Input: { 
     "topic": "Impact of AI regulation on European startups",
     "depth": "comprehensive"
   }
   ```

2. **GPT Researcher - Schnelle Übersicht (3 Minuten)**
   ```javascript
   Methode: POST
   URL: http://gpt-researcher:8000/api/research
   Body: {
     "query": "{{ $json.topic }}",
     "report_type": "outline_report",
     "max_iterations": 3
   }
   ```

3. **Wait + GPT Researcher Ergebnisse abrufen**

4. **Code Node - Kernbehauptungen extrahieren**
   ```javascript
   const report = $json.report;
   
   // Fettgedruckte Aussagen, Statistiken, Vorhersagen extrahieren
   const claimPatterns = [
     /\d+%/g,  // Prozentzahlen
     /\$[\d,]+/g,  // Dollar-Beträge
     /by \d{4}/gi,  // Jahres-Vorhersagen
     /research shows/gi,  // Recherche-Behauptungen
     /studies indicate/gi  // Studien-Referenzen
   ];
   
   const claims = [];
   for (const pattern of claimPatterns) {
     const matches = report.match(pattern);
     if (matches) {
       // Sätze extrahieren, die diese Muster enthalten
       matches.forEach(match => {
         const sentences = report.split(/[.!?]/);
         const claimSentences = sentences.filter(s => s.includes(match));
         claims.push(...claimSentences.map(s => s.trim()));
       });
     }
   }
   
   // Eindeutige Behauptungen zurückgeben
   return [...new Set(claims)].map(claim => ({ json: { claim } }));
   ```

5. **Loop Over Claims**

6. **HTTP Request - Jede Behauptung verifizieren (Innerhalb Loop)**
   ```javascript
   Methode: POST
   URL: http://local-deep-research:2024/api/verify
   Body: {
     "statement": "{{ $json.item.claim }}",
     "context": "{{ $('GPT Researcher').json.report.substring(0, 1000) }}",
     "iterations": 3,
     "confidence_threshold": 0.8
   }
   ```

7. **Wait + Poll + Ergebnisse abrufen** (wie in Beispiel 1)

8. **Aggregate Node - Verifizierten Bericht kompilieren**
   ```javascript
   const gptReport = $('GPT Researcher').first().json.report;
   const verifications = $input.all().map(v => v.json);
   
   const verified = verifications.filter(v => v.verified && v.confidence >= 0.8);
   const unverified = verifications.filter(v => !v.verified || v.confidence < 0.8);
   
   return [{
     json: {
       originalReport: gptReport,
       verifiedClaims: verified.length,
       unverifiedClaims: unverified.length,
       confidenceAverage: verifications.reduce((sum, v) => sum + v.confidence, 0) / verifications.length,
       flaggedForReview: unverified,
       fullVerifications: verifications
     }
   }];
   ```

9. **Action Nodes** - Verifizierten Bericht speichern oder unverifizierte Behauptungen eskalieren

**Anwendungsfall**: Geschäftsberichte mit hohem Risiko, behördliche Einreichungen, Investoren-Kommunikation.

#### Beispiel 3: Kontinuierliche Faktenprüfungs-Pipeline

Veröffentlichte Inhalte überwachen und Genauigkeit kontinuierlich verifizieren.

**Workflow-Struktur:**
1. **Schedule Trigger**
   ```javascript
   Cron: 0 */6 * * *  // Alle 6 Stunden
   ```

2. **HTTP Request - Aktuelle Artikel abrufen**
   ```javascript
   // Von CMS, Website oder Content-API
   Methode: GET
   URL: https://your-cms.com/api/articles/recent
   ```

3. **Loop Over Articles**

4. **Code Node - Faktische Behauptungen extrahieren**
   ```javascript
   const article = $json.item;
   
   // Regex oder einfachen LLM-Aufruf verwenden, um Behauptungen zu extrahieren
   // Fokus auf: Statistiken, Daten, Zitate, Recherche-Referenzen
   const claims = extractFactualClaims(article.content);
   
   return claims.map(claim => ({
     json: {
       article_id: article.id,
       article_title: article.title,
       claim: claim,
       published_date: article.publishedAt
     }
   }));
   ```

5. **HTTP Request - Behauptungen mit Local Deep Research verifizieren**
   ```javascript
   Methode: POST
   URL: http://local-deep-research:2024/api/verify
   Body: {
     "statement": "{{ $json.claim }}",
     "published_date": "{{ $json.published_date }}",
     "iterations": 4
   }
   ```

6. **Wait + Poll + Ergebnisse**

7. **IF Node - Auf falsche Behauptungen prüfen**
   ```javascript
   Bedingung: {{ $json.verified }} === false || {{ $json.confidence }} < 0.7
   ```

8. **Alarm-Pfad - Redaktionsteam benachrichtigen**
   ```javascript
   // Slack/E-Mail-Benachrichtigung
   Nachricht: |
     ⚠️ Potenzielle Ungenauigkeit erkannt
     
     Artikel: {{ $json.article_title }}
     Behauptung: {{ $json.claim }}
     Urteil: {{ $json.verdict }}
     Konfidenz: {{ $json.confidence }}
     
     Konsultierte Quellen: {{ $json.sources.length }}
     
     Bitte überprüfen und bei Bedarf aktualisieren.
   ```

**Anwendungsfall**: Content-Qualitätssicherung, redaktionelle Faktenprüfung, Compliance-Überwachung.

### Fehlerbehebung

**Problem 1: Recherche dauert zu lange (>20 Minuten)**

```bash
# Container-Status prüfen
launchkit ps | grep local-deep-research

# Logs auf festgefahrene Prozesse ansehen
launchkit logs local-deep-research --tail 100 --follow
```

**Lösung:**
- `iterations` reduzieren (3 statt 5 versuchen)
- Anfrage vereinfachen: spezifischer sein
- Prüfen, ob Such-Backend (SearXNG) reagiert:
  ```bash
  launchkit exec n8n curl http://searxng:8080/search?q=test
  ```

**Problem 2: Niedrige Konfidenz-Scores**

```bash
# Prüfen, ob LLM-Provider funktioniert
launchkit logs local-deep-research | grep -i "llm\|error"
```

**Lösung:**
- Anfrage könnte zu mehrdeutig sein - spezifischer sein
- `iterations` auf 5-7 erhöhen für gründlichere Recherche
- Prüfen, ob Thema aktiv umstritten ist (niedrige Konfidenz wird erwartet)
- LLM-Konfiguration verifizieren (OpenAI-Key oder Ollama-Verbindung)

**Problem 3: Suchmaschinen-Konnektivitätsprobleme**

```bash
# Such-Backend testen
launchkit exec local-deep-research curl http://searxng:8080/health

# Such-Logs prüfen
launchkit logs searxng --tail 50
```

**Lösung:**
- Verifizieren, dass SearXNG oder anderes Such-Backend funktioniert
- Docker-Netzwerk-Konnektivität prüfen
- Such-Service neu starten:
  ```bash
  launchkit restart searxng local-deep-research
  ```

**Problem 4: Widersprüchliche Informationen gefunden**

Dies ist tatsächlich ein GUTES Zeichen - zeigt gründliche Recherche.

```bash
# Das Ergebnis wird enthalten:
{
  "contradictions_found": [
    {
      "claim": "...",
      "source1": "...",
      "source2": "...",
      "contradiction": "..."
    }
  ],
  "confidence_score": 0.65,  // Niedriger wegen Konflikten
  "warnings": ["Multiple contradictory sources found"]
}
```

**Nächste Schritte:**
- Widersprüche manuell überprüfen
- Iterationen erhöhen, um Konflikte zu lösen
- Kontext hinzufügen, um Recherche zu zuverlässigen Quellen zu leiten

**Problem 5: API-Timeout**

```bash
# Umgebungsvariablen prüfen
launchkit exec local-deep-research printenv | grep -E "OPENAI|OLLAMA|SEARXNG"

# Auf Rate-Limiting prüfen
launchkit logs local-deep-research | grep -i "rate\|limit\|quota"
```

**Lösung:**
- Ollama für lokale Inferenz verwenden (keine Rate-Limits):
  ```bash
  # In .env:
  LLM_PROVIDER=ollama
  OLLAMA_BASE_URL=http://ollama:11434
  ```
- Verzögerungen zwischen mehreren Recherche-Anfragen in n8n hinzufügen
- Prüfen, ob externe API-Kontingente überschritten sind

### Best Practices

**Wann Local Deep Research nutzen:**

✅ **Perfekt für:**
- Faktenprüfung kritischer Geschäftsentscheidungen
- Verifizierung von Statistiken und Finanzdaten
- Akademische Recherche mit hoher Genauigkeitsanforderung
- Behördliche Compliance-Recherche
- Medizinische/wissenschaftliche Behauptungs-Verifizierung
- Rechtliche Recherche und Due Diligence

❌ **Nicht ideal für:**
- Schnelle Überblicke (stattdessen GPT Researcher nutzen)
- Meinungsbasierte Fragen
- Kreative Content-Generierung
- Echtzeit-Daten (direkte APIs nutzen)
- Einfache Informations-Lookups

**Recherche-Strategie nach verfügbarer Zeit:**

**Schnelle Recherche (2-5 Min):**
```
GPT Researcher (outline_report, 3 Iterationen)
→ Nutzen für: Überblicke, Brainstorming, erste Exploration
```

**Tiefenrecherche (10-20 Min):**
```
Local Deep Research (5 Iterationen, hohe Konfidenz)
→ Nutzen für: Faktenprüfung, detaillierte Analyse, Entscheidungsunterstützung
```

**Umfassende Recherche (30+ Min):**
```
GPT Researcher (Gliederung) → Behauptungen extrahieren
→ Local Deep Research (jede Behauptung verifizieren)
→ Finalen Bericht synthetisieren
→ Nutzen für: Kritische Entscheidungen, Publikationen, Compliance
```

**Optimierungstipps:**

- **Kontext ist der Schlüssel**: Immer vorherige Recherche als Kontext bereitstellen
- **Spezifische Anfragen**: "Was ist der ROI von X?" > "Erzähl mir über X"
- **Schrittweise iterieren**: Mit 3 Iterationen beginnen, bei Bedarf erhöhen
- **Parallele Verarbeitung**: Mehrere Behauptungen gleichzeitig in n8n verifizieren
- **Ergebnisse cachen**: Verifizierte Fakten in Datenbank speichern, um erneute Recherche zu vermeiden

**Integrationsmuster:**

```javascript
// Muster 1: Schnell + Tief
GPT Researcher (Überblick) → Local Deep Research (Kernbehauptungen verifizieren)

// Muster 2: Multi-Quellen-Validierung
SearXNG (rohe Ergebnisse) → Local Deep Research (synthetisieren + verifizieren)

// Muster 3: Kontinuierliche Überwachung
Zeitplan → Behauptungen sammeln → Local Deep Research → Alarm bei Falschheit

// Muster 4: Mensch in der Schleife
Local Deep Research → Falls Konfidenz < 0.8 → Menschliche Überprüfung
```

### Ressourcen

- **Offizielle Dokumentation**: https://github.com/langchain-ai/local-deep-researcher
- **GitHub Repository**: https://github.com/langchain-ai/local-deep-researcher
- **LangChain Docs**: https://python.langchain.com/docs/
- **Interne API**: `http://local-deep-research:2024`
- **WebSocket-Updates**: `ws://local-deep-research:2024/ws/{task_id}`

**Verwandte Services:**
- Mit **GPT Researcher** für Schnell + Tief-Strategie kombinieren
- **SearXNG** als Such-Backend nutzen
- Ergebnisse in **PostgreSQL** oder **Supabase** speichern
- Mit **Ollama** für lokale LLM-Inferenz verarbeiten
- Mit **Perplexica** für alternative Perspektiven vergleichen
