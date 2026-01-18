### What is PostgreSQL?

PostgreSQL (also known as Postgres) is the world's most advanced open-source relational database. AI CoreKit uses PostgreSQL 17, which brings significant performance improvements, enhanced JSON capabilities, and better support for AI workloads through extensions like pgvector. PostgreSQL serves as the primary database for n8n, Cal.com, Supabase, and many other services in the stack.

PostgreSQL 17 includes overhauled memory management (up to 20x less RAM for vacuum operations), 2x faster bulk exports, improved logical replication for high availability, and SQL/JSON support with the JSON_TABLE function for converting JSON to relational tables.

### Features

- ✅ **PostgreSQL 17** - Latest version with improved performance and scalability
- ✅ **ACID Compliance** - Full transaction support with data integrity guarantees
- ✅ **Advanced SQL** - Support for JSON, arrays, full-text search, window functions
- ✅ **pgvector Extension** - Store and query vector embeddings for AI/ML applications
- ✅ **Logical Replication** - Real-time data replication with failover support
- ✅ **Row Level Security** - Fine-grained access control at the row level
- ✅ **JSON/JSONB Support** - Native JSON storage with indexing and querying
- ✅ **Full-Text Search** - Built-in text search without external services
- ✅ **Foreign Data Wrappers** - Connect to external data sources (MySQL, MongoDB, etc.)
- ✅ **Stored Procedures** - Complex business logic in SQL, PL/pgSQL, Python, JavaScript

### Initial Setup

PostgreSQL is automatically installed and configured during AI CoreKit installation.

**Access PostgreSQL:**

```bash
# Access PostgreSQL CLI
docker exec -it postgres psql -U postgres

# Or connect as a specific database user
docker exec -it postgres psql -U n8n -d n8n
```

**Important Credentials (stored in `.env`):**

```bash
# View PostgreSQL credentials
grep "POSTGRES" .env

# Key variables:
# POSTGRES_USER - Admin username (default: postgres)
# POSTGRES_PASSWORD - Admin password
# POSTGRES_DB - Default database name
```

**Create Your First Database:**

```sql
-- Connect to PostgreSQL
docker exec -it postgres psql -U postgres

-- Create a new database
CREATE DATABASE myapp;

-- Create a user
CREATE USER myapp_user WITH PASSWORD 'secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;

-- Enable pgvector extension (for AI/vector operations)
\c myapp
CREATE EXTENSION vector;

-- Verify pgvector is enabled
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### n8n Integration Setup

PostgreSQL is accessible from n8n using internal Docker networking.

**Internal URL for n8n:** `http://postgres:5432`

**Create PostgreSQL Credentials in n8n:**

1. In n8n, go to **Credentials** → **New Credential**
2. Search for **Postgres**
3. Fill in:
   - **Host:** `postgres` (internal Docker hostname)
   - **Database:** Your database name (e.g., `n8n`, `postgres`, or custom DB)
   - **User:** Database user (e.g., `postgres` or `n8n`)
   - **Password:** From `.env` file (`POSTGRES_PASSWORD`)
   - **Port:** `5432` (default)
   - **SSL:** Disable (not needed for internal connections)

### Example Workflows

#### Example 1: Customer Data Pipeline with PostgreSQL

```javascript
// Store customer data in PostgreSQL and trigger actions on changes

// 1. Webhook Trigger - Receive new customer signup

// 2. Postgres Node - Insert customer record
Operation: Insert
Table: customers
Columns: name, email, company, created_at
Values:
  name: {{$json.name}}
  email: {{$json.email}}
  company: {{$json.company}}
  created_at: {{$now.toISO()}}
Return Fields: * (return all columns including ID)

// 3. Code Node - Generate welcome email content
const customer = $input.item.json;

return {
  customerId: customer.id,
  subject: `Welcome to our platform, ${customer.name}!`,
  body: `Hi ${customer.name},\n\nWe're excited to have ${customer.company} on board!\n\nBest regards,\nThe Team`,
  email: customer.email
};

// 4. SMTP Node - Send welcome email
To: {{$json.email}}
Subject: {{$json.subject}}
Message: {{$json.body}}

