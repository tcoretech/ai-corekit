# 🔥 Supabase - Open-Source Firebase-Alternative

### Was ist Supabase?

Supabase ist eine umfassende Open-Source Backend-as-a-Service (BaaS) Plattform, die auf PostgreSQL basiert. Sie bietet alles, was du zum Erstellen produktionsreifer Anwendungen brauchst: Datenbank, Authentifizierung, Echtzeit-Abonnements, Speicher, Edge Functions und Vektor-Embeddings für KI-Funktionen. Oft als "Open-Source Firebase-Alternative" bezeichnet, gibt dir Supabase die volle Kontrolle über deine Daten bei gleichzeitiger Benutzerfreundlichkeit wie bei verwalteten Diensten.

Der selbst gehostete Supabase-Stack im AI CoreKit umfasst PostgreSQL 17 mit pgvector-Erweiterung, PostgREST (automatisch generierte REST-API), GoTrue (JWT-basierte Authentifizierung), Realtime-Server (WebSocket-Abonnements), Storage-API (S3-kompatible Dateispeicherung) und Supabase Studio (Web-Dashboard).

### Features

- ✅ **PostgreSQL 17 Datenbank** - Die vertrauenswürdigste relationale Datenbank der Welt mit voller SQL-Unterstützung
- ✅ **Automatisch generierte REST-API** - Sofortige RESTful-API aus deinem Datenbankschema via PostgREST
- ✅ **Echtzeit-Abonnements** - WebSocket-basierte Live-Datensynchronisation für Multiplayer-Erlebnisse
- ✅ **Authentifizierung & Auth** - JWT-basierte Benutzerverwaltung mit Row Level Security (RLS)
- ✅ **Dateispeicher** - S3-kompatibler Objektspeicher integriert mit Postgres-Berechtigungen
- ✅ **Edge Functions** - Serverlose TypeScript-Funktionen am Edge (Deno-basiert)
- ✅ **Vektor-Embeddings** - pgvector-Erweiterung für KI-semantische Suche und RAG-Systeme
- ✅ **GraphQL-Unterstützung** - Optionale GraphQL-API via pg_graphql-Erweiterung
- ✅ **Vollständiger SQL-Zugriff** - Direkte PostgreSQL-Verbindung für komplexe Abfragen
- ✅ **Supabase Studio** - Schönes Web-Dashboard für Datenbankverwaltung

### Erste Einrichtung

**Erster Login im Supabase Studio:**

1. Navigiere zu `https://supabase.deinedomain.com`
2. Login mit Zugangsdaten aus `.env`:
   - Benutzername: Wert aus `DASHBOARD_USERNAME`
   - Passwort: Wert aus `DASHBOARD_PASSWORD`
3. Du siehst das Supabase Studio Dashboard

**Wichtige Zugangsdaten (gespeichert in `.env`):**

```bash
# Supabase-Zugangsdaten anzeigen
grep "SUPABASE\|POSTGRES" .env

# Wichtige Zugangsdaten:
# POSTGRES_PASSWORD - Datenbank-Admin-Passwort
# ANON_KEY - Öffentlicher API-Schlüssel (sicher für Frontend)
# SERVICE_ROLE_KEY - Admin-API-Schlüssel (nur Backend, umgeht RLS)
# JWT_SECRET - Wird für JWT-Token-Signierung verwendet
```

**Erstelle deine erste Tabelle:**

1. Im Studio, gehe zu **Table Bearbeiteor** → **New Table**
2. Beispiel: Erstelle eine `users` Tabelle:
   - Tabellenname: `users`
   - Spalten hinzufügen:
     - `id` (uuid, primary key, default: `gen_random_uuid()`)
     - `email` (text, unique)
     - `name` (text)
     - `created_at` (timestamptz, default: `now()`)
3. Aktiviere Row Level Security (RLS) für Datenschutz
4. Klicke auf **Save**

Deine Tabelle ist sofort über die REST-API verfügbar!

### n8n-Integration einrichten

**Credentials in n8n erstellen:**

1. In n8n, gehe zu **Credentials** → **Add Credential**
2. Suche nach **Supabase**
3. Fülle aus:
   - **Host**: `http://supabase-kong:8000` (interne URL)
   - **Service Role Secret**: Kopiere aus `.env` Datei (`SERVICE_ROLE_KEY`)
