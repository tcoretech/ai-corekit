# 🕸️ Neo4j - Native Graph-Datenbank-Plattform

### Was ist Neo4j?

Neo4j ist die weltweit führende native Graph-Datenbank, die Daten als Knoten (Entitäten), Beziehungen (Verbindungen) und Eigenschaften speichert anstelle von Tabellen oder Dokumenten. Im Gegensatz zu relationalen Datenbanken, die JOINs verwenden, sind Beziehungen in Neo4j vollwertige Bürger, die nativ gespeichert werden und Millionen von Beziehungsdurchläufen pro Sekunde ermöglichen. Mit der deklarativen Cypher-Abfragesprache (ähnlich wie SQL, aber für Graphen optimiert) kannst du komplexe Beziehungsabfragen intuitiv mit ASCII-Art-ähnlicher Syntax schreiben. Perfekt für Wissensgraphen, Betrugserkennung, Empfehlungssysteme, soziale Netzwerke und KI-Anwendungen.

### Features

- **🔗 Native Graph-Speicherung**: Beziehungen als vollwertige Bürger - keine JOINs erforderlich
- **⚡ Extrem schnell**: Millionen von Durchläufen pro Sekunde mit optimierten Graph-Algorithmen
- **🔍 Cypher-Abfragesprache**: Intuitive, ASCII-Art-basierte Abfragesprache (wie visuelles Zeichnen)
- **🎯 Schema-Optional**: Flexible Datenmodellierung ohne feste Schemas
- **🔄 ACID-konform**: Vollständige Transaktionssicherheit und Datenintegrität
- **📊 Integrierte Browser-UI**: Web-basierte Oberfläche für Abfrage-Entwicklung und Visualisierung
- **🌐 Horizontal skalierbar**: Clustering und Sharding für Enterprise-Workloads

### Initiales Setup

**Erster Login zu Neo4j:**

1. **Zugriff auf Neo4j Browser:**
```
https://neo4j.deinedomain.com
```

2. **Initiale Login-Zugangsdaten:**
- **Verbindungs-URL:** `neo4j://neo4j:7687` (Bolt-Protokoll)
- **Benutzername:** `neo4j`
- **Passwort:** Prüfe `.env`-Datei für `NEO4J_AUTH` (Format: `neo4j/passwort`)

```bash
# Passwort vom Server prüfen
grep NEO4J_AUTH /root/ai-corekit/.env
# Beispiel-Ausgabe: NEO4J_AUTH=neo4j/dein-passwort-hier
```

3. **Standard-Passwort ändern (Erster Login):**
Neo4j fordert dich auf, das Passwort bei der ersten Verbindung zu ändern.
- Altes Passwort: `neo4j` (oder aus `.env`)
- Neues Passwort: Wähle ein starkes Passwort

4. **Beispieldaten erkunden (Optional):**
```cypher
// Im Neo4j Browser die eingebaute Film-Datenbank ausprobieren
:play movies

// Folge der Anleitung und führe die CREATE-Anweisungen aus
// Probiere dann deine erste Abfrage aus:
MATCH (m:Movie {title: "The Matrix"})
RETURN m
```

### Cypher-Abfragesprache Grundlagen

Cypher verwendet ASCII-Art-Syntax, um Graph-Muster darzustellen:

**Knoten** - Dargestellt mit Klammern `()`
```cypher
// Einen Personen-Knoten erstellen
CREATE (p:Person {name: "Alice", age: 30})

// Alle Personen-Knoten finden
MATCH (p:Person)
RETURN p.name, p.age
```

**Beziehungen** - Dargestellt mit Pfeilen `-->`
```cypher
// Knoten und Beziehung erstellen
CREATE (alice:Person {name: "Alice"})
CREATE (bob:Person {name: "Bob"})
CREATE (alice)-[:KNOWS {since: 2020}]->(bob)

// Freunde finden
MATCH (alice:Person {name: "Alice"})-[:KNOWS]->(friend)
RETURN friend.name
```

**Muster** - Knoten und Beziehungen kombinieren
```cypher
// Freunde von Freunden finden
MATCH (person:Person {name: "Alice"})-[:KNOWS]->()-[:KNOWS]->(fof)
RETURN fof.name

// Kürzesten Pfad finden
MATCH path = shortestPath(
  (alice:Person {name: "Alice"})-[:KNOWS*]-(bob:Person {name: "Bob"})
)
RETURN path
```

