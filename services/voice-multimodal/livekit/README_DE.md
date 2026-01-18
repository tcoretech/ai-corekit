# 🎙️ LiveKit - Sprach-Agenten

### Was ist LiveKit?

LiveKit ist professionelle WebRTC-Infrastruktur zum Erstellen von Echtzeit-Sprach- und Video-Anwendungen. Es ist speziell für KI-Sprach-Agenten, Live-Streaming und Videokonferenzen konzipiert - verwendet von ChatGPTs Advanced Voice Mode und Tausenden von Produktionsanwendungen. Anders als traditionelle Videokonferenz-Tools mit Web-Oberflächen ist LiveKit eine **API-first-Plattform**, die erfordert, dass du Clients mit SDKs erstellst.

### ⚠️ KRITISCHE Anforderungen

**UDP-Ports 50000-50100 sind ZWINGEND für Audio/Video erforderlich:**

- ❌ Ohne UDP: Nur Signaling funktioniert, **KEIN Media-Streaming!**
- ⚠️ Viele VPS-Anbieter **blockieren UDP-Traffic** standardmäßig
- ✅ TCP-Port 7882 als Fallback erforderlich
- 🧪 **Teste UDP-Konnektivität VOR dem Erstellen von Sprach-Agenten**

**UDP-Test vor Installation:**

```bash
# 1. UDP-Port-Bereich in Firewall öffnen
sudo ufw allow 50000:50100/udp
sudo ufw allow 7882/tcp

# 2. UDP-Konnektivität testen (benötigt zwei Terminals)

# Terminal 1 (auf deinem VPS):
nc -u -l 50000

# Terminal 2 (aus externem Netzwerk, z.B. dein Laptop):
nc -u DEINE_VPS_IP 50000
# Text eingeben und Enter drücken - sollte in Terminal 1 erscheinen

# 3. Wenn Text nicht erscheint, ist UDP BLOCKIERT von deinem Anbieter
```

### VPS-Anbieter-Kompatibilität

| Anbieter | UDP-Status | Empfehlung |
|----------|------------|------------|
| **Hetzner Cloud** | ✅ Funktioniert gut | ⭐ Empfohlen für LiveKit |
| **DigitalOcean** | ✅ Gutes UDP | ⭐ Empfohlen |
| **Contabo** | ✅ Funktioniert (Game-Server-Support) | Gute Wahl |
| **OVH** | ❌ Blockiert oft UDP | ⚠️ Nicht empfohlen |
| **Scaleway** | ⚠️ Firewall-Einschränkungen | Kann Konfiguration erfordern |
| **AWS/GCP** | ⚠️ Erfordert NAT-Setup | Komplexes Setup |

### Hauptunterschiede: LiveKit vs Jitsi Meet

| Feature | LiveKit | Jitsi Meet |
|---------|---------|------------|
| **Hauptverwendung** | KI-Sprach-Agenten, SDKs | Videokonferenzen |
| **Authentifizierung** | JWT-Tokens (Backend erforderlich) | Keine Auth erforderlich |
| **Web-UI** | ❌ Keine (nur API) | ✅ Vollständige Meeting-Oberfläche |
| **Integration** | SDK-first (Entwickler) | Browser-first (Endbenutzer) |
| **UDP-Ports** | 50000-50100 | Nur 10000 |
| **Am besten für** | Sprach-KI, benutzerdefinierte Apps | Schnelle Meetings, Cal.com |

### Funktionen

- **JWT-basierte Authentifizierung** - Sichere token-basierte Client-Zugriffskontrolle
- **SFU-Architektur** - Skalierbare Selective Forwarding Unit für niedrige Latenz
- **KI-Agenten-Ready** - Entwickelt für Sprach-KI-Anwendungen
- **Multi-Plattform-SDKs** - JavaScript, React, Flutter, Swift, Kotlin, Go
- **Niedrige Latenz** - <100ms Glass-to-Glass-Latenz
- **Simulcast-Unterstützung** - Mehrere Qualitätsstreams pro Teilnehmer
- **E2E-Verschlüsselung** - Optional End-to-End-Verschlüsselung
- **Server-seitige Aufzeichnung** - Egress-Service für Aufnahmen
- **WebRTC-Standards** - Vollständige WebRTC-Konformität

### Architecture

