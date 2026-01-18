# ⚡ Redis - In-Memory Store

### Was ist Redis?

Redis (REmote DIctionary Server) ist ein Open-Source In-Memory-Datenspeicher, der als Datenbank, Cache, Message Broker und Streaming-Engine verwendet wird. Im Gegensatz zu traditionellen Datenbanken, die Daten auf der Festplatte speichern, hält Redis alles im RAM, was Sub-Millisekunden-Antwortzeiten ermöglicht und Millionen Anfragen pro Sekunde verarbeiten kann. Im AI CoreKit treibt Redis Caching-Layer, Session-Speicherung, Job-Queues und Echtzeit-Features über mehrere Dienste hinweg an.

Redis unterstützt reichhaltige Datentypen einschließlich Strings, Hashes, Listen, Sets, Sorted Sets, Bitmaps und Streams. Mit atomaren Operationen und Lua-Scripting ermöglicht Redis komplexe Workflows bei gleichzeitig blitzschneller Performance.

### Features

- ✅ **In-Memory Performance** - Sub-Millisekunden-Latenz mit Daten im RAM gespeichert
- ✅ **Reichhaltige Datenstrukturen** - Strings, Hashes, Listen, Sets, Sorted Sets, Bitmaps, Streams
- ✅ **Atomare Operationen** - Thread-sichere Operationen ohne Race Conditions
- ✅ **Pub/Sub Messaging** - Echtzeit-Nachrichtenverteilung für Event-getriebene Architekturen
- ✅ **Persistenz-Optionen** - RDB-Snapshots und AOF (Append-Only File) für Datenhaltbarkeit
- ✅ **Lua-Scripting** - Komplexe Operationen atomar serverseitig ausführen
- ✅ **Expiration/TTL** - Automatische Schlüssel-Ablauf für Cache-Management
- ✅ **Transaktionen** - Multi-Command-Transaktionen mit WATCH für optimistisches Locking
- ✅ **Replikation** - Master-Replica-Replikation für hohe Verfügbarkeit
- ✅ **Clustering** - Horizontale Skalierung über mehrere Nodes

### Erste Einrichtung

Redis wird automatisch während der AI CoreKit-Installation installiert und konfiguriert.

**Auf Redis zugreifen:**

```bash
# Redis CLI aufrufen
docker exec -it redis redis-cli

# Verbindung testen
docker exec redis redis-cli PING
# Sollte zurückgeben: PONG

# Redis Info anzeigen
docker exec redis redis-cli INFO
```

**Wichtige Konfiguration:**

```bash
# Redis läuft auf Standard-Port 6379 (nur intern)
# Kein Passwort erforderlich für interne Docker-Netzwerk-Verbindungen

# Redis-Konfiguration prüfen
docker exec redis redis-cli CONFIG GET maxmemory
docker exec redis redis-cli CONFIG GET maxmemory-policy
```

**Grundlegende Redis-Befehle:**

```bash
# Einen Schlüssel setzen
docker exec redis redis-cli SET mykey "Hallo Redis"

# Einen Schlüssel abrufen
docker exec redis redis-cli GET mykey

# Mit Ablaufzeit setzen (TTL)
docker exec redis redis-cli SETEX mykey 60 "läuft in 60 Sekunden ab"

# Verbleibende TTL prüfen
docker exec redis redis-cli TTL mykey

# Einen Schlüssel löschen
docker exec redis redis-cli DEL mykey

# Alle Schlüssel auflisten (mit Vorsicht in Produktion verwenden!)
docker exec redis redis-cli KEYS "*"
```

### n8n-Integration einrichten

Redis ist von n8n aus über den nativen Redis-Node erreichbar.

**Interne URL für n8n:** `redis` (Hostname) auf Port `6379`

**Redis-Credentials in n8n erstellen:**

1. In n8n, gehe zu **Credentials** → **New Credential**
2. Suche nach **Redis**
3. Fülle aus:
   - **Password:** Leer lassen (kein Passwort für interne Verbindungen)
   - **Host:** `redis` (Docker-Service-Name)
   - **Port:** `6379` (Standard)
   - **Database Number:** `0` (Standard)

