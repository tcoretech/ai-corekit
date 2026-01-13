# 🐘 PostgreSQL - Relationale Datenbank

### Was ist PostgreSQL?

PostgreSQL (auch bekannt als Postgres) ist die fortschrittlichste Open-Source relationale Datenbank der Welt. AI CoreKit verwendet PostgreSQL 17, das bedeutende Performance-Verbesserungen, erweiterte JSON-Funktionen und bessere Unterstützung für KI-Workloads durch Erweiterungen wie pgvector bringt. PostgreSQL dient als primäre Datenbank für n8n, Cal.com, Supabase und viele andere Dienste im Stack.

PostgreSQL 17 beinhaltet überarbeitetes Speichermanagement (bis zu 20x weniger RAM für Vacuum-Operationen), 2x schnellere Bulk-Exports, verbesserte logische Replikation für hohe Verfügbarkeit und SQL/JSON-Unterstützung mit der JSON_TABLE-Funktion zum Konvertieren von JSON in relationale Tabellen.

### Features

- ✅ **PostgreSQL 17** - Neueste Version mit verbesserter Performance und Skalierbarkeit
- ✅ **ACID-Konformität** - Vollständige Transaktionsunterstützung mit Datenintegritäts-Garantien
- ✅ **Erweitertes SQL** - Unterstützung für JSON, Arrays, Volltextsuche, Window-Funktionen
- ✅ **pgvector-Erweiterung** - Speichere und frage Vektor-Embeddings für KI/ML-Anwendungen ab
- ✅ **Logische Replikation** - Echtzeit-Datenreplikation mit Failover-Unterstützung
- ✅ **Row Level Security** - Feinkörnige Zugriffskontrolle auf Zeilenebene
- ✅ **JSON/JSONB-Unterstützung** - Native JSON-Speicherung mit Indizierung und Abfragen
- ✅ **Volltextsuche** - Eingebaute Textsuche ohne externe Dienste
- ✅ **Foreign Data Wrappers** - Verbinde zu externen Datenquellen (MySQL, MongoDB, etc.)
- ✅ **Stored Procedures** - Komplexe Geschäftslogik in SQL, PL/pgSQL, Python, JavaScript

### Erste Einrichtung

PostgreSQL wird automatisch während der AI CoreKit-Installation installiert und konfiguriert.

**Auf PostgreSQL zugreifen:**

```bash
# PostgreSQL CLI aufrufen
docker exec -it postgres psql -U postgres

# Oder als spezifischer Datenbankbenutzer verbinden
docker exec -it postgres psql -U n8n -d n8n
```

**Wichtige Zugangsdaten (gespeichert in `.env`):**

```bash
# PostgreSQL-Zugangsdaten anzeigen
grep "POSTGRES" .env

# Wichtige Variablen:
# POSTGRES_USER - Admin-Benutzername (Standard: postgres)
# POSTGRES_PASSWORD - Admin-Passwort
# POSTGRES_DB - Standard-Datenbankname
```

**Erstelle deine erste Datenbank:**

```sql
-- Mit PostgreSQL verbinden
docker exec -it postgres psql -U postgres

-- Neue Datenbank erstellen
CREATE DATABASE myapp;

-- Benutzer erstellen
CREATE USER myapp_user WITH PASSWORD 'sicheres_passwort';

-- Berechtigungen vergeben
GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;

-- pgvector-Erweiterung aktivieren (für KI/Vektor-Operationen)
\c myapp
CREATE EXTENSION vector;

-- Verifizieren dass pgvector aktiviert ist
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### n8n-Integration einrichten

PostgreSQL ist über internes Docker-Networking von n8n aus erreichbar.

**Interne URL für n8n:** `http://postgres:5432`

**PostgreSQL-Credentials in n8n erstellen:**

1. In n8n, gehe zu **Credentials** → **New Credential**
2. Suche nach **Postgres**
3. Fülle aus:
   - **Host:** `postgres` (interner Docker-Hostname)
   - **Database:** Dein Datenbankname (z.B. `n8n`, `postgres`, oder benutzerdefinierte DB)
   - **User:** Datenbankbenutzer (z.B. `postgres` oder `n8n`)
   - **Password:** Aus `.env` Datei (`POSTGRES_PASSWORD`)
   - **Port:** `5432` (Standard)
   - **SSL:** Deaktivieren (nicht nötig für interne Verbindungen)