4. Klicke auf **Save**

**Für externen Zugriff (von außerhalb des Docker-Netzwerks):**
- **Host**: `https://supabase.deinedomain.com`
- Verwende denselben Service Role Key

**Interne URLs für n8n:**
- **REST API**: `http://supabase-kong:8000/rest/v1/`
- **Auth API**: `http://supabase-kong:8000/auth/v1/`
- **Storage API**: `http://supabase-kong:8000/storage/v1/`
- **Realtime**: `ws://supabase-realtime:4000/socket`

### E-Mail-Konfiguration

Supabase integriert sich automatisch mit dem Mail-System des AI CoreKit für authentifizierungsbezogene E-Mails:

**Automatisierte E-Mail-Funktionen:**
- ✅ **Benutzerregistrierungs-Bestätigungen** - Willkommens-E-Mails mit Verifizierungslinks
- ✅ **Passwort-Zurücksetzungs-E-Mails** - Sichere Reset-Links an Benutzer
- ✅ **Magic Link Authentifizierung** - Passwortloser Login via E-Mail
- ✅ **E-Mail-Änderungs-Bestätigungen** - Neue E-Mail-Adressen verifizieren

**Mail-System-Integration:**

Die E-Mail-Konfiguration ist **automatisch** - keine manuelle Einrichtung erforderlich! Supabase verwendet das in deiner `.env` Datei konfigurierte Mail-System:

- **Entwicklung (Mailpit)**: Alle E-Mails werden in der Mailpit-UI unter `https://mail.deinedomain.com` erfasst
- **Produktion (Docker-Mailserver)**: Echte E-Mails werden über deine Domain zugestellt

**E-Mail-Vorlagen:**

Passe E-Mail-Vorlagen im Supabase Studio an:
1. Gehe zu **Authentication** → **Email Templates**
2. Bearbeite Vorlagen für:
   - Bestätigungs-E-Mail
   - Benutzer einladen
   - Magic Link
   - E-Mail ändern
   - Passwort zurücksetzen
3. Verwende Template-Variablen: `{{ .ConfirmationURL }}`, `{{ .Token }}`, `{{ .Email }}`

**SMTP-Einstellungen (Vorkonfiguriert):**

Diese werden automatisch aus deiner `.env` Datei gesetzt:

```bash
# Mailpit (Entwicklung) - Standard
SMTP_HOST=mailpit
SMTP_PORT=1025
SMTP_USER=admin
SMTP_ADMIN_EMAIL=noreply@deinedomain.com

# Docker-Mailserver (Produktion) - Falls bei Installation gewählt
SMTP_HOST=mailserver
SMTP_PORT=587
SMTP_USER=noreply@deinedomain.com
SMTP_SECURE=true
```

**E-Mail-Ablauf testen:**

```javascript
// n8n Workflow: Supabase Auth E-Mails testen

// 1. HTTP Request Node - Testbenutzer erstellen
Methode: POST
URL: http://supabase-kong:8000/auth/v1/admin/users
Header:
  apikey: {{ $env.SERVICE_ROLE_KEY }}
  Authorization: Bearer {{ $env.SERVICE_ROLE_KEY }}
  Content-Type: application/json
Body:
{
  "email": "test@deinedomain.com",
  "email_confirm": false,
  "password": "TestPass123!"
}

// Benutzer erhält automatisch Bestätigungs-E-Mail!

// 2. Mailpit überprüfen (Entwicklung)
// Öffne: https://mail.deinedomain.com
// Siehe Bestätigungs-E-Mail im Posteingang

// 3. HTTP Request Node - Passwort-Zurücksetzung auslösen
Methode: POST  
URL: http://supabase-kong:8000/auth/v1/recover
Header:
  apikey: {{ $env.ANON_KEY }}
  Content-Type: application/json
Body:
{
  "email": "test@deinedomain.com"
}

// Passwort-Zurücksetzungs-E-Mail automatisch gesendet!
```

### Integration mit anderen Diensten

#### Metabase Analytics Integration

Verbinde Supabase als Datenquelle in Metabase für leistungsstarke Analysen:

**Einrichtung in Metabase:**