**Häufige Operationen:**
```cypher
// CREATE - Daten einfügen
CREATE (n:Node {property: "value"})

// MATCH - Muster finden
MATCH (n:Label {property: "value"})
RETURN n

// WHERE - Ergebnisse filtern
MATCH (p:Person)
WHERE p.age > 25
RETURN p.name

// SET - Eigenschaften aktualisieren
MATCH (p:Person {name: "Alice"})
SET p.age = 31

// DELETE - Knoten/Beziehungen entfernen
MATCH (p:Person {name: "Bob"})
DETACH DELETE p  // DETACH entfernt zuerst Beziehungen

// ORDER BY - Ergebnisse sortieren
MATCH (p:Person)
RETURN p.name, p.age
ORDER BY p.age DESC

// LIMIT - Ergebnisse begrenzen
MATCH (p:Person)
RETURN p
LIMIT 10
```

### n8n Integration Setup

**Methoden zur Integration von Neo4j mit n8n:**

1. **HTTP Request Node** (Direkte Bolt/HTTP API)
2. **Community Node** (n8n-nodes-neo4j installieren)
3. **Code Node** (Benutzerdefiniertes JavaScript mit neo4j-driver)

#### Methode 1: HTTP Request Node

Neo4j bietet eine HTTP-API für Cypher-Abfragen.

**Interne URL:** `http://neo4j:7474/db/neo4j/tx/commit`

**HTTP Request Konfiguration:**
```javascript
Methode: POST
URL: http://neo4j:7474/db/neo4j/tx/commit
Authentication: Basic Auth
  Username: neo4j
  Password: {{ $env.NEO4J_PASSWORD }}
Header:
  Content-Type: application/json
  Accept: application/json;charset=UTF-8
Body (JSON):
{
  "statements": [
    {
      "statement": "MATCH (n:Person) RETURN n.name AS name LIMIT 10"
    }
  ]
}
```

**Antwort-Format:**
```json
{
  "results": [
    {
      "columns": ["name"],
      "data": [
        {"row": ["Alice"]},
        {"row": ["Bob"]}
      ]
    }
  ],
  "errors": []
}
```

#### Methode 2: Community Node (Empfohlen)

Installiere den Neo4j Community Node für eine bessere Integration.

**Installation:**
```
n8n UI → Einstellungen → Community Nodes → Installieren
Package: n8n-nodes-neo4j
```

**Zugangsdaten-Setup:**
- **Name:** Neo4j Credentials
- **Schema:** `neo4j` oder `bolt`
- **Host:** `neo4j`
- **Port:** `7687`
- **Benutzername:** `neo4j`
- **Passwort:** Aus `.env`-Datei
- **Datenbank:** `neo4j` (Standard)

### Beispiel-Workflows

#### Beispiel 1: Wissensgraph-Builder

Erstelle einen Wissensgraphen aus strukturierten Daten.

**Workflow-Struktur:**
1. **Webhook/Schedule Trigger**
   ```javascript
   Input: {
     "entities": [
       {"type": "Person", "name": "Alice", "role": "Developer"},
       {"type": "Person", "name": "Bob", "role": "Designer"},
       {"type": "Company", "name": "Acme Corp"}
     ],
     "relationships": [
       {"from": "Alice", "to": "Acme Corp", "type": "WORKS_FOR"},
       {"from": "Bob", "to": "Acme Corp", "type": "WORKS_FOR"},
       {"from": "Alice", "to": "Bob", "type": "COLLABORATES_WITH"}
     ]
   }
   ```

2. **Code Node - Cypher-Anweisungen vorbereiten**
   ```javascript
   const entities = $json.entities;
   const relationships = $json.relationships;
   
   // CREATE-Anweisungen für Entitäten generieren
   const entityStatements = entities.map(e => 
     `MERGE (n:${e.type} {name: '${e.name}'}) ` +
     `SET n.role = '${e.role || ''}'`
   );
   
   // CREATE-Anweisungen für Beziehungen generieren
   const relStatements = relationships.map(r =>
     `MATCH (a {name: '${r.from}'}), (b {name: '${r.to}'}) ` +
     `MERGE (a)-[:${r.type}]->(b)`
   );
   
   return [{
     json: {
       cypher: [...entityStatements, ...relStatements].join('\n')
     }
   }];
   ```

3. **HTTP Request Node - In Neo4j ausführen**
   ```javascript
   Methode: POST
   URL: http://neo4j:7474/db/neo4j/tx/commit
   Authentication: Basic Auth (neo4j Zugangsdaten)
   Body: {
     "statements": [
       {
         "statement": "{{ $json.cypher }}"
       }
     ]
   }
   ```

4. **Code Node - Graph verifizieren**
   ```javascript
   // Abfrage zur Visualisierung des Graphen
   const verifyQuery = `
     MATCH (n)-[r]->(m)
     RETURN n.name AS from, type(r) AS relationship, m.name AS to
     LIMIT 100
   `;
   
   return [{
     json: {
       query: verifyQuery
     }
   }];
   ```

**Anwendungsfall**: CRM-Systeme, Organigramme, Projektabhängigkeiten.

