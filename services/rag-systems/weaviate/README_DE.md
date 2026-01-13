# 🗄️ Weaviate - KI-Vektor-Datenbank

### Was ist Weaviate?

Weaviate (ausgesprochen "we-vee-eight") ist eine Open-Source, KI-native Vektor-Datenbank, geschrieben in Go. Sie speichert sowohl Datenobjekte als auch deren Vektor-Embeddings und ermöglicht erweiterte semantische Suchfunktionen durch Vergleich der in Vektoren kodierten Bedeutung anstatt sich ausschließlich auf Keyword-Matching zu verlassen. Weaviate kombiniert die Kraft der Vektor-Ähnlichkeitssuche mit strukturierter Filterung, Multi-Tenancy und Cloud-nativer Skalierbarkeit, was es ideal für RAG-Anwendungen, Empfehlungssysteme und agenten-gesteuerte Workflows macht.

### Funktionen

- **Hybrid-Suche** - Kombiniere Vektor-Ähnlichkeit (semantisch) mit Keyword-Suche (BM25) für beste Ergebnisse
- **Multi-Modal-Unterstützung** - Durchsuche Text, Bilder, Audio und andere Datentypen mit integrierten Vectorizern
- **GraphQL & REST-APIs** - Flexibles Abfragen mit GraphQL für komplexe Suchen und REST für CRUD-Operationen
- **Integrierte Vectorizer** - Automatische Embedding-Generierung über OpenAI, Cohere, HuggingFace, Google und mehr
- **Multi-Tenancy** - Isolierte Daten-Namespaces für SaaS-Anwendungen
- **Verteilte Architektur** - Horizontale Skalierung mit Sharding und Replikation
- **Echtzeit-RAG** - Native Integration mit generativen Modellen für Retrieval-Augmented Generation

### Ersteinrichtung

**Zugriff auf Weaviate:**

Weaviate ist vorinstalliert und läuft auf deiner AI CoreKit Instanz.

1. **GraphQL Playground:** `https://weaviate.deinedomain.com/v1/graphql`
   - Interaktiver Query-Builder und Test-Oberfläche
   - Keine Authentifizierung erforderlich (nur interne Nutzung)
2. **REST-API:** `http://weaviate:8080` (intern) oder `https://weaviate.deinedomain.com` (extern)
3. **gRPC-API:** `weaviate:50051` (intern, hochperformante Abfragen)

**Erste Schritte:**

```bash
# Prüfen ob Weaviate läuft
curl http://localhost:8080/v1/.well-known/ready
# Antwort: {"status": "ok"}

# Weaviate-Version und Module prüfen
curl http://localhost:8080/v1/meta

# Erste Collection erstellen (in Weaviate "class" genannt)
curl -X POST http://localhost:8080/v1/schema \
  -H 'Content-Type: application/json' \
  -d '{
    "class": "Article",
    "vectorizer": "none",
    "properties": [
      {
        "name": "title",
        "dataType": ["text"]
      },
      {
        "name": "content",
        "dataType": ["text"]
      }
    ]
  }'

# Prüfen ob Collection erstellt wurde
curl http://localhost:8080/v1/schema
```

### n8n Integration Setup

**Von n8n aus mit Weaviate verbinden:**

- **Interne REST-URL:** `http://weaviate:8080`
- **Interne GraphQL-URL:** `http://weaviate:8080/v1/graphql`
- **Keine Authentifizierung** für internen Zugriff erforderlich

#### Beispiel 1: Collection erstellen & Objekte einfügen

Neue Collection für semantische Suche einrichten:

```javascript
// 1. HTTP Request: Collection erstellen (Schema)
Methode: POST
URL: http://weaviate:8080/v1/schema
Header:
  Content-Type: application/json
Body: {
  "class": "Document",
  "vectorizer": "none",  // Wir stellen eigene Vektoren bereit
  "properties": [
    {
      "name": "title",
      "dataType": ["text"],
      "tokenization": "word"
    },
    {
      "name": "content",
      "dataType": ["text"],
      "tokenization": "word"
    },
    {
      "name": "category",
      "dataType": ["text"],
      "tokenization": "field"  // Für exakte Übereinstimmung
    },
    {
      "name": "created_at",
      "dataType": ["date"]
    }
  ]
}

// 2. HTTP Request: Embedding generieren (OpenAI)
Methode: POST
URL: https://api.openai.com/v1/embeddings
Header:
  Authorization: Bearer {{ $env.OPENAI_API_KEY }}
Body: {
  "input": "{{ $json.content }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: Weaviate-Objekt vorbereiten
const embedding = $json.data[0].embedding;
const weaviateObject = {
  class: "Document",
  properties: {
    title: $json.title,
    content: $json.content,
    category: $json.category,
    created_at: new Date().toISOString()
  },
  vector: embedding
};
return { object: weaviateObject };

// 4. HTTP Request: Objekt in Weaviate einfügen
Methode: POST
URL: http://weaviate:8080/v1/objects
Body: {{ $json.object }}
```

