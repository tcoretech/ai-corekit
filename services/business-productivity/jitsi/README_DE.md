# 📹 Jitsi Meet - Videokonferenzen

### Was ist Jitsi Meet?

Jitsi Meet ist eine professionelle, selbst gehostete Videokonferenz-Plattform, die sichere, funktionsreiche Meetings ohne externe Abhängigkeiten bietet. Sie integriert sich nahtlos mit Cal.com für automatische Meeting-Raum-Generierung und ist perfekt für Kundengespräche, Team-Meetings, Webinare und Remote-Zusammenarbeit.

### ⚠️ KRITISCHE Anforderungen

**UDP Port 10000 ist ZWINGEND für Audio/Video erforderlich:**
- Ohne UDP 10000: Nur Chat funktioniert, KEIN Audio/Video!
- Viele VPS-Anbieter blockieren UDP-Traffic standardmäßig
- Teste UDP-Konnektivität VOR dem produktiven Einsatz von Jitsi
- Alternative: Nutze externe Dienste (Zoom, Google Meet) mit Cal.com

### UDP-Test vor Installation

**Vor der Jitsi-Installation prüfen, ob UDP auf deinem VPS funktioniert:**

```bash
# 1. UDP-Port in Firewall öffnen
sudo ufw allow 10000/udp

# 2. UDP-Konnektivität testen (benötigt zwei Terminals)
# Terminal 1 (auf deinem VPS):
nc -u -l 10000

# Terminal 2 (aus externem Netzwerk, z.B. dein Laptop):
nc -u DEINE_VPS_IP 10000
# Text eingeben und Enter drücken
# Wenn Text in Terminal 1 erscheint, funktioniert UDP! ✅
# Wenn nichts erscheint, wird UDP von deinem Provider blockiert ❌
```

### VPS-Provider-Kompatibilität

**Funktioniert gut mit Jitsi:**
- ✅ **Hetzner Cloud** - WebRTC-freundlich, empfohlen
- ✅ **DigitalOcean** - Gute WebRTC-Performance
- ✅ **Contabo** - Game-Server-Support = UDP OK
- ✅ **Vultr** - Gut für Echtzeit-Anwendungen

**Oft problematisch:**
- ❌ **OVH** - Blockiert häufig UDP-Traffic
- ❌ **Scaleway** - Strikte Firewall-Einschränkungen
- ⚠️ **AWS/GCP** - Benötigt NAT-Konfiguration (fortgeschritten)

### Funktionen

- **Keine Authentifizierung erforderlich** - Gastfreundlich für Meeting-Teilnehmer
- **Lobby-Modus** - Kontrolliere, wer deine Meetings betritt
- **HD-Video** - Bis zu 1280x720 Auflösung
- **Bildschirmfreigabe** - Teile Desktop oder spezifische Anwendungen
- **Aufzeichnung** - Optionale lokale Aufzeichnung (erfordert zusätzliches Setup)
- **Mobile Apps** - iOS und Android native Apps
- **Cal.com-Integration** - Automatische Meeting-Raum-Generierung
- **Ende-zu-Ende-Verschlüsselung** - Optionales E2EE für sensible Meetings
- **Chat & Reaktionen** - In-Meeting-Textchat und Emoji-Reaktionen

### Erste Einrichtung

**Jitsi nach Installation testen:**

1. Navigiere zu `https://meet.deinedomain.com`
2. Erstelle einen Test-Raum: `https://meet.deinedomain.com/test123`
3. Erlaube Kamera/Mikrofon-Berechtigungen
4. Überprüfe:
   - ✅ Du kannst dich selbst im Video sehen
   - ✅ Audio funktioniert
   - ✅ Bildschirmfreigabe funktioniert
5. Teste aus einem anderen Netzwerk (Mobiltelefon mit 4G)

**Architektur:**

Jitsi besteht aus mehreren Komponenten:
- **jitsi-web** - Web-Oberfläche
- **jitsi-prosody** - XMPP-Server für Signalisierung
- **jitsi-jicofo** - Focus-Komponente (verwaltet Sitzungen)
- **jitsi-jvb** - Video-Bridge (verarbeitet Medienströme über UDP 10000)

### Cal.com-Integration

**Automatische Videokonferenzen für Buchungen:**

#### 1. Jitsi-App in Cal.com installieren

1. Cal.com öffnen: `https://cal.deinedomain.com`
2. Gehe zu **Einstellungen** → **Apps**
3. Finde **Jitsi Video**
4. Klicke auf **App installieren**
5. Konfiguriere:
   - **Server-URL:** `https://meet.deinedomain.com`
   - Kein Trailing Slash!
