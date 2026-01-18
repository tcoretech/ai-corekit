# ⚡ bolt.diy - KI-App-Builder

### Was ist bolt.diy?

bolt.diy ist eine KI-gestützte Full-Stack-Entwicklungsplattform, die es dir ermöglicht, vollständige Webanwendungen mithilfe natürlicher Sprachprompts zu erstellen. Basierend auf StackBlitz's bolt-Technologie kombiniert es KI-Unterstützung mit einer Live-Entwicklungsumgebung und ermöglicht schnelles Prototyping und MVP-Erstellung ohne tiefgehende Programmierkenntnisse.

### Funktionen

- **KI-gestützte Entwicklung**: Beschreibe deine App in natürlicher Sprache, beobachte wie sie in Echtzeit gebaut wird
- **Full-Stack-Unterstützung**: Frontend (React, Vue, Svelte) und Backend (Node.js, Python) in einer Umgebung
- **Live-Vorschau**: Sieh Änderungen sofort mit Hot Module Replacement
- **Code-Export**: Lade vollständige Projekte mit allen Abhängigkeiten herunter
- **Multi-Modell-Unterstützung**: Funktioniert mit OpenAI, Anthropic, Groq und anderen LLM-Anbietern
- **WebContainer-Technologie**: Führt Node.js direkt im Browser aus für sofortiges Feedback

### Ersteinrichtung

**Erster Zugriff auf bolt.diy:**
1. Navigiere zu `https://bolt.deinedomain.com`
2. Kein Login erforderlich - bolt.diy startet sofort
3. Konfiguriere API-Keys für dein bevorzugtes KI-Modell:
   - Klicke auf das Einstellungen-Symbol (⚙️) oben rechts
   - Füge deinen API-Key hinzu (OpenAI, Anthropic, Groq, etc.)
   - Wähle dein bevorzugtes Modell (Claude Sonnet 3.5, GPT-4, etc.)

**Empfohlene Modelle:**
- **Claude 3.5 Sonnet**: Am besten für komplexe Full-Stack-Anwendungen
- **GPT-4**: Exzellent für React und Frontend-Entwicklung
- **Groq (Llama)**: Schnell, gut für schnelle Prototypen
- **Ollama**: Lokale Modelle, benötigt aktivierten Ollama-Service

### n8n-Integration einrichten

Obwohl bolt.diy keinen direkten n8n-Node hat, kannst du generierte Apps mit n8n-Workflows integrieren:

**Workflow-Muster: KI-App-Generierungs-Pipeline**

```javascript
// 1. Manual Trigger oder Webhook
// Benutzer übermittelt App-Anforderungen

// 2. Code Node: bolt.diy-Prompt vorbereiten
const appSpec = {
  description: $json.userRequest,
  features: $json.requiredFeatures,
  tech_stack: "React + Node.js + PostgreSQL"
};

const boltPrompt = `Erstelle eine ${appSpec.tech_stack}-Anwendung:
${appSpec.description}

Erforderliche Funktionen:
${appSpec.features.join('\n')}

Inkludiere Authentifizierung, Datenbankmodelle und REST-API.`;

return { prompt: boltPrompt };

// 3. Manueller Schritt: Entwickler nutzt bolt.diy
// → Öffne bolt.deinedomain.com
// → Füge den generierten Prompt ein
// → Überprüfe und iteriere mit KI
// → Exportiere den generierten Code

// 4. GitHub Node: Repository erstellen
// Exportierten Code zu GitHub hochladen

// 5. Webhook: Deployment-Pipeline auslösen
// → Vercel/Netlify für Frontend
// → Railway/Fly.io für Backend
```

**Interne URL:** `http://bolt:5173` (für interne Service-zu-Service-Kommunikation)

### Beispiel-Anwendungsfälle

#### Beispiel 1: Schnelle MVP-Entwicklung

**Szenario**: SaaS-Landingpage mit Authentifizierung in 10 Minuten erstellen

```
Prompt: "Erstelle eine moderne SaaS-Landingpage für einen KI-Schreibassistenten namens 'WriteWise'. 
Inkludiere:
- Hero-Sektion mit Gradient-Hintergrund
- Features-Sektion (3 Hauptfunktionen)
- Preistabelle (Free, Pro, Enterprise)
- E-Mail-Anmeldeformular mit Supabase-Integration
- Responsives Design mit Tailwind CSS"

Ergebnis: Vollständige React-App mit:
- Modernen UI-Komponenten
- Funktionierender Formular-Validierung
- Supabase-Auth-Integration
- Mobile-responsivem Layout
- Bereit zum Deployment
```

#### Beispiel 2: Interne Tool-Erstellung

**Szenario**: Benutzerdefiniertes Admin-Dashboard für dein Team erstellen

```
Prompt: "Erstelle ein Admin-Dashboard zur Verwaltung von AI CoreKit Services:
- Service-Status-Übersicht (läuft/gestoppt)
- Ressourcennutzungs-Charts (CPU, RAM, Disk)
- Schnellaktionen (Services neu starten, Logs ansehen)
- Authentifizierung mit Benutzername/Passwort
- Dark-Mode-Unterstützung
- Nutze Express.js-Backend, React-Frontend"

Ergebnis: Full-Stack-Admin-Tool, das du:
- Intern deployen kannst
- Mit Docker-API verbinden kannst
- Mit zusätzlichen Prompts anpassen kannst
- Exportieren und selbst hosten kannst
```

#### Beispiel 3: API-Wrapper-Entwicklung

**Szenario**: Benutzerdefinierten API-Client für deine KI-Services erstellen

```
Prompt: "Baue einen Node.js-API-Wrapper für Ollama mit:
- TypeScript-Unterstützung
- Streaming-Antworten
- Konversationshistorien-Verwaltung
- Rate Limiting
- Fehlerbehandlung mit Retries
- Express-Server mit REST-Endpunkten"

Ergebnis: Produktionsreifer API-Wrapper, den du:
- In n8n-Workflows nutzen kannst
- Als Microservice deployen kannst
- Mit benutzerdefinierter Logik erweitern kannst
```

### Entwicklungs-Workflow

**Iterative Entwicklung mit bolt.diy:**