```
┌─────────────┐      WebSocket      ┌──────────────┐
│   Client    │ ←─────────────────→ │   LiveKit    │
│   (Browser) │      JWT Token      │   Server     │
└─────────────┘                     └──────────────┘
                                           │
                 ┌─────────────────────────┼─────────────────────────┐
                 │                         │                         │
           ┌─────▼──────┐           ┌─────▼──────┐           ┌─────▼──────┐
           │  WebRTC    │           │  WebRTC    │           │  WebRTC    │
           │  Media     │           │  Media     │           │  Media     │
           │ UDP 50000+ │           │ UDP 50000+ │           │ UDP 50000+ │
           └────────────┘           └────────────┘           └────────────┘
           Client A                 Client B                 Client C
```

### Ersteinrichtung

**Nach Installation:**

1. **API-Credentials** (automatisch generiert in `.env`):
   - API-Schlüssel: `${LIVEKIT_API_KEY}`
   - API-Secret: `${LIVEKIT_API_SECRET}`
   - WebSocket-URL: `wss://livekit.deinedomain.com`

2. **Keine Web-Oberfläche** - LiveKit ist nur API, du musst Clients mit SDKs erstellen

3. **Verbindung testen:**
   ```bash
   # Test-Token generieren
   bash scripts/generate_livekit_token.sh
   
   # Token im LiveKit Playground verwenden:
   # https://agents-playground.livekit.io
   ```

### Zugriffstoken generieren

LiveKit benötigt JWT-Token für Client-Authentifizierung. Generiere sie in deinem Backend (n8n, Node.js, Python):

#### Option 1: CLI-Hilfsskript (Am schnellsten zum Testen)

```bash
# Token mit Standardwerten generieren
bash scripts/generate_livekit_token.sh

# Raum und Benutzer angeben
bash scripts/generate_livekit_token.sh mein-raum mein-benutzer

# Ausgabe:
# Token erfolgreich generiert!
# Zugriffstoken: eyJhbGc...
# Verwende dieses Token im LiveKit Playground:
# https://agents-playground.livekit.io
```

**Parameter:**
- `raum-name` (optional): Raum zum Beitreten, Standard ist `voice-test`
- `user-id` (optional): Benutzer-Identität, Standard ist `user-<timestamp>`

#### Option 2: Node.js (für n8n)

```javascript
// In n8n Code-Node oder Function installieren
// npm install livekit-server-sdk

const { AccessToken } = require('livekit-server-sdk');

// Token für einen Teilnehmer erstellen
const token = new AccessToken(
  process.env.LIVEKIT_API_KEY,
  process.env.LIVEKIT_API_SECRET,
  {
    identity: 'user-' + Date.now(),
    name: 'Benutzername'
  }
);

// Raum-Berechtigungen erteilen
token.addGrant({
  roomJoin: true,
  room: 'mein-sprach-raum',
  canPublish: true,    // Kann sprechen/Video senden
  canSubscribe: true   // Kann andere hören/sehen
});

const jwt = token.toJwt();
return { token: jwt, wsUrl: 'wss://livekit.deinedomain.com' };
```

#### Option 3: Python

```python
from livekit import AccessToken, VideoGrants
import os
import time

# Token erstellen
token = AccessToken(
    api_key=os.getenv('LIVEKIT_API_KEY'),
    api_secret=os.getenv('LIVEKIT_API_SECRET')
)

# Identität und Berechtigungen setzen
token.identity = f"user-{int(time.time())}"
token.name = "Benutzername"
token.add_grant(VideoGrants(
    room_join=True,
    room="mein-sprach-raum",
    can_publish=True,
    can_subscribe=True
))

jwt_token = token.to_jwt()
print(f"Zugriffstoken: {jwt_token}")
```

### n8n-Integration

**Vollständiger KI-Sprach-Agenten-Workflow:**