6. Klicke auf **Speichern**

#### 2. Event-Typen konfigurieren

1. Gehe zu **Event-Typen**
2. Bearbeite einen Event-Typ (oder erstelle neuen)
3. Unter **Standort**, wähle **Jitsi Video**
4. Änderungen speichern

**Meeting-Links werden jetzt automatisch generiert!**

#### 3. Meeting-URL-Format

Wenn jemand ein Meeting bucht:
- **Automatisches Format:** `https://meet.deinedomain.com/cal/[buchungs-referenz]`
- **Beispiel:** `https://meet.deinedomain.com/cal/abc123def456`

Sowohl du als auch der Teilnehmer erhalten diesen Link in Bestätigungs-E-Mails.

### n8n-Integration

**Automatisierte Meeting-Workflows:**

#### Beispiel 1: Meeting-Erinnerungen

```javascript
// 1. Cal.com Webhook Trigger - booking.created
// Wird ausgelöst, wenn jemand ein Meeting bucht

// 2. Code Node - Erinnerungszeit berechnen
const booking = $json;
const meetingTime = new Date(booking.startTime);
const reminderTime = new Date(meetingTime.getTime() - 3600000); // 1 Stunde vorher

return {
  attendeeEmail: booking.attendees[0].email,
  meetingTitle: booking.title,
  meetingUrl: `https://meet.deinedomain.com/cal/${booking.uid}`,
  reminderTime: reminderTime.toISOString(),
  attendeeName: booking.attendees[0].name,
  hostName: booking.user.name
};

// 3. Wait Node - Bis Erinnerungszeit
Wait Until: {{$json.reminderTime}}

// 4. Send Email Node - Erinnerung an Teilnehmer
To: {{$('Code Node').json.attendeeEmail}}
Subject: Meeting-Erinnerung - {{$('Code Node').json.meetingTitle}}
Nachricht: |
  Hallo {{$('Code Node').json.attendeeName}},
  
  Dein Meeting mit {{$('Code Node').json.hostName}} beginnt in 1 Stunde!
  
  📅 Meeting: {{$('Code Node').json.meetingTitle}}
  🔗 Hier beitreten: {{$('Code Node').json.meetingUrl}}
  
  Bis gleich!

// 5. Slack Node - Team benachrichtigen
Kanal: #meetings
Nachricht: |
  🔔 Anstehendes Meeting in 1 Stunde
  Meeting: {{$('Code Node').json.meetingTitle}}
  Teilnehmer: {{$('Code Node').json.attendeeName}}
  Link: {{$('Code Node').json.meetingUrl}}
```

#### Beispiel 2: Follow-up nach Meeting

```javascript
// 1. Cal.com Webhook Trigger - booking.completed
// Wird nach Meeting-Ende ausgelöst (basierend auf geplanter Dauer)

// 2. Wait Node - 5 Minuten nach Meeting
Wait: 5 minutes

// 3. Send Email Node - Dankeschön + Feedback
To: {{$json.attendees[0].email}}
Subject: Danke für das Meeting!
Nachricht: |
  Hallo {{$json.attendees[0].name}},
  
  Danke, dass du dir heute Zeit für uns genommen hast!
  
  Wir würden uns über dein Feedback freuen:
  [Feedback-Formular-Link]
  
  Nächste Schritte:
  - Wir senden die Zusammenfassung bis EOD
  - Follow-up-Meeting in 2 Wochen
  
  Mit freundlichen Grüßen,
  {{$json.user.name}}

// 4. HTTP Request - Aufgabe im Projektmanagement erstellen
Methode: POST
URL: http://vikunja:3456/api/v1/tasks
Body: {
  "title": "Follow-up mit {{$json.attendees[0].name}}",
  "description": "Meeting: {{$json.title}}\nDatum: {{$json.startTime}}",
  "due_date": "{{$now.plus(2, 'weeks').toISO()}}"
}
```

#### Beispiel 3: KI-Meeting-Transkription

```javascript
// Benötigt Whisper-Service