#### Beispiel 2: Empfehlungssystem

Finde Empfehlungen basierend auf Graph-Mustern.

**Workflow-Struktur:**
1. **Webhook Trigger**
   ```javascript
   Input: {
     "user": "Alice",
     "type": "product_recommendations"
   }
   ```

2. **HTTP Request - Empfehlungen finden**
   ```javascript
   Methode: POST
   URL: http://neo4j:7474/db/neo4j/tx/commit
   Body: {
     "statements": [
       {
         "statement": `
           // Produkte finden, die ähnliche Nutzer ebenfalls gekauft haben
           MATCH (user:User {name: $userName})-[:PURCHASED]->(p:Product)
           MATCH (p)<-[:PURCHASED]-(other:User)-[:PURCHASED]->(rec:Product)
           WHERE NOT (user)-[:PURCHASED]->(rec)
           RETURN rec.name AS product, 
                  rec.category AS category,
                  COUNT(*) AS score
           ORDER BY score DESC
           LIMIT 5
         `,
         "parameters": {
           "userName": "{{ $json.user }}"
         }
       }
     ]
   }
   ```

3. **Code Node - Empfehlungen formatieren**
   ```javascript
   const results = $json.results[0].data;
   
   const recommendations = results.map(item => ({
     product: item.row[0],
     category: item.row[1],
     score: item.row[2]
   }));
   
   return [{
     json: {
       user: $('Webhook').item.json.user,
       recommendations: recommendations,
       generated_at: new Date().toISOString()
     }
   }];
   ```

4. **Empfehlungen senden** - E-Mail oder API-Antwort

**Anwendungsfall**: E-Commerce-Empfehlungen, Content-Vorschläge, soziale Verbindungen.

#### Beispiel 3: Betrugserkennung

Erkennung verdächtiger Muster in Transaktionsnetzwerken.

**Workflow-Struktur:**
1. **Schedule Trigger** (Jede Stunde)

2. **HTTP Request - Verdächtige Muster finden**
   ```javascript
   Methode: POST
   URL: http://neo4j:7474/db/neo4j/tx/commit
   Body: {
     "statements": [
       {
         "statement": `
           // Zirkuläre Geldtransfers finden (potenzielle Geldwäsche)
           MATCH path = (a:Account)-[:TRANSFERRED*3..5]->(a)
           WHERE ALL(r IN relationships(path) WHERE r.amount > 1000)
           AND length(path) >= 3
           RETURN a.account_id AS suspicious_account,
                  [n IN nodes(path) | n.account_id] AS path_accounts,
                  [r IN relationships(path) | r.amount] AS amounts,
                  length(path) AS circle_length
           ORDER BY circle_length DESC
           LIMIT 10
         `
       }
     ]
   }
   ```

3. **Code Node - Risiko analysieren**
   ```javascript
   const suspiciousPatterns = $json.results[0].data;
   
   const highRisk = suspiciousPatterns
     .filter(pattern => {
       const totalAmount = pattern.row[2].reduce((sum, amt) => sum + amt, 0);
       return totalAmount > 50000 && pattern.row[3] >= 4;
     })
     .map(pattern => ({
       account: pattern.row[0],
       pathAccounts: pattern.row[1],
       totalBetrag: pattern.row[2].reduce((sum, amt) => sum + amt, 0),
       riskScore: pattern.row[3] * 10  // Höhere Kreise = höheres Risiko
     }));
   
   return [{
     json: {
       alertsFound: highRisk.length,
       highRiskAccounts: highRisk
     }
   }];
   ```

4. **IF Node - Prüfen ob Warnungen existieren**
5. **Warnung-Pfad** - Benachrichtige Betrugs-Team via Slack/E-Mail

**Anwendungsfall**: Banking-Betrugserkennung, Versicherungsanspruch-Analyse, Netzwerksicherheit.

### Fehlerbehebung

**Problem 1: Keine Verbindung zum Neo4j Browser**

```bash
# Prüfen ob Neo4j läuft
corekit ps | grep neo4j

# Logs auf Fehler prüfen
corekit logs neo4j --tail 100

# Prüfen ob Ports erreichbar sind
corekit port neo4j 7474
corekit port neo4j 7687
```

**Lösung:**
- Verifiziere, dass Caddy korrekt zu Neo4j routet
- Prüfe `.env`-Datei auf korrektes `NEO4J_AUTH`-Format
- Versuche direkten Zugriff: `http://localhost:7474` (falls Port exponiert ist)

**Problem 2: Authentifizierung fehlgeschlagen**