### Beispiel-Workflows

#### Beispiel 1: Kundendaten-Pipeline mit PostgreSQL

```javascript
// Kundendaten in PostgreSQL speichern und Aktionen bei Änderungen auslösen

// 1. Webhook Trigger - Neue Kundenanmeldung empfangen

// 2. Postgres Node - Kundeneintrag einfügen
Operation: Einfügen
Table: customers
Columns: name, email, company, created_at
Values:
  name: {{$json.name}}
  email: {{$json.email}}
  company: {{$json.company}}
  created_at: {{$now.toISO()}}
Return Fields: * (alle Spalten inkl. ID zurückgeben)

// 3. Code Node - Willkommens-E-Mail-Inhalt generieren
const customer = $input.item.json;

return {
  customerId: customer.id,
  subject: `Willkommen auf unserer Plattform, ${customer.name}!`,
  body: `Hallo ${customer.name},\n\nWir freuen uns, ${customer.company} an Bord zu haben!\n\nBeste Grüße,\nDas Team`,
  email: customer.email
};

// 4. SMTP Node - Willkommens-E-Mail senden
To: {{$json.email}}
Subject: {{$json.subject}}
Nachricht: {{$json.body}}

// 5. Postgres Node - Kundenstatus aktualisieren
Operation: Update
Table: customers
Where: id = {{$('Insert Customer').json.id}}
Columns: status, welcome_email_sent_at
Values:
  status: active
  welcome_email_sent_at: {{$now.toISO()}}
```

#### Beispiel 2: Vektorsuche für semantische Dokumentensuche (RAG)

```javascript
// pgvector verwenden um Dokumenten-Embeddings zu speichern und zu durchsuchen

// 1. HTTP Request - Dokumente von API oder Webhook abrufen

// 2. Loop Over Documents

// 3. OpenAI Node - Embedding für jedes Dokument generieren
Modell: text-embedding-3-small (gibt 1536-dimensionalen Vektor aus)
Input: {{$json.content}}

// 4. Postgres Node - Dokument mit Embedding speichern
Operation: Abfrage ausführen
Abfrage: |
  INSERT INTO documents (title, content, embedding, created_at)
  VALUES (
    $1,
    $2,
    $3::vector,
    NOW()
  )
  RETURNING id;
Parameter:
  $1: {{$json.title}}
  $2: {{$json.content}}
  $3: {{$json.embedding}}  -- OpenAI gibt JSON-Array zurück, Postgres konvertiert es

// 5. Search Trigger (Webhook oder Schedule)

// 6. OpenAI Node - Embedding für Suchanfrage generieren
Modell: text-embedding-3-small
Input: {{$json.search_query}}

// 7. Postgres Node - Semantische Suche mit pgvector
Operation: Abfrage ausführen
Abfrage: |
  SELECT 
    id,
    title,
    content,
    1 - (embedding <=> $1::vector) AS similarity_score
  FROM documents
  WHERE 1 - (embedding <=> $1::vector) > 0.7  -- Ähnlichkeits-Schwellwert
  ORDER BY embedding <=> $1::vector  -- Cosinus-Distanz
  LIMIT 5;
Parameter:
  $1: {{$json.embedding}}  -- Anfrage-Embedding

// Gibt die Top 5 semantisch ähnlichsten Dokumente zurück
// <=> Operator ist Cosinus-Distanz (0 = identisch, 2 = gegenteilig)
```

#### Beispiel 3: Echtzeit-Datensynchronisation mit Datenbank-Triggern