// 1. Cal.com Webhook - booking.created
// 2. Wait Until - Meeting-Zeit
// 3. Wait - Meeting-Dauer + 5 Minuten
// 4. Prüfen, ob Aufzeichnung existiert (manuelle Aufzeichnung erforderlich)
// 5. Falls Aufzeichnung existiert:
//    - Mit Whisper transkribieren
//    - Mit OpenAI zusammenfassen
//    - Zusammenfassung per E-Mail an Teilnehmer
```

### Sicherheit & Zugriffskontrolle

**Warum keine Basic Auth?**
- Meeting-Teilnehmer benötigen direkten URL-Zugriff
- Mobile Apps erwarten direkte Verbindung
- Cal.com-Integration erfordert offenen Zugriff
- Sicherheit wird auf Raum-Ebene gehandhabt, nicht auf Site-Ebene

**Sicherheitsoptionen auf Raum-Ebene:**

1. **Lobby-Modus** (Empfohlen)
   - Host muss Teilnehmer vor Eintritt genehmigen
   - Verhindert unerwünschte Gäste
   - In Meeting-Einstellungen aktivieren

2. **Meeting-Passwörter**
   - Passwort zur Raum-URL hinzufügen
   - Format: `https://meet.deinedomain.com/SecureRoom123?jwt=password`
   - Passwort separat vom Link teilen

3. **Eindeutige Raumnamen**
   - Nutze lange, zufällige Raumnamen
   - Vermeide vorhersehbare Namen wie "sales-call"
   - Beispiel: `https://meet.deinedomain.com/xK9mP2nQ4vL7`

4. **Zeitlich begrenzte Meetings**
   - Maximale Meeting-Dauer konfigurieren
   - Automatisches Ende nach Timeout
   - In Jitsi-Konfiguration festlegen

### Fehlerbehebung

**Kein Audio/Video (Häufigstes Problem):**

```bash
# 1. UDP-Port in Firewall überprüfen
sudo ufw status | grep 10000

# Sollte zeigen:
# 10000/udp                  ALLOW       Anywhere

# 2. Prüfen, ob JVB (Video Bridge) läuft
docker ps | grep jitsi-jvb

# Sollte Container mit "Up"-Status zeigen

# 3. JVB-Logs auf Fehler prüfen
docker logs jitsi-jvb --tail 100

# Suche nach:
# - "Failed to bind" → Port-Konflikt
# - "No candidates" → UDP blockiert
# - "ICE failed" → Netzwerkprobleme

# 4. UDP aus externem Netzwerk testen
# (Siehe UDP-Test vor Installation oben)

# 5. JVB-Host-Adresse korrekt gesetzt prüfen
grep JVB_DOCKER_HOST_ADDRESS .env

# Sollte deine öffentliche IP zeigen:
# JVB_DOCKER_HOST_ADDRESS=DEINE_OEFFENTLICHE_IP
```

**Teilnehmer können nicht beitreten:**

```bash
# 1. Alle Jitsi-Komponenten laufend prüfen
docker ps | grep jitsi

# Sollte 4 Container zeigen:
# - jitsi-web
# - jitsi-prosody
# - jitsi-jicofo
# - jitsi-jvb

# 2. Caddy-Routing prüfen
docker logs caddy | grep jitsi

# 3. Aus externem Browser testen (Inkognito)
# Öffnen: https://meet.deinedomain.com

# 4. Browser-Konsole auf Fehler prüfen (F12)
```

**Einseitiges Video (Du siehst sie, sie sehen dich nicht):**

```bash
# Weist normalerweise auf UDP-Probleme für ausgehenden Traffic hin

# Firewall-Regeln prüfen
sudo iptables -L -n | grep 10000

# JVB neu starten
docker compose restart jitsi-jvb

# Prüfen, ob Router/Firewall ausgehendes UDP erlaubt
# Manche Unternehmensnetzwerke blockieren UDP
```

**Jitsi-Dienste starten nicht:**

```bash
# Logs für jede Komponente prüfen
docker logs jitsi-web --tail 50
docker logs jitsi-prosody --tail 50
docker logs jitsi-jicofo --tail 50
docker logs jitsi-jvb --tail 50

# Alle Passwörter in .env generiert prüfen
grep JICOFO_COMPONENT_SECRET .env
grep JICOFO_AUTH_PASSWORD .env
grep JVB_AUTH_PASSWORD .env

# Falls welche fehlen, Secrets neu generieren:
cd ai-corekit
sudo bash ./scripts/03_generate_secrets.sh

# Alle Jitsi-Dienste neu starten
docker compose down
docker compose up -d jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb
```

**Cal.com-Integration funktioniert nicht:**