1. Navigiere zu `https://analytics.deinedomain.com`
2. Klicke auf **Add Database**
3. Wähle **PostgreSQL**
4. Konfiguriere die Verbindung:
   ```
   Database Type: PostgreSQL
   Name: Supabase
   Host: supabase-db
   Port: 5432
   Database name: postgres
   Username: postgres
   Password: [Prüfe POSTGRES_PASSWORD in .env]
   SSL: Nicht erforderlich (internes Netzwerk)
   ```
5. Klicke auf **Save**

**Anwendungsfälle:**
- Analysiere Benutzerverhalten und Anmeldungen
- Verfolge API-Nutzungsmuster
- Überwache Datenbankwachstum
- Erstelle benutzerdefinierte Anwendungs-Dashboards
- Echtzeit-Metriken zu Authentifizierungs-Events

**Beispiel Metabase-Abfrage:**

```sql
-- Tägliche Benutzer-Anmeldungen
SELECT 
  DATE(created_at) as signup_date,
  COUNT(*) as new_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users
FROM auth.users
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY signup_date DESC;

-- Aktivste Tabellen
SELECT 
  schemaname,
  tablename,
  n_tup_ins as inserts,
  n_tup_upd as updates,
  n_tup_del as deletes
FROM pg_stat_user_tables
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC
LIMIT 10;
```

### Beispiel-Workflows

#### Beispiel 1: Benutzer erstellen und in Supabase speichern

```javascript
// Vollständiger Benutzerregistrierungs-Workflow

// 1. Webhook Trigger - Registrierungsdaten empfangen
// POST an Webhook mit:
{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "sicheres_passwort"
}

// 2. Supabase Node - Auth-Benutzer erstellen
Credential: Supabase
Resource: Row
Operation: Einfügen
Table: auth.users (oder Auth API verwenden)

// Besserer Ansatz: HTTP Request für Auth API verwenden
Methode: POST
URL: http://supabase-kong:8000/auth/v1/signup
Authentication: None
Send Header: Yes
Header:
  - apikey: {{ $credentials.SERVICE_ROLE_KEY }}
  - Content-Type: application/json
Send Body: Yes
Body Content Type: JSON
{
  "email": "{{ $json.email }}",
  "password": "{{ $json.password }}",
  "email_confirm": true
}

// Antwort enthält Benutzer-ID und JWT-Token

// 3. Supabase Node - Benutzerprofil einfügen
Credential: Supabase
Resource: Row
Operation: Einfügen
Table: users
Columns:
  - id: {{ $json.user.id }}
  - email: {{ $json.email }}
  - name: {{ $json.name }}

// 4. Willkommens-E-Mail senden
// Verwende deinen bevorzugten E-Mail-Node (Gmail, SendGrid, Mailpit)
```

#### Beispiel 2: Echtzeit-Datensynchronisation zu externer API

```javascript
// Supabase-Datenänderungen mit externem System synchronisieren

// 1. Schedule Trigger
// Läuft alle 5 Minuten, um nach neuen Einträgen zu suchen

// 2. Supabase Node - Neue Einträge abrufen
Credential: Supabase
Resource: Row
Operation: Get All
Table: orders
Filters:
  - Column: synced
  - Operator: is
  - Wert: false
  - Column: created_at
  - Operator: gt (greater than)
  - Wert: {{ $now.minus({ minutes: 10 }).toISO() }}

// 3. Loop Over Items Node
// Verarbeite jede neue Bestellung

// 4. HTTP Request Node - An externe API senden
Methode: POST
URL: https://api.external-service.com/orders
Authentication: Bearer Token
Send Body: Yes
Body:
{
  "order_id": "{{ $json.id }}",
  "customer_email": "{{ $json.customer_email }}",
  "total": {{ $json.total }},
  "items": {{ JSON.stringify($json.items) }}
}

// 5. IF Node - Prüfen ob erfolgreich
{{ $json.statusCode === 200 }}

// 6. Supabase Node - Als synchronisiert markieren (falls erfolgreich)
Credential: Supabase
Resource: Row
Operation: Update
Table: orders
Update Key: id
Update Wert: {{ $json.id }}
Columns:
  - synced: true
  - synced_at: {{ $now.toISO() }}

// 7. Fehlerbehandlung (falls fehlgeschlagen)
// Fehler in separate Tabelle protokollieren oder Alarm senden
```