**Verfügbare Redis-Operationen in n8n:**
- **Delete** - Schlüssel entfernen
- **Get** - Wert abrufen
- **Incr** - Zähler erhöhen
- **Info** - Redis-Server-Info
- **Keys** - Schlüssel nach Muster finden
- **Pop** - Element aus Liste entfernen und zurückgeben
- **Push** - Element zur Liste hinzufügen
- **Set** - Schlüssel-Wert-Paar speichern
- **Set Expire** - TTL auf Schlüssel setzen

### Beispiel-Workflows

#### Beispiel 1: API-Anfragen Rate Limiting

```javascript
// Rate Limiting implementieren um API-Missbrauch zu verhindern

// 1. Webhook Trigger - API-Anfrage empfangen

// 2. Code Node - Benutzer-Identifikator extrahieren
const userId = $json.headers['x-user-id'] || $json.query.user_id;
const rateKey = `rate_limit:${userId}`;

return {
  userId: userId,
  rateKey: rateKey,
  timestamp: Date.now()
};

// 3. Redis Node - Aktuelle Anfragenzahl prüfen
Operation: Get
Key: {{$json.rateKey}}

// 4. Code Node - Rate Limit berechnen
const currentCount = parseInt($input.item.json.value || '0');
const limit = 100; // 100 Anfragen pro Stunde
const ttl = 3600; // 1 Stunde in Sekunden

if (currentCount >= limit) {
  // Rate Limit überschritten
  return {
    allowed: false,
    remaining: 0,
    resetTime: Date.now() + (ttl * 1000),
    message: 'Rate Limit überschritten. Versuche es später erneut.'
  };
}

return {
  allowed: true,
  currentCount: currentCount,
  remaining: limit - currentCount - 1,
  key: $('Code Node').json.rateKey
};

// 5. IF Node - Prüfen ob erlaubt
{{$json.allowed}} equals true

// TRUE ZWEIG:
// 6. Redis Node - Zähler erhöhen
Operation: Incr
Key: {{$('Code Node').json.rateKey}}

// 7. Redis Node - Ablaufzeit bei erster Anfrage setzen
Operation: Set Expire
Key: {{$('Code Node').json.rateKey}}
TTL: 3600

// 8. HTTP Request - An tatsächliche API weiterleiten
// ... Anfrage verarbeiten ...

// 9. Mit Erfolg + Rate Limit Headers antworten
Header:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: {{$('Code Node').json.remaining}}
  X-RateLimit-Reset: {{$('Code Node').json.resetTime}}

// FALSE ZWEIG:
// 10. Mit 429 Too Many Requests antworten
Statuscode: 429
Body: {{$('Code Node').json.message}}
```

#### Beispiel 2: Datenbank-Abfragen cachen

```javascript
// Teure Datenbank-Abfragen in Redis cachen

// 1. Webhook oder Schedule Trigger

// 2. Code Node - Cache-Schlüssel generieren
const query = $json.query || 'SELECT * FROM products WHERE category = "electronics"';
const cacheKey = `cache:query:${require('crypto').createHash('md5').update(query).digest('hex')}`;

return {
  query: query,
  cacheKey: cacheKey
};

// 3. Redis Node - Versuch gecachtes Ergebnis zu holen
Operation: Get
Key: {{$json.cacheKey}}

// 4. IF Node - Prüfen ob Cache-Treffer
{{$json.value}} is not empty

// CACHE-TREFFER (TRUE ZWEIG):
// 5. Code Node - Gecachte Daten parsen
return {
  source: 'cache',
  data: JSON.parse($input.item.json.value),
  cached: true
};

// CACHE-MISS (FALSE ZWEIG):
// 6. Postgres Node - Abfrage ausführen
Abfrage: {{$('Code Node').json.query}}

// 7. Code Node - Cache-Daten vorbereiten
const results = $input.all();
const cacheData = JSON.stringify(results);

return {
  source: 'database',
  data: results,
  cacheDaten: cacheData,
  cacheKey: $('Code Node').json.cacheKey
};

// 8. Redis Node - Im Cache speichern
Operation: Set
Key: {{$json.cacheKey}}
Wert: {{$json.cacheData}}
TTL: 3600  // 1 Stunde cachen

// 9. Merge Branch - Ergebnisse zurückgeben
// (Beide Zweige laufen hier mit Daten zusammen)

// Performance-Verbesserung:
// - Erste Anfrage: ~100ms (Datenbankabfrage)
// - Gecachte Anfragen: ~5ms (Redis-Lookup)
// - 20x schnellere Antwortzeit!
```

