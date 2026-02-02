# 🔍 Qdrant - Vektor-Datenbank

### Was ist Qdrant?

Qdrant (ausgesprochen "Quadrant") ist eine hochperformante Open-Source-Vektor-Datenbank und Ähnlichkeits-Suchmaschine, geschrieben in Rust. Sie bietet produktionsreife Infrastruktur zum Speichern, Suchen und Verwalten hochdimensionaler Vektoren mit zusätzlichen JSON-ähnlichen Payloads. Qdrant ist optimiert für KI-Anwendungen wie RAG (Retrieval-Augmented Generation), semantische Suche, Empfehlungssysteme und Anomalieerkennung und bietet sowohl Geschwindigkeit als auch Skalierbarkeit für Milliarden-Vektor-Operationen.

### Funktionen

- **Schnelle Vektorsuche** - HNSW (Hierarchical Navigable Small World) Indexierung für effiziente Nearest-Neighbor-Suche
- **Mehrere Distanzmetriken** - Kosinus-Ähnlichkeit, Dot Product und Euklidische Distanz
- **Payload-Filterung** - Umfangreiche Filterung auf Metadaten bei der Vektorsuche (Hybrid-Suche)
- **Verteilter Modus** - Horizontale Skalierung mit Sharding und Replikation
- **REST & gRPC API** - Flexible APIs mit Client-Bibliotheken für Python, JavaScript, Rust, Go und mehr
- **Quantisierungs-Unterstützung** - Reduziere Speichernutzung mit Skalar-, Produkt- und binärer Quantisierung
- **On-Disk-Speicherung** - Speichere Vektoren auf Festplatte, um RAM für große Datensätze zu sparen

### Ersteinrichtung

**Zugriff auf Qdrant:**

Qdrant ist vorinstalliert und läuft auf deiner AI CoreKit Instanz.

1. **Web-UI:** `https://qdrant.deinedomain.com`
   - Collections anzeigen, Punkte durchsuchen, Vektoren inspizieren
   - Keine Authentifizierung erforderlich (nur interne Nutzung)
2. **REST-API:** `http://qdrant:6333` (intern) oder `https://qdrant.deinedomain.com` (extern)
3. **gRPC-API:** `qdrant:6334` (intern, schneller für hohen Durchsatz)

**Erste Schritte:**

```bash
# Prüfen ob Qdrant läuft
curl http://localhost:6333/

# Erste Collection erstellen
curl -X PUT http://localhost:6333/collections/test_collection \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    }
  }'

# Prüfen ob Collection erstellt wurde
curl http://localhost:6333/collections/test_collection
```

### n8n Integration Setup

**Von n8n aus mit Qdrant verbinden:**

- **Interne URL:** `http://qdrant:6333` (verwende diese für HTTP Request Nodes)
- **gRPC-URL:** `qdrant:6334` (für hochperformante Operationen)
- **Keine Authentifizierung** für internen Zugriff erforderlich

#### Beispiel 1: Collection erstellen & Vektoren einfügen

Neue Vektor-Collection für semantische Suche einrichten:

```javascript
// 1. HTTP Request: Collection erstellen
Methode: PUT
URL: http://qdrant:6333/collections/documents
Header:
  Content-Type: application/json
Body: {
  "vectors": {
    "size": 1536,  // OpenAI text-embedding-3-small
    "distance": "Cosine"
  },
  "optimizers_config": {
    "indexing_threshold": 10000
  }
}

// 2. HTTP Request: Embeddings generieren (OpenAI)
Methode: POST
URL: https://api.openai.com/v1/embeddings
Header:
  Authorization: Bearer {{ $env.OPENAI_API_KEY }}
  Content-Type: application/json
Body: {
  "input": "{{ $json.text }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Point für Qdrant vorbereiten
const embedding = $json.data[0].embedding;
const point = {
  id: $json.document_id,
  vector: embedding,
  payload: {
    text: $json.text,
    source: $json.source,
    timestamp: new Date().toISOString(),
    metadata: $json.metadata
  }
};
return { points: [point] };

// 4. HTTP Request: Vektor zu Qdrant hochladen
Methode: PUT
URL: http://qdrant:6333/collections/documents/points
Body: {
  "points": {{ $json.points }}
}
```

#### Beispiel 2: Semantische Such-Pipeline

Nach ähnlichen Dokumenten mit Vektor-Ähnlichkeit suchen:

```javascript
// 1. Webhook: Suchanfrage empfangen

// 2. HTTP Request: Query-Embedding generieren
Methode: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": "{{ $json.query }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Embedding extrahieren
const queryVector = $json.data[0].embedding;
return { query_vector: queryVector };

// 4. HTTP Request: Qdrant durchsuchen
Methode: POST
URL: http://qdrant:6333/collections/documents/points/query
Header:
  Content-Type: application/json
Body: {
  "query": {{ $json.query_vector }},
  "limit": 5,
  "with_payload": true,
  "with_vector": false
}

// 5. Code Node: Ergebnisse formatieren
const results = $json.result.map(point => ({
  id: point.id,
  score: point.score,
  text: point.payload.text,
  source: point.payload.source
}));
return { results };

// 6. Mit Ergebnissen auf Webhook antworten
```

#### Beispiel 3: Gefilterte Vektorsuche

Vektor-Ähnlichkeit mit Metadaten-Filterung kombinieren:

```javascript
// 1. Trigger: Benutzeranfrage mit Filtern

// 2. HTTP Request: Suche mit Filtern
Methode: POST
URL: http://qdrant:6333/collections/documents/points/query
Body: {
  "query": [0.1, 0.2, ...],  // Dein Query-Vektor
  "filter": {
    "must": [
      {
        "key": "source",
        "match": { "value": "documentation" }
      },
      {
        "key": "timestamp",
        "range": {
          "gte": "2024-01-01T00:00:00Z"
        }
      }
    ]
  },
  "limit": 10,
  "with_payload": ["text", "source", "timestamp"]
}

// Ergebnis: Nur Vektoren, die BEIDES erfüllen:
// - Semantische Ähnlichkeit zur Anfrage
// - source = "documentation"
// - timestamp >= 2024-01-01
```

#### Beispiel 4: Batch-Upsert für große Datensätze

Viele Vektoren effizient auf einmal hochladen:

```javascript
// 1. Database Trigger: Neue Datensätze hinzugefügt

// 2. Split in Batches Node: Batches von 100 erstellen

// 3. Loop over Batches

// 4. HTTP Request: Batch-Embeddings generieren
Methode: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": {{ $json.batch.map(item => item.text) }},
  "model": "text-embedding-3-small"
}

// 5. Code Node: Batch-Points vorbereiten
const points = $json.data.map((emb, idx) => ({
  id: $json.batch[idx].id,
  vector: emb.embedding,
  payload: {
    text: $json.batch[idx].text,
    category: $json.batch[idx].category,
    created_at: $json.batch[idx].created_at
  }
}));
return { points };

// 6. HTTP Request: Batch-Upsert zu Qdrant
Methode: PUT
URL: http://qdrant:6333/collections/documents/points
Body: {
  "points": {{ $json.points }}
}

// 7. Wait Node: 1 Sekunde (Rate Limits vermeiden)

// 8. Loop läuft weiter bis alle Batches verarbeitet sind
```

#### Beispiel 5: Hybrid-Suche (Vektor + Text)

Dichte Vektoren mit spärlicher Textsuche kombinieren:

```javascript
// 1. Collection mit dichten und spärlichen Vektoren erstellen
// HTTP Request: Collection erstellen
Methode: PUT
URL: http://qdrant:6333/collections/hybrid_docs
Body: {
  "vectors": {
    "dense": {
      "size": 1536,
      "distance": "Cosine"
    }
  },
  "sparse_vectors": {
    "sparse": {}
  }
}

// 2. HTTP Request: Hybrid-Suche
Methode: POST
URL: http://qdrant:6333/collections/hybrid_docs/points/query
Body: {
  "prefetch": [
    {
      "query": {
        "indices": [1, 2, 5, 10],  // Spärlicher Vektor (BM25-Keywords)
        "values": [0.5, 0.8, 0.3, 0.9]
      },
      "using": "sparse",
      "limit": 100
    }
  ],
  "query": [0.1, 0.2, ...],  // Dichter Vektor (semantisch)
  "using": "dense",
  "limit": 10
}

// Dies führt aus:
// 1. BM25-Keyword-Suche (sparse) -> 100 Kandidaten
// 2. Semantisches Reranking (dense) -> Top 10 Ergebnisse
```

### Erweiterte Konfiguration

#### Collection-Einstellungen optimieren

```bash
# Collection mit benutzerdefinierten HNSW-Parametern erstellen
curl -X PUT http://localhost:6333/collections/optimized \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    },
    "hnsw_config": {
      "m": 32,  # Höher = bessere Genauigkeit, mehr Speicher
      "ef_construct": 256,  # Höher = bessere Index-Qualität
      "full_scan_threshold": 20000
    },
    "optimizers_config": {
      "indexing_threshold": 50000,
      "memmap_threshold": 100000  # Index auf Festplatte speichern
    }
  }'
```

#### Payload-Indizes für schnelles Filtern erstellen

