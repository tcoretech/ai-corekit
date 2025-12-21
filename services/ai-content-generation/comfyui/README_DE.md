# 🎨 ComfyUI - Bildgenerierung

### Was ist ComfyUI?

ComfyUI ist eine leistungsstarke node-basierte Oberfläche für Stable Diffusion und andere KI-Bildgenerierungsmodelle. Im Gegensatz zu einfachen Prompt-zu-Bild-Tools bietet ComfyUI ein visuelles Workflow-System, bei dem du Nodes verbindest, um komplexe Bildgenerierungs-Pipelines zu erstellen. Es ist hochgradig anpassbar, unterstützt mehrere Modelle und ist perfekt sowohl für Anfänger als auch für fortgeschrittene Benutzer, die volle Kontrolle über ihren KI-Bildgenerierungsprozess wünschen.

### Funktionen

- **Node-basierter Workflow** - Visuelle Programmierung für Bildgenerierungs-Pipelines
- **Mehrere Modelle unterstützt** - FLUX, SDXL, SD 1.5, ControlNet, LoRA und mehr
- **Benutzerdefinierte Workflows** - Vollständige Generierungs-Pipelines speichern und teilen
- **Erweiterte Kontrolle** - ControlNet, IP-Adapter, Inpainting, Outpainting
- **Batch-Verarbeitung** - Mehrere Varianten effizient generieren
- **API-Unterstützung** - Programmatischer Zugriff für n8n-Integration
- **Modell-Manager** - Einfache Modellinstallation und -verwaltung
- **Community-Workflows** - Tausende vorgefertigte Workflows verfügbar
- **Benutzerdefinierte Nodes** - Erweiterbar mit von der Community erstellten Node-Paketen
- **Hohe Leistung** - Für GPU-Beschleunigung optimiert

### Ersteinrichtung

**Erster Login bei ComfyUI:**

1. Navigiere zu `https://comfyui.deinedomain.com`
2. Die Oberfläche lädt sofort - kein Login erforderlich
3. Du siehst den Standard-Workflow (Text-zu-Bild)
4. **Wichtig:** Keine Modelle sind vorinstalliert - du musst sie zuerst herunterladen

**ComfyUI ist einsatzbereit, benötigt aber Modelle!**

### Essentielle Modelle herunterladen

ComfyUI benötigt KI-Modelle, um Bilder zu generieren. So geht's los:

**Option 1: Download über Web-UI (Am einfachsten)**

1. Klicke auf **Manager**-Button (unten rechts)
2. Wähle **Install Models**
3. Wähle Modellkategorie:
   - **Checkpoints:** Basismodelle (FLUX, SDXL, SD 1.5)
   - **LoRA:** Stil-Modifikatoren
   - **ControlNet:** Posen-/Kantenkontrolle
   - **VAE:** Bild-Encoder/Decoder
4. Klicke auf **Install** neben dem gewünschten Modell
5. Warte auf Abschluss des Downloads

**Option 2: Manueller Download**

```bash
# Auf ComfyUI-Modellverzeichnis zugreifen
cd /var/lib/docker/volumes/${PROJECT_NAME:-localai}_comfyui_data/_data/models

# FLUX.1-schnell herunterladen (schnell, empfohlen für Anfänger)
cd checkpoints
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors

# SDXL herunterladen (vielseitig, gute Qualität)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# VAE herunterladen (erforderlich für SDXL)
cd ../vae
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

# ComfyUI neu starten, um neue Modelle zu erkennen
docker compose restart comfyui
```

**Empfohlene Modelle für Anfänger:**

| Modell | Größe | Am besten für | Download-Priorität |
|--------|-------|---------------|-------------------|
| **FLUX.1-schnell** | 23GB | Schnelle Generierung, großartige Qualität | ⭐ Essentiell |
| **SDXL Base 1.0** | 6.5GB | Vielseitig, fotorealistisch | ⭐ Essentiell |
| **SD 1.5** | 4GB | Schnell, breite LoRA-Unterstützung | ⭐⭐ Empfohlen |
| **SDXL Turbo** | 6.5GB | Ultra-schnell, 1-Schritt-Generierung | ⭐⭐ Empfohlen |

**Modell-Speicherorte:**

```
checkpoints/     - Basismodelle (FLUX, SDXL, SD 1.5)
loras/          - Stil-Modifikatoren
controlnet/     - Posen- und Kantenkontroll-Modelle
vae/            - Bild-Encoder/Decoder
upscale_models/ - KI-Upscaler
embeddings/     - Textual Inversion Embeddings
```