#### Beispiel 2: Vektorsuche mit GraphQL

Semantische Suche mit GraphQL durchführen:

```javascript
// 1. Webhook: Suchanfrage empfangen

// 2. HTTP Request: Query-Embedding generieren
Methode: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": "{{ $json.query }}",
  "model": "text-embedding-3-small"
}

// 3. Code Node: GraphQL-Query vorbereiten
const queryVector = $json.data[0].embedding;
const graphqlQuery = {
  query: `{
    Get {
      Document(
        nearVector: {
          vector: ${JSON.stringify(queryVector)}
        }
        limit: 5
      ) {
        title
        content
        category
        _additional {
          distance
          id
        }
      }
    }
  }`
};
return graphqlQuery;

// 4. HTTP Request: Weaviate durchsuchen
Methode: POST
URL: http://weaviate:8080/v1/graphql
Header:
  Content-Type: application/json
Body: {{ $json }}

// 5. Code Node: Ergebnisse extrahieren
const results = $json.data.Get.Document.map(doc => ({
  id: doc._additional.id,
  title: doc.title,
  content: doc.content,
  category: doc.category,
  similarity: 1 - doc._additional.distance  // Distanz zu Ähnlichkeit konvertieren
}));
return { results };

// 6. Mit Ergebnissen antworten
```

#### Beispiel 3: Hybrid-Suche (Vektor + Keyword)

Semantische und Keyword-Suche für beste Ergebnisse kombinieren:

```javascript
// 1. Trigger: Benutzeranfrage

// 2. HTTP Request: GraphQL Hybrid-Suche
Methode: POST
URL: http://weaviate:8080/v1/graphql
Header:
  Content-Type: application/json
Body: {
  "query": "{
    Get {
      Document(
        hybrid: {
          query: \"{{ $json.query }}\"
          alpha: 0.5
        }
        limit: 10
      ) {
        title
        content
        category
        _additional {
          score
          explainScore
        }
      }
    }
  }"
}

// alpha: 0.0 = reine Keyword-Suche (BM25)
// alpha: 0.5 = ausgewogene Hybrid-Suche
// alpha: 1.0 = reine Vektor-Suche (semantisch)

// Ergebnis: Das Beste aus beiden Welten!
// - Findet semantisch ähnlichen Inhalt
// - Verstärkt exakte Keyword-Treffer
```

#### Beispiel 4: Gefilterte Vektorsuche

Vektor-Ähnlichkeit mit Metadaten-Filterung kombinieren:

```javascript
// 1. Trigger: Benutzeranfrage mit Filtern

// 2. HTTP Request: Gefilterte Vektorsuche
Methode: POST
URL: http://weaviate:8080/v1/graphql
Body: {
  "query": "{
    Get {
      Document(
        nearText: {
          concepts: [\"{{ $json.query }}\"]
        }
        where: {
          operator: And
          operands: [
            {
              path: [\"category\"]
              operator: Equal
              valueText: \"documentation\"
            },
            {
              path: [\"created_at\"]
              operator: GreaterThanEqual
              valueDatum: \"2024-01-01T00:00:00Z\"
            }
          ]
        }
        limit: 5
      ) {
        title
        content
        category
        created_at
        _additional {
          distance
        }
      }
    }
  }"
}

// Diese Suche:
// 1. Findet semantisch ähnliche Dokumente
// 2. Filtert auf category = "documentation"
// 3. Zeigt nur Dokumente ab 2024
```

#### Beispiel 5: Batch-Import mit REST-API

Viele Objekte effizient auf einmal importieren:

```javascript
// 1. Database Trigger: Neue Datensätze

// 2. Split in Batches Node: Batches von 100 erstellen

// 3. Loop over Batches

// 4. HTTP Request: Batch-Embeddings generieren
Methode: POST
URL: https://api.openai.com/v1/embeddings
Body: {
  "input": {{ $json.batch.map(item => item.content) }},
  "model": "text-embedding-3-small"
}

// 5. Code Node: Batch-Objekte vorbereiten
const objects = $json.data.map((emb, idx) => ({
  class: "Document",
  properties: {
    title: $json.batch[idx].title,
    content: $json.batch[idx].content,
    category: $json.batch[idx].category,
    created_at: new Date().toISOString()
  },
  vector: emb.embedding
}));
return { objects };

// 6. HTTP Request: Batch-Insert
Methode: POST
URL: http://weaviate:8080/v1/batch/objects
Body: {
  "objects": {{ $json.objects }}
}

// 7. Antwort auf Fehler prüfen
// Weaviate gibt Status pro Objekt zurück

// 8. Wait Node: 1 Sekunde (Rate Limits vermeiden)

// 9. Loop läuft weiter
```

#### Beispiel 6: Generative Suche (RAG)

Weaivates integrierte RAG-Fähigkeiten nutzen:

```javascript
// 1. Webhook: Benutzerfrage empfangen

// 2. HTTP Request: Generative Suche
Methode: POST
URL: http://weaviate:8080/v1/graphql
Body: {
  "query": "{
    Get {
      Document(
        nearText: {
          concepts: [\"{{ $json.question }}\"]
        }
        limit: 3
      ) {
        title
        content
        _additional {
          generate(
            singleResult: {
              prompt: \"Beantworte diese Frage: {{ $json.question }}\\n\\nMit diesem Kontext: {content}\"
            }
          ) {
            singleResult
            error
          }
        }
      }
    }
  }"
}

// Weaviate wird:
// 1. Top 3 relevante Dokumente finden
// 2. Diese an konfiguriertes LLM senden (OpenAI, Cohere, etc.)
// 3. Generierte Antwort zurückgeben

// 3. Code Node: Antwort extrahieren
const answer = $json.data.Get.Document[0]._additional.generate.singleResult;
const sources = $json.data.Get.Document.map(doc => ({
  title: doc.title,
  content: doc.content.substring(0, 200) + "..."
}));
return { answer, sources };

// 4. Antwort senden
```

### Erweiterte Konfiguration

#### Integrierte Vectorizer verwenden

Weaviate konfigurieren, um Embeddings automatisch zu generieren:

```bash
# Collection mit OpenAI-Vectorizer erstellen
curl -X POST http://localhost:8080/v1/schema \
  -H 'Content-Type: application/json' \
  -H 'X-OpenAI-Api-Key: DEIN_API_KEY' \
  -d '{
    "class": "Article",
    "vectorizer": "text2vec-openai",
    "moduleConfig": {
      "text2vec-openai": {
        "model": "text-embedding-3-small",
        "dimensions": 1536,
        "vectorizeClassName": false
      }
    },
    "properties": [
      {
        "name": "title",
        "dataType": ["text"]
      },
      {
        "name": "content",
        "dataType": ["text"]
      }
    ]
  }'

# Jetzt werden Objekte beim Einfügen automatisch vektorisiert!
curl -X POST http://localhost:8080/v1/objects \
  -H 'Content-Type: application/json' \
  -d '{
    "class": "Article",
    "properties": {
      "title": "Weaviate Tutorial",
      "content": "Dies ist ein Beispiel-Artikel."
    }
  }'
# Kein Vektor nötig - Weaviate generiert ihn automatisch!
```

#### Multi-Tenancy-Setup

Daten für verschiedene Benutzer/Klienten isolieren:

```bash
# Multi-Tenancy für Collection aktivieren
curl -X POST http://localhost:8080/v1/schema \
  -d '{
    "class": "Document",
    "multiTenancyConfig": {
      "enabled": true
    },
    "properties": [...]
  }'

# Tenant erstellen
curl -X POST http://localhost:8080/v1/schema/Document/tenants \
  -d '{
    "tenants": [
      {"name": "tenant_a"},
      {"name": "tenant_b"}
    ]
  }'

# Objekt für spezifischen Tenant einfügen
curl -X POST http://localhost:8080/v1/objects \
  -d '{
    "class": "Document",
    "tenant": "tenant_a",
    "properties": {...}
  }'

# Nur spezifischen Tenant abfragen
# GraphQL: Get { Document(tenant: "tenant_a") {...} }
```

#### Replikation für hohe Verfügbarkeit

```bash
# Collection mit Replikation erstellen
curl -X POST http://localhost:8080/v1/schema \
  -d '{
    "class": "Article",
    "replicationConfig": {
      "factor": 2  # 2 Kopien jedes Shards
    },
    "properties": [...]
  }'
```

### Fehlerbehebung

**Collection-Erstellung schlägt fehl:**

