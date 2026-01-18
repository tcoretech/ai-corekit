# 🐍 Python Runner - Native Python-Ausführung für n8n

### Was ist Python Runner?

Python Runner (offiziell **n8n Task Runners**) ist ein Sidecar-Container (`n8nio/runners`), der **native Python-Ausführung** in n8n-Workflows ermöglicht. Im Gegensatz zu n8ns Legacy-Pyodide-basiertem Python (WebAssembly) verwendet Python Runner **echtes Python 3.x** mit vollem Zugriff auf die Standardbibliothek und Drittanbieter-Pakete.

Dies ermöglicht die direkte Verwendung leistungsstarker Python-Bibliotheken wie `pandas`, `numpy`, `requests`, `scikit-learn` und vieler anderer in deinen n8n-Code-Nodes - perfekt für Datenverarbeitung, maschinelles Lernen, API-Interaktionen und komplexe Transformationen, die mit JavaScript schwierig oder unmöglich wären.

**Derzeit in Beta:** Diese Funktion wird aktiv entwickelt und wird in zukünftigen n8n-Versionen zur Standard-Python-Ausführungsmethode.

### Features

- **Native Python 3.x:** Echter CPython-Interpreter (kein WebAssembly) mit vollständiger Standardbibliothek
- **Umfangreiche Paket-Unterstützung:** Installiere `pandas`, `numpy`, `requests`, `scikit-learn`, `beautifulsoup4` und hunderte weitere
- **Bessere Performance:** Schnellere Ausführung im Vergleich zu Pyodide bei rechenintensiven Aufgaben
- **Isolierte Ausführung:** Jede Aufgabe läuft in einer isolierten Umgebung für Sicherheit
- **Automatischer Lebenszyklus:** Python-Prozesse starten bei Bedarf und beenden sich nach Idle-Timeout
- **WebSocket-Kommunikation:** Schnelle Echtzeit-Kommunikation zwischen n8n und Python Runner
- **Eigene Abhängigkeiten:** Füge deine eigenen Python-Pakete über eigenes Docker-Image hinzu
- **Parallele Ausführung:** Führe mehrere Python-Aufgaben gleichzeitig aus (konfigurierbare Parallelität)

### So funktioniert es

1. **n8n Haupt-Container:** Verwaltet Workflow-Orchestrierung und UI
2. **n8nio/runners Sidecar:** Führt Python- (und JavaScript-) Task-Runner aus
3. **Code-Node-Ausführung:** Wenn eine Code-Node mit Python ausgelöst wird:
   - n8n sendet den Python-Code per WebSocket an den Runner
   - Runner startet einen Python-Prozess und führt den Code aus
   - Gibt Ergebnisse zurück an n8n
   - Python-Prozess beendet sich nach Idle-Timeout

**Architektur:**
```
n8n Container ← WebSocket → n8nio/runners Container
(Workflow-Engine)             (Python + JS Runner)
```

### Erste Einrichtung

Python Runner ist **bereits im AI CoreKit konfiguriert**, wenn du mit der neuesten Version installiert hast. Überprüfe, ob es aktiviert ist:

#### Schritt 1: Überprüfen, ob Python Runner aktiviert ist

```bash
# n8n-Umgebungsvariablen prüfen
docker exec n8n env | grep N8N_RUNNERS

# Sollte anzeigen:
# N8N_RUNNERS_ENABLED=true
# N8N_RUNNERS_MODE=external
# N8N_RUNNERS_AUTH_TOKEN=<secret>
```

#### Schritt 2: Runner-Container überprüfen

```bash
# Prüfen, ob n8nio/runners Container läuft
docker ps | grep runners

# Sollte Container namens 'python-runner' oder ähnlich zeigen
```

#### Schritt 3: Python in n8n Code Node testen

1. **n8n öffnen:** Navigiere zu `https://n8n.deinedomain.com`
2. **Test-Workflow erstellen:**
   - Füge **Manual Trigger** Node hinzu
   - Füge **Code** Node hinzu
   - Wähle **Python** als Sprache (nicht JavaScript)
   
3. **Test-Code:**
```python
# Teste natives Python mit Standardbibliothek
import sys
import json
from datetime import datetime

result = {
    "python_version": sys.version,
    "current_time": datetime.now().isoformat(),
    "message": "Natives Python funktioniert!"
}

return [result]
```

4. **Workflow ausführen:**
   - Klicke "Execute Workflow"
   - Sollte Python-Version und aktuelle Zeit in der Ausgabe zeigen
   - Wenn es funktioniert: Python Runner ist korrekt konfiguriert! ✅

#### Schritt 4: Zusätzliche Python-Pakete installieren (Optional)