// 5. Postgres Node - Update customer status
Operation: Update
Table: customers
Where: id = {{$('Insert Customer').json.id}}
Columns: status, welcome_email_sent_at
Values:
  status: active
  welcome_email_sent_at: {{$now.toISO()}}
```

#### Example 2: Vector Search for Semantic Document Retrieval (RAG)

```javascript
// Use pgvector to store and search document embeddings

// 1. HTTP Request - Fetch documents from API or Webhook

// 2. Loop Over Documents

// 3. OpenAI Node - Generate embedding for each document
Model: text-embedding-3-small (outputs 1536-dimensional vector)
Input: {{$json.content}}

// 4. Postgres Node - Store document with embedding
Operation: Execute Query
Query: |
  INSERT INTO documents (title, content, embedding, created_at)
  VALUES (
    $1,
    $2,
    $3::vector,
    NOW()
  )
  RETURNING id;
Parameters:
  $1: {{$json.title}}
  $2: {{$json.content}}
  $3: {{$json.embedding}}  -- OpenAI returns JSON array, Postgres converts it

// 5. Search Trigger (Webhook or Schedule)

// 6. OpenAI Node - Generate embedding for search query
Model: text-embedding-3-small
Input: {{$json.search_query}}

// 7. Postgres Node - Semantic search using pgvector
Operation: Execute Query
Query: |
  SELECT 
    id,
    title,
    content,
    1 - (embedding <=> $1::vector) AS similarity_score
  FROM documents
  WHERE 1 - (embedding <=> $1::vector) > 0.7  -- similarity threshold
  ORDER BY embedding <=> $1::vector  -- cosine distance
  LIMIT 5;
Parameters:
  $1: {{$json.embedding}}  -- query embedding

// Returns top 5 most semantically similar documents
// <=> operator is cosine distance (0 = identical, 2 = opposite)
```

#### Example 3: Real-Time Data Sync with Database Triggers

```javascript
// Use PostgreSQL triggers to automatically notify n8n of data changes

// Step 1: Create notification function in PostgreSQL
// Run this SQL in your database:

CREATE OR REPLACE FUNCTION notify_n8n_on_order()
RETURNS TRIGGER AS $$
DECLARE
  payload JSON;
BEGIN
  -- Build JSON payload
  payload := json_build_object(
    'event', TG_OP,  -- INSERT, UPDATE, DELETE
    'table', TG_TABLE_NAME,
    'record', row_to_json(NEW),
    'old_record', row_to_json(OLD)
  );
  
  -- Send webhook notification
  PERFORM pg_notify('order_changes', payload::text);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

// Step 2: Create trigger
CREATE TRIGGER order_changes
  AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_n8n_on_order();

// Step 3: n8n Workflow with Postgres Trigger Node
// 1. Postgres Trigger Node
Database: your_database
Channel: order_changes  -- matches pg_notify channel name
// This node listens for PostgreSQL NOTIFY events

// 2. Code Node - Process the trigger event
const event = JSON.parse($input.item.json.payload);

return {
  eventType: event.event,  // INSERT, UPDATE, DELETE
  tableName: event.table,
  newData: event.record,
  oldData: event.old_record,
  timestamp: new Date().toISOString()
};

// 3. IF Node - Route based on event type
{{$json.eventType}} equals 'INSERT'

// 4. Different actions for each event type
// - INSERT: Send "New Order" notification
// - UPDATE: Check if status changed, send update
// - DELETE: Log cancellation, send refund workflow
```

### Advanced Use Cases

#### Setting Up pgvector for AI Applications

```sql
-- Enable pgvector extension
CREATE EXTENSION vector;

-- Create table with vector column
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  title TEXT,
  content TEXT,
  embedding VECTOR(1536),  -- 1536 dimensions for OpenAI text-embedding-3-small
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create HNSW index for fast similarity search
-- HNSW is recommended for most use cases (fast and accurate)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

-- Alternative: IVFFlat index (good for very large datasets)
-- CREATE INDEX ON documents USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);

-- Insert document with embedding (example)
INSERT INTO documents (title, content, embedding)
VALUES (
  'PostgreSQL Guide',
  'PostgreSQL is a powerful database...',
  '[0.1, 0.2, -0.3, ...]'::vector  -- Your 1536-dimensional embedding
);