#### Beispiel 3: Session-Management für Multi-User-Anwendung

```javascript
// Benutzersitzungen in Redis speichern und verwalten

// WORKFLOW 1: Benutzer-Login - Session erstellen

// 1. Webhook Trigger - POST /api/login
Body: {"username": "user@example.com", "password": "***"}

// 2. Postgres Node - Zugangsdaten verifizieren
Abfrage: SELECT id, username, role FROM users WHERE email = $1 AND password_hash = crypt($2, password_hash)
Parameter: [{{$json.username}}, {{$json.password}}]

// 3. IF Node - Prüfen ob Benutzer gefunden
{{$json.id}} exists

// 4. Code Node - Session generieren
const crypto = require('crypto');
const sessionId = crypto.randomBytes(32).toString('hex');
const sessionData = {
  userId: $input.item.json.id,
  username: $input.item.json.username,
  role: $input.item.json.role,
  loginTime: new Date().toISOString(),
  lastActivity: new Date().toISOString()
};

return {
  sessionId: sessionId,
  sessionKey: `session:${sessionId}`,
  sessionDaten: JSON.stringify(sessionData),
  userId: sessionData.userId
};

// 5. Redis Node - Session speichern
Operation: Set
Key: {{$json.sessionKey}}
Wert: {{$json.sessionData}}
TTL: 86400  // 24 Stunden

// 6. Mit Session-Token antworten
Status: 200
Body: {
  "success": true,
  "sessionId": "{{$json.sessionId}}",
  "expiresIn": 86400
}
Header:
  Set-Cookie: session_id={{$json.sessionId}}; HttpOnly; Secure; Max-Age=86400


// WORKFLOW 2: Session bei jeder Anfrage validieren

// 1. Webhook Trigger - Jede API-Anfrage

// 2. Code Node - Session-ID extrahieren
const sessionId = $json.headers.cookie?.match(/session_id=([^;]+)/)?.[1] 
                  || $json.headers['x-session-id'];

return {
  sessionId: sessionId,
  sessionKey: `session:${sessionId}`
};

// 3. Redis Node - Session-Daten holen
Operation: Get
Key: {{$json.sessionKey}}

// 4. IF Node - Prüfen ob gültige Session
{{$json.value}} is not empty

// TRUE ZWEIG - Gültige Session:
// 5. Code Node - Session parsen und aktualisieren
const session = JSON.parse($input.item.json.value);
session.lastActivity = new Date().toISOString();

return {
  session: session,
  sessionKey: $('Code Node').json.sessionKey,
  sessionDaten: JSON.stringify(session)
};

// 6. Redis Node - Letzte Aktivität aktualisieren
Operation: Set
Key: {{$json.sessionKey}}
Wert: {{$json.sessionData}}
TTL: 86400  // TTL auffrischen

// 7. Mit autorisierter Anfrage fortfahren...

// FALSE ZWEIG - Ungültige/abgelaufene Session:
// 8. 401 Unauthorized antworten
Status: 401
Body: {"error": "Ungültige oder abgelaufene Session"}


// WORKFLOW 3: Logout - Session zerstören

// 1. Webhook Trigger - POST /api/logout

// 2. Code Node - Session-ID extrahieren
const sessionId = $json.headers['x-session-id'];
return { sessionKey: `session:${sessionId}` };

// 3. Redis Node - Session löschen
Operation: Delete
Key: {{$json.sessionKey}}

// 4. Mit Erfolg antworten
Status: 200
Body: {"success": true, "message": "Erfolgreich abgemeldet"}
```