```bash
# 1. Prüfen ob Weaviate läuft
docker ps | grep weaviate

# 2. Logs prüfen
docker logs weaviate --tail 50

# 3. API-Erreichbarkeit prüfen
curl http://localhost:8080/v1/.well-known/ready

# 4. Vorhandenes Schema prüfen
curl http://localhost:8080/v1/schema

# 5. Collection löschen, wenn beschädigt
curl -X DELETE http://localhost:8080/v1/schema/BrokenCollection
```

**GraphQL-Abfragen schlagen fehl:**

```bash
# 1. GraphQL-Syntax validieren
# GraphQL-Formatter verwenden: https://graphql-formatter.com/

# 2. Häufige Probleme prüfen:
# - Fehlende Anführungszeichen um Strings
# - Falsche Feldnamen (case-sensitive!)
# - Falsche Datentypen in Filtern

# 3. Im GraphQL-Playground testen
# Navigiere zu: http://localhost:8080/v1/graphql

# 4. Query-Antwort auf Fehler prüfen
curl -X POST http://localhost:8080/v1/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query": "..."}'
# Nach "errors"-Array in Antwort suchen

# 5. Query vereinfachen, um Problem zu isolieren
# Mit einfachem Get beginnen, dann Filter schrittweise hinzufügen
```

**Objekte werden bei Suche nicht gefunden:**

```bash
# 1. Prüfen ob Objekte eingefügt wurden
curl http://localhost:8080/v1/objects?class=Document&limit=5

# 2. Objektanzahl prüfen
# GraphQL:
# { Aggregate { Document { meta { count } } } }

# 3. Vektor-Dimensionen überprüfen
# Collection erwartet: 1536 Dimensionen
# Deine Vektoren müssen auch sein: 1536 Dimensionen

# 4. Mit einfacher Keyword-Suche testen
# BM25 verwenden, um zu prüfen ob Daten existieren:
# { Get { Document(bm25: {query: "test"}) { title } } }

# 5. Distanz-Schwelle prüfen
# Höheres Limit oder keinen Distanzfilter versuchen
```

**Hohe Speicherauslastung:**

```bash
# 1. Weaviate-Statistiken prüfen
curl http://localhost:8080/v1/nodes

# 2. Vektor-Quantisierung aktivieren
# Product Quantization reduziert Speicher um Faktor 4-10
curl -X PATCH http://localhost:8080/v1/schema/Document \
  -d '{
    "vectorIndexConfig": {
      "pq": {
        "enabled": true,
        "segments": 96,
        "centroids": 256
      }
    }
  }'

# 3. HNSW-Parameter anpassen
# Niedrigere ef und maxConnections
curl -X PATCH http://localhost:8080/v1/schema/Document \
  -d '{
    "vectorIndexConfig": {
      "ef": 64,  # Standard: 128
      "maxConnections": 32  # Standard: 64
    }
  }'

# 4. Speicher überwachen
docker stats weaviate

# 5. Sharding für große Datenmengen erwägen
# Daten über mehrere Nodes verteilen
```

**Langsame Query-Performance:**

```bash
# 1. Query-Komplexität prüfen
# Tiefe verschachtelte Cross-References vermeiden

# 2. Filter effizient einsetzen
# Indizierte Properties: schneller
# Nicht-indizierte Properties: langsamer

# 3. HNSW-Einstellungen optimieren
curl -X PATCH http://localhost:8080/v1/schema/Document \
  -d '{
    "vectorIndexConfig": {
      "ef": 128,  # Höher = bessere Genauigkeit, langsamer
      "efConstruction": 256
    }
  }'

# 4. Limit-Parameter verwenden
# Nicht mehr Ergebnisse abrufen als nötig

# 5. Caching häufiger Queries erwägen
# Query-Result-Caching in deiner Anwendung implementieren
```

### Best Practices

**Collection-Design:**
- Verwende beschreibende Class-Namen (PascalCase): `Article`, `UserProfile`
- Definiere explizite Property-Typen
- Aktiviere Vectorizer, wenn du Auto-Embedding möchtest
- Verwende `tokenization: "field"` für Exact-Match-Properties (IDs, Kategorien)
- Verwende `tokenization: "word"` für Volltext-Such-Properties

**Property-Datentypen:**
- `text` - Für durchsuchbaren Text
- `text[]` - Für Text-Arrays
- `int`, `number` - Für numerische Werte
- `boolean` - Für true/false
- `date` - Für Zeitstempel (ISO 8601 Format)
- `geoCoordinates` - Für Breiten-/Längengrad-Positionen
- `phoneNumber` - Für Telefonnummern
- `blob` - Für Binärdaten