-- Semantic search query
SELECT 
  id,
  title,
  content,
  1 - (embedding <=> '[0.1, 0.2, ...]'::vector) AS similarity
FROM documents
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector  -- cosine distance
LIMIT 5;
```

**Distance Operators:**
- `<->` - Euclidean distance (L2)
- `<=>` - Cosine distance (recommended for embeddings)
- `<#>` - Negative inner product (for max inner product search)

**Index Types:**
- **HNSW**: Best for most cases, faster queries, more accurate
- **IVFFlat**: Better for very large datasets (>1M rows), uses less memory

#### Row Level Security (RLS) for Multi-Tenant Applications

```sql
-- Enable RLS on table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own documents
CREATE POLICY "users_own_documents"
ON documents
FOR ALL
USING (user_id = current_user_id());

-- Policy: Admins can see everything
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

-- Function to get current user ID (implement based on your auth system)
CREATE OR REPLACE FUNCTION current_user_id()
RETURNS UUID AS $$
BEGIN
  RETURN current_setting('app.user_id')::UUID;
END;
$$ LANGUAGE plpgsql STABLE;

-- Set user ID in session (from n8n or application)
-- SET app.user_id = 'user-uuid-here';
```

#### Database Functions for Complex Logic

```sql
-- Create function to calculate order total with tax
CREATE OR REPLACE FUNCTION calculate_order_total(
  order_id_param INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
  subtotal NUMERIC;
  tax_rate NUMERIC := 0.08;  -- 8% tax
  total NUMERIC;
BEGIN
  -- Calculate subtotal
  SELECT SUM(quantity * price) INTO subtotal
  FROM order_items
  WHERE order_id = order_id_param;
  
  -- Calculate total with tax
  total := subtotal * (1 + tax_rate);
  
  RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Call function from n8n:
// Postgres Node - Execute Query
SELECT calculate_order_total(123) AS total;

-- Or create a trigger to automatically update totals:
CREATE TRIGGER update_order_total
  AFTER INSERT OR UPDATE OR DELETE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_order_total();
```

### Troubleshooting

**Connection refused / Cannot connect to database:**

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs postgres --tail 100

# Restart PostgreSQL
docker compose restart postgres

# Test connection from host
docker exec postgres pg_isready -U postgres
# Should return: postgres:5432 - accepting connections

# Test connection from n8n container
docker exec n8n ping postgres
# Should successfully ping the postgres container
```

**Database queries are slow:**

```bash
# Check active connections and queries
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"

# Check table sizes
docker exec postgres psql -U postgres -c "
  SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
  FROM pg_tables
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
  LIMIT 10;"

# Analyze query performance with EXPLAIN
docker exec postgres psql -U postgres -d your_database -c "
  EXPLAIN ANALYZE
  SELECT * FROM your_table WHERE your_column = 'value';"

# Create indexes for frequently queried columns
# In psql or via n8n Postgres Node:
CREATE INDEX idx_table_column ON your_table(your_column);

# Vacuum and analyze tables (reclaim space and update statistics)
docker exec postgres psql -U postgres -d your_database -c "VACUUM ANALYZE;"
```

**pgvector queries returning no results or errors:**

```bash
# Check if pgvector extension is enabled
docker exec postgres psql -U postgres -d your_database -c "
  SELECT * FROM pg_extension WHERE extname = 'vector';"

# If not enabled, enable it:
docker exec postgres psql -U postgres -d your_database -c "CREATE EXTENSION vector;"

# Verify vector column dimension
docker exec postgres psql -U postgres -d your_database -c "
  SELECT column_name, data_type, udt_name
  FROM information_schema.columns
  WHERE table_name = 'your_table' AND data_type = 'USER-DEFINED';"

# Check if HNSW index exists and is valid
docker exec postgres psql -U postgres -d your_database -c "
  SELECT indexname, indexdef
  FROM pg_indexes
  WHERE tablename = 'your_table';"

# Rebuild index if corrupted
docker exec postgres psql -U postgres -d your_database -c "
  REINDEX INDEX your_index_name;"