#### Beispiel 4: Job-Queue mit Hintergrundverarbeitung

```javascript
// Redis-Listen als Job-Queue für Hintergrundaufgaben verwenden

// PRODUCER WORKFLOW - Jobs zur Queue hinzufügen

// 1. Webhook oder Schedule Trigger

// 2. Code Node - Job-Payload erstellen
const jobs = [
  {
    id: Date.now(),
    type: 'send_email',
    data: {
      to: 'user@example.com',
      subject: 'Willkommen!',
      body: 'Danke für deine Anmeldung'
    }
  },
  {
    id: Date.now() + 1,
    type: 'generate_report',
    data: {
      reportType: 'monthly',
      userId: 12345
    }
  }
];

return jobs.map(job => ({
  json: {
    queueKey: 'jobs:pending',
    jobDaten: JSON.stringify(job)
  }
}));

// 3. Redis Node - Job zur Queue pushen
Operation: Push
Key: {{$json.queueKey}}
Wert: {{$json.jobData}}
Position: Right  // RPUSH - ans Ende der Queue hinzufügen


// CONSUMER WORKFLOW - Jobs verarbeiten

// 1. Schedule Trigger - Alle 10 Sekunden

// 2. Redis Node - Job aus Queue poppen (blockierend)
Operation: Pop
Key: jobs:pending
Position: Left  // LPOP - vom Anfang der Queue entfernen

// 3. IF Node - Prüfen ob Job existiert
{{$json.value}} is not empty

// 4. Code Node - Job parsen
const job = JSON.parse($input.item.json.value);

return {
  jobId: job.id,
  jobType: job.type,
  jobDaten: job.data
};

// 5. Switch Node - Nach Job-Typ routen
{{$json.jobType}}
  Case: send_email → E-Mail senden Zweig
  Case: generate_report → Bericht generieren Zweig
  Case: process_data → Daten verarbeiten Zweig

// E-MAIL SENDEN ZWEIG:
// 6a. SMTP Node - E-Mail senden
To: {{$json.jobData.to}}
Subject: {{$json.jobData.subject}}
Body: {{$json.jobData.body}}

// 7a. Redis Node - Job als abgeschlossen markieren
Operation: Set
Key: job:{{$json.jobId}}:status
Wert: completed
TTL: 3600  // Status für 1 Stunde behalten

// BERICHT GENERIEREN ZWEIG:
// 6b. Postgres Node - Berichtsdaten abrufen
// 7b. PDF generieren
// 8b. Zu Storage hochladen
// 9b. Als abgeschlossen markieren...

// Job-Queue Vorteile:
// - Producer von Consumer entkoppeln
// - Traffic-Spitzen elegant handhaben
// - Fehlgeschlagene Jobs wiederholen
// - Worker unabhängig skalieren
```

#### Beispiel 5: Echtzeit Pub/Sub-Benachrichtigungen

```javascript
// Redis Pub/Sub für Echtzeit-Event-Broadcasting verwenden

// PUBLISHER WORKFLOW - Benachrichtigungen senden

// 1. Webhook Trigger - Bestellung platziert Event

// 2. Code Node - Benachrichtigung erstellen
const notification = {
  type: 'order_placed',
  orderId: $json.orderId,
  userId: $json.userId,
  amount: $json.total,
  timestamp: new Date().toISOString(),
  message: `Neue Bestellung #${$json.orderId} für ${$json.total}€`
};

return {
  channel: 'notifications:orders',
  message: JSON.stringify(notification)
};

// 3. Execute Command Node - In Redis-Channel publishen
Command: docker
Arguments: exec redis redis-cli PUBLISH {{$json.channel}} '{{$json.message}}'