**Such-Strategie:**
- **Rein semantisch:** Verwende `nearText` oder `nearVector` (alpha=1.0)
- **Rein Keyword:** Verwende `bm25` (alpha=0.0)
- **Ausgewogene Hybrid:** Verwende `hybrid` mit alpha=0.5
- **Gefilterte Semantik:** Kombiniere `nearText` mit `where`-Filtern

**Performance-Tipps:**
- Objekte in Batches einfügen (100-1000 auf einmal)
- Verwende gRPC für hochfrequente Queries
- Indiziere Properties, die in Filtern verwendet werden
- Begrenze Ergebnisgröße (Standard 100, nach Bedarf anpassen)
- Verwende Multi-Tenancy für SaaS-Anwendungen
- Aktiviere Replikation für hohe Verfügbarkeit

**Daten-Modellierung:**
- Vermeide tiefe Cross-References (langsam bei Skalierung)
- Bette verwandte Daten im selben Objekt ein, wenn möglich
- Verwende Filter statt Cross-References für einfache Beziehungen
- Beispiel: Speichere Autorennamen im Book-Objekt, nicht als Referenz

### Integration mit anderen AI CoreKit Services

**Weaviate + RAGApp:**
- RAGApp kann konfiguriert werden, um Weaviate als Vektor-Store zu nutzen
- Alternative zu Qdrant mit anderem Feature-Set
- GraphQL-Schnittstelle bietet Flexibilität

**Weaviate + Flowise:**
- Verwende Weaviate Vector Store Node
- URL: `http://weaviate:8080`
- Integrierte Unterstützung in Flowise

**Weaviate + LangChain/LlamaIndex:**
- Native Integrationen verfügbar
- Python: `pip install weaviate-client`
- JavaScript: `npm install weaviate-client`

**Weaviate + n8n:**
- Erstelle eigene RAG-Workflows
- Verwende HTTP Request oder GraphQL Nodes
- Kombiniere mit anderen Services (Whisper, OCR, etc.)

**Weaviate + Ollama:**
- Konfiguriere Ollama als Vectorizer
- Lokale Embeddings mit `nomic-embed-text`
- Kostenlose und private Alternative zu OpenAI

### Distanz-Metriken

Weaviate unterstützt mehrere Distanz-Metriken:

**Cosine Distance:**
- Am besten für: Text-Embeddings
- Bereich: 0 (identisch) bis 2 (entgegengesetzt)
- Normalisierte Vektoren empfohlen

**Dot Product:**
- Am besten für: Wenn Magnitude wichtig ist
- Bereich: -∞ bis +∞
- Schneller als Cosine

**L2 Squared (Euklidisch):**
- Am besten für: Räumliche Daten
- Bereich: 0 (identisch) bis +∞
- Tatsächliche Distanz im Vektorraum

**Manhattan (L1):**
- Am besten für: Hochdimensionale Daten
- Bereich: 0 (identisch) bis +∞

**Hamming:**
- Am besten für: Binäre Vektoren
- Zählt unterschiedliche Bits

### GraphQL vs REST API

**Verwende GraphQL für:**
- ✅ Komplexe Queries mit Filtern
- ✅ Abruf spezifischer Properties
- ✅ Verschachtelte Cross-Reference-Queries
- ✅ Aggregationen und Analysen
- ✅ Interaktive Entwicklung (Playground)

**Verwende REST für:**
- ✅ CRUD-Operationen auf Objekten
- ✅ Schema-Management
- ✅ Batch-Operationen
- ✅ Objekt-Abruf per ID
- ✅ Einfachere Integration

**Verwende gRPC für:**
- ✅ Hochfrequente Queries
- ✅ Niedrige Latenz-Anforderungen
- ✅ Große Datenübertragungen
- ✅ Produktive Such-Endpoints

### Ressourcen

- **Offizielle Website:** https://weaviate.io/
- **Dokumentation:** https://weaviate.io/developers/weaviate
- **GitHub:** https://github.com/weaviate/weaviate
- **GraphQL Playground:** `https://weaviate.deinedomain.com/v1/graphql`
- **REST API Docs:** https://weaviate.io/developers/weaviate/api/rest
- **Python Client:** https://github.com/weaviate/weaviate-python-client
- **JS Client:** https://github.com/weaviate/typescript-client
- **Community:** Slack & Forum (Links auf Website)
- **Weaviate Academy:** https://weaviate.io/developers/academy