Um Pakete außerhalb der Python-Standardbibliothek zu verwenden, musst du ein eigenes `n8nio/runners` Image erstellen:

**Eigenes Dockerfile erstellen:**
```dockerfile
# custom-runners.Dockerfile
FROM n8nio/runners:latest

# Wechsle zu root um Pakete zu installieren
USER root

# Installiere zusätzliche Python-Pakete
RUN pip install --no-cache-dir \
    pandas==2.1.4 \
    numpy==1.26.3 \
    requests==2.31.0 \
    beautifulsoup4==4.12.3 \
    scikit-learn==1.4.0 \
    pillow==10.2.0

# Wechsle zurück zu non-root User
USER node

# Aktualisiere Allowlist für Code Node (WICHTIG!)
# Diese Datei steuert, welche Pakete importiert werden können
COPY n8n-task-runners.json /usr/local/lib/node_modules/@n8n/task-runner/
```

**Allowlist-Datei erstellen (`n8n-task-runners.json`):**
```json
{
  "N8N_RUNNERS_PYTHON_ALLOW_BUILTIN": "*",
  "N8N_RUNNERS_PYTHON_ALLOW_EXTERNAL": [
    "pandas",
    "numpy",
    "requests",
    "bs4",
    "sklearn",
    "PIL"
  ]
}
```

**Bauen und Deployen:**
```bash
# Eigenes Image bauen
docker build -f custom-runners.Dockerfile -t custom-runners:latest .

# docker-compose.yml aktualisieren um eigenes Image zu verwenden
# Ändere: image: n8nio/runners:latest
# Zu: image: custom-runners:latest

# Container neu starten
docker compose down
docker compose up -d
```

### Python in n8n Code Nodes verwenden

#### Zugriff auf Eingabedaten

Python Code Nodes erhalten Daten von vorherigen Nodes über die `_items` Variable:

```python
# Alle Eingabe-Items abrufen
items = _items

# Jedes Item verarbeiten
for item in items:
    # Auf JSON-Daten zugreifen
    name = item["json"]["name"]
    age = item["json"]["age"]
    
    # Felder ändern oder hinzufügen
    item["json"]["greeting"] = f"Hallo, {name}! Du bist {age} Jahre alt."

# Geänderte Items zurückgeben
return items
```

#### Häufige Muster

**Muster 1: Datentransformation mit Pandas**
```python
import pandas as pd

# Eingabe-Items in DataFrame konvertieren
df = pd.DataFrame([item["json"] for item in _items])

# Transformationen durchführen
df["total"] = df["price"] * df["quantity"]
df["category"] = df["product"].str.upper()

# Zeilen filtern
df = df[df["total"] > 100]

# Zurück zu n8n Items konvertieren
result = []
for _, row in df.iterrows():
    result.append({"json": row.to_dict()})

return result
```

**Muster 2: API-Anfragen**
```python
import requests

results = []
for item in _items:
    url = item["json"]["api_url"]
    
    # HTTP-Anfrage durchführen
    response = requests.get(url, timeout=10)
    
    # Antwort zu Ergebnissen hinzufügen
    results.append({
        "json": {
            "url": url,
            "status_code": response.status_code,
            "data": response.json()
        }
    })

return results
```

**Muster 3: Machine Learning Vorhersage**
```python
from sklearn.ensemble import RandomForestClassifier
import numpy as np

# Angenommen, Modell wurde woanders trainiert
# Hier demonstrieren wir nur das Muster

# Features aus Eingabe extrahieren
features = []
for item in _items:
    features.append([
        item["json"]["feature1"],
        item["json"]["feature2"],
        item["json"]["feature3"]
    ])

X = np.array(features)

# Vorhersagen treffen (Beispiel - du würdest ein trainiertes Modell laden)
# predictions = model.predict(X)

# Für Demo nur verarbeitete Daten zurückgeben
results = []
for i, item in enumerate(_items):
    results.append({
        "json": {
            **item["json"],
            "processed": True,
            "index": i
        }
    })

return results
```

**Muster 4: Web Scraping**
```python
from bs4 import BeautifulSoup
import requests

url = _items[0]["json"]["url"]

# Webseite abrufen
response = requests.get(url)
soup = BeautifulSoup(response.content, 'html.parser')

# Daten extrahieren
titles = soup.find_all('h2')
links = soup.find_all('a')

results = [{
    "json": {
        "url": url,
        "title_count": len(titles),
        "link_count": len(links),
        "titles": [t.text.strip() for t in titles[:5]]
    }
}]

return results
```

### n8n Integrations-Beispiele

#### Beispiel 1: CSV-Datenanalyse

CSV-Daten analysieren, die über n8n hochgeladen wurden:

```
1. HTTP Request Node: CSV-Datei herunterladen
2. Code Node (Python):
```

```python
import pandas as pd
import io

# CSV-Inhalt vom vorherigen Node abrufen
csv_content = _items[0]["binary"]["data"]

# CSV lesen
df = pd.read_csv(io.StringIO(csv_content.decode('utf-8')))

# Analyse durchführen
summary = {
    "total_rows": len(df),
    "columns": list(df.columns),
    "numeric_summary": df.describe().to_dict(),
    "missing_values": df.isnull().sum().to_dict()
}

return [{"json": summary}]
```

#### Beispiel 2: Batch-Bildverarbeitung

Bilder mit Pillow verarbeiten:

```
1. Loop Over Items Node
2. HTTP Request: Bild herunterladen
3. Code Node (Python):
```

```python
from PIL import Image
import io
import base64

# Bild vom vorherigen Node abrufen
image_data = _items[0]["binary"]["data"]

# Bild öffnen und Größe ändern
img = Image.open(io.BytesIO(image_data))
img_resized = img.resize((800, 600))

# In base64 konvertieren
buffer = io.BytesIO()
img_resized.save(buffer, format="PNG")
img_base64 = base64.b64encode(buffer.getvalue()).decode()

return [{
    "json": {
        "original_size": img.size,
        "new_size": img_resized.size
    },
    "binary": {
        "data": img_base64
    }
}]
```

#### Beispiel 3: Natürliche Sprachverarbeitung

Textstimmung analysieren (erfordert TextBlob):

```
1. Webhook Trigger: Text-Eingabe empfangen
2. Code Node (Python):
```

```python
# Hinweis: Erfordert eigenes Runner-Image mit installiertem textblob

from textblob import TextBlob

results = []
for item in _items:
    text = item["json"]["text"]
    
    # Stimmung analysieren
    blob = TextBlob(text)
    sentiment = blob.sentiment
    
    results.append({
        "json": {
            "text": text,
            "polarity": sentiment.polarity,  # -1 bis 1
            "subjectivity": sentiment.subjectivity,  # 0 bis 1
            "sentiment": "positiv" if sentiment.polarity > 0 else "negativ"
        }
    })

return results
```

#### Beispiel 4: Datenbankoperationen mit SQLAlchemy

Direkter Datenbankzugriff (erfordert eigenen Runner mit sqlalchemy):

```
1. Schedule Trigger: Täglich um 9 Uhr
2. Code Node (Python):
```

```python
from sqlalchemy import create_engine, text
import pandas as pd

# Datenbankverbindung
engine = create_engine("postgresql://user:pass@postgres:5432/mydb")

# Daten abfragen
query = """
SELECT customer_id, SUM(amount) as total
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY customer_id
ORDER BY total DESC
LIMIT 10
"""

df = pd.read_sql(query, engine)

# In n8n Items konvertieren
results = []
for _, row in df.iterrows():
    results.append({"json": row.to_dict()})

return results
```

### Fehlerbehebung

**Problem 1: Python Runner startet nicht**

```bash
# Runner-Container-Logs prüfen
docker logs python-runner --tail 100

# Häufiger Fehler: "connection refused"
# Lösung: Überprüfen, dass N8N_RUNNERS_AUTH_TOKEN in beiden Containern übereinstimmt

# n8n-Umgebung prüfen
docker exec n8n env | grep N8N_RUNNERS_AUTH_TOKEN

# Runner-Umgebung prüfen
docker exec python-runner env | grep N8N_RUNNERS_AUTH_TOKEN

# Sollten identisch sein
```

**Lösung:**
- Stelle sicher, dass `N8N_RUNNERS_AUTH_TOKEN` gesetzt ist und in beiden Containern (n8n und runners) übereinstimmt
- Beide Container neu starten: `docker compose restart n8n python-runner`
- Netzwerkverbindung prüfen: `docker exec n8n ping python-runner`

**Problem 2: "Module not found" Fehler**

```python
# Fehler: ModuleNotFoundFehler: No module named 'pandas'
```

**Lösung:**
- Python Runner enthält standardmäßig nur die Standardbibliothek
- Um Drittanbieter-Pakete zu verwenden, eigenes Runner-Image bauen (siehe Einrichtung Schritt 4)
- Paket zur Allowlist in `n8n-task-runners.json` hinzufügen
- Paket-Installation überprüfen: `docker exec python-runner pip list | grep pandas`

**Problem 3: Code-Ausführungs-Timeout**

```bash
# Timeout-Einstellungen prüfen
docker exec n8n env | grep N8N_RUNNERS_TASK_TIMEOUT

# Standard ist 60 Sekunden
```