```javascript
// PostgreSQL-Trigger verwenden um n8n automatisch über Datenänderungen zu benachrichtigen

// Schritt 1: Benachrichtigungsfunktion in PostgreSQL erstellen
// Führe dieses SQL in deiner Datenbank aus:

CREATE OR REPLACE FUNCTION notify_n8n_on_order()
RETURNS TRIGGER AS $$
DECLARE
  payload JSON;
BEGIN
  -- JSON-Payload erstellen
  payload := json_build_object(
    'event', TG_OP,  -- INSERT, UPDATE, DELETE
    'table', TG_TABLE_NAME,
    'record', row_to_json(NEW),
    'old_record', row_to_json(OLD)
  );
  
  -- Webhook-Benachrichtigung senden
  PERFORM pg_notify('order_changes', payload::text);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

// Schritt 2: Trigger erstellen
CREATE TRIGGER order_changes
  AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_n8n_on_order();

// Schritt 3: n8n Workflow mit Postgres Trigger Node
// 1. Postgres Trigger Node
Database: deine_datenbank
Kanal: order_changes  -- passt zum pg_notify Kanalnamen
// Dieser Node hört auf PostgreSQL NOTIFY-Events

// 2. Code Node - Trigger-Event verarbeiten
const event = JSON.parse($input.item.json.payload);

return {
  eventType: event.event,  // INSERT, UPDATE, DELETE
  tableName: event.table,
  newDaten: event.record,
  oldDaten: event.old_record,
  timestamp: new Date().toISOString()
};

// 3. IF Node - Routing basierend auf Event-Typ
{{$json.eventType}} equals 'INSERT'

// 4. Unterschiedliche Aktionen für jeden Event-Typ
// - INSERT: "Neue Bestellung"-Benachrichtigung senden
// - UPDATE: Prüfen ob Status sich geändert hat, Update senden
// - DELETE: Stornierung protokollieren, Rückerstattungs-Workflow senden
```

### Erweiterte Anwendungsfälle

#### pgvector für KI-Anwendungen einrichten

```sql
-- pgvector-Erweiterung aktivieren
CREATE EXTENSION vector;

-- Tabelle mit Vektor-Spalte erstellen
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  title TEXT,
  content TEXT,
  embedding VECTOR(1536),  -- 1536 Dimensionen für OpenAI text-embedding-3-small
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- HNSW-Index für schnelle Ähnlichkeitssuche erstellen
-- HNSW wird für die meisten Anwendungsfälle empfohlen (schnell und genau)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

-- Alternative: IVFFlat-Index (gut für sehr große Datensätze)
-- CREATE INDEX ON documents USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);

-- Dokument mit Embedding einfügen (Beispiel)
INSERT INTO documents (title, content, embedding)
VALUES (
  'PostgreSQL Guide',
  'PostgreSQL ist eine leistungsstarke Datenbank...',
  '[0.1, 0.2, -0.3, ...]'::vector  -- Dein 1536-dimensionales Embedding
);

-- Semantische Such-Abfrage
SELECT 
  id,
  title,
  content,
  1 - (embedding <=> '[0.1, 0.2, ...]'::vector) AS similarity
FROM documents
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector  -- Cosinus-Distanz
LIMIT 5;
```

**Distanz-Operatoren:**
- `<->` - Euklidische Distanz (L2)
- `<=>` - Cosinus-Distanz (empfohlen für Embeddings)
- `<#>` - Negatives inneres Produkt (für Max-Inner-Product-Suche)

**Index-Typen:**
- **HNSW**: Am besten für die meisten Fälle, schnellere Abfragen, genauer
- **IVFFlat**: Besser für sehr große Datensätze (>1M Zeilen), verwendet weniger Speicher

#### Row Level Security (RLS) für Multi-Tenant-Anwendungen

```sql
-- RLS auf Tabelle aktivieren
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Policy: Benutzer können nur ihre eigenen Dokumente sehen
CREATE POLICY "users_own_documents"
ON documents
FOR ALL
USING (user_id = current_user_id());

-- Policy: Admins können alles sehen
CREATE POLICY "admins_see_all"
ON documents
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = current_user_id()
    AND users.role = 'admin'
  )
);

-- Funktion um aktuelle Benutzer-ID zu erhalten (implementiere basierend auf deinem Auth-System)
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
BEGIN
  RETURN current_setting('app.user_id')::UUID;
END;
$$ LANGUAGE plpgsql STABLE;

-- Benutzer-ID in Session setzen (von n8n oder Anwendung)
-- SET app.user_id = 'benutzer-uuid-hier';
```

#### Datenbank-Funktionen für komplexe Logik