### Grundlegende Bildgenerierung

**Einfaches Text-zu-Bild:**

1. Lade den Standard-Workflow (oder aktualisiere die Seite)
2. Finde den **Load Checkpoint**-Node
3. Wähle dein heruntergeladenes Modell aus dem Dropdown
4. Finde den **CLIP Text Encode (Prompt)**-Node
5. Gib deinen positiven Prompt ein: `"eine wunderschöne Landschaft mit Bergen und See, goldene Stunde, 8k, hochdetailliert"`
6. Gib negativen Prompt ein: `"verschwommen, niedrige Qualität, verzerrt"`
7. Klicke auf **Queue Prompt** (rechte Seitenleiste)
8. Warte auf Generierung (10-60 Sekunden je nach Modell)
9. Bild erscheint im **Save Image**-Node

**Workflow-Steuerung:**

- **Queue Prompt:** Generierung starten
- **Clear:** Alle in der Warteschlange befindlichen Prompts entfernen
- **Manager:** Modelle und benutzerdefinierte Nodes installieren
- **Load:** Gespeicherte Workflows importieren
- **Save:** Aktuellen Workflow exportieren

### n8n-Integration einrichten

**ComfyUI API-Konfiguration:**

ComfyUI bietet eine REST-API für programmatische Bildgenerierung von n8n aus.

**Interne URL für n8n:** `http://comfyui:8188`

**API-Endpunkte:**
- `/prompt` - Generierungs-Job in Warteschlange einreihen
- `/history` - Generierungsverlauf abrufen
- `/queue` - Warteschlangen-Status prüfen
- `/view` - Generierte Bilder abrufen

### Beispiel-Workflows

#### Beispiel 1: KI Social-Media-Content-Generator

Automatisch Bilder für Social-Media-Posts generieren:

```javascript
// Gebrandete Social-Media-Bilder aus Text-Prompts generieren

// 1. Schedule Trigger - Täglich um 9 Uhr
// Oder: Webhook für On-Demand-Generierung

// 2. Code Node - Prompts vorbereiten
const topics = [
  "moderner minimalistischer Arbeitsplatz",
  "gesunde Frühstücksschüssel",
  "Sonnenuntergang am Strand",
  "gemütliches Café"
];

const selectedTopic = topics[Math.floor(Math.random() * topics.length)];

const comfyWorkflow = {
  "3": {
    "inputs": {
      "seed": Math.floor(Math.random() * 1000000),
      "steps": 20,
      "cfg": 8,
      "sampler_name": "euler",
      "scheduler": "normal",
      "denoise": 1,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  "4": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  "6": {
    "inputs": {
      "text": `${selectedTopic}, professionelle Fotografie, hohe Qualität, 8k, trending auf artstation`,
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "verschwommen, niedrige Qualität, verzerrt, hässlich, schlechte Anatomie",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": "social_media",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
};

return {
  json: {
    prompt: comfyWorkflow,
    topic: selectedTopic
  }
};

// 3. HTTP Request Node - An ComfyUI senden
Methode: POST
URL: http://comfyui:8188/prompt
Header:
  Content-Type: application/json
Body (JSON):
{
  "prompt": {{$json.prompt}},
  "client_id": "n8n-workflow"
}

// 4. Wait Node - Auf Generierung warten
Betrag: 60
Unit: seconds

// 5. HTTP Request Node - Generiertes Bild abrufen
Methode: GET
URL: http://comfyui:8188/history/{{$('Queue Generation').json.prompt_id}}
Response Format: JSON

// 6. Code Node - Bilddaten extrahieren
const history = $input.first().json;
const promptId = Object.keys(history)[0];
const outputs = history[promptId].outputs;

// Bild-Output finden
let imageInfo;
for (const nodeId in outputs) {
  if (outputs[nodeId].images) {
    imageInfo = outputs[nodeId].images[0];
    break;
  }
}

return {
  json: {
    filename: imageInfo.filename,
    subfolder: imageInfo.subfolder,
    type: imageInfo.type
  }
};

// 7. HTTP Request Node - Bild herunterladen
Methode: GET
URL: http://comfyui:8188/view?filename={{$json.filename}}&subfolder={{$json.subfolder}}&type={{$json.type}}
Response Format: File
Output Property Name: data

// 8. Move Binary - Datei umbenennen
Mode: Move to new property
From Property: data
To Property: image
New File Name: social_{{$now.format('YYYY-MM-DD')}}.png

// 9. Google Drive Node - Zu Drive hochladen
Operation: Upload
File: {{$binary.image}}
Folder: Social Media Content
Name: {{$('Code - Extract').json.filename}}

// 10. Slack Node - Mit Team teilen
Kanal: #marketing
Nachricht: |
  🎨 Neues Social-Media-Bild generiert!
  
  Thema: {{$('Prepare Prompts').json.topic}}
  
  📁 Verfügbar in Google Drive: Social Media Content
  
Anhänge: {{$binary.image}}
```