// Oder HTTP Request zur Redis REST API verwenden (falls verfügbar)
// Oder mit einem Service integrieren, der auf Redis Pub/Sub hört


// SUBSCRIBER WORKFLOW - Auf Benachrichtigungen hören
// Hinweis: n8n hat keinen nativen Redis Pub/Sub Trigger
// Aber du kannst Redis Trigger Node mit Polling oder externem Service verwenden

// Alternative: Webhook + externer Subscriber verwenden
// Externes Skript hört auf Redis Pub/Sub und sendet Webhooks an n8n

// Beispiel externer Subscriber (Node.js):
/*
const redis = require('redis');
const axios = require('axios');

const subscriber = redis.createClient({
  host: 'redis',
  port: 6379
});

subscriber.subscribe('notifications:orders');

subscriber.on('message', (channel, message) => {
  const notification = JSON.parse(message);
  
  // An n8n Webhook senden
  axios.post('https://n8n.deinedomain.com/webhook/order-notification', notification);
});
*/

// 1. Webhook Trigger - Empfängt Benachrichtigungen vom Subscriber

// 2. Switch Node - Nach Benachrichtigungstyp routen
{{$json.type}}
  Case: order_placed → Lager benachrichtigen
  Case: payment_received → Bestätigungs-E-Mail senden
  Case: order_shipped → Tracking aktualisieren

// 3. Entsprechende Aktion basierend auf Benachrichtigungstyp ausführen

// Pub/Sub Anwendungsfälle:
// - Echtzeit-Dashboards
// - Chat-Anwendungen
// - Live-Updates
// - Event-Broadcasting
// - Microservices-Kommunikation
```

### Erweiterte Anwendungsfälle

#### Leaderboard mit Sorted Sets

```bash
# Sorted Sets sind perfekt für Leaderboards, Rankings, Priority Queues

# Spieler mit Scores hinzufügen
docker exec redis redis-cli ZADD leaderboard 1500 "player1"
docker exec redis redis-cli ZADD leaderboard 2300 "player2"
docker exec redis redis-cli ZADD leaderboard 1800 "player3"

# Top 10 Spieler abrufen
docker exec redis redis-cli ZREVRANGE leaderboard 0 9 WITHSCORES

# Spieler-Rang abrufen
docker exec redis redis-cli ZREVRANK leaderboard "player2"

# Spieler-Score erhöhen
docker exec redis redis-cli ZINCRBY leaderboard 100 "player1"

# Spieler in Score-Bereich abrufen
docker exec redis redis-cli ZRANGEBYSCORE leaderboard 1500 2000 WITHSCORES
```

#### Distributed Locking

```bash
# Race Conditions in verteilten Systemen verhindern

# Lock erwerben (SET mit NX und EX)
docker exec redis redis-cli SET lock:resource:123 "worker-1" NX EX 30
# Gibt OK zurück wenn Lock erworben, nil wenn bereits gesperrt

# Lock freigeben (nur wenn man es besitzt)
docker exec redis redis-cli EVAL "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end" 1 lock:resource:123 "worker-1"

# Anwendungsfall: Sicherstellen dass nur ein Worker einen Job verarbeitet
# - Worker versucht Lock zu erwerben vor Verarbeitung
# - Bei Erfolg, Job verarbeiten und Lock freigeben
# - Bei Misserfolg, Job überspringen (anderer Worker bearbeitet ihn)
```

#### Cache-Eviction-Policies

```bash
# Konfigurieren wie Redis mit Speicherlimits umgeht

# Aktuelle Policy prüfen
docker exec redis redis-cli CONFIG GET maxmemory-policy

# Eviction-Policy setzen
docker exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Verfügbare Policies:
# - noeviction: Fehler zurückgeben wenn Speicherlimit erreicht
# - allkeys-lru: Am wenigsten kürzlich verwendete Schlüssel entfernen
# - allkeys-lfu: Am wenigsten häufig verwendete Schlüssel entfernen
# - volatile-lru: LRU-Schlüssel mit TTL entfernen
# - volatile-lfu: LFU-Schlüssel mit TTL entfernen
# - volatile-ttl: Schlüssel mit kürzester TTL entfernen
# - allkeys-random: Zufällige Schlüssel entfernen
# - volatile-random: Zufällige Schlüssel mit TTL entfernen