```sql
-- Funktion erstellen um Bestellsumme mit Steuer zu berechnen
CREATE OR REPLACE FUNCTION calculate_order_total(
  order_id_param INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
  subtotal NUMERIC;
  tax_rate NUMERIC := 0.08;  -- 8% Steuer
  total NUMERIC;
BEGIN
  -- Zwischensumme berechnen
  SELECT SUM(quantity * price) INTO subtotal
  FROM order_items
  WHERE order_id = order_id_param;
  
  -- Gesamtsumme mit Steuer berechnen
  total := subtotal * (1 + tax_rate);
  
  RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Funktion von n8n aus aufrufen:
// Postgres Node - Execute Query
SELECT calculate_order_total(123) AS total;

-- Oder Trigger erstellen um Summen automatisch zu aktualisieren:
CREATE TRIGGER update_order_total
  AFTER INSERT OR UPDATE OR DELETE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_order_total();
```

### Fehlerbehebung

**Verbindung abgelehnt / Kann nicht mit Datenbank verbinden:**

```bash
# Prüfen ob PostgreSQL läuft
docker ps | grep postgres

# PostgreSQL-Logs prüfen
docker logs postgres --tail 100

# PostgreSQL neu starten
docker compose restart postgres

# Verbindung vom Host aus testen
docker exec postgres pg_isready -U postgres
# Sollte zurückgeben: postgres:5432 - accepting connections

# Verbindung vom n8n-Container aus testen
docker exec n8n ping postgres
# Sollte postgres-Container erfolgreich anpingen
```

**Datenbankabfragen sind langsam:**

```bash
# Aktive Verbindungen und Abfragen prüfen
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"

# Tabellengrößen prüfen
docker exec postgres psql -U postgres -c "
  SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
  FROM pg_tables
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
  LIMIT 10;"

# Abfrage-Performance mit EXPLAIN analysieren
docker exec postgres psql -U postgres -d deine_datenbank -c "
  EXPLAIN ANALYZE
  SELECT * FROM deine_tabelle WHERE deine_spalte = 'wert';"

# Indizes für häufig abgefragte Spalten erstellen
# In psql oder via n8n Postgres Node:
CREATE INDEX idx_table_column ON deine_tabelle(deine_spalte);

# Tabellen Vacuum und analysieren (Speicher freigeben und Statistiken aktualisieren)
docker exec postgres psql -U postgres -d deine_datenbank -c "VACUUM ANALYZE;"
```

**pgvector-Abfragen geben keine Ergebnisse oder Fehler zurück:**

```bash
# Prüfen ob pgvector-Erweiterung aktiviert ist
docker exec postgres psql -U postgres -d deine_datenbank -c "
  SELECT * FROM pg_extension WHERE extname = 'vector';"

# Falls nicht aktiviert, aktivieren:
docker exec postgres psql -U postgres -d deine_datenbank -c "CREATE EXTENSION vector;"

# Vektor-Spalten-Dimension verifizieren
docker exec postgres psql -U postgres -d deine_datenbank -c "
  SELECT column_name, data_type, udt_name
  FROM information_schema.columns
  WHERE table_name = 'deine_tabelle' AND data_type = 'USER-DEFINED';"

# Prüfen ob HNSW-Index existiert und gültig ist
docker exec postgres psql -U postgres -d deine_datenbank -c "
  SELECT indexname, indexdef
  FROM pg_indexes
  WHERE tablename = 'deine_tabelle';"

# Index neu erstellen falls korrupt
docker exec postgres psql -U postgres -d deine_datenbank -c "
  REINDEX INDEX dein_index_name;"
```

**Häufige Probleme:**
- **Falsche Vektor-Dimension**: Stelle sicher dass Embedding-Dimension mit Spalten-Definition übereinstimmt (z.B. `VECTOR(1536)`)
- **Fehlender Index**: Erstelle HNSW oder IVFFlat Index für schnelle Suchen
- **Distanz-Operator**: Verwende `<=>` für Cosinus-Distanz (am häufigsten für Embeddings)
- **JSONB-Konvertierung**: Wenn Embeddings von n8n übergeben werden, sind sie bereits JSON-Arrays und Postgres konvertiert sie automatisch

**Speicher voll während Vacuum:**

```bash
# PostgreSQL 17 hat verbessertes Vacuum-Speichermanagement
# Aber bei anhaltenden Problemen:

# Aktuelle maintenance_work_mem Einstellung prüfen
docker exec postgres psql -U postgres -c "SHOW maintenance_work_mem;"

# Falls nötig erhöhen (in postgresql.conf oder via ALTER SYSTEM)
docker exec postgres psql -U postgres -c "ALTER SYSTEM SET maintenance_work_mem = '1GB';"

# Konfiguration neu laden
docker exec postgres psql -U postgres -c "SELECT pg_reload_conf();"

# PostgreSQL neu starten
docker compose restart postgres
```