```bash
# 1. Jitsi-Server-URL in Cal.com überprüfen
# Einstellungen → Apps → Jitsi Video
# Muss sein: https://meet.deinedomain.com (kein Trailing Slash)

# 2. Manuelle Meeting-Erstellung testen
# Event in Cal.com erstellen
# Test-Meeting buchen
# Prüfen, ob Jitsi-Link generiert wird

# 3. Cal.com-Logs prüfen
docker logs calcom --tail 100 | grep -i jitsi

# 4. Jitsi-Erreichbarkeit vom Cal.com-Container prüfen
docker exec calcom curl https://meet.deinedomain.com
# Sollte HTML zurückgeben, nicht Fehler
```

**UDP vom VPS-Provider blockiert (Keine Lösung):**

Falls UDP-Test fehlschlägt und Provider es nicht aktiviert:

**Alternative Lösungen:**
1. **Externe Dienste nutzen**
   - Cal.com mit Zoom konfigurieren
   - Oder Google Meet Integration
   - Beide funktionieren gut mit Cal.com

2. **VPS-Provider wechseln**
   - Zu Hetzner, DigitalOcean oder Contabo migrieren
   - Alle unterstützen UDP für WebRTC

3. **TURN-Server einrichten** (Fortgeschritten)
   - Fällt auf TURN zurück, wenn UDP fehlschlägt
   - Benötigt zusätzlichen VPS mit UDP
   - Komplexere Konfiguration

4. **Jitsi als Service nutzen**
   - Kostenlos: https://meet.jit.si
   - Kostenpflichtig: https://8x8.vc
   - Stattdessen in Cal.com konfigurieren

### Performance-Tipps

**Bandbreiten-Anforderungen:**
- **Video:** 2-4 Mbps pro Teilnehmer (HD)
- **Nur Audio:** 50-100 Kbps pro Teilnehmer
- **Bildschirmfreigabe:** +1-2 Mbps

**Server-Ressourcen:**
- **CPU:** ~1 Core pro 10 Teilnehmer
- **RAM:** 1-2GB für Jitsi-Dienste
- **Getestet:** Bis zu 35 Teilnehmer auf 4-Core VPS

**Best Practices:**
- Nutze **Lobby-Modus** für Meetings >10 Personen
- Deaktiviere Video für große Meetings (nur Audio)
- Nutze **720p** statt 1080p (bessere Performance)
- Begrenze Bildschirmfreigabe auf eine Person gleichzeitig
- Erwäge externen Service für >30 Teilnehmer

### Erweiterte Konfiguration

**Aufzeichnung aktivieren:**

Benötigt zusätzliches Setup:
1. Jibri installieren (Jitsi-Aufzeichnungsdienst)
2. Speicherort konfigurieren
3. In Meeting-Einstellungen aktivieren

**Benutzerdefiniertes Branding:**

Jitsi-Config bearbeiten, um anzupassen:
- Logo und Farben
- Willkommensseiten-Text
- Raumnamen-Format
- Standardeinstellungen

**Integration mit anderen Tools:**

- **Matrix/Element** - Jitsi mit Matrix-Räumen verbinden
- **Slack/Discord** - Jitsi-Calls aus Chat starten
- **WordPress** - Jitsi auf Website einbetten

### Ressourcen

- **Offizielle Dokumentation:** https://jitsi.github.io/handbook/
- **Community-Forum:** https://community.jitsi.org/
- **GitHub:** https://github.com/jitsi/jitsi-meet
- **Docker-Setup:** https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker
- **Mobile Apps:**
  - iOS: https://apps.apple.com/app/jitsi-meet/id1165103905
  - Android: https://play.google.com/store/apps/details?id=org.jitsi.meet

### Best Practices

**Für Gastgeber:**
- Teste Meeting-Raum vor wichtigen Calls
- Nutze Lobby-Modus für Kundenmeetings
- Teile Meeting-Link 24h vor Call
- Halte Raumnamen professionell
- Habe Backup-Plan (Telefonnummer, Zoom-Link)

**Für Teilnehmer:**
- Trete 2-3 Minuten früher bei, um Audio/Video zu testen
- Nutze Kopfhörer, um Echo zu vermeiden
- Stumm schalten, wenn nicht sprechend
- Nutze "Hand heben"-Funktion für Fragen
- Stabile Internetverbindung (Kabel > WLAN)

**Für Organisationen:**
- Erstelle Namenskonvention für Meeting-Räume
- Richte automatisierte Erinnerungen ein (n8n)
- Überwache Server-Ressourcen während großer Meetings
- Halte IT-Support-Kontakt bereit
- Dokumentiere Setup für Team-Mitglieder