```

**Common issues:**
- **Wrong vector dimension**: Ensure embedding dimension matches column definition (e.g., `VECTOR(1536)`)
- **Missing index**: Create HNSW or IVFFlat index for fast searches
- **Distance operator**: Use `<=>` for cosine distance (most common for embeddings)
- **JSONB conversion**: When passing embeddings from n8n, they're already JSON arrays and Postgres converts them automatically

**Out of memory during vacuum:**

```bash
# PostgreSQL 17 has improved vacuum memory management
# But if still experiencing issues:

# Check current maintenance_work_mem setting
docker exec postgres psql -U postgres -c "SHOW maintenance_work_mem;"

# Increase if needed (in postgresql.conf or via ALTER SYSTEM)
docker exec postgres psql -U postgres -c "ALTER SYSTEM SET maintenance_work_mem = '1GB';"

# Reload configuration
docker exec postgres psql -U postgres -c "SELECT pg_reload_conf();"

# Restart PostgreSQL
docker compose restart postgres
```

**Version compatibility issues (PostgreSQL 18 vs 17):**

```bash
# Check your PostgreSQL version
docker exec postgres postgres --version

# AI CoreKit pins to PostgreSQL 17 by default
# If you have PostgreSQL 18 and want to keep it:
echo "POSTGRES_VERSION=18" >> .env

# If you have incompatible data after upgrade:
# 1. Backup your data
docker exec postgres pg_dumpall -U postgres > postgres_backup.sql

# 2. Stop services
docker compose down

# 3. Remove volume
docker volume rm ${PROJECT_NAME:-localai}_postgres_data

# 4. Start PostgreSQL
docker compose up -d postgres
sleep 10

# 5. Restore data
docker exec -i postgres psql -U postgres < postgres_backup.sql

# 6. Start all services
docker compose up -d
```

### Resources

- **Official Documentation:** https://www.postgresql.org/docs/17/
- **PostgreSQL 17 Release Notes:** https://www.postgresql.org/docs/17/release-17.html
- **pgvector Documentation:** https://github.com/pgvector/pgvector
- **pgvector Examples:** https://github.com/pgvector/pgvector#examples
- **SQL Tutorial:** https://www.postgresql.org/docs/17/tutorial.html
- **Performance Tips:** https://wiki.postgresql.org/wiki/Performance_Optimization
- **n8n Postgres Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/
- **PostgreSQL Community:** https://www.postgresql.org/community/

### Best Practices

**Database Design:**
- Use UUID for primary keys: `id UUID DEFAULT gen_random_uuid()`
- Add timestamps: `created_at TIMESTAMPTZ DEFAULT NOW()`
- Always add indexes on foreign keys and frequently queried columns
- Use `SERIAL` or `BIGSERIAL` for auto-incrementing IDs
- Normalize data appropriately (usually 3NF)

**Vector Embeddings:**
- Use `text-embedding-3-small` (1536 dimensions) for OpenAI embeddings
- HNSW index is recommended for most use cases (fast + accurate)
- Normalize embeddings before storage for cosine distance
- Store metadata alongside embeddings for filtering
- Use `VECTOR(dimension)` column type matching your embedding model

**Performance:**
- Create indexes on columns used in WHERE, JOIN, ORDER BY
- Use connection pooling (PgBouncer) for high-traffic applications
- Run `VACUUM ANALYZE` regularly (or enable autovacuum)
- Monitor with `pg_stat_statements` extension
- Use prepared statements in n8n for repeated queries

**Security:**
- Use Row Level Security (RLS) for multi-tenant applications
- Never store plaintext passwords (use `pgcrypto` extension)
- Use least privilege principle for database users
- Enable SSL for production external connections
- Regularly backup with `pg_dump` or `pg_basebackup`

**Backup Strategy:**
```bash
# Daily automated backup script
docker exec postgres pg_dump -U postgres -d your_database -F c > backup_$(date +%Y%m%d).dump

# Restore from backup
docker exec -i postgres pg_restore -U postgres -d your_database < backup_YYYYMMDD.dump

# Full cluster backup
docker exec postgres pg_dumpall -U postgres > full_backup_$(date +%Y%m%d).sql
```