1. **Initialer Prompt**: Beginne mit einer klaren, detaillierten Beschreibung
2. **Generierten Code überprüfen**: Prüfe Struktur und Abhängigkeiten
3. **Mit Follow-ups verfeinern**: 
   - "Füge Benutzer-Authentifizierung hinzu"
   - "Mache es mobile-responsiv"
   - "Füge Fehlerbehandlung zu den API-Aufrufen hinzu"
4. **In Live-Vorschau testen**: Interagiere mit der App in Echtzeit
5. **Code exportieren**: Lade vollständiges Projekt mit package.json herunter
6. **Deployen**: Zu GitHub pushen, auf Hosting-Plattform deployen

**Best Practices:**
- **Sei spezifisch**: Detaillierte Prompts produzieren bessere Ergebnisse
- **Schrittweise iterieren**: Füge Funktionen einzeln hinzu
- **Häufig testen**: Nutze die Live-Vorschau, um Probleme früh zu erkennen
- **Oft exportieren**: Speichere Fortschritt vor größeren Änderungen
- **Gute Modelle verwenden**: Claude 3.5 Sonnet oder GPT-4 für komplexe Apps

### Fehlerbehebung

**"Blocked Request" oder App lädt nicht:**

bolt.diy verwendet Vite, das Probleme mit Reverse Proxies haben kann. Dieser Fork enthält automatische Hostname-Konfiguration.

```bash
# 1. Prüfen, ob BOLT_HOSTNAME korrekt in .env gesetzt ist
grep BOLT_HOSTNAME .env
# Sollte zeigen: BOLT_HOSTNAME=bolt.deinedomain.com

# 2. Prüfen, ob bolt.diy läuft
docker ps | grep bolt

# 3. bolt.diy-Logs auf Fehler prüfen
docker logs bolt -f

# 4. Service neu starten
docker compose restart bolt

# 5. Browser-Cache leeren und erneut versuchen
# Chrome: Strg+Umschalt+Entf → Zwischengespeicherte Bilder und Dateien löschen
```

**KI-Modell antwortet nicht:**

```bash
# 1. API-Key in bolt.diy-Einstellungen verifizieren
# Auf Einstellungen-Symbol klicken → API-Key-Format prüfen

# 2. API-Key separat testen
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"Hallo"}]}'

# 3. Rate Limits im Dashboard deines KI-Anbieters prüfen
# OpenAI: platform.openai.com/usage
# Anthropic: console.anthropic.com
```

**Generierter Code funktioniert nicht:**

```bash
# 1. Browser-Konsole auf Fehler prüfen (F12)
# Nach Dependency- oder Syntax-Fehlern suchen

# 2. package.json überprüfen
# Sicherstellen, dass alle Abhängigkeiten kompatibel sind

# 3. Zuerst einen einfacheren Prompt versuchen
# Komplexität schrittweise aufbauen

# 4. Besseres KI-Modell verwenden
# Von Groq zu Claude 3.5 Sonnet wechseln

# 5. Exportieren und lokal testen
npm install
npm run dev
```

**Langsame Generierungsgeschwindigkeit:**

```bash
# 1. Groq für schnellere Antworten verwenden (Trade-off: Qualität)
# Einstellungen → Groq auswählen → llama-3.1-70b wählen

# 2. Große Anfragen in kleinere Prompts aufteilen
# Statt: "Baue gesamte App"
# Nutze: "Baue Homepage" → "Füge API hinzu" → "Füge Auth hinzu"

# 3. Netzwerkverbindung prüfen
# bolt.diy streamt Antworten in Echtzeit

# 4. Ressourcennutzung überwachen
docker stats bolt
# Hohe CPU? Der Browser könnte mit großen Projekten kämpfen
```

**Kann Code nicht exportieren oder herunterladen:**

```bash
# 1. Browser-Download-Einstellungen prüfen
# Sicherstellen, dass Downloads nicht blockiert sind

# 2. Anderen Browser versuchen
# Firefox, Chrome, Safari funktionieren alle unterschiedlich

# 3. Code manuell kopieren, falls Export fehlschlägt
# Auf jede Datei klicken → Inhalt kopieren → In lokalen Bearbeiteor einfügen

# 4. bolt.diy-Logs prüfen
docker logs bolt | grep -i error
```

### Integration mit AI CoreKit Services

**bolt.diy + Supabase:**
- Vollständige CRUD-Apps mit Supabase-Backend generieren
- Automatische Datenbank-Schema-Erstellung
- Echtzeit-Subscriptions-Unterstützung
- Integrierte Auth-Integration

**bolt.diy + n8n:**
- Generierte APIs als n8n HTTP Request Ziele exportieren
- Benutzerdefinierte UI für n8n-Workflows bauen
- Admin-Dashboards für Workflow-Management erstellen

**bolt.diy + Ollama:**
- Lokale Modelle für Code-Generierung nutzen (falls Ollama aktiviert)
- Keine API-Kosten für Entwicklung
- Volle Privatsphäre für sensible Projekte

**bolt.diy + ComfyUI:**
- Bildverarbeitungs-Oberflächen generieren
- Benutzerdefinierte ComfyUI-Workflow-Bearbeiteoren bauen
- Galerien für generierte Bilder erstellen

### Ressourcen