```javascript
// 1. Webhook-Trigger - Benutzer fordert Sprachanruf an
// Eingabe: { "userId": "123", "userName": "Alice" }

// 2. Code-Node - LiveKit-Token generieren
const { AccessToken } = require('livekit-server-sdk');

const roomName = `raum-${Date.now()}`;
const token = new AccessToken(
  process.env.LIVEKIT_API_KEY,
  process.env.LIVEKIT_API_SECRET,
  {
    identity: $json.userId,
    name: $json.userName
  }
);

token.addGrant({
  roomJoin: true,
  room: roomName,
  canPublish: true,
  canSubscribe: true
});

return {
  token: token.toJwt(),
  wsUrl: 'wss://livekit.deinedomain.com',
  roomName: roomName
};

// 3. HTTP Response-Node - Credentials an Client zurückgeben
Body:
{
  "token": "{{$json.token}}",
  "wsUrl": "{{$json.wsUrl}}",
  "room": "{{$json.roomName}}"
}

// Client verbindet sich mit LiveKit über diese Credentials
// Audio-Streams: Benutzer → LiveKit → n8n → KI → LiveKit → Benutzer
```

### Beispiel-Workflows

#### Beispiel 1: KI-Sprach-Assistenten-Pipeline

```javascript
// Vollständiger Sprach-Agenten-Flow: Sprache → KI → Sprache

// 1. LiveKit Webhook - track.published (Benutzer spricht)
// LiveKit sendet Webhook, wenn Teilnehmer zu sprechen beginnt

// 2. HTTP Request - Audio-Segment herunterladen
Methode: GET
URL: http://livekit-server:7881/recordings/{{$json.trackId}}
Header:
  Authorization: Bearer {{$env.LIVEKIT_API_KEY}}

// 3. HTTP Request - Mit Whisper transkribieren
Methode: POST
URL: http://faster-whisper:8000/v1/audio/transcriptions
Body (Form Data):
  Datei: {{$binary.data}}
  model: Systran/faster-whisper-large-v3

// 4. HTTP Request - KI-Antwort erhalten (OpenAI/Claude/Ollama)
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "llama3.2",
  "messages": [
    {"role": "system", "content": "Du bist ein hilfreicher Sprach-Assistent."},
    {"role": "user", "content": "{{$json.text}}"}
  ]
}

// 5. HTTP Request - Sprache mit TTS generieren
Methode: POST
URL: http://openedai-speech:8000/v1/audio/speech
Body: {
  "model": "tts-1",
  "input": "{{$json.choices[0].message.content}}",
  "voice": "alloy"
}

// 6. LiveKit Audio publizieren - Antwort zurück in Raum senden
// Verwende LiveKit-API, um Audio-Track im Raum zu publizieren
```

#### Beispiel 2: Meeting-Aufzeichnung & Transkription

```javascript
// Automatische Meeting-Verarbeitung

// 1. LiveKit Webhook - recording.finished
// Ausgelöst, wenn LiveKit Aufzeichnung beendet

// 2. HTTP Request - Aufzeichnung herunterladen
Methode: GET
URL: http://livekit-server:7881/recordings/{{$json.recordingId}}
Header:
  Authorization: Bearer {{$env.LIVEKIT_API_SECRET}}

// 3. HTTP Request - Mit Whisper transkribieren
// (Gleich wie Beispiel 1, Schritt 3)

// 4. HTTP Request - Mit LLM zusammenfassen
Methode: POST
URL: http://open-webui:8080/api/chat/completions
Body: {
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "user",
      "content": "Fasse dieses Meeting-Transkript zusammen:\n\n{{$json.text}}"
    }
  ]
}

// 5. E-Mail-Node - Zusammenfassung an Teilnehmer senden
An: {{$json.participantEmails}}
Betreff: Meeting-Zusammenfassung - {{$json.roomName}}
Body: 
  Meeting: {{$json.roomName}}
  Datum: {{$json.startTime}}
  Dauer: {{$json.duration}}
  
  Zusammenfassung:
  {{$json.summary}}
  
  Vollständiges Transkript:
  {{$json.transcript}}

// 6. Google Drive - Transkript speichern
Dateiname: Meeting_{{$json.roomName}}_{{$now}}.txt
Inhalt: {{$json.transcript}}
```

#### Beispiel 3: Sprachgesteuerte Automatisierung