#### Beispiel 3: Datei-Upload zu Supabase Storage

```javascript
// Dateien von externen Quellen zu Supabase Storage hochladen

// 1. HTTP Request Node - Datei herunterladen
Methode: GET
URL: {{ $json.file_url }}
Response Format: File
Binary Property: data

// 2. HTTP Request Node - Zu Supabase Storage hochladen
Methode: POST
URL: http://supabase-kong:8000/storage/v1/object/documents/{{ $json.fileName }}
Authentication: None
Send Header: Yes
Header:
  - apikey: {{ $credentials.SERVICE_ROLE_KEY }}
  - Authorization: Bearer {{ $credentials.SERVICE_ROLE_KEY }}
  - Content-Type: {{ $binary.data.mimeType }}
Send Body: Yes
Body Content Type: RAW/Custom
Body: {{ $binary.data }}

// Antwort:
{
  "Key": "documents/example.pdf",
  "Id": "uuid-here"
}

// 3. Supabase Node - Datei-Metadaten speichern
Credential: Supabase
Resource: Row
Operation: Einfügen
Table: file_metadata
Columns:
  - storage_path: documents/{{ $json.fileName }}
  - original_url: {{ $json.file_url }}
  - mime_type: {{ $binary.data.mimeType }}
  - size_bytes: {{ $binary.data.fileSize }}
  - uploaded_at: {{ $now.toISO() }}

// 4. Öffentliche URL generieren (falls Bucket öffentlich ist)
// URL-Format: https://supabase.deinedomain.com/storage/v1/object/public/documents/filename.pdf
```

#### Beispiel 4: Vektor-Embeddings für KI-Suche

```javascript
// Semantische Suche mit Supabase pgvector erstellen

// 1. Webhook Trigger - Dokumenttext empfangen
{
  "title": "Erste Schritte mit n8n",
  "content": "n8n ist ein Workflow-Automatisierungs-Tool..."
}

// 2. OpenAI Node - Embedding generieren
Operation: Create Embeddings
Modell: text-embedding-3-small
Input: {{ $json.content }}

// Antwort: Array mit 1536 Dimensionen

// 3. Supabase Node - Dokument mit Embedding speichern
Credential: Supabase
Resource: Row
Operation: Einfügen
Table: documents
Columns:
  - title: {{ $json.title }}
  - content: {{ $json.content }}
  - embedding: {{ JSON.stringify($json.data[0].embedding) }}

// Hinweis: Tabelle muss vector-Spalte haben:
// CREATE TABLE documents (
//   id bigserial primary key,
//   title text,
//   content text,
//   embedding vector(1536)
// );

// 4. Zum Suchen: SQL-Funktion verwenden
// Im Supabase Studio SQL Bearbeiteor erstellen:
CREATE OR REPLACE FUNCTION search_documents(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id bigint,
  title text,
  content text,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    id,
    title,
    content,
    1 - (embedding <=> query_embedding) AS similarity
  FROM documents
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;

// 5. HTTP Request Node - Über RPC suchen
Methode: POST
URL: http://supabase-kong:8000/rest/v1/rpc/search_documents
Header:
  - apikey: {{ $credentials.SERVICE_ROLE_KEY }}
  - Content-Type: application/json
Body:
{
  "query_embedding": {{ JSON.stringify($json.embedding) }},
  "match_threshold": 0.7,
  "match_count": 5
}

// Gibt die Top 5 ähnlichsten Dokumente zurück
```

#### Beispiel 5: Echtzeit-Webhook bei Datenbankänderungen

```javascript
// Workflow auslösen wenn sich Supabase-Daten ändern

// 1. Realtime in Supabase Studio aktivieren:
// - Gehe zu Database → Replication
// - Füge Tabelle 'orders' zur Publikation 'supabase_realtime' hinzu

// 2. In n8n: Webhook Trigger verwenden
// Webhook-URL einrichten: https://n8n.deinedomain.com/webhook/supabase-orders

// 3. Datenbank-Funktion in Supabase erstellen:
CREATE OR REPLACE FUNCTION notify_n8n_on_order()
RETURNS trigger AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://n8n.deinedomain.com/webhook/supabase-orders',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'event', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

// 4. Trigger erstellen:
CREATE TRIGGER order_changes
  AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_n8n_on_order();

// 5. n8n Workflow verarbeitet Webhook automatisch
// - Prüfe $json.event (INSERT, UPDATE, DELETE)
// - Greife auf neue Daten in $json.record zu
// - Sende E-Mail, aktualisiere externe Systeme, etc.
```

