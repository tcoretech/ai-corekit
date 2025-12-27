# 📱 Postiz - Social Media Management

### Was ist Postiz?

Postiz ist eine leistungsstarke, Open-Source Social-Media-Management-Plattform, die Content-Planung, -Scheduling und -Analytics über 20+ Plattformen hinweg zentralisiert. Es ist eine selbst gehostete Alternative zu Buffer, Hootsuite und ähnlichen Tools und bietet KI-gestützte Content-Erstellung, Team-Zusammenarbeit und umfassende Analytics – alles bei voller Kontrolle über deine Daten.

### Funktionen

- **Multi-Plattform-Unterstützung** - Plane Posts für 20+ Plattformen: X, Facebook, Instagram, LinkedIn, YouTube, TikTok, Threads, Bluesky, Reddit, Mastodon, Pinterest, Dribbble, Slack, Discord
- **KI-Content-Generierung** - OpenAI-gestützte Post-Erstellung mit Hashtags, Emojis und CTAs
- **Visueller Kalender** - Drag-and-Drop-Scheduling mit klarer Übersicht über alle Inhalte
- **Design-Studio** - Canva-ähnliche Oberfläche zum Erstellen von Grafiken, Infografiken und Videos
- **Analytics & Insights** - Verfolge Engagement, Reichweite, Impressionen und Publikums-Demografie
- **Team-Zusammenarbeit** - Multi-User-Unterstützung mit Rollen, Berechtigungen und Kommentar-System

### Erste Einrichtung

**Erste Anmeldung bei Postiz:**

1. Navigiere zu `https://postiz.deinedomain.com`
2. **Erster Benutzer wird Admin** - Erstelle dein Konto
3. Schließe die Organisations-Einrichtung ab
4. Verbinde dein erstes Social-Media-Konto

**Social-Media-Konten verbinden:**

1. Klicke auf **Integrationen** in der Seitenleiste
2. Wähle Plattform (X, Facebook, LinkedIn, etc.)
3. Autorisiere über OAuth
4. Konto erscheint in deiner Kanalliste

### API-Schlüssel generieren

**Für n8n-Integration und Automatisierung:**

1. Klicke auf **Einstellungen** (Zahnrad-Symbol, oben rechts)
2. Gehe zum Abschnitt **Public API**
3. Klicke auf **API-Schlüssel generieren**
4. Kopieren und sicher speichern

**API-Limits:**
- 30 Anfragen pro Stunde
- Gilt für API-Calls, nicht Post-Anzahl
- Plane voraus, um Effizienz zu maximieren

### n8n-Integrations-Setup

**Option 1: Benutzerdefinierter Postiz-Node (Empfohlen)**

Postiz hat einen benutzerdefinierten n8n-Community-Node:

1. n8n → Einstellungen → **Community-Nodes**
2. Suche: `n8n-nodes-postiz`
3. Klicke auf **Installieren**
4. n8n neu starten: `docker compose restart n8n`

**Postiz-Credentials in n8n erstellen:**
```javascript
// Postiz API Credentials
API URL: https://postiz.deinedomain.com
API Key: [Dein API-Schlüssel aus Postiz-Einstellungen]
```

**Option 2: HTTP Request Node**

```javascript
// HTTP Request Node Konfiguration
Methode: POST
URL: https://postiz.deinedomain.com/api/public/v1/posts
Authentication: Header Auth
  Header: Authorization
  Wert: {{$env.POSTIZ_API_KEY}}
  
Header:
  Content-Type: application/json
```

**Interne URL:** `http://postiz:3000`

### Beispiel-Workflows

#### Beispiel 1: Blog-Beiträge automatisch in Social Media posten