```javascript
// "Hey Assistent, schalte das Licht ein"

// 1. LiveKit Audio-Stream → Whisper-Transkription

// 2. Code-Node - Intent-Erkennung
const text = $json.text.toLowerCase();
const intent = {
  action: null,
  device: null
};

if (text.includes('einschalten') || text.includes('anschalten')) {
  intent.action = 'on';
} else if (text.includes('ausschalten')) {
  intent.action = 'off';
}

if (text.includes('licht') || text.includes('lampe')) {
  intent.device = 'lights';
} else if (text.includes('thermostat') || text.includes('temperatur')) {
  intent.device = 'thermostat';
}

return intent;

// 3. IF-Node - Prüfe ob gültiger Befehl
If: {{$json.action}} !== null AND {{$json.device}} !== null

// 4. HTTP Request - Hausautomation steuern
Methode: POST
URL: http://homeassistant:8123/api/services/light/turn_{{$json.action}}
Header:
  Authorization: Bearer {{$env.HOMEASSISTANT_TOKEN}}
Body: {
  "entity_id": "light.living_room"
}

// 5. TTS-Antwort - Aktion bestätigen
"Okay, schalte {{$json.device}} {{$json.action === 'on' ? 'ein' : 'aus'}}"
→ LiveKit Audio publizieren
```

### Client-SDK-Integration

#### JavaScript/TypeScript (Web)

```javascript
import { Room, RoomEvent } from 'livekit-client';

// Token von deinem Backend abrufen (n8n webhook)
const response = await fetch('/api/get-livekit-token');
const { token, wsUrl } = await response.json();

// Mit Raum verbinden
const room = new Room();
await room.connect(wsUrl, token);

// Mikrofon aktivieren
await room.localParticipant.setMicrophoneEnabled(true);

// Auf Audio-Antwort des KI-Agenten hören
room.on(RoomEvent.TrackSubscribed, (track, publication, participant) => {
  if (track.kind === 'audio') {
    const audioElement = track.attach();
    document.body.appendChild(audioElement);
  }
});

// Verbindung trennen
await room.disconnect();
```

#### React-Beispiel

```jsx
import { LiveKitRoom, AudioTrack, useParticipants } from '@livekit/components-react';
import { useState, useEffect } from 'react';

function VoiceAgent() {
  const [token, setToken] = useState('');

  useEffect(() => {
    // Token von n8n webhook abrufen
    fetch('/api/livekit-token')
      .then(r => r.json())
      .then(data => setToken(data.token));
  }, []);

  return (
    <LiveKitRoom
      serverUrl="wss://livekit.deinedomain.com"
      token={token}
      connect={true}
      audio={true}
      video={false}
    >
      <AudioTrack />
      <ParticipantList />
    </LiveKitRoom>
  );
}

function ParticipantList() {
  const participants = useParticipants();
  
  return (
    <div>
      <h3>Im Raum: {participants.length}</h3>
      {participants.map(p => (
        <div key={p.identity}>{p.name}</div>
      ))}
    </div>
  );
}
```

### KI-Sprach-Agenten-Anwendungsfälle

**Kundensupport-Bot:**
- Benutzer ruft über Browser an
- LiveKit streamt Audio zu n8n
- Whisper transkribiert in Echtzeit
- LLM generiert kontextuelle Antworten
- TTS synthetisiert natürliche Stimme
- Bot antwortet konversationell

**Sprachlern-Assistent:**
- Schüler übt Konversation
- KI analysiert Aussprache
- Gibt sofortiges Feedback
- Verfolgt Fortschritt über Zeit

**Sprachgesteuertes Smart Home:**
- "Schalte das Licht ein"
- LiveKit → Whisper → Intent-Erkennung
- n8n löst Hausautomation aus
- TTS bestätigt Aktion

**Live-Übersetzungsdienst:**
- Mehrsprachige Konferenz
- Echtzeit-Transkription
- Übersetzung via LibreTranslate
- TTS in Zielsprache

### Sicherheit & Token-Berechtigungen

**Warum JWT-Authentifizierung:**
- ✅ Token laufen automatisch ab
- ✅ Granulare Berechtigungen pro Raum
- ✅ Backend kontrolliert Zugriff
- ✅ Keine gemeinsamen Passwörter
- ✅ Pro Sitzung widerrufbar

**Token-Berechtigungsstufen:**

```javascript
// Minimale Berechtigungen (nur zuhören)
token.addGrant({
  roomJoin: true,
  room: 'raum-name',
  canPublish: false,    // Kann nicht sprechen
  canSubscribe: true    // Kann andere hören
});

// Volle Berechtigungen (sprechen und hören)
token.addGrant({
  roomJoin: true,
  room: 'raum-name',
  canPublish: true,     // Kann sprechen
  canSubscribe: true    // Kann andere hören
});

// Admin-Berechtigungen
token.addGrant({
  roomJoin: true,
  room: 'raum-name',
  canPublish: true,
  canSubscribe: true,
  roomAdmin: true       // Kann Benutzer kicken, Raum beenden
});
```