### Erweiterte Anwendungsfälle

#### Row Level Security (RLS) Einrichtung

Sichere deine Daten mit PostgreSQL Row Level Security:

```sql
-- RLS auf Tabelle aktivieren
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Policy: Benutzer können nur ihre eigenen Dokumente sehen
CREATE POLICY "Users can view own documents"
ON documents FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Benutzer können ihre eigenen Dokumente einfügen
CREATE POLICY "Users can create own documents"
ON documents FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Admin kann alles sehen
CREATE POLICY "Admins can view all"
ON documents FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.uid() = id
    AND raw_user_meta_data->>'role' = 'admin'
  )
);
```

#### Datenbank-Funktionen für komplexe Logik

```sql
-- Funktion: Benutzerstatistiken abrufen
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid uuid)
RETURNS json AS $$
BEGIN
  RETURN json_build_object(
    'total_orders', (SELECT COUNT(*) FROM orders WHERE user_id = user_uuid),
    'total_spent', (SELECT SUM(total) FROM orders WHERE user_id = user_uuid),
    'last_order_date', (SELECT MAX(created_at) FROM orders WHERE user_id = user_uuid)
  );
END;
$$ LANGUAGE plpgsql;

// Aus n8n mit HTTP Request aufrufen:
// POST http://supabase-kong:8000/rest/v1/rpc/get_user_stats
// Body: {"user_uuid": "uuid-here"}
```

### Fehlerbehebung

**Verbindung abgelehnt / Dienst nicht erreichbar:**

```bash
# Prüfen ob Supabase-Dienste laufen
docker ps | grep supabase

# Sollte zeigen: supabase-db, supabase-kong, supabase-auth, 
#             supabase-rest, supabase-storage, supabase-realtime, supabase-studio

# Logs auf Fehler prüfen
docker logs supabase-kong --tail 50
docker logs supabase-db --tail 50

# Supabase-Dienste neu starten
docker compose restart supabase-kong supabase-db supabase-auth supabase-rest
```

**Authentifizierungsfehler (JWT ungültig):**

```bash
# JWT_SECRET über alle Dienste hinweg verifizieren
grep JWT_SECRET .env

# Prüfen dass SERVICE_ROLE_KEY korrekt ist
docker exec supabase-db psql -U postgres -c "SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'jwt_secret';"

# API-Authentifizierung testen
curl -X GET 'http://localhost:8000/rest/v1/users' \
  -H "apikey: DEIN_ANON_KEY" \
  -H "Authorization: Bearer DEIN_ANON_KEY"

# Falls 401 Unauthorized, Secrets neu generieren und Dienste neu starten
```

**Row Level Security blockiert Abfragen:**

```bash
# Problem: Leere Ergebnisse obwohl Daten existieren
# Grund: RLS-Policies verhindern Zugriff

# Lösung 1: SERVICE_ROLE_KEY verwenden (umgeht RLS)
# In n8n, SERVICE_ROLE_KEY statt ANON_KEY verwenden

# Lösung 2: RLS-Policies korrigieren
# Policies in Supabase Studio prüfen:
# Database → Tables → [tabelle] → Policies

# Lösung 3: RLS temporär zum Debuggen deaktivieren
# Im Supabase Studio SQL Bearbeiteor:
ALTER TABLE deine_tabelle DISABLE ROW LEVEL SECURITY;
# WARNUNG: Nur zum Debuggen, für Produktion wieder aktivieren!
```

**Vektorsuche funktioniert nicht:**

```bash
# pgvector-Erweiterung aktivieren
docker exec supabase-db psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Erweiterung ist installiert verifizieren
docker exec supabase-db psql -U postgres -c "\dx vector"

# Vektor-Spaltentyp prüfen
docker exec supabase-db psql -U postgres -c "\d+ documents"
# Sollte zeigen: embedding | vector(1536)

# Vektor-Ähnlichkeitsabfrage testen
docker exec supabase-db psql -U postgres -d postgres -c "
SELECT id, title, 
       embedding <=> '[0,0,0,...]'::vector AS distance 
FROM documents 
ORDER BY distance 
LIMIT 5;"
```