```javascript
// 1. RSS Feed Trigger - Blog auf neue Beiträge überwachen
URL: https://yourblog.com/feed.xml
Check every: 1 hour

// 2. Code Node - Post-Daten extrahieren
const item = $json;
return {
  title: item.title,
  url: item.link,
  summary: item.contentSnippet,
  published: item.pubDate
};

// 3. OpenAI Node - Social Post generieren
Modell: gpt-4o-mini
Prompt: |
  Erstelle einen ansprechenden Social-Media-Post für diesen Blog-Artikel:
  Titel: {{$json.title}}
  Zusammenfassung: {{$json.summary}}
  
  Mach ihn einprägsam mit Emojis und Hashtags. Halte ihn unter 280 Zeichen.
  Füge einen Call-to-Action hinzu, um den vollständigen Artikel zu lesen.

// 4. Postiz Node (oder HTTP Request) - Post planen
Operation: Create Post
Channels: ["twitter", "linkedin", "facebook"]
Inhalt: {{$json.ai_generated_post}}
Link: {{$('Extract Data').json.url}}
Scheduled Time: Now + 30 minutes

// 5. Slack Node - Team benachrichtigen
Kanal: #marketing
Nachricht: |
  📝 Neuer Blog-Beitrag automatisch für Social Media geplant!
  
  Titel: {{$('Extract Data').json.title}}
  Plattformen: Twitter, LinkedIn, Facebook
  Geht live in 30 Minuten
```

#### Beispiel 2: KI-gestützter Content-Kalender

```javascript
// Generiere eine Woche Social-Media-Posts mit KI

// 1. Schedule Trigger - Montag um 9 Uhr

// 2. OpenAI Node - Content-Ideen generieren
Modell: gpt-4o
Prompt: |
  Generiere 7 ansprechende Social-Media-Post-Ideen für diese Woche.
  Themen: KI, Automatisierung, Produktivität, Tech-Tipps
  
  Gib als JSON-Array zurück:
  [
    {
      "day": "Montag",
      "topic": "...",
      "content": "...",
      "hashtags": "..."
    }
  ]

// 3. Split in Batches - Jeden Tag verarbeiten

// 4. Code Node - Für Postiz formatieren
const post = $json;
const dayOffset = {
  "Montag": 0,
  "Dienstag": 1,
  "Mittwoch": 2,
  "Donnerstag": 3,
  "Freitag": 4,
  "Samstag": 5,
  "Sonntag": 6
};

const scheduleDate = new Date();
scheduleDate.setDate(scheduleDate.getDate() + dayOffset[post.day]);
scheduleDate.setHours(10, 0, 0, 0); // 10 Uhr jeden Tag

return {
  content: `${post.content}\n\n${post.hashtags}`,
  scheduledTime: scheduleDate.toISOString(),
  platforms: ["twitter", "linkedin"]
};

// 5. Loop Over Posts
// 6. HTTP Request - Geplante Posts erstellen
Methode: POST
URL: http://postiz:3000/api/public/v1/posts
Header:
  Authorization: {{$env.POSTIZ_API_KEY}}
Body: {
  "content": "{{$json.content}}",
  "scheduledTime": "{{$json.scheduledTime}}",
  "integrations": ["twitter_id", "linkedin_id"]
}

// 7. Aggregate - Alle erstellten Posts sammeln
// 8. Email Node - Bestätigung senden
To: marketing@company.com
Subject: Social Media für die Woche geplant!
Nachricht: |
  ✅ 7 Posts erfolgreich für Twitter & LinkedIn geplant
  
  Posts gehen täglich um 10 Uhr ab Montag live.
```

#### Beispiel 3: Performance-Analytics-Report