# Speicherlimit setzen
docker exec redis redis-cli CONFIG SET maxmemory 256mb
```

### Fehlerbehebung

**Verbindung abgelehnt / Kann nicht mit Redis verbinden:**

```bash
# Prüfen ob Redis läuft
docker ps | grep redis

# Redis-Logs prüfen
docker logs redis --tail 100

# Redis-Verbindung testen
docker exec redis redis-cli PING
# Sollte zurückgeben: PONG

# Redis neu starten
docker compose restart redis

# Von n8n-Container aus testen
docker exec n8n ping redis
# Sollte erfolgreich anpingen
```

**Redis Speicherprobleme / Kein Speicher mehr:**

```bash
# Speichernutzung prüfen
docker exec redis redis-cli INFO memory

# Wichtige Metriken zum Prüfen:
# - used_memory_human: Gesamter von Redis verwendeter Speicher
# - used_memory_rss_human: Resident Set Size (physisches RAM)
# - maxmemory_human: Speicherlimit
# - mem_fragmentation_ratio: Speicherfragmentierung

# Größte Schlüssel prüfen
docker exec redis redis-cli --bigkeys

# Alle Schlüssel löschen (GEFAHR! Mit Vorsicht verwenden)
docker exec redis redis-cli FLUSHALL

# Speicherlimit setzen
docker exec redis redis-cli CONFIG SET maxmemory 512mb

# LRU-Eviction aktivieren
docker exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

**Langsame Redis-Performance:**

```bash
# Nach langsamen Befehlen suchen
docker exec redis redis-cli SLOWLOG GET 10

# Redis-Operationen in Echtzeit überwachen
docker exec redis redis-cli MONITOR
# Strg+C drücken zum Stoppen

# Aktuelle Verbindungen prüfen
docker exec redis redis-cli CLIENT LIST

# Latenz prüfen
docker exec redis redis-cli --latency

# Prüfen ob Redis auf Festplatte speichert (kann Latenz-Spitzen verursachen)
docker exec redis redis-cli INFO persistence

# Persistenz für reinen Cache deaktivieren (schneller, aber Datenverlust bei Neustart)
docker exec redis redis-cli CONFIG SET save ""
docker exec redis redis-cli CONFIG SET appendonly no
```

**Schlüssel laufen nicht ab:**

```bash
# Prüfen ob Schlüssel TTL gesetzt hat
docker exec redis redis-cli TTL mykey
# Gibt zurück: -2 (Schlüssel existiert nicht), -1 (keine Ablaufzeit), oder verbleibende Sekunden

# Ablaufzeit auf existierenden Schlüssel setzen
docker exec redis redis-cli EXPIRE mykey 3600

# Ablauf-Häufigkeit prüfen
docker exec redis redis-cli CONFIG GET hz
# Höheres hz = häufigere Ablauf-Prüfungen (Standard: 10)

# Sofortige Ablauf-Prüfung erzwingen (nicht empfohlen in Produktion)
docker exec redis redis-cli DEBUG SLEEP 0
```

**Redis Persistenz-Probleme:**

```bash
# Letzte Speicherzeit prüfen
docker exec redis redis-cli LASTSAVE

# Speichern auf Festplatte erzwingen
docker exec redis redis-cli SAVE
# oder async:
docker exec redis redis-cli BGSAVE

# Persistenz-Konfiguration prüfen
docker exec redis redis-cli CONFIG GET save
docker exec redis redis-cli CONFIG GET appendonly

# AOF (Append-Only File) Rewrite-Info anzeigen
docker exec redis redis-cli INFO persistence | grep aof

# Persistenz deaktivieren (nur Cache-Modus)
docker exec redis redis-cli CONFIG SET save ""
docker exec redis redis-cli CONFIG SET appendonly no
```