#### Beispiel 2: Produktfotografie-Automatisierung

Konsistente Produktbilder für E-Commerce generieren:

```javascript
// Professionelle Produktfotos mit konsistentem Stil erstellen

// 1. Webhook Trigger - Produktdetails empfangen
// Payload: { "product_name": "Moderner Stuhl", "color": "blau", "style": "minimalistisch" }

// 2. Code Node - Detaillierten Prompt erstellen
const product = $json.product_name;
const color = $json.color;
const style = $json.style || "modern";

const positivePrompt = `professionelle Produktfotografie von ${product}, ${color} Farbe, ${style} Stil, weißer Hintergrund, Studio-Beleuchtung, hohe Auflösung, scharfer Fokus, kommerzielle Fotografie, E-Commerce-Foto`;

const negativePrompt = "verschwommen, Schatten, unordentlicher Hintergrund, verzerrt, niedrige Qualität, Wasserzeichen";

// Workflow-Template laden
const workflow = {
  "4": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "6": {
    "inputs": {
      "text": positivePrompt,
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": negativePrompt,
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "3": {
    "inputs": {
      "seed": Math.floor(Math.random() * 999999),
      "steps": 25,
      "cfg": 7.5,
      "sampler_name": "dpmpp_2m",
      "scheduler": "karras",
      "denoise": 1,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 4  // 4 Varianten generieren
    },
    "class_type": "EmptyLatentImage"
  },
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": `product_${product.replace(/\s+/g, '_')}`,
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
};

return {
  json: {
    workflow,
    product,
    positivePrompt
  }
};

// 3. HTTP Request - Generierung in Warteschlange einreihen
Methode: POST
URL: http://comfyui:8188/prompt
Body: { "prompt": {{$json.workflow}} }

// 4. Wait - Generierungszeit ermöglichen
Betrag: 90
Unit: seconds

// 5. HTTP Request - Ergebnisse abrufen
Methode: GET
URL: http://comfyui:8188/history/{{$('Queue Generation').json.prompt_id}}

// 6. Code Node - Alle generierten Bilder verarbeiten
const history = $input.first().json;
const promptId = Object.keys(history)[0];
const outputs = history[promptId].outputs;

const images = [];
for (const nodeId in outputs) {
  if (outputs[nodeId].images) {
    outputs[nodeId].images.forEach(img => {
      images.push({
        filename: img.filename,
        subfolder: img.subfolder,
        type: img.type
      });
    });
  }
}

return images.map(img => ({ json: img }));

// 7. Loop Over Items - Jede Variante verarbeiten

// 8. HTTP Request - Bild herunterladen
Methode: GET
URL: http://comfyui:8188/view?filename={{$json.filename}}&subfolder={{$json.subfolder}}&type={{$json.type}}
Response Format: File

// 9. Supabase Node - In Datenbank speichern
Operation: Einfügen
Table: product_images
Daten:
  product_id: {{$('Webhook').json.product_id}}
  image_url: Generated URL
  style: {{$('Webhook').json.style}}
  color: {{$('Webhook').json.color}}
  created_at: {{$now.toISO()}}

// 10. S3/Cloudflare R2 - Zu CDN hochladen (optional)
// Für Produktions-Serving

// 11. Email Node - Produktteam benachrichtigen (nach Loop-Ende)
To: product-team@company.com
Subject: Produktbilder generiert: {{$('Build Prompt').json.product}}
Body: |
  ✅ Produktfotografie abgeschlossen!
  
  Produkt: {{$('Build Prompt').json.product}}
  Varianten: 4 Bilder generiert
  Stil: {{$('Webhook').json.style}}
  
  Bilder verfügbar in Produktdatenbank.
  
  Verwendeter Prompt: {{$('Build Prompt').json.positivePrompt}}
```

#### Beispiel 3: KI-Kunst-Pipeline mit Stil-Transfer

Konsistente gebrandete Kunstwerke erstellen:

```javascript
// Kunstwerke generieren, die den Markenrichtlinien entsprechen

// 1. Schedule Trigger - Wöchentliche Content-Generierung

// 2. Read Binary Files - Stil-Referenzbild laden
File Pfad: /data/shared/brand_style_reference.png

// 3. Code Node - Workflow mit ControlNet vorbereiten
const workflow = {
  // Modelle laden
  "1": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  
  // ControlNet für Stil-Transfer laden
  "2": {
    "inputs": {
      "control_net_name": "control_v11p_sd15_canny.pth"
    },
    "class_type": "ControlNetLoader"
  },
  
  // Prompts
  "6": {
    "inputs": {
      "text": "abstrakte digitale Kunst, lebendige Farben, geometrische Formen, modernes Design, professionelle Illustration",
      "clip": ["1", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "hässlich, verschwommen, niedrige Qualität, verzerrt",
      "clip": ["1", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  
  // Generierungs-Einstellungen
  "3": {
    "inputs": {
      "seed": Math.floor(Math.random() * 999999),
      "steps": 30,
      "cfg": 8.5,
      "sampler_name": "dpmpp_2m_sde",
      "scheduler": "karras",
      "denoise": 0.85,
      "model": ["1", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  
  // Latent Image
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  
  // Dekodieren und speichern
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["1", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": "branded_art",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
};

return { json: { workflow } };

// 4. HTTP Request - Generieren
Methode: POST
URL: http://comfyui:8188/prompt
Body: { "prompt": {{$json.workflow}} }

// 5. Wait - Generierungszeit
Betrag: 120 seconds

// 6. HTTP Request - Bild abrufen
// ... (ähnlich wie in vorherigen Beispielen)

// 7. OpenAI Vision Node - Marken-Compliance prüfen
Modell: gpt-4o
System: "Du bist ein Marken-Compliance-Prüfer. Analysiere, ob das Bild den Markenrichtlinien entspricht."
User: "Entspricht dieses Bild unserem Markenstil? Sei spezifisch."
Image: {{$binary.image}}

// 8. IF Node - KI-Genehmigung prüfen
Bedingung: {{$json.message.content}} enthält "entspricht"

// Zweig: Genehmigt
// 9a. In Produktionsordner verschieben
// 10a. In sozialen Medien posten

// Zweig: Abgelehnt
// 9b. Zur manuellen Überprüfung einreihen
// 10b. Design-Team benachrichtigen
```

### Benutzerdefinierte Workflows

**Deinen Workflow speichern:**

1. Erstelle deinen Workflow in ComfyUI
2. Klicke auf **Save**-Button
3. Gib Dateinamen ein: `mein_workflow.json`
4. Workflow wird in `/output/workflows/` gespeichert

**Gespeicherten Workflow laden:**

1. Klicke auf **Load**-Button
2. Wähle deinen Workflow aus der Liste
3. Workflow lädt automatisch

**Workflows teilen:**

- JSON aus ComfyUI exportieren
- Über GitHub, Civitai oder ComfyUI-Foren teilen
- Workflows anderer mit **Load** importieren

### Fehlerbehebung

**Problem 1: "No model loaded"-Fehler**

```bash
# Installierte Modelle prüfen
docker exec comfyui ls -la /app/models/checkpoints/

# Prüfen, ob Modell im .safetensors-Format ist
# Modelle müssen im korrekten Unterverzeichnis sein

# Fehlendes Modell herunterladen
docker exec comfyui wget -P /app/models/checkpoints/ \
  https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# ComfyUI neu starten
docker compose restart comfyui
```

**Lösung:**
- Sicherstellen, dass Modelle im Verzeichnis `/models/checkpoints/` sind
- `.safetensors`-Format verwenden (nicht `.ckpt`)
- ComfyUI-Seite nach Hinzufügen von Modellen aktualisieren
- Prüfen, dass Modell-Dateiname im Workflow genau übereinstimmt

**Problem 2: Out of Memory / CUDA-Fehler**

```bash
# GPU-Speicher-Nutzung prüfen
docker exec comfyui nvidia-smi

# Batch-Größe im Workflow reduzieren
# Von batch_size: 4 zu batch_size: 1 ändern

# Kleinere Modelle verwenden
# SDXL Turbo (6GB) statt FLUX (23GB)

# Low-VRAM-Modus in ComfyUI-Einstellungen aktivieren
# Einstellungen → Execution → CPU-Fallback aktivieren
```

**Lösung:**
- Niedrigere Auflösung verwenden (512x512 oder 768x768)
- Batch-Größe auf 1 reduzieren
- Quantisierte Modelle verwenden (fp16 statt fp32)
- Andere GPU-Anwendungen schließen
- GPU upgraden oder Cloud-GPU verwenden

**Problem 3: Langsame Generierungszeiten**