```javascript
// Wöchentliche Social-Media-Analytics-Zusammenfassung

// 1. Schedule Trigger - Freitag um 17 Uhr

// 2. HTTP Request - Posts der letzten 7 Tage abrufen
Methode: GET
URL: http://postiz:3000/api/public/v1/posts
Header:
  Authorization: {{$env.POSTIZ_API_KEY}}
Query Parameter:
  startDatum: {{$now.minus(7, 'days').toISO()}}
  endDatum: {{$now.toISO()}}

// 3. Code Node - Metriken berechnen
const posts = $json.posts;

const stats = {
  totalPosts: posts.length,
  platforms: {},
  topPerformer: null,
  totalEngagement: 0
};

posts.forEach(post => {
  // Nach Plattform gruppieren
  const platform = post.integration.name;
  if (!stats.platforms[platform]) {
    stats.platforms[platform] = {
      count: 0,
      engagement: 0
    };
  }
  
  stats.platforms[platform].count++;
  stats.platforms[platform].engagement += post.engagement || 0;
  stats.totalEngagement += post.engagement || 0;
  
  // Top-Performer tracken
  if (!stats.topPerformer || post.engagement > stats.topPerformer.engagement) {
    stats.topPerformer = post;
  }
});

return stats;

// 4. OpenAI Node - Insights generieren
Modell: gpt-4o-mini
Prompt: |
  Analysiere die Social-Media-Performance dieser Woche und gib Insights:
  
  {{JSON.stringify($json)}}
  
  Gib an:
  1. Gesamt-Performance-Zusammenfassung
  2. Beste Plattform
  3. Empfehlungen für nächste Woche

// 5. Google Docs Node - Report erstellen
Document: Wöchentlicher Social Media Report
Inhalt: |
  # Social Media Report - Woche vom {{$now.toFormat('dd. MMM')}}
  
  ## 📊 Übersicht
  - Gesamt Posts: {{$('Calculate').json.totalPosts}}
  - Gesamt Engagement: {{$('Calculate').json.totalEngagement}}
  
  ## 🏆 Top Post
  {{$('Calculate').json.topPerformer.content}}
  Engagement: {{$('Calculate').json.topPerformer.engagement}}
  
  ## 🤖 KI-Insights
  {{$json.insights}}

// 6. Slack Node - Report teilen
Kanal: #marketing
Nachricht: |
  📈 Wöchentlicher Social Media Report ist fertig!
  
  [Link zum Google Doc]
```

#### Beispiel 4: User-Generated Content Workflow

```javascript
// Marken-Erwähnungen überwachen und mit Erlaubnis reposten

// 1. HTTP Request - Nach Marken-Erwähnungen suchen
// (Nutze Twitter API, Instagram API oder Web Scraping)

// 2. Code Node - Qualitäts-Content filtern
const mentions = $json;
return mentions.filter(m => 
  m.engagement > 100 && 
  m.sentiment === 'positive' &&
  !m.author.isSpam
);

// 3. Send Email - Erlaubnis anfragen
To: {{$json.author.email}}
Subject: Wir würden gerne deinen Content zeigen!
Nachricht: |
  Hallo {{$json.author.name}},
  
  Wir haben deinen tollen Post über unser Produkt gesehen!
  Dürfen wir ihn auf unseren Kanälen mit Nennung teilen?
  
  Antworte mit JA zur Bestätigung.

// 4. Wait for Webhook - Benutzer-Genehmigung
// E-Mail-Antwort löst Webhook aus

// 5. IF Node - Genehmigung prüfen
Bedingung: {{$json.response}} === "JA"

// 6. Postiz Node - Repost planen
Inhalt: |
  Toller Content von @{{$json.author.username}}! 🎉
  
  {{$json.original_content}}
  
  #UserFeature #Community
Channels: ["twitter", "instagram", "linkedin"]
Media: {{$json.media_url}}
```

### API-Endpunkt-Referenz

**Post erstellen:**
```bash
POST /api/public/v1/posts
{
  "content": "Dein Post-Inhalt",
  "scheduledTime": "2025-01-20T10:00:00Z",
  "integrations": ["twitter_id", "facebook_id"]
}
```

**Posts abrufen:**
```bash
GET /api/public/v1/posts?startDate=2025-01-01&endDate=2025-01-20
```

**Medien hochladen:**
```bash
POST /api/public/v1/upload
{
  "file": "base64_encoded_image"
}
```

**Von URL hochladen:**
```bash
POST /api/public/v1/upload-from-url
{
  "url": "https://example.com/image.jpg"
}
```

### KI-Content-Generierung

**Eingebauten KI-Assistenten verwenden:**

1. Neuen Post in Postiz-UI erstellen
2. Auf **KI generieren** Button klicken
3. Prompt eingeben: "Erstelle ansprechenden Post über Produktlaunch"
4. KI generiert Content mit Hashtags und Emojis
5. Bearbeiten und planen

**Aktuelle Einschränkung:** Nur OpenAI unterstützt (noch kein Ollama)