**Storage-Upload schlägt fehl:**

```bash
# Prüfen ob Storage-Bucket existiert
# Supabase Studio → Storage → Buckets

# Bucket via SQL erstellen falls nötig:
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

# Dateigrößen-Limits prüfen (Standard: 50MB)
# In .env:
STORAGE_FILE_SIZE_LIMIT=52428800

# S3-kompatiblen Storage verifizieren ist konfiguriert
docker exec supabase-storage env | grep STORAGE

# Upload via curl testen
curl -X POST 'http://localhost:8000/storage/v1/object/documents/test.txt' \
  -H "apikey: DEIN_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer DEIN_SERVICE_ROLE_KEY" \
  -H "Content-Type: text/plain" \
  --data-binary "Test-Dateiinhalt"
```

**Datenbank-Migrationen werden nicht angewendet:**

```bash
# Migrationsstatus prüfen
docker exec supabase-db psql -U postgres -c "SELECT * FROM supabase_migrations.schema_migrations;"

# Migrationen manuell ausführen
cd ai-corekit
docker exec -i supabase-db psql -U postgres < supabase/migrations/deine_migration.sql

# Datenbank zurücksetzen (WARNUNG: Löscht alle Daten!)
docker compose down supabase-db
docker volume rm ai-corekit_supabase_db_data
docker compose up -d supabase-db
```

**Supabase Pooler startet immer wieder neu:**

```bash
# Problem: supabase-pooler Komponente startet immer wieder neu
# Dies ist ein bekanntes Problem bei bestimmten Konfigurationen

# Lösung: Folge dem Workaround von GitHub
# https://github.com/supabase/supabase/issues/30210#issuecomment-2456955578

# Pooler-Logs auf spezifischen Fehler prüfen
docker logs supabase-pooler --tail 100

# Temporärer Workaround: Pooler deaktivieren falls nicht benötigt
# supabase-pooler in docker-compose.yml auskommentieren
# Die meisten Anwendungsfälle benötigen den Pooler nicht
```

**Supabase Analytics startet nicht:**

```bash
# Problem: supabase-analytics Komponente schlägt fehl nach Änderung des Postgres-Passworts
# Dies passiert weil Analytics den Passwort-Hash speichert

# ⚠️ WARNUNG: Diese Lösung löscht alle Analytics-Daten!

# Lösung: Analytics-Daten zurücksetzen
docker compose down supabase-analytics
docker volume rm ai-corekit_supabase_analytics_data
docker compose up -d supabase-analytics

# Alternative: Altes Passwort für Postgres behalten
# Oder Passwort nach initialer Einrichtung nicht ändern
```

**Dienste können sich nicht mit Supabase verbinden:**

```bash
# Problem: n8n oder andere Dienste erhalten "connection refused"
# Häufige Ursache: Sonderzeichen in POSTGRES_PASSWORD

# Aktuelles Passwort prüfen
grep POSTGRES_PASSWORD .env

# Falls Passwort Sonderzeichen wie @ # $ % etc. enthält:
# 1. Neues Passwort ohne Sonderzeichen generieren
NEW_PASS=$(openssl rand -base64 32 | tr -d '/@+=' | head -c 24)
echo "Neues Passwort: $NEW_PASS"

# 2. .env Datei aktualisieren
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASS/" .env

# 3. Alle Supabase-Dienste neu starten
docker compose down supabase-db supabase-auth supabase-rest supabase-storage
docker compose up -d supabase-db supabase-auth supabase-rest supabase-storage

# 4. Verbindung von n8n aus testen
docker exec n8n ping supabase-db
docker exec n8n nc -zv supabase-db 5432
```

### Performance-Tipps

**Abfragen optimieren:**

```sql
-- Indizes für häufig abgefragte Spalten hinzufügen
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- EXPLAIN verwenden um Abfrage-Performance zu analysieren
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 'uuid-here';

-- Für Vektorsuche, HNSW Index verwenden (schneller als IVFFlat)
CREATE INDEX ON documents 
USING hnsw (embedding vector_cosine_ops);
```

**Connection Pooling:**