**Häufige n8n Redis Node Fehler:**

```bash
# Fehler: "Connection timeout"
# Lösung: Prüfen dass Redis läuft und erreichbar ist
docker compose restart redis

# Fehler: "WRONGTYPE Operation against a key holding the wrong kind of value"
# Lösung: Schlüssel existiert mit anderem Datentyp, anderen Schlüssel verwenden oder alten Schlüssel löschen
docker exec redis redis-cli DEL mykey

# Fehler: "OOM command not allowed when used memory > 'maxmemory'"
# Lösung: Speicherlimit erhöhen oder Eviction-Policy aktivieren
docker exec redis redis-cli CONFIG SET maxmemory 512mb
docker exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Ressourcen

- **Offizielle Dokumentation:** https://redis.io/docs/
- **Befehls-Referenz:** https://redis.io/commands/
- **Datentypen:** https://redis.io/docs/data-types/
- **Pub/Sub Guide:** https://redis.io/docs/interact/pubsub/
- **n8n Redis Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.redis/
- **Redis Best Practices:** https://redis.io/docs/management/optimization/
- **Redis University:** https://university.redis.com/ (kostenlose Kurse)
- **Try Redis:** https://try.redis.io/ (interaktives Tutorial)

### Best Practices

**Performance:**
- Verwende Pipelining für mehrere Operationen (reduziert Netzwerk-Roundtrips)
- Vermeide KEYS-Befehl in Produktion (verwende stattdessen SCAN)
- Verwende Redis-Transaktionen (MULTI/EXEC) für atomare Operationen
- Setze passende TTLs auf alle Cache-Schlüssel
- Überwache Speichernutzung und setze maxmemory-Limits
- Verwende Connection Pooling (die meisten Redis-Clients tun dies automatisch)

**Caching-Strategie:**
- Cache-aside Pattern: App prüft Cache, dann DB bei Miss
- Write-through: Gleichzeitig in Cache und DB schreiben
- Write-behind: In Cache schreiben, asynchron in DB schreiben
- Verwende Consistent Hashing für verteiltes Caching
- Implementiere Cache Warming für kritische Daten
- Füge Randomisierung zu TTLs hinzu um Cache Stampede zu vermeiden

**Datenstrukturen:**
- Verwende Hashes für Objekte statt mehrere Schlüssel
- Verwende Sets für eindeutige Items und Mitgliedschaftsprüfungen
- Verwende Sorted Sets für Rankings, Leaderboards, Zeitreihen
- Verwende Listen für Queues (LPUSH/RPOP oder RPUSH/LPOP)
- Verwende Streams für Event-Logs und Message Queues

**Sicherheit:**
- Exponiere Redis nicht zum öffentlichen Internet (nur internes Docker-Netzwerk)
- Verwende Redis ACLs für feinkörnige Zugriffskontrolle (Redis 6+)
- Aktiviere Authentifizierung in Produktionsumgebungen
- Verwende TLS für verschlüsselte Verbindungen
- Sichere RDB-Dateien regelmäßig
- Überwache auf ungewöhnliche Befehlsmuster

**Speicherverwaltung:**
```bash
# Speicherlimit setzen
maxmemory 512mb

# Eviction-Policy setzen
maxmemory-policy allkeys-lru

# Persistenz für reinen Cache deaktivieren
save ""
appendonly no

# Komprimierung aktivieren
# (Redis komprimiert nicht, aber verwende komprimierte Werte in App)
```

**Überwachung:**
- Überwache Speichernutzung, Hit-Rate, Evictions
- Setze Alarme für Speicher-Schwellwerte
- Verfolge langsame Abfragen mit SLOWLOG
- Überwache Verbindungsanzahl und Latenz
- Verwende Redis INFO für detaillierte Metriken
- Erwäge Redis-Monitoring-Tools (RedisInsight, Redis Enterprise)