**Workaround für lokale KI:**
Nutze n8n mit Ollama, um Content zu generieren, sende dann an Postiz API.

### Team-Zusammenarbeit

**Team-Mitglieder einladen:**

1. Einstellungen → **Team**
2. Klicke auf **Mitglied einladen**
3. E-Mail eingeben und Rolle wählen:
   - **Admin** - Voller Zugriff
   - **Member** - Posts erstellen und planen
   - **Viewer** - Nur Ansicht

**Posts kommentieren:**
- Team-Mitglieder können geplante Posts kommentieren
- Änderungen vor Veröffentlichung diskutieren
- Genehmigungs-Workflow für sensible Inhalte

### Fehlerbehebung

**Posts werden nicht veröffentlicht:**

```bash
# Postiz-Worker überprüfen
docker logs postiz-worker --tail 50

# Social-Account-Verbindung überprüfen
# Postiz UI → Integrationen → Status prüfen

# Konto erneut autorisieren, falls nötig
# Tokens laufen nach 60-90 Tagen für die meisten Plattformen ab

# Geplante Zeit prüfen
# Posts müssen mindestens 5 Minuten im Voraus geplant werden
```

**API-Rate-Limit überschritten:**

```bash
# Fehler: 429 Too Many Requests
# Limit: 30 Anfragen/Stunde

# Lösung: Request-Throttling in n8n implementieren
// Wait Node zwischen Anfragen hinzufügen
Wait: 2 Minuten

// Oder Posts im Batch planen
// Mehrere Posts in einem API-Call planen
```

**Medien-Upload fehlgeschlagen:**

```bash
# Dateigröße prüfen
# Max: 10MB pro Datei

# Unterstützte Formate:
# Bilder: JPG, PNG, GIF, WEBP
# Videos: MP4, MOV (max 100MB)

# Große Dateien vor Upload komprimieren
docker exec n8n ffmpeg -i input.mp4 -vcodec libx264 -crf 28 output.mp4
```

**OAuth-Authentifizierung fehlgeschlagen:**

```bash
# Benötigt öffentliche URL für Callbacks
# Kann nicht localhost verwenden

# Falls Cloudflare Tunnel genutzt wird:
# Sicherstellen, dass Tunnel aktiv ist

# Callback-URL in Plattform-Einstellungen prüfen
# Beispiel Twitter: https://postiz.deinedomain.com/api/integration/twitter/callback
```

### Ressourcen

- **Offizielle Website:** https://postiz.com/
- **Dokumentation:** https://docs.postiz.com/
- **GitHub:** https://github.com/gitroomhq/postiz-app
- **API-Docs:** https://docs.postiz.com/public-api
- **n8n Community Node:** https://www.npmjs.com/package/n8n-nodes-postiz
- **Discord Community:** https://discord.gg/postiz

### Best Practices

**Content-Strategie:**
- Plane Content 1-2 Wochen im Voraus
- Nutze visuellen Kalender für Übersicht
- Erstelle Content in Batches an bestimmten Tagen
- Mische Werbe- und ansprechenden Content

**Scheduling:**
- Poste während Peak-Engagement-Zeiten
- Verteile Posts über Plattformen (nicht überall gleichzeitig posten)
- Nutze Postiz-Analytics, um beste Zeiten zu finden
- Plane mindestens 5 Minuten im Voraus

**Medien:**
- Füge immer Bilder/Videos hinzu (höheres Engagement)
- Nutze Design-Studio für gebrandete Grafiken
- Halte Videos unter 2 Minuten für beste Performance
- Optimiere Bilder (vor Upload komprimieren)

**API-Automatisierung:**
- Implementiere Fehlerbehandlung in Workflows
- Nutze Webhooks für Echtzeit-Updates
- Batch-Operationen, um Rate-Limits einzuhalten
- Überwache API-Nutzung, um Limits nicht zu erreichen

**Team-Workflow:**
- Erstelle Genehmigungs-Prozess für sensible Posts
- Nutze Kommentare für Zusammenarbeit
- Weise Team-Mitgliedern spezifische Plattformen zu
- Regelmäßige Review-Meetings mit Analytics