### Fehlerbehebung

**Kein Audio/Video (Am häufigsten):**

```bash
# 1. Prüfe ob LiveKit-Server läuft
docker ps | grep livekit

# Sollte zeigen:
# livekit-server (Up)
# livekit-sfu (Up)

# 2. Server-Logs prüfen
docker logs livekit-server --tail 100
docker logs livekit-sfu --tail 100

# Suche nach:
# - "Started SFU" ✅
# - "Failed to bind" ❌ Port-Konflikt
# - "ICE failed" ❌ Netzwerkprobleme

# 3. UDP-Ports offen verifizieren
sudo netstat -ulnp | grep 50000

# Sollte lauschende Ports 50000-50100 zeigen

# 4. UDP-Konnektivität testen
# (Verwende UDP-Test vor Installation von oben)

# 5. Öffentliche IP-Konfiguration prüfen
grep JVB_DOCKER_HOST_ADDRESS .env

# Sollte deine öffentliche IP zeigen
```

**Token-Authentifizierungsfehler:**

```bash
# 1. API Key/Secret in .env prüfen
cat .env | grep LIVEKIT

# Sollte zeigen:
# LIVEKIT_API_KEY=...
# LIVEKIT_API_SECRET=...

# 2. Token-Generierung verifizieren
# Ungültige Token schlagen fehl mit "401 Unauthorized"
bash scripts/generate_livekit_token.sh

# 3. Token im LiveKit Playground testen
# https://agents-playground.livekit.io

# 4. Token-Ablauf prüfen
# Token laufen ab - generiere neue für jede Sitzung
```

**WebSocket-Verbindung fehlgeschlagen:**

```bash
# 1. Caddy Reverse Proxy prüfen
docker logs caddy | grep livekit

# Sollte erfolgreiche Proxy-Routen zeigen

# 2. WebSocket-Verbindung testen
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test123" \
  https://livekit.deinedomain.com

# Sollte zurückgeben: 101 Switching Protocols

# 3. DNS-Auflösung verifizieren
nslookup livekit.deinedomain.com

# 4. SSL-Zertifikat prüfen
curl -v https://livekit.deinedomain.com 2>&1 | grep SSL
```

**Media-Stream-Probleme:**

```bash
# 1. SFU (Selective Forwarding Unit) Logs prüfen
docker logs livekit-sfu --tail 100

# Suche nach ICE-Negotiation-Fehlern

# 2. Öffentliche IP ist korrekt verifizieren
# LiveKit muss deine öffentliche IP für ICE-Kandidaten kennen
curl ifconfig.me
# Vergleiche mit JVB_DOCKER_HOST_ADDRESS in .env

# 3. Von verschiedenen Netzwerken testen
# Versuche Verbindung von Mobilfunk vs WiFi
# Hilft Firewall/NAT-Probleme zu identifizieren

# 4. Detailliertes Logging aktivieren
# In docker-compose.yml, setze:
# LIVEKIT_LOG_LEVEL=debug

# 5. Bandbreite überwachen
docker stats livekit-server livekit-sfu
# Hohe CPU/Netzwerk? Kann auf Media-Routing-Probleme hinweisen
```

**UDP durch Anbieter blockiert:**

Wenn UDP-Test fehlschlägt und dein Anbieter UDP blockiert:

**Option 1: TCP-Fallback verwenden** (höhere Latenz)
```bash
# Konfiguriere LiveKit zur Verwendung von TCP-Port 7882
# Bereits in AI CoreKit konfiguriert
# Aber erwarte ~50-100ms zusätzliche Latenz
```

**Option 2: TURN-Server verwenden** (komplex)
```bash
# Richte coturn oder verwalteten TURN-Service ein
# Konfiguriere in LiveKit ICE-Servern
# Benötigt zusätzlichen Server/Service
```

**Option 3: VPS-Anbieter wechseln**
```bash
# Empfohlen: Hetzner Cloud, DigitalOcean
# Teste UDP VOR Migration
```