```bash
# Aktuelles Passwort in .env prüfen
grep NEO4J_AUTH /root/ai-corekit/.env

# Falls Passwort in Neo4j geändert wurde, aber nicht in .env:
# Option 1: .env-Datei aktualisieren
nano /root/ai-corekit/.env
# Ändere NEO4J_AUTH=neo4j/dein-neues-passwort

# Option 2: Neo4j komplett zurücksetzen (WARNUNG: Löscht alle Daten)
corekit down neo4j
docker volume rm ai-corekit_neo4j_data
corekit up -d neo4j
```

**Lösung:**
- Stelle sicher, dass der Benutzername `neo4j` ist (kann nicht geändert werden)
- Passwort-Format in .env: `NEO4J_AUTH=neo4j/deinpasswort`
- Keine Leerzeichen um das `=`-Zeichen

**Problem 3: Abfrage läuft langsam**

```bash
# Container-Ressourcen prüfen
docker stats neo4j --no-stream

# Abfrage-Performance im Neo4j Browser prüfen
# Mit EXPLAIN oder PROFILE ausführen:
EXPLAIN MATCH (n:Person) RETURN n

# Prüfen ob Indizes existieren
SHOW INDEXES
```

**Lösung:**
- Erstelle Indizes für häufig abgefragte Eigenschaften:
  ```cypher
  CREATE INDEX person_name FOR (p:Person) ON (p.name)
  CREATE INDEX product_id FOR (p:Product) ON (p.id)
  ```
- Verwende Constraints für eindeutige Eigenschaften:
  ```cypher
  CREATE CONSTRAINT user_email FOR (u:User) REQUIRE u.email IS UNIQUE
  ```
- Optimiere Abfrage-Muster (vermeide unbegrenzte Beziehungen `[:KNOWS*]`)

**Problem 4: Zu wenig Speicher**

```bash
# Speichernutzung prüfen
docker stats neo4j

# Neo4j-Konfiguration anzeigen
corekit exec neo4j cat /var/lib/neo4j/conf/neo4j.conf | grep memory
```

**Lösung:**
- Erhöhe Heap-Speicher in `docker-compose.yml`:
  ```yaml
  neo4j:
    environment:
      - NEO4J_dbms_memory_heap_max__size=2G
      - NEO4J_dbms_memory_pagecache_size=1G
  ```
- Neo4j neu starten:
  ```bash
  corekit restart neo4j
  ```

**Problem 5: Knoten kann nicht gelöscht werden (Beziehungs-Constraint)**

```cypher
// Fehler: Cannot delete node<123>, because it still has relationships
DELETE n

// Lösung: Verwende DETACH DELETE, um zuerst Beziehungen zu entfernen
MATCH (n:Person {name: "Bob"})
DETACH DELETE n
```

### Best Practices

**Data Modeling:**
- Use clear, descriptive labels (`:Person`, `:Product`, not `:P`, `:Pr`)
- Relationship types as verbs (`:WORKS_FOR`, `:PURCHASED`)
- Properties for attributes (dates, counts, names)
- Avoid storing lists in properties (use separate nodes instead)

**Query Optimization:**
- Always use labels in MATCH clauses: `MATCH (p:Person)` not `MATCH (p)`
- Create indexes on frequently queried properties
- Use LIMIT to restrict large result sets
- Use EXPLAIN/PROFILE to analyze query performance
- Avoid Cartesian products (always connect patterns with relationships)

**Schema Design:**
- Create constraints for unique identifiers:
  ```cypher
  CREATE CONSTRAINT user_id FOR (u:User) REQUIRE u.id IS UNIQUE
  ```
- Create indexes for search properties:
  ```cypher
  CREATE INDEX person_name FOR (p:Person) ON (p.name)
  ```
- Use composite indexes for multi-property searches:
  ```cypher
  CREATE INDEX person_name_age FOR (p:Person) ON (p.name, p.age)
  ```

**n8n Integration:**
- Always use parameterized queries to prevent Cypher injection
- Batch operations for better performance (group multiple statements)
- Use transactions for data consistency
- Handle errors gracefully (check `errors` array in response)

### Ressourcen

- **Official Documentation**: https://neo4j.com/docs/
- **Cypher Manual**: https://neo4j.com/docs/cypher-manual/current/
- **Developer Guides**: https://neo4j.com/developer/
- **Graph Academy** (Free Courses): https://graphacademy.neo4j.com/
- **Neo4j Browser**: `https://neo4j.yourdomain.com`
- **Bolt Protocol**: `neo4j://neo4j:7687` (internal)
- **HTTP API**: `http://neo4j:7474` (internal)
- **Community Forum**: https://community.neo4j.com/

**Related Services:**
- Use with **LightRAG** for automatic knowledge graph creation
- Feed data from **PostgreSQL** or **Supabase**
- Visualize with **Grafana** (using Neo4j plugin)
- Query from **n8n** workflows for graph operations
- Combine with **Ollama** for AI-powered graph analysis