```bash
# Feld für schnelleres Filtern indexieren
curl -X PUT http://localhost:6333/collections/documents/index \
  -H 'Content-Type: application/json' \
  -d '{
    "field_name": "category",
    "field_schema": "keyword"
  }'

# Numerisches Feld indexieren
curl -X PUT http://localhost:6333/collections/documents/index \
  -H 'Content-Type: application/json' \
  -d '{
    "field_name": "price",
    "field_schema": "float"
  }'
```

#### Quantisierung für Speicher-Effizienz

```bash
# Skalare Quantisierung aktivieren
curl -X PATCH http://localhost:6333/collections/documents \
  -H 'Content-Type: application/json' \
  -d '{
    "quantization_config": {
      "scalar": {
        "type": "int8",
        "quantile": 0.99,
        "always_ram": true
      }
    }
  }'

# Ergebnis: 4x Speicherreduzierung bei minimalem Genauigkeitsverlust
```

### Fehlerbehebung

**Collection-Erstellung schlägt fehl:**

```bash
# 1. Prüfen ob Qdrant läuft
docker ps | grep qdrant

# 2. Logs auf Fehler prüfen
docker logs qdrant --tail 50

# 3. API-Erreichbarkeit prüfen
curl http://localhost:6333/
# Sollte zurückgeben: {"title":"qdrant - vector search engine","version":"1.x.x"}

# 4. Verfügbare Collections prüfen
curl http://localhost:6333/collections

# 5. Collection löschen und neu erstellen, wenn beschädigt
curl -X DELETE http://localhost:6333/collections/broken_collection
```

**Suche liefert keine Ergebnisse:**

```bash
# 1. Prüfen ob Collection Punkte hat
curl http://localhost:6333/collections/documents

# Sollte zeigen: "points_count": > 0

# 2. Vektor-Dimensionen überprüfen
# Collection-Größe: 384
# Query-Vektor-Größe muss auch sein: 384

# 3. Mit Scroll testen, um Rohdaten zu sehen
curl -X POST http://localhost:6333/collections/documents/points/scroll \
  -H 'Content-Type: application/json' \
  -d '{"limit": 5, "with_payload": true, "with_vector": true}'

# 4. Distanzmetrik prüfen
# Bei normalisierten Vektoren Dot Product statt Cosine verwenden

# 5. Limit erhöhen oder Schwelle anpassen
# Versuche limit: 100, um zu sehen, ob Ergebnisse existieren aber niedrig bewertet wurden
```

**Hohe Speichernutzung:**

```bash
# 1. Collection-Statistiken prüfen
curl http://localhost:6333/collections/documents

# 2. Quantisierung aktivieren
# Reduziert Speicher um 4-16x (siehe Erweiterte Konfiguration)

# 3. Vektoren auf Festplatte speichern
curl -X PATCH http://localhost:6333/collections/documents \
  -d '{
    "vectors": {
      "on_disk": true
    }
  }'

# 4. HNSW-Parameter reduzieren
# Niedrigere m- und ef_construct-Werte

# 5. Speicher überwachen
docker stats qdrant
```

**Langsame Such-Performance:**

```bash
# 1. Payload-Indizes für gefilterte Felder erstellen
# Siehe Abschnitt Erweiterte Konfiguration

# 2. Collection optimieren
curl -X POST http://localhost:6333/collections/documents/segments

# 3. ef-Parameter für HNSW erhöhen
# In Suchanfrage: "params": {"hnsw_ef": 128}

# 4. Kleineres Ergebnis-Limit verwenden
# limit: 10 statt 100

# 5. gRPC für schnelleren Durchsatz aktivieren
# Port 6334 statt 6333 verwenden
```

**Punkte werden nicht indexiert:**

```bash
# 1. Optimizer-Status prüfen
curl http://localhost:6333/collections/documents

# Suche nach: "optimizer_status": "ok" oder "optimizing"

# 2. Auf Abschluss der Indexierung warten
# Collections werden während Optimierung "gelb"
# Wird "grün" wenn fertig

# 3. Optimierung erzwingen
curl -X POST http://localhost:6333/collections/documents/optimizer

# 4. Indexierungs-Schwelle prüfen
# Collection muss > indexing_threshold Punkte haben
# Standard: 20.000 Punkte

# 5. Indexierung manuell auslösen
# Schwelle senken oder mehr Punkte einfügen
```

### Best Practices

**Vektor-Dimensionen:**
- **OpenAI text-embedding-3-small:** 1536 Dimensionen
- **OpenAI text-embedding-3-large:** 3072 Dimensionen
- **Ollama nomic-embed-text:** 768 Dimensionen
- **Sentence-Transformers (all-MiniLM-L6-v2):** 384 Dimensionen