**Option 4: LiveKit Cloud verwenden**
```bash
# Verwaltetes LiveKit-Hosting
# https://livekit.io/cloud
# Keine UDP-Konfiguration erforderlich
```

### Performance & Überwachung

**Ressourcenanforderungen:**
- **Bandbreite:** 50-100 kbps pro Audio-Stream
- **CPU:** ~0,5 Kerne pro 10 Audio-Teilnehmer
- **RAM:** 512MB Basis + 50MB pro aktivem Raum
- **Teilnehmer:** Getestet bis zu 100 Audio-Streams pro VPS

**LiveKit Admin-API:**

```bash
# Aktive Räume auflisten
curl -X GET http://livekit-server:7881/rooms \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"

# Raum-Details abrufen
curl -X GET http://livekit-server:7881/rooms/mein-raum \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"

# Raum beenden (alle Teilnehmer kicken)
curl -X DELETE http://livekit-server:7881/rooms/mein-raum \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"

# Teilnehmer im Raum auflisten
curl -X GET http://livekit-server:7881/rooms/mein-raum/participants \
  -H "Authorization: Bearer ${LIVEKIT_API_SECRET}"
```

**Webhook-Events für n8n:**

Konfiguriere Webhooks, um Echtzeit-Events zu empfangen:
- `room_started` - Raum erstellt
- `room_finished` - Raum geschlossen
- `participant_joined` - Benutzer tritt bei
- `participant_left` - Benutzer verlässt
- `track_published` - Audio/Video-Stream startet
- `track_unpublished` - Audio/Video-Stream stoppt
- `recording_finished` - Aufzeichnung abgeschlossen

### Integration mit AI CoreKit-Services

**LiveKit + Whisper (STT):**
- Streame Audio aus LiveKit-Räumen
- Transkribiere in Echtzeit mit Whisper
- URL: `http://faster-whisper:8000`

**LiveKit + OpenedAI-Speech (TTS):**
- Generiere KI-Sprach-Antworten
- Publiziere Audio zurück in LiveKit-Raum
- URL: `http://openedai-speech:8000`

**LiveKit + Ollama/OpenAI:**
- Verarbeite transkribierten Text mit LLM
- Generiere intelligente Antworten
- Vollständige Sprach-Agenten-Pipeline

**LiveKit + n8n:**
- Orchestriere gesamten Sprach-Agenten-Workflow
- Handle Webhooks und Events
- Verwalte Status und Konversationsfluss

### Ressourcen

- **Offizielle Dokumentation**: [docs.livekit.io](https://docs.livekit.io/)
- **SDK-Beispiele**: [github.com/livekit/livekit-examples](https://github.com/livekit/livekit-examples)
- **Agents Playground**: [agents-playground.livekit.io](https://agents-playground.livekit.io)
- **Discord Community**: [livekit.io/discord](https://livekit.io/discord)
- **API-Referenz**: [docs.livekit.io/reference/server/server-apis](https://docs.livekit.io/reference/server/server-apis/)
- **Client-SDKs**: JavaScript, React, Flutter, Swift, Kotlin, Go, Python

### Produktions-Checkliste

Vor der Bereitstellung von LiveKit-Sprach-Agenten in Produktion:

- [ ] UDP-Ports 50000-50100 verifiziert offen und zugänglich
- [ ] TCP-Port 7882 als Fallback zugänglich
- [ ] API-Schlüssel und Secret sicher in Umgebungsvariablen gespeichert
- [ ] Token-Generierung getestet und funktionierend
- [ ] WebSocket-Verbindung verifiziert (`wss://livekit.deinedomain.com`)
- [ ] Audio-Stream-Fluss validiert (Benutzer → LiveKit → n8n → KI → Benutzer)
- [ ] Überwachungs-Webhooks in n8n konfiguriert
- [ ] Client-SDK integriert und getestet
- [ ] Fehlerbehandlung für Netzwerkausfälle implementiert
- [ ] Latenz gemessen (<100ms Ziel für Sprache)
- [ ] Bandbreitenanforderungen berechnet
- [ ] Skalierungsplan definiert (SFU kann 100+ Streams handhaben)
- [ ] Sicherheitsaudit abgeschlossen (JWT-Berechtigungen, Token-Ablauf)
- [ ] SSL-Zertifikat gültig und automatisch erneuernd
- [ ] Backup/Failover-Strategie vorhanden