- **Offizielles Repository**: [github.com/stackblitz-labs/bolt.diy](https://github.com/stackblitz-labs/bolt.diy)
- **Dokumentation**: [docs.bolt.new](https://docs.bolt.new) (bolt.new ist die gehostete Version)
- **Community-Beispiele**: Schau bei r/bolt_diy für Inspiration vorbei
- **Video-Tutorials**: Suche "bolt.diy tutorial" auf YouTube
- **Best Practices**: [github.com/stackblitz-labs/bolt.diy/discussions](https://github.com/stackblitz-labs/bolt.diy/discussions)

### Sicherheitshinweise

- **Keine Authentifizierung**: bolt.diy hat keine eingebaute Auth - geschützt durch Caddy Basic Auth falls konfiguriert
- **API-Keys**: Committe niemals API-Keys in generierte Code-Repositories
- **Öffentliches Deployment**: Generierte Apps können deine Prompts enthalten - überprüfe vor dem Teilen
- **Code-Review**: Überprüfe KI-generierten Code immer vor Produktiv-Nutzung
- **Umgebungsvariablen**: Nutze .env-Dateien für sensible Konfiguration
- **Nur HTTPS**: Greife nur über HTTPS auf bolt.diy zu, um API-Keys während der Übertragung zu schützen


---

# 🎨 OpenUI - UI-Komponenten-Generator</b> 🧪</summary>

### Was ist OpenUI?

OpenUI ist ein **experimentelles** KI-gestütztes Tool, das UI-Komponenten direkt aus Textbeschreibungen generiert. Es verwendet große Sprachmodelle, um React-, Vue-, Svelte- oder reine HTML-Komponenten basierend auf deinen Prompts zu erstellen. Obwohl es schnell Komponenten-Code erzeugen kann, variiert die Ausgabequalität erheblich je nach verwendetem LLM-Modell.

**⚠️ Wichtig:** OpenUI ist experimentell und eignet sich am besten für Prototyping und Inspiration als für produktionsfertigen Code. Für komplexe UI-Anforderungen oder vollständige Anwendungen solltest du stattdessen **bolt.diy** in Betracht ziehen.

### Funktionen

- **Multi-Framework-Unterstützung** - Generiere React-, Vue-, Svelte- oder HTML-Komponenten
- **Live-Vorschau** - Sieh Komponenten in Echtzeit rendern, während sie generiert werden
- **KI-gestützt** - Verwendet Claude, GPT-4, Groq oder Ollama-Modelle
- **Kopieren/Exportieren** - Erhalte sauberen Code, bereit zum Einfügen in dein Projekt
- **Styling-Optionen** - Wähle zwischen Tailwind CSS, reinem CSS oder styled-components
- **Komponenten-Varianten** - Generiere mehrere Design-Optionen zum Vergleich
- **Schnelle Iteration** - Verfeinere Komponenten schnell mit Folge-Prompts

### Ersteinrichtung

**Erster Zugriff auf OpenUI:**

1. Navigiere zu `https://openui.deinedomain.com`
2. Kein Login erforderlich - OpenUI startet sofort
3. Konfiguriere deinen KI-Anbieter:
   - Klicke auf **Einstellungen** (Zahnrad-Symbol)
   - Wähle Anbieter: OpenAI, Anthropic, Groq oder Ollama
   - Gib API-Schlüssel ein (falls externer Anbieter verwendet wird)
   - Wähle Modell

**Empfohlene Modell-Konfiguration:**

| Anbieter | Modell | Qualität | Geschwindigkeit | Kosten | Am besten für |
|----------|-------|---------|-----------------|--------|---------------|
| **Anthropic** | Claude 3.5 Sonnet | ⭐⭐⭐⭐⭐ | Mittel | $$ | Produktionsreife Komponenten |
| **OpenAI** | GPT-4o | ⭐⭐⭐⭐⭐ | Mittel | $$ | Komplexe Layouts, Barrierefreiheit |
| **OpenAI** | GPT-4o-mini | ⭐⭐⭐⭐ | Schnell | $ | Schnelle Prototypen |
| **Groq** | llama-3.1-70b | ⭐⭐⭐ | Sehr schnell | $ | Schnelle Iteration |
| **Ollama** | Lokale Modelle | ⭐⭐ | Variiert | Kostenlos | Privatsphäre, Experimente |

**⚠️ Kritisch:** Für beste Ergebnisse verwende **Claude 3.5 Sonnet** oder **GPT-4o**. Modelle niedrigerer Qualität können unbrauchbare Komponenten erzeugen.

### Grundlegende Verwendung

**Generiere eine einfache Komponente:**

1. Öffne `https://openui.deinedomain.com`
2. Wähle Framework: **React**, **Vue**, **Svelte** oder **HTML**
3. Gib Beschreibung in die Prompt-Box ein:
   ```
   Moderne Preiskarte mit Gradientenhintergrund, 
   drei Stufen (Basic, Pro, Enterprise), 
   mit Funktionslisten und Call-to-Action-Buttons
   ```
4. Klicke auf **Generieren**
5. Warte 10-30 Sekunden für die Generierung
6. Sieh dir die Live-Vorschau auf der rechten Seite an
7. Klicke auf **Code kopieren**, um ihn in deinem Projekt zu verwenden

**Verfeinern mit Folge-Prompts:**

```
"Mach den Gradienten lila statt blau"
"Füge Hover-Animationen zu den Karten hinzu"
"Mach es mobile-responsive"
"Füge Icons für jede Funktion hinzu"
```

### Komponenten-Beispiele

#### Beispiel 1: Dashboard-Karte

```
Prompt: "Erstelle eine Dashboard-Statistik-Karte mit:
- Großer Zahl (Metrik-Wert)
- Prozentuale Änderung mit Aufwärts-/Abwärtspfeil
- Kleinem Diagramm/Sparkline
- Tooltip beim Hover
- Verwende Tailwind CSS mit shadcn/ui Design-Stil"

Framework: React
Modell: Claude 3.5 Sonnet

Ergebnis: Produktionsreife Komponente mit:
✓ Ordentlichen TypeScript-Typen
✓ Responsivem Design
✓ Barrierefreiem Markup
✓ Sauberem, kommentiertem Code
```

#### Beispiel 2: Formular-Komponente

```
Prompt: "Modernes Kontaktformular mit:
- Name-, E-Mail-, Nachricht-Feldern
- Echtzeit-Validierung
- Submit-Button mit Lade-Status
- Erfolgs-/Fehler-Toast-Benachrichtigungen
- Dark-Mode-Unterstützung"

Framework: React
Modell: GPT-4o

Ergebnis: Funktionale Formular-Komponente mit:
✓ Formular-Validierung
✓ Zustandsverwaltung
✓ Fehlerbehandlung
✓ Barrierefreiheitsfunktionen
```

#### Beispiel 3: Navigationsmenü

```
Prompt: "Responsive Navigationsleiste:
- Logo links
- Menüpunkte in der Mitte
- Suchleiste und Profil-Avatar rechts
- Mobil: Hamburger-Menü mit ausziehbarer Schublade
- Sticky beim Scrollen
- Glassmorphismus-Effekt"

Framework: Vue 3
Modell: Claude 3.5 Sonnet

Ergebnis: Vollständige Nav-Komponente mit:
✓ Mobile Responsivität
✓ Flüssigen Animationen
✓ Vue 3 Composition API
✓ Modernem Styling
```

### Integrationsmuster

**OpenUI + bolt.diy Workflow:**

1. **Komponenten in OpenUI generieren** - Schnelle UI-Mockups
2. **In bolt.diy kopieren** - In vollständige App integrieren
3. **Mit KI verfeinern** - bolt.diy für Funktionalität verwenden
4. **Bereitstellen** - Vollständige Anwendung mit funktionierendem Backend

**OpenUI + n8n Workflow:**

```javascript
// OpenUI-generierte Komponenten als E-Mail-Templates verwenden

// 1. E-Mail-Template-Komponente in OpenUI generieren
Prompt: "Responsive E-Mail-Vorlage mit Header, Content-Bereich, 
         und Footer. Verwende Inline-CSS für E-Mail-Kompatibilität."

// 2. HTML-Ausgabe kopieren

// 3. In n8n E-Mail-senden-Node verwenden
HTML: [OpenUI-generiertes HTML einfügen]

// 4. Mit n8n-Variablen personalisieren
Betreff: Bestellbestätigung - {{ $json.orderId }}
Body: Platzhalter ersetzen mit {{ $json.customerName }}
```

### Best Practices

**Prompt-Engineering für OpenUI:**

✅ **Tu:**
- Sei spezifisch über Layout und Struktur
- Erwähne Framework-spezifische Muster (Hooks, Composables)
- Gib den Styling-Ansatz an (Tailwind, CSS-Module)
- Fordere explizit responsives Design an
- Bitte um Barrierefreiheitsfunktionen
- Erwähne Dark Mode falls benötigt

❌ **Nicht:**
- Vage Beschreibungen verwenden ("mach es schön")
- Komplexe Geschäftslogik erwarten
- Annehmen, dass Zustandsverwaltung enthalten ist
- Backend-Integration anfordern
- Perfekten Code beim ersten Versuch erwarten

**Beispiele für gute Prompts:**

```
✓ "Erstelle eine React-Komponente mit Tailwind CSS: 
   Karte mit Bild links (40%), Textinhalt rechts (60%), 
   CTA-Button unten, Hover-Effekt zum Anheben der Karte mit Schatten, 
   Mobil: Bild oben gestapelt"

✓ "Vue 3 Composable für Formular-Validierung mit:
   - E-Mail-Validierung Regex
   - Passwort-Stärke-Prüfer  
   - Echtzeit-Fehlermeldungen
   - Gibt reaktiven Status und Validierungsfunktionen zurück"

✓ "Svelte-Komponente: Tab-Oberfläche mit 3 Tabs,
   flüssige Slide-Animationen zwischen Inhalten,
   Indikatorlinie für aktiven Tab,
   Tastaturnavigation (Pfeiltasten),
   ARIA-Labels für Barrierefreiheit"
```

**Beispiele für schlechte Prompts:**

```
✗ "Schönes Login-Formular"
✗ "Dashboard"
✗ "Mach es modern"
✗ "Komponente wie Facebook"
```

### Einschränkungen & bekannte Probleme

**Qualität variiert je nach Modell:**

- **Claude 3.5 Sonnet / GPT-4o**: Durchgehend gut, produktionstauglich
- **GPT-4o-mini**: Gut für einfache Komponenten, kann bei komplexen Layouts Schwierigkeiten haben
- **Groq-Modelle**: Schnell, aber oft Code niedrigerer Qualität
- **Ollama-Modelle**: Sehr inkonsistent, erfordert oft mehrere Versuche

**Häufige Probleme:**

1. **Unvollständige Komponenten** - Fehlende Imports, defektes JSX
2. **Nicht-funktionale Logik** - Zustandsverwaltung funktioniert nicht
3. **Schlechte Responsivität** - Nur Desktop-Designs
4. **Barrierefreiheitslücken** - Fehlende ARIA-Labels, Tastaturnavigation
5. **Styling-Konflikte** - CSS-Spezifitätsprobleme

**Wann OpenUI verwenden:**

✅ Gut für:
- Schnelle Komponenten-Mockups
- Design-Inspiration
- Lernen von Komponenten-Mustern
- Einfache, statische UI-Elemente
- E-Mail-Templates (HTML)

❌ Nicht gut für:
- Produktionsreife Komponenten ohne Überprüfung
- Komplexe Geschäftslogik
- Vollständige Seitenlayouts
- Komponenten mit Backend-Integration
- Geschäftskritische UI

### Fehlerbehebung

**Schlechte Ausgabequalität:**

```bash
# 1. Zu einem besseren Modell wechseln
Einstellungen → Anbieter: Anthropic
Modell: claude-3-5-sonnet-20241022

# 2. Prompt spezifischer machen
Statt: "Login-Formular"
Verwende: "React-Login-Formular mit E-Mail-Feld, Passwortfeld mit 
      Anzeigen/Verbergen-Umschaltung, Angemeldet-bleiben-Checkbox, Submit-Button 
      mit Lade-Status, Fehlermeldungs-Anzeige, 
      mit Tailwind CSS"

# 3. Mehrere Generierungen versuchen
Klicke 2-3 Mal auf "Generieren", wähle das beste Ergebnis

# 4. bolt.diy für komplexe Komponenten verwenden
OpenUI eignet sich am besten für einfache, isolierte Komponenten
```

**Komponente wird nicht gerendert:**

```bash
# 1. Browser-Konsole (F12) auf Fehler prüfen

# 2. Häufige Probleme:
- Fehlende Imports: Erforderliche Dependencies hinzufügen
- JSX-Syntaxfehler: Klammer-Fehlanpassungen beheben
- CSS-Probleme: Prüfen, ob Klassennamen korrekt sind

# 3. Code außerhalb von OpenUI testen
In CodeSandbox oder lokales Projekt kopieren
Dependencies manuell installieren
Mit ordentlichen Dev-Tools debuggen
```

**API-Fehler:**

```bash
# 1. API-Schlüssel verifizieren
Einstellungen → API-Schlüssel → Neu eingeben und speichern

# 2. API-Limits prüfen
OpenAI: platform.openai.com/usage
Anthropic: console.anthropic.com

# 3. OpenUI-Logs prüfen
docker logs openui --tail 50

# 4. Service bei Bedarf neu starten
docker compose restart openui
```

**Langsame Generierung:**

```bash
# 1. Zu schnellerem Modell wechseln
Groq: llama-3.1-70b (schnell, niedrigere Qualität)
OpenAI: gpt-4o-mini (ausgewogen)

# 2. Prompt vereinfachen
Komplexe Komponenten in kleinere Teile aufteilen
Inkrementell generieren

# 3. OpenUI-Ressourcen prüfen
docker stats openui
# Niedriger CPU/RAM? Server upgraden

# 4. Netzwerk zum KI-Anbieter prüfen
# Langsame API-Antworten können anbieterseitig sein
```

### Alternative: bolt.diy

**Wenn OpenUI nicht ausreicht:**

Wenn OpenUI schlechte Qualität generiert oder du brauchst:
- Vollständige Anwendungsentwicklung
- Backend-Integration
- Komplexe Zustandsverwaltung
- Mehrere verbundene Komponenten
- Produktionsfertigen Code

**→ Verwende stattdessen bolt.diy:**
- Zuverlässigere Code-Generierung
- Full-Stack-Fähigkeiten
- Besserer Iterations-Workflow
- Live-Entwicklungsumgebung
- Kann ganze Anwendungen generieren

Siehe [bolt.diy-Abschnitt](#ai-powered-development) für vollständige Dokumentation.

### Ressourcen

- **Offizielles Repository**: [github.com/wandb/openui](https://github.com/wandb/openui)
- **Dokumentation**: Begrenzt - Tool ist experimentell
- **Komponenten-Bibliotheken**: 
  - [shadcn/ui](https://ui.shadcn.com) - Muster für bessere Prompts kopieren
  - [Tailwind UI](https://tailwindui.com) - Inspiration für Designs
- **Alternative Tools**:
  - **bolt.diy** - Full-Stack-KI-Entwicklung
  - **v0.dev** - Vercels UI-Generator (extern)
  - **Lovable** - KI-App-Builder (extern)

### Sicherheit & Best Practices

**Code-Überprüfung erforderlich:**
- **Überprüfe generierten Code immer** vor Produktivnutzung
- Prüfe auf Sicherheitslücken
- Validiere Eingabebehandlung
- Teste Barrierefreiheit
- Verifiziere responsives Verhalten

**API-Schlüssel-Sicherheit:**
- Verwende Umgebungsvariablen für API-Schlüssel
- Committen keine Schlüssel in Git
- Rotiere Schlüssel regelmäßig
- Überwache API-Nutzung auf Anomalien

**Datenschutz-Überlegungen:**
- Deine Prompts werden an KI-Anbieter gesendet (OpenAI, Anthropic, etc.)
- Füge keine sensible Geschäftslogik in Prompts ein
- Verwende Ollama für private/sensible Projekte
- Generierter Code kann von KI-Anbietern protokolliert werden

**Lizenzierung:**
- Lizenzierung von KI-generiertem Code ist unklar
- Überprüfe die Bedingungen deines KI-Anbieters
- Berücksichtige rechtliche Auswirkungen für kommerzielle Nutzung
- Teste gründlich, als wäre es Drittanbieter-Code

</details>

### KI-Agenten

<details>
<summary><b>🤖 Flowise - Visueller KI-Builder

### Was ist Flowise?

Flowise ist ein Open-Source visueller KI-Agenten-Builder, mit dem du anspruchsvolle KI-Anwendungen über eine Drag-and-Drop-Oberfläche erstellen kannst. Aufgebaut auf LangChain ermöglicht es Entwicklern und Nicht-Entwicklern gleichermaßen, Chatbots, Konversations-Agenten, RAG-Systeme und Multi-Agenten-Workflows ohne umfangreichen Code zu erstellen. Stell es dir vor wie "Figma für KI-Backend-Anwendungen".

### Funktionen

- **Visueller Workflow-Builder** - Drag-and-Drop-Oberfläche zum Erstellen von KI-Agenten und LLM-Flows
- **Multi-Agenten-Systeme** - Erstelle Teams spezialisierter KI-Agenten mit Supervisor-Koordination
- **RAG-Unterstützung** - Verbinde mit Dokumenten, Datenbanken und Wissensbasen für kontextbewusste Antworten
- **Tool-Calling** - Agenten können externe Tools, APIs und Funktionen dynamisch nutzen
- **Speicherverwaltung** - Konversations-Gedächtnis und Kontext-Beibehaltung über Sitzungen hinweg
- **Mehrere LLM-Unterstützung** - Funktioniert mit OpenAI, Anthropic, Ollama, Groq und 50+ weiteren Anbietern
- **Vorgefertigte Vorlagen** - Starte mit fertigen Vorlagen für häufige Anwendungsfälle
- **Assistenten-Modus** - Einsteigerfreundliche Methode zur Erstellung von KI-Agenten mit Datei-Upload-RAG
- **AgentFlow V2** - Erweiterte sequenzielle Workflows mit Schleifen, Bedingungen und Human-in-the-Loop
- **Streaming-Unterstützung** - Echtzeit-Antwort-Streaming für bessere UX
- **Überall einbetten** - Generiere einbettbare Chat-Widgets für Websites

### Ersteinrichtung

**Erster Login bei Flowise:**

1. Navigiere zu `https://flowise.deinedomain.com`
2. **Erster Benutzer wird Admin** - Erstelle dein Konto
3. Setze ein starkes Passwort
4. Einrichtung abgeschlossen!

**Schnellstart:**

1. Klicke auf **Neu hinzufügen** → Wähle **Assistent** (am einfachsten) oder **Chatflow** (flexibel)
2. Wähle eine Vorlage oder starte von Grund auf
3. Füge Nodes hinzu, indem du sie aus der linken Seitenleiste ziehst
4. Verbinde Nodes, um deinen Flow zu erstellen
5. Konfiguriere jeden Node (LLM, Prompts, Tools, etc.)
6. Klicke auf **Speichern**, dann **Bereitstellen**
7. Teste in der Chat-Oberfläche

### Drei Wege zum Erstellen in Flowise

**1. Assistent (Einsteigerfreundlich)**
- Einfache Oberfläche zum Erstellen von KI-Assistenten
- Lade Dateien für automatisches RAG hoch
- Befolge Anweisungen und verwende Tools
- Am besten für: Einfache Chatbots, Dokumenten-Q&A

**2. Chatflow (Flexibel)**
- Volle Kontrolle über LLM-Ketten
- Erweiterte Techniken: Graph RAG, Reranker, Retriever
- Am besten für: Benutzerdefinierte Workflows, komplexe Logik

**3. AgentFlow (Am leistungsstärksten)**
- Multi-Agenten-Systeme mit Supervisor-Orchestrierung
- Sequenzielle Workflows mit Verzweigung
- Schleifen und Bedingungen
- Human-in-the-Loop-Fähigkeiten
- Am besten für: Komplexe Automatisierung, Enterprise-Workflows

### Deinen ersten Agenten erstellen

**Einfacher Chatbot mit RAG:**

1. **Neuen Assistenten erstellen:**
   - Klicke auf **Neu hinzufügen** → **Assistent**
   - Benenne ihn: "Dokumenten-Q&A-Bot"

2. **Einstellungen konfigurieren:**
   - **Modell**: Wähle `gpt-4o` (oder `llama3.2` über Ollama)
   - **Anweisungen**: 
     ```
     Du bist ein hilfreicher Assistent, der Fragen basierend auf hochgeladenen Dokumenten beantwortet.
     Wenn du die Antwort nicht weißt, sag es - erfinde keine Informationen.
     ```

3. **Dokumente hochladen:**
   - Klicke auf **Dateien hochladen**
   - Füge PDF-, DOCX-, TXT-Dateien hinzu
   - Flowise erstellt automatisch Vektor-Embeddings

4. **Testen:**
   - Klicke auf **Chat**-Symbol
   - Frage: "Was sind die Hauptpunkte im hochgeladenen Dokument?"
   - Agent ruft relevante Chunks ab und antwortet

5. **Bereitstellen:**
   - Klicke auf **Bereitstellen**
   - Erhalte API-Endpunkt und Einbettungscode

### Multi-Agenten-Systeme

**Supervisor + Workers-Muster:**

Flowise unterstützt hierarchische Multi-Agenten-Systeme, bei denen ein Supervisor-Agent mehrere Worker-Agenten koordiniert:

```
Benutzeranfrage
    ↓
Supervisor-Agent (koordiniert Aufgaben)
    ↓
    ├─→ Worker 1: Recherche-Agent (durchsucht Web)
    ├─→ Worker 2: Analyse-Agent (analysiert Daten)
    └─→ Worker 3: Schreib-Agent (erstellt Berichte)
    ↓
Supervisor aggregiert Ergebnisse
    ↓
Endgültige Antwort
```

**Ein Multi-Agenten-System erstellen:**

1. **Workers zuerst erstellen:**
   - Recherche-Agent: Google-Such-Tool hinzufügen
   - Analyse-Agent: Code-Interpreter-Tool hinzufügen
   - Schreib-Agent: Spezialisierter Prompt zum Schreiben

2. **Supervisor erstellen:**
   - **Supervisor-Agent**-Node hinzufügen
   - Alle Worker-Nodes verbinden
   - Delegationslogik konfigurieren

3. **Beispiel - Lead-Recherche-System:**
   - **Worker 1 (Lead-Researcher)**: Verwendet Google-Suche, um Firmeninfos zu finden
   - **Worker 2 (E-Mail-Schreiber)**: Erstellt personalisierte Outreach-E-Mails
   - **Supervisor**: Koordiniert Recherche → E-Mail-Generierungs-Workflow

### n8n-Integration

**Flowise-Agenten von n8n aufrufen:**

Flowise stellt eine REST-API bereit, die n8n über HTTP-Request-Nodes aufrufen kann.

**Flowise-API-Details abrufen:**

1. Öffne in Flowise deinen bereitgestellten Chatflow/Agentflow
2. Klicke auf **API**-Tab
3. Kopiere:
   - **Endpunkt-URL**: `https://flowise.deinedomain.com/api/v1/prediction/{FLOW_ID}`
   - **API-Schlüssel**: Generiere in Einstellungen → API-Schlüssel

**n8n HTTP Request-Konfiguration:**

```javascript
// HTTP Request Node
Methode: POST
URL: https://flowise.deinedomain.com/api/v1/prediction/{{FLOW_ID}}
Authentifizierung: Header Auth
  Header-Name: Authorization
  Header-Wert: Bearer {{YOUR_FLOWISE_API_KEY}}

Body (JSON):
{
  "question": "{{$json.user_query}}",
  "overrideConfig": {
    // Optional: Chatflow-Parameter überschreiben
  }
}

// Antwort-Struktur:
{
  "text": "KI-Agenten-Antwort...",
  "chatId": "uuid-hier",
  "messageId": "uuid-hier"
}
```

### Beispiel-Workflows

#### Beispiel 1: Kundensupport-Automatisierung

**n8n → Flowise-Integration:**

```javascript
// 1. Webhook-Trigger - Support-Ticket empfangen
// Eingabe: { "email": "kunde@beispiel.com", "issue": "Kann mich nicht anmelden" }

// 2. HTTP Request - Flowise Support-Agent abfragen
Methode: POST
URL: https://flowise.deinedomain.com/api/v1/prediction/support-agent-id
Header:
  Authorization: Bearer {{$env.FLOWISE_API_KEY}}
Body: {
  "question": "Kundenproblem: {{$json.issue}}. Gib Lösungsschritte an.",
  "overrideConfig": {
    "sessionId": "{{$json.email}}" // Konversationskontext beibehalten
  }
}

// 3. Code-Node - Flowise-Antwort parsen
const solution = $json.text;
return {
  customer: $('Webhook').item.json.email,
  issue: $('Webhook').item.json.issue,
  ai_solution: solution,
  resolved: solution.includes("gelöst") || solution.includes("behoben")
};

// 4. IF-Node - Prüfen, ob automatisch gelöst
If: {{$json.resolved}} === true

// 5a. E-Mail senden - Automatisch gelöst
An: {{$json.customer}}
Betreff: Problem gelöst
Body: {{$json.ai_solution}}

// 5b. Ticket erstellen - Benötigt menschliche Überprüfung
// → Baserow/Airtable-Node
```

#### Beispiel 2: Multi-Agenten-Recherche-Pipeline

**Komplett in Flowise erstellt, ausgelöst von n8n:**

```javascript
// In Flowise: Multi-Agenten-Recherche-System erstellen

// Agent 1: Web-Researcher
Tools: Google-Suche, Web-Scraper
Aufgabe: Informationen über {{topic}} finden

// Agent 2: Datenanalyst  
Tools: Code-Interpreter
Aufgabe: Erkenntnisse analysieren und extrahieren

// Agent 3: Berichtsschreiber
Tools: Dokument-Generator
Aufgabe: Executive Summary erstellen

// Supervisor
Koordiniert: Recherche → Analyse → Schreiben
Gibt zurück: Vollständigen Recherchebericht

// In n8n:
// 1. Zeitplan-Trigger - Täglich um 9 Uhr

// 2. Code-Node - Recherche-Themen definieren
return [
  { topic: "KI-Automatisierungstrends 2025" },
  { topic: "LLM-Kostenoptimierungsstrategien" },
  { topic: "Enterprise-RAG-Implementierungen" }
];

// 3. HTTP Request - Flowise Multi-Agent aufrufen
// (Schleife über Themen)
URL: https://flowise.deinedomain.com/api/v1/prediction/research-team-id
Body: {
  "question": "Recherchiere {{$json.topic}} und liefere umfassenden Bericht"
}

// 4. Google Drive - Berichte speichern
Dateiname: Recherche_{{$json.topic}}_{{$now}}.pdf
Inhalt: {{$json.text}}

// 5. Slack - Team benachrichtigen
Nachricht: "Tägliche Rechercheberichte abgeschlossen: {{$json.length}} Themen"
```

#### Beispiel 3: RAG-Dokumenten-Q&A-System

**Flowise-Setup:**

1. **Chatflow mit RAG erstellen:**
   - **Document Loaders** hinzufügen: PDF, DOCX, Web-Scraper
   - **Text Splitter** hinzufügen: Recursive Character Splitter (Chunk-Größe: 1000)
   - **Embeddings** hinzufügen: OpenAI-Embeddings
   - **Vector Store** hinzufügen: Qdrant (intern: `http://qdrant:6333`)
   - **Retriever** hinzufügen: Vector Store Retriever (top k: 5)
   - **LLM Chain** hinzufügen: GPT-4o mit RAG-Prompt
   - Verbinden: Dokumente → Splitter → Embeddings → Vector Store → Retriever → LLM

2. **Dokumente hochladen:**
   - Unternehmensrichtlinien, Produktdokumente, FAQs
   - Flowise verarbeitet und speichert in Qdrant

3. **Bereitstellen & API-Schlüssel erhalten**

**n8n-Integration:**

```javascript
// 1. Slack-Trigger - Bei Nachricht im #fragen-Kanal

// 2. HTTP Request - Flowise RAG abfragen
URL: https://flowise.deinedomain.com/api/v1/prediction/rag-chatbot-id
Body: {
  "question": "{{$json.text}}"
}

// 3. Slack-Antwort
Antwort im Thread: {{$json.text}}
Nachricht: {{$json.response}}
Zitate: {{$json.sourceDocuments}}
```

### Erweiterte Funktionen

**AgentFlow V2 (Sequenzielle Workflows):**

- **Tool-Node**: Führe spezifische Tools deterministisch aus
- **Bedingungs-Node**: Verzweigungslogik basierend auf Ausgaben
- **Schleifen-Node**: Iteriere über Ergebnisse
- **Variablen-Node**: Speichere und rufe Status ab
- **SubFlow-Node**: Rufe andere Flowise-Flows als Module auf

**Beispiel - Rechnungsverarbeitungs-Flow:**

```
Start
  ↓
Tool-Node: Text aus PDF-Rechnung extrahieren
  ↓
LLM-Node: Rechnungsdaten parsen (Betrag, Datum, Lieferant)
  ↓
Bedingungs-Node: Betrag > 1000€?
  ├─ Ja → SubFlow: Genehmigungsworkflow
  └─ Nein → Tool-Node: Auto-Genehmigung
  ↓
Tool-Node: Buchhaltungssystem aktualisieren
  ↓
Ende
```

### Best Practices

**Prompt-Engineering:**
- Sei spezifisch in System-Anweisungen
- Füge Beispiele gewünschter Ausgaben hinzu
- Definiere Verhalten für Grenzfälle
- Verwende Variablen für dynamische Inhalte

**RAG-Optimierung:**
- Chunk-Größe: 500-1500 Zeichen (abhängig vom Anwendungsfall)
- Überlappung: 10-20% für besseren Kontext
- Top-K-Abruf: 3-7 Chunks
- Verwende Metadaten-Filterung wenn möglich
- Aktualisiere Vector Store regelmäßig mit neuen Dokumenten

**Multi-Agenten-Design:**
- Halte Worker-Agenten spezialisiert (Single Responsibility)
- Supervisor sollte klare Delegationsregeln haben
- Teste Agenten einzeln vor dem Kombinieren
- Überwache Token-Nutzung pro Agent

**Performance:**
- Verwende Streaming für bessere UX
- Cache Embeddings wenn möglich
- Setze angemessene Timeout-Limits
- Implementiere Rate-Limiting für öffentliche Endpunkte

### Fehlerbehebung

**Agent antwortet nicht:**

```bash
# 1. Prüfe, ob Flowise läuft
docker ps | grep flowise

# 2. Logs prüfen
docker logs flowise -f

# 3. API-Schlüssel verifizieren
# In Flowise: Einstellungen → API-Schlüssel → Prüfe ob Schlüssel gültig ist

# 4. Mit curl testen
curl -X POST https://flowise.deinedomain.com/api/v1/prediction/YOUR_FLOW_ID \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question": "Hallo"}'
```

**RAG findet Dokumente nicht:**

```bash
# 1. Prüfe, ob Dokumente verarbeitet wurden
# In Flowise: Flow öffnen → Vector-Store-Node prüfen → Gespeicherte Dokumente ansehen

# 2. Qdrant-Status verifizieren
docker ps | grep qdrant
curl http://localhost:6333/health

# 3. Embeddings-Modell prüfen
# Stelle sicher, dass OpenAI-API-Schlüssel gesetzt ist oder Ollama für lokale Embeddings läuft

# 4. Abruf direkt testen
# In Flowise: Testmodus → Frage stellen → "Source Documents" in Antwort prüfen

# 5. Abruf-Einstellungen anpassen
# Top-K-Wert erhöhen (versuche 5-10)
# Ähnlichkeitsschwelle senken
# Verschiedene Chunk-Größen ausprobieren
```

**Multi-Agenten-Fehler:**

```bash
# 1. Worker-Agenten einzeln prüfen
# Teste jeden Worker separat vor Supervisor

# 2. Tool-Verfügbarkeit verifizieren
# Prüfe, ob Tools (Google-Suche, APIs) mit gültigen Credentials konfiguriert sind

# 3. LLM-Unterstützung für Function Calling prüfen
# Nicht alle Modelle unterstützen Tool Calling - verwende GPT-4o, Claude 3.5 oder Mistral

# 4. Supervisor-Prompt überprüfen
# Stelle sicher, dass Supervisor klare Anweisungen hat, wann welcher Worker zu verwenden ist

# 5. Logs auf spezifische Fehler überwachen
docker logs flowise | grep -i error
```

**n8n-Integrationsprobleme:**

```bash
# 1. Flowise-API-Endpunkt verifizieren
# Genaue URL im Flowise-API-Tab prüfen

# 2. Authentifizierung testen
# API-Schlüssel in Flowise neu generieren bei 401/403-Fehlern

# 3. Request-Format prüfen
# Body muss JSON mit "question"-Feld sein

# 4. CORS bei Bedarf aktivieren
# Setze CORS_ORIGINS-Umgebungsvariable in Flowise

# 5. n8n HTTP Request Timeout prüfen
# Timeout für lang laufende Agenten erhöhen (60-120 Sekunden)
```

**Langsame Performance:**

```bash
# 1. Modellgeschwindigkeit prüfen
# GPT-4o: Langsam aber akkurat
# GPT-4o-mini: Schneller, gute Qualität
# Groq: Sehr schnell (versuche llama-3.1-70b)

# 2. RAG-Abruf optimieren
# Top-K-Wert reduzieren
# Kleinere Embedding-Modelle verwenden

# 3. Streaming aktivieren
# In Flowise-Chatflow-Einstellungen: Streaming-Antworten aktivieren

# 4. Flowise-Ressourcen überwachen
docker stats flowise
# Hohe CPU/Memory? Server upgraden oder gleichzeitige Anfragen reduzieren

# 5. Caching verwenden
# Konversations-Gedächtnis-Caching aktivieren
# Embeddings für häufig abgerufene Dokumente cachen
```

### Integration mit AI CoreKit-Services

**Flowise + Qdrant:**
- Verwende Qdrant als Vector Store für RAG
- Interne URL: `http://qdrant:6333`
- Erstelle Collections in Qdrant UI, referenziere sie in Flowise

**Flowise + Ollama:**
- Verwende lokale LLMs statt OpenAI
- Ollama Chat Models-Node hinzufügen
- Basis-URL: `http://ollama:11434`
- Modelle: llama3.2, mistral, qwen2.5-coder

**Flowise + n8n:**
- n8n löst Flowise-Agenten über API aus
- Flowise kann n8n-Webhooks als Tools aufrufen
- Bidirektionale Integration für komplexe Workflows

**Flowise + Open WebUI:**
- Beide können dasselbe Ollama-Backend verwenden
- Flowise für agentische Workflows
- Open WebUI für einfache Chat-Oberfläche

### Ressourcen

- **Offizielle Website**: [flowiseai.com](https://flowiseai.com)
- **Dokumentation**: [docs.flowiseai.com](https://docs.flowiseai.com)
- **GitHub**: [github.com/FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise)
- **Marketplace**: Vorgefertigte Vorlagen und Flows in Flowise UI
- **Community**: [Discord](https://discord.gg/jbaHfsRVBW)
- **YouTube-Tutorials**: Suche "Flowise tutorial" für Video-Anleitungen
- **Vorlagen-Bibliothek**: Integrierte Vorlagen in Flowise für häufige Anwendungsfälle

### Sicherheitshinweise

- **Authentifizierung erforderlich**: Richte API-Schlüssel für Produktion ein
- **Rate-Limiting**: Implementiere Rate-Limits für öffentliche Endpunkte
- **API-Schlüssel-Verwaltung**: Speichere Schlüssel in Umgebungsvariablen, niemals hardcoden
- **CORS-Konfiguration**: Konfiguriere CORS_ORIGINS für Web-Einbettungen
- **Datenschutz**: In RAG hochgeladene Dokumente werden in Vector-DB gespeichert
- **LLM-API-Schlüssel**: Halte OpenAI/Anthropic-Schlüssel sicher
- **Zugriffskontrolle**: Beschränke Flowise-Dashboard-Zugriff auf vertrauenswürdige Benutzer

### Preise & Ressourcen

**Ressourcenanforderungen:**
- **Basis-Chatbot**: 2GB RAM, minimale CPU
- **RAG-System**: 4GB RAM, moderate CPU (für Embeddings)
- **Multi-Agent**: 8GB+ RAM, höhere CPU
- **Mit Ollama**: +8GB RAM pro LLM-Modell

**API-Kosten (bei Verwendung externer LLMs):**
- OpenAI: ~0,01€ pro Konversation mit GPT-4o-mini
- Anthropic: ~0,025€ pro Konversation mit Claude 3.5 Sonnet
- Groq: Kostenloses Kontingent verfügbar, dann nutzungsbasiert
- Ollama: Kostenlos (selbst gehostet)

**Kostenoptimierung:**
- Verwende Ollama für Entwicklung/Testing
- Wechsle zu externen APIs für Produktionsqualität
- Implementiere Caching zur Reduzierung von API-Aufrufen
- Verwende günstigere Modelle (GPT-4o-mini) wenn möglich