Wähle basierend auf Genauigkeit vs. Speicher-Tradeoff.

**Collection-Design:**
- Verwende **einzelne Collection** mit Payload-basierter Filterung (Multitenancy)
- Erstelle nur mehrere Collections, wenn du harte Isolation brauchst
- Indexiere häufig gefilterte Payload-Felder
- Verwende konsistente Benennung: `{app}_{datentyp}` (z.B. `myapp_documents`)

**Payload-Struktur:**
```json
{
  "id": "doc_123",
  "vector": [...],
  "payload": {
    "text": "Originaler Inhalt",
    "metadata": {
      "source": "web",
      "author": "John Doe",
      "timestamp": "2025-01-01T00:00:00Z"
    },
    "tags": ["ai", "database"],
    "category": "documentation"
  }
}
```

**Such-Optimierung:**
- Indexiere Payload-Felder, die in Filtern verwendet werden
- Verwende `with_payload: ["field1", "field2"]` um nur benötigte Felder abzurufen
- Setze `with_vector: false`, wenn du Vektoren nicht in Ergebnissen brauchst
- Batch-Operationen wenn möglich (100-1000 Punkte auf einmal hochladen)
- Verwende gRPC-API für High-Throughput-Szenarien

**Speicherverwaltung:**
- Aktiviere Quantisierung für große Collections (>1M Vektoren)
- Speichere Vektoren auf Festplatte, wenn Speicher begrenzt ist
- Verwende `on_disk_payload: true` für große Payloads
- Überwache Speicher mit `docker stats qdrant`

**Backup & Wiederherstellung:**
```bash
# Snapshot erstellen
curl -X POST http://localhost:6333/collections/documents/snapshots

# Snapshot herunterladen
curl http://localhost:6333/collections/documents/snapshots/snapshot_name \
  --output snapshot.snapshot

# Von Snapshot wiederherstellen
curl -X PUT http://localhost:6333/collections/documents/snapshots/upload \
  --data-binary @snapshot.snapshot
```

### Integration mit anderen AI CoreKit Services

**Qdrant + RAGApp:**
- RAGApp verwendet Qdrant als Standard-Vector-Store
- Vorkonfiguriert unter `http://qdrant:6333`
- Alle RAGApp-Dokumenten-Embeddings in Qdrant gespeichert

**Qdrant + Flowise:**
- Verwende Qdrant Vector Store Node in Flowise
- URL: `http://qdrant:6333`
- Collections werden automatisch von Flowise-Agenten erstellt
- Ermöglicht RAG-Workflows mit visuellem Builder

**Qdrant + Ollama:**
- Generiere Embeddings lokal mit Ollama
- Modell: `nomic-embed-text` (768 Dimensionen)
- Kostenlos und schnell für Entwicklung
- Beispiel: Dokumente embedden → In Qdrant speichern → Suchen

**Qdrant + Open WebUI:**
- Open WebUI kann Qdrant für Dokumenten-RAG verwenden
- Konfiguriere in Open WebUI Einstellungen
- Dokumente hochladen → Automatisch eingebettet → In Qdrant gespeichert

**Qdrant + n8n:**
- Erstelle benutzerdefinierte RAG-Pipelines
- Automatisiere Dokumenten-Ingestion und Suche
- Kombiniere mit SearXNG, Whisper, OCR, etc.
- Erstelle intelligente Automatisierungs-Workflows

### Distanzmetriken erklärt

**Kosinus-Ähnlichkeit:**
- Am besten für: Text-Embeddings, semantische Suche
- Bereich: -1 (entgegengesetzt) bis 1 (identisch)
- Normalisierte Vektoren: Fokus auf Richtung, nicht Größe

**Dot Product:**
- Am besten für: Wenn Größe wichtig ist
- Bereich: -∞ bis +∞
- Schneller als Kosinus (keine Normalisierung nötig)

**Euklidische Distanz:**
- Am besten für: Räumliche Daten, Bild-Embeddings
- Bereich: 0 (identisch) bis +∞
- Misst tatsächliche Distanz im Vektorraum

### Ressourcen

- **Offizielle Website:** https://qdrant.tech/
- **Dokumentation:** https://qdrant.tech/documentation/
- **GitHub:** https://github.com/qdrant/qdrant
- **Web-UI:** `https://qdrant.deinedomain.com`
- **REST-API-Docs:** https://api.qdrant.tech/api-reference
- **Python-Client:** https://github.com/qdrant/qdrant-client
- **Community:** Discord (Link auf Website)
- **Benchmarks:** https://qdrant.tech/benchmarks/