**Lösung:**
- Timeout für lang laufende Aufgaben erhöhen:
```yaml
# docker-compose.yml
environment:
  - N8N_RUNNERS_TASK_TIMEOUT=300  # 5 Minuten
```
- Python-Code für Performance optimieren
- Batch-Verarbeitung statt Schleifen verwenden, wo möglich
- Aufgabe in kleinere Teile aufbrechen

**Problem 4: Hohe Speicherauslastung**

```bash
# Runner-Speichernutzung überwachen
docker stats python-runner --no-stream

# Maximale Speicherzuweisung prüfen
docker exec python-runner env | grep N8N_RUNNERS_MAX_OLD_SPACE_SIZE
```

**Lösung:**
- Speicherlimit in docker-compose.yml erhöhen:
```yaml
python-runner:
  image: n8nio/runners:latest
  deploy:
    resources:
      limits:
        memory: 2G  # Von Standard 1G erhöhen
```
- Python-Code optimieren (Generatoren verwenden, in Batches verarbeiten)
- Auf Memory Leaks in eigenen Paketen prüfen

**Problem 5: "Permission Denied" Fehler**

```bash
# Runner-Benutzer prüfen
docker exec python-runner whoami

# Sollte sein: node (nicht root)
```

**Lösung:**
- Runner läuft als non-root Benutzer für Sicherheit
- Versuche nicht, System-Pakete zur Laufzeit zu installieren
- Build custom image with packages pre-installed as root
- Avoid file operations requiring root permissions

### Ressourcen

- **n8n Task Runners Documentation:** https://docs.n8n.io/hosting/configuration/task-runners/
- **Task Runner Environment Variables:** https://docs.n8n.io/hosting/configuration/environment-variables/task-runners/
- **Code Node Documentation:** https://docs.n8n.io/code/code-node/
- **n8nio/runners Docker Image:** https://hub.docker.com/r/n8nio/runners
- **GitHub - n8n Repository:** https://github.com/n8n-io/n8n
- **Adding Extra Dependencies:** https://github.com/n8n-io/n8n/tree/master/docker/images/runners
- **Python Built-in Modules:** https://docs.python.org/3/library/
- **n8n Community Forum:** https://community.n8n.io/
- **Task Runner Launcher:** https://github.com/n8n-io/task-runner-launcher

### Best Practices

**Performance:**
- Use native Python instead of Pyodide for compute-intensive tasks
- Process data in batches to reduce number of Python task invocations
- Set appropriate `N8N_RUNNERS_MAX_CONCURRENCY` (default: 5) based on server resources
- Monitor memory usage and adjust limits accordingly
- Use generator expressions instead of list comprehensions for large datasets

**Sicherheit:**
- Never disable `N8N_RUNNERS_PYTHON_DENY_INSECURE_BUILTINS` in production
- Only allowlist packages you actually need in `n8n-task-runners.json`
- Keep Python packages updated in custom runner image
- Use secrets/environment variables for sensitive data (not hardcoded in code)
- Validate and sanitize all input data before processing

**Package Management:**
- Pin exact package versions in custom Dockerfile (e.g., `pandas==2.1.4`)
- Test custom runner image thoroughly before deploying to production
- Document all installed packages and their purposes
- Regularly update packages for security patches
- Keep custom runner image in version control

**Debugging:**
- Enable debug logging: `N8N_RUNNERS_LAUNCHER_LOG_LEVEL=debug`
- Use `print()` statements in Python code (output appears in Code node)
- Monitor runner logs: `docker logs python-runner --follow`
- Test Python code locally before adding to n8n
- Start with simple examples and gradually add complexity

**Code Organization:**
```python
# Good: Organized and reusable
def process_item(item):
    """Process a single item."""
    # Processing logic here
    return modified_item

results = [process_item(item) for item in _items]
return results

# Bad: Everything in one block
# (Hard to read and debug)
```

**Error Handling:**
```python
# Always include error handling
results = []
for item in _items:
    try:
        # Processing logic
        result = process(item)
        results.append({"json": result})
    except Exception as e:
        # Log error and continue
        results.append({
            "json": {
                "error": str(e),
                "item": item["json"]
            }
        })

return results
```

**Resource Monitoring:**
```bash
# Check runner health
docker exec python-runner curl -f http://localhost:5680/healthz || echo "Runner unhealthy"

# Monitor concurrent tasks
docker logs python-runner | grep "concurrent tasks"

# Memory and CPU usage
docker stats python-runner --no-stream
```

**Typical Resource Usage:**
- **Idle:** ~50-100MB RAM, <1% CPU
- **Active (light tasks):** ~200-500MB RAM, 5-20% CPU
- **Active (heavy tasks):** ~500MB-2GB RAM, 50-100% CPU