**Versions-Kompatibilitätsprobleme (PostgreSQL 18 vs 17):**

```bash
# PostgreSQL-Version prüfen
docker exec postgres postgres --version

# AI CoreKit ist standardmäßig auf PostgreSQL 17 festgelegt
# Falls du PostgreSQL 18 hast und es behalten möchtest:
echo "POSTGRES_VERSION=18" >> .env

# Falls du inkompatible Daten nach Upgrade hast:
# 1. Daten sichern
docker exec postgres pg_dumpall -U postgres > postgres_backup.sql

# 2. Dienste stoppen
docker compose down

# 3. Volume entfernen
docker volume rm ${PROJECT_NAME:-localai}_postgres_data

# 4. PostgreSQL starten
docker compose up -d postgres
sleep 10

# 5. Daten wiederherstellen
docker exec -i postgres psql -U postgres < postgres_backup.sql

# 6. Alle Dienste starten
docker compose up -d
```

### Ressourcen

- **Offizielle Dokumentation:** https://www.postgresql.org/docs/17/
- **PostgreSQL 17 Release Notes:** https://www.postgresql.org/docs/17/release-17.html
- **pgvector Dokumentation:** https://github.com/pgvector/pgvector
- **pgvector Beispiele:** https://github.com/pgvector/pgvector#examples
- **SQL Tutorial:** https://www.postgresql.org/docs/17/tutorial.html
- **Performance-Tipps:** https://wiki.postgresql.org/wiki/Performance_Optimization
- **n8n Postgres Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/
- **PostgreSQL Community:** https://www.postgresql.org/community/

### Best Practices

**Datenbankdesign:**
- Verwende UUID für Primärschlüssel: `id UUID DEFAULT gen_random_uuid()`
- Füge Zeitstempel hinzu: `created_at TIMESTAMPTZ DEFAULT NOW()`
- Füge immer Indizes auf Fremdschlüssel und häufig abgefragte Spalten hinzu
- Verwende `SERIAL` oder `BIGSERIAL` für auto-inkrementierende IDs
- Normalisiere Daten angemessen (üblicherweise 3NF)

**Vektor-Embeddings:**
- Verwende `text-embedding-3-small` (1536 Dimensionen) für OpenAI Embeddings
- HNSW Index wird für die meisten Anwendungsfälle empfohlen (schnell + genau)
- Normalisiere Embeddings vor der Speicherung für Kosinus-Distanz
- Speichere Metadaten neben Embeddings zum Filtern
- Verwende `VECTOR(dimension)` Spaltentyp passend zu deinem Embedding-Modell

**Performance:**
- Erstelle Indizes auf Spalten die in WHERE, JOIN, ORDER BY verwendet werden
- Verwende Connection Pooling (PgBouncer) für Anwendungen mit hohem Traffic
- Führe `VACUUM ANALYZE` regelmäßig aus (oder aktiviere autovacuum)
- Überwache mit `pg_stat_statements` Erweiterung
- Verwende Prepared Statements in n8n für wiederholte Abfragen

**Sicherheit:**
- Verwende Row Level Security (RLS) für Multi-Tenant-Anwendungen
- Speichere niemals Klartext-Passwörter (verwende `pgcrypto` Erweiterung)
- Verwende das Prinzip der minimalen Rechte für Datenbankbenutzer
- Aktiviere SSL für externe Produktionsverbindungen
- Sichere regelmäßig mit `pg_dump` oder `pg_basebackup`

**Backup-Strategie:**
```bash
# Tägliches automatisches Backup-Skript
docker exec postgres pg_dump -U postgres -d deine_datenbank -F c > backup_$(date +%Y%m%d).dump

# Aus Backup wiederherstellen
docker exec -i postgres pg_restore -U postgres -d deine_datenbank < backup_YYYYMMDD.dump

# Vollständiges Cluster-Backup
docker exec postgres pg_dumpall -U postgres > full_backup_$(date +%Y%m%d).sql
```