Supabase enthält Connection Pooling via Supavisor, aber für n8n-Workflows mit hohem Traffic:

```javascript
// Connection Pooling in n8n verwenden
// Statt mehrerer Supabase Nodes, Operationen bündeln:

// ❌ Langsam: Schleife mit einzelnen Inserts
// Schleife über 100 Items → Supabase Insert (100 DB-Verbindungen)

// ✅ Schnell: Einzelner Batch-Insert
// HTTP Request an /rest/v1/table mit Array von Objekten
Methode: POST
URL: http://supabase-kong:8000/rest/v1/orders
Body: {{ JSON.stringify($items().map(item => item.json)) }}
```

**Caching:**

```sql
-- Materialized Views für teure Abfragen verwenden
CREATE MATERIALIZED VIEW user_stats AS
SELECT 
  user_id,
  COUNT(*) as total_orders,
  SUM(total) as total_spent
FROM orders
GROUP BY user_id;

-- Periodisch mit pg_cron aktualisieren
SELECT cron.schedule('refresh-user-stats', '0 */6 * * *', 
  'REFRESH MATERIALIZED VIEW user_stats;');

-- View statt roher Tabelle abfragen (viel schneller)
SELECT * FROM user_stats WHERE user_id = 'uuid';
```

### Ressourcen

- **Offizielle Dokumentation:** https://supabase.com/docs
- **Self-Hosting Guide:** https://supabase.com/docs/guides/self-hosting/docker
- **API-Referenz:** https://supabase.com/docs/reference/javascript/introduction
- **REST-API:** https://supabase.com/docs/guides/api
- **Realtime Guide:** https://supabase.com/docs/guides/realtime
- **Storage Guide:** https://supabase.com/docs/guides/storage
- **Vector/AI Guide:** https://supabase.com/docs/guides/ai
- **Edge Functions:** https://supabase.com/docs/guides/functions
- **Row Level Security:** https://supabase.com/docs/guides/auth/row-level-security
- **GitHub:** https://github.com/supabase/supabase
- **n8n Integration:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/
- **Community Forum:** https://github.com/supabase/supabase/discussions
- **Discord:** https://discord.supabase.com

### Best Practices

**Sicherheit:**
- Verwende SERVICE_ROLE_KEY immer nur in Backend-Workflows (n8n)
- Verwende ANON_KEY für Frontend-Anwendungen mit aktiviertem RLS
- Aktiviere Row Level Security auf allen Tabellen
- Expose niemals SERVICE_ROLE_KEY in clientseitigem Code
- Rotiere JWT-Secrets regelmäßig in Produktion

**Datenbankdesign:**
- Verwende UUID für Primärschlüssel: `id uuid DEFAULT gen_random_uuid()`
- Füge `created_at` und `updated_at` Zeitstempel hinzu
- Aktiviere RLS von Anfang an (schwieriger später hinzuzufügen)
- Verwende Foreign-Key-Constraints für referenzielle Integrität
- Indiziere häufig abgefragte Spalten

**API-Nutzung:**
- Verwende Bulk-Operationen statt Schleifen (schneller, weniger Verbindungen)
- Implementiere Paginierung für große Datensätze (`range` Header)
- Verwende `select` Parameter um nur benötigte Spalten abzurufen
- Nutze PostgreSQL-Funktionen für komplexe Logik (läuft serverseitig)
- Cache teure Abfragen mit Materialized Views

**Vektor-Embeddings:**
- Verwende `text-embedding-3-small` (1536 Dimensionen) für Balance aus Qualität/Kosten
- Speichere Embeddings als `halfvec` Typ um 50% Speicherplatz zu sparen
- Verwende HNSW Index für schnelle Ähnlichkeitssuche
- Normalisiere Embeddings vor Speicherung (verwende OpenAI's `dimensions` Parameter)
- Bündle mehrere Dokumente beim Embedden um API-Aufrufe zu reduzieren

**Überwachung:**
- Überwache Datenbankgröße: `docker exec supabase-db psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('postgres'));"`
- Prüfe Verbindungsanzahl: `SELECT count(*) FROM pg_stat_activity;`
- Aktiviere Query-Logging für langsame Abfragen
- Richte Alarme für Speicherplatz und Verbindungslimits ein
- Verwende Supabase Studio Dashboard zur Performance-Überwachung