```bash
# Prüfen, ob GPU verwendet wird
docker exec comfyui nvidia-smi

# CUDA-Funktionalität verifizieren
docker exec comfyui python -c "import torch; print(torch.cuda.is_available())"

# xFormers für schnellere Generierung aktivieren
# Zu docker-compose.yml hinzufügen:
#   environment:
#     - COMMANDLINE_ARGS=--use-xformers
```

**Lösung:**
- SDXL Turbo oder LCM-Modelle für schnellere Generierung verwenden
- Schrittzahl reduzieren (15-20 Schritte statt 30-50)
- Effiziente Sampler verwenden: `euler_a`, `dpm++ 2m`
- TensorRT-Optimierung aktivieren
- Niedrigeren CFG-Scale verwenden (6-8 statt 10-15)

**Problem 4: API-Verbindungsfehler von n8n**

```bash
# API-Konnektivität testen
curl http://comfyui:8188/system_stats

# ComfyUI-Logs prüfen
docker logs comfyui --tail 50

# Prüfen, ob ComfyUI läuft
docker ps | grep comfyui

# Bei Bedarf neu starten
docker compose restart comfyui
```

**Lösung:**
- Interne URL verwenden: `http://comfyui:8188` von n8n aus
- Sicherstellen, dass ComfyUI-Container läuft
- Prüfen, dass Prompt-JSON gültig ist
- HTTP-Request-Timeout auf 120 Sekunden erhöhen
- Warteschlange überwachen: `http://comfyui:8188/queue`

### Ressourcen

- **Offizielles GitHub:** https://github.com/comfyanonymous/ComfyUI
- **Dokumentation:** https://docs.comfy.org/
- **Modell-Downloads:** https://civitai.com/ (größte Modellbibliothek)
- **Community-Workflows:** https://comfyworkflows.com/
- **Benutzerdefinierte Nodes:** https://github.com/ltdrdata/ComfyUI-Manager
- **API-Dokumentation:** https://github.com/comfyanonymous/ComfyUI/wiki/API
- **Discord-Community:** https://discord.gg/comfyui
- **Video-Tutorials:** https://www.youtube.com/c/OlivioSarikas

### Best Practices

**Modellverwaltung:**
1. **Klein anfangen** - SDXL zuerst herunterladen, andere nach Bedarf hinzufügen
2. **Modelle organisieren** - Unterordner für verschiedene Modelltypen verwenden
3. **Regelmäßige Bereinigung** - Ungenutzte Modelle entfernen, um Speicherplatz zu sparen
4. **Modelle testen** - Neue Modelle immer zuerst mit einfachen Prompts testen
5. **Workflows sichern** - Wichtige Workflows regelmäßig exportieren

**Prompt Engineering:**
- **Spezifisch sein** - "rotes Sportauto" vs "vintage roter Ferrari 250 GTO"
- **Qualitäts-Tags verwenden** - "8k, hochdetailliert, professionelle Fotografie"
- **Negative Prompts** - Immer einschließen: "verschwommen, niedrige Qualität, verzerrt"
- **Stil-Modifikatoren** - "im Stil von [Künstler/Bewegung]"
- **Komposition** - Spezifizieren: "Nahaufnahme", "Weitwinkel", "Vogelperspektive"

**Performance-Optimierung:**
1. **Auflösung** - Bei 512x512 starten, später hochskalieren falls nötig
2. **Schritte** - 20-30 Schritte sind normalerweise ausreichend
3. **CFG Scale** - 7-8 für die meisten Fälle, höher für mehr Prompt-Treue
4. **Sampler** - `euler_a` oder `dpmpp_2m` für Geschwindigkeit
5. **Batch-Generierung** - Mehrere Varianten in einem Durchlauf generieren

**n8n-Integrations-Tipps:**
1. **Asynchrone Verarbeitung** - Immer Wait-Node nach Einreihung einschließen
2. **Fehlerbehandlung** - Try/Catch um ComfyUI-Aufrufe hinzufügen
3. **Rate Limiting** - Nicht mehr als 3-5 Prompts gleichzeitig einreihen
4. **Bildspeicherung** - Sofort nach Generierung in S3/Drive speichern
5. **Monitoring** - Generierungszeiten und Erfolgsraten protokollieren

**Sicherheit:**
- ComfyUI hat standardmäßig keine Authentifizierung
- Caddy Reverse Proxy für HTTPS und Basic Auth verwenden
- ComfyUI nicht direkt ins Internet exponieren
- API-Zugriff nur über n8n (internes Netzwerk)
- Regelmäßige Backups von Modellen und Workflows
