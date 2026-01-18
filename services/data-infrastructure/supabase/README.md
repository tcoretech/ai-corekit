### What is Supabase?

Supabase is a comprehensive open-source backend-as-a-service (BaaS) platform built on PostgreSQL. It provides everything you need to build production-ready applications: database, authentication, real-time subscriptions, storage, edge functions, and vector embeddings for AI features. Often called the "open-source Firebase alternative," Supabase gives you full control over your data while maintaining the ease of use of managed services.

The self-hosted Supabase stack in AI CoreKit includes PostgreSQL 17 with pgvector extension, PostgREST (auto-generated REST API), GoTrue (JWT-based authentication), Realtime server (WebSocket subscriptions), Storage API (S3-compatible file storage), and Supabase Studio (web dashboard).

### Features

- ✅ **PostgreSQL 17 Database** - World's most trusted relational database with full SQL support
- ✅ **Auto-Generated REST API** - Instant RESTful API from your database schema via PostgREST
- ✅ **Real-Time Subscriptions** - WebSocket-based live data sync for multiplayer experiences
- ✅ **Authentication & Auth** - JWT-based user management with Row Level Security (RLS)
- ✅ **File Storage** - S3-compatible object storage integrated with Postgres permissions
- ✅ **Edge Functions** - Serverless TypeScript functions at the edge (Deno-based)
- ✅ **Vector Embeddings** - pgvector extension for AI semantic search and RAG systems
- ✅ **GraphQL Support** - Optional GraphQL API via pg_graphql extension
- ✅ **Full SQL Access** - Direct PostgreSQL connection for complex queries
- ✅ **Supabase Studio** - Beautiful web dashboard for database management

### Initial Setup

**First Login to Supabase Studio:**

1. Navigate to `https://supabase.yourdomain.com`
2. Login with credentials from `.env`:
   - Username: Value from `DASHBOARD_USERNAME`
   - Password: Value from `DASHBOARD_PASSWORD`
3. You'll see the Supabase Studio dashboard

**Important Credentials (stored in `.env`):**

```bash
# View your Supabase credentials
grep "SUPABASE\|POSTGRES" .env

# Key credentials:
# POSTGRES_PASSWORD - Database admin password
# ANON_KEY - Public API key (safe to use in frontend)
# SERVICE_ROLE_KEY - Admin API key (backend only, bypasses RLS)
# JWT_SECRET - Used for JWT token signing
```

**Create Your First Table:**

1. In Studio, go to **Table Editor** → **New Table**
2. Example: Create a `users` table:
   - Table name: `users`
   - Add columns:
     - `id` (uuid, primary key, default: `gen_random_uuid()`)
     - `email` (text, unique)
     - `name` (text)
     - `created_at` (timestamptz, default: `now()`)
3. Enable Row Level Security (RLS) for data protection
4. Click **Save**

Your table is instantly accessible via REST API!

### n8n Integration Setup

**Create Credentials in n8n:**

1. In n8n, go to **Credentials** → **Add Credential**
2. Search for **Supabase**
3. Fill in:
   - **Host**: `http://supabase-kong:8000` (internal URL)
   - **Service Role Secret**: Copy from `.env` file (`SERVICE_ROLE_KEY`)
4. Click **Save**

**For external access (from outside Docker network):**
- **Host**: `https://supabase.yourdomain.com`
- Use the same Service Role Key

**Internal URLs for n8n:**
- **REST API**: `http://supabase-kong:8000/rest/v1/`
- **Auth API**: `http://supabase-kong:8000/auth/v1/`
- **Storage API**: `http://supabase-kong:8000/storage/v1/`
- **Realtime**: `ws://supabase-realtime:4000/socket`

### Email Configuration

Supabase automatically integrates with AI CoreKit's mail system for authentication-related emails:

**Automated Email Features:**
- ✅ **User Registration Confirmations** - Welcome emails with verification links
- ✅ **Password Reset Emails** - Secure reset links sent to users
- ✅ **Magic Link Authentication** - Passwordless login via email
- ✅ **Email Change Confirmations** - Verify new email addresses

**Mail System Integration:**

The email configuration is **automatic** - no manual setup required! Supabase uses the mail system configured in your `.env` file:

- **Development (Mailpit)**: All emails captured in Mailpit UI at `https://mail.yourdomain.com`
- **Production (Docker-Mailserver)**: Real emails delivered via your domain

**Email Templates:**

Customize email templates in Supabase Studio:
1. Go to **Authentication** → **Email Templates**
2. Edit templates for:
   - Confirmation email
   - Invite user
   - Magic Link
   - Change Email
   - Reset Password
3. Use template variables: `{{ .ConfirmationURL }}`, `{{ .Token }}`, `{{ .Email }}`

**SMTP Settings (Pre-configured):**

These are automatically set from your `.env` file:

```bash
# Mailpit (Development) - Default
SMTP_HOST=mailpit
SMTP_PORT=1025
SMTP_USER=admin
SMTP_ADMIN_EMAIL=noreply@yourdomain.com

# Docker-Mailserver (Production) - If selected during install
SMTP_HOST=mailserver
SMTP_PORT=587
SMTP_USER=noreply@yourdomain.com
SMTP_SECURE=true
```

**Testing Email Flow:**

```javascript
// n8n Workflow: Test Supabase Auth Emails

// 1. HTTP Request Node - Create Test User
Method: POST
URL: http://supabase-kong:8000/auth/v1/admin/users
Headers:
  apikey: {{ $env.SERVICE_ROLE_KEY }}
  Authorization: Bearer {{ $env.SERVICE_ROLE_KEY }}
  Content-Type: application/json
Body:
{
  "email": "test@yourdomain.com",
  "email_confirm": false,
  "password": "TestPass123!"
}

// User receives confirmation email automatically!

// 2. Check Mailpit (Development)
// Open: https://mail.yourdomain.com
// See confirmation email in inbox

// 3. HTTP Request Node - Trigger Password Reset
Method: POST  
URL: http://supabase-kong:8000/auth/v1/recover
Headers:
  apikey: {{ $env.ANON_KEY }}
  Content-Type: application/json
Body:
{
  "email": "test@yourdomain.com"
}

// Password reset email sent automatically!
```

### Integration with Other Services

#### Metabase Analytics Integration

Connect Supabase as a data source in Metabase for powerful analytics:

**Setup in Metabase:**

1. Navigate to `https://analytics.yourdomain.com`
2. Click **Add Database**
3. Select **PostgreSQL**
4. Configure connection:
   ```
   Database Type: PostgreSQL
   Name: Supabase
   Host: supabase-db
   Port: 5432
   Database name: postgres
   Username: postgres
   Password: [Check POSTGRES_PASSWORD in .env]
   SSL: Not required (internal network)
   ```
5. Click **Save**

**Use Cases:**
- Analyze user behavior and signups
- Track API usage patterns
- Monitor database growth
- Create custom application dashboards
- Real-time metrics on authentication events

**Example Metabase Query:**

```sql
-- Daily User Signups
SELECT 
  DATE(created_at) as signup_date,
  COUNT(*) as new_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users
FROM auth.users
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY signup_date DESC;

-- Most Active Tables
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

### Example Workflows

#### Example 1: Create User and Store in Supabase

```javascript
// Complete user registration workflow

// 1. Webhook Trigger - Receive registration data
// POST to webhook with:
{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "secure_password"
}

// 2. Supabase Node - Create Auth User
Credential: Supabase
Resource: Row
Operation: Insert
Table: auth.users (or use Auth API)

// Better approach: Use HTTP Request for Auth API
Method: POST
URL: http://supabase-kong:8000/auth/v1/signup
Authentication: None
Send Headers: Yes
Headers:
  - apikey: {{ $credentials.SERVICE_ROLE_KEY }}
  - Content-Type: application/json
Send Body: Yes
Body Content Type: JSON
{
  "email": "{{ $json.email }}",
  "password": "{{ $json.password }}",
  "email_confirm": true
}

// Response includes user ID and JWT token

// 3. Supabase Node - Insert User Profile
Credential: Supabase
Resource: Row
Operation: Insert
Table: users
Columns:
  - id: {{ $json.user.id }}
  - email: {{ $json.email }}
  - name: {{ $json.name }}

// 4. Send Welcome Email
// Use your preferred email node (Gmail, SendGrid, Mailpit)
```

#### Example 2: Real-Time Data Sync to External API

```javascript
// Sync Supabase data changes to external system

// 1. Schedule Trigger
// Runs every 5 minutes to check for new records

// 2. Supabase Node - Get New Records
Credential: Supabase
Resource: Row
Operation: Get All
Table: orders
Filters:
  - Column: synced
  - Operator: is
  - Value: false
  - Column: created_at
  - Operator: gt (greater than)
  - Value: {{ $now.minus({ minutes: 10 }).toISO() }}

// 3. Loop Over Items Node
// Process each new order

// 4. HTTP Request Node - Send to External API
Method: POST
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

// 5. IF Node - Check if successful
{{ $json.statusCode === 200 }}

// 6. Supabase Node - Mark as Synced (if successful)
Credential: Supabase
Resource: Row
Operation: Update
Table: orders
Update Key: id
Update Value: {{ $json.id }}
Columns:
  - synced: true
  - synced_at: {{ $now.toISO() }}

// 7. Error Handling (if failed)
// Log error to separate table or send alert
```

#### Example 3: File Upload to Supabase Storage

```javascript
// Upload files from external sources to Supabase Storage

// 1. HTTP Request Node - Download File
Method: GET
URL: {{ $json.file_url }}
Response Format: File
Binary Property: data

// 2. HTTP Request Node - Upload to Supabase Storage
Method: POST
URL: http://supabase-kong:8000/storage/v1/object/documents/{{ $json.fileName }}
Authentication: None
Send Headers: Yes
Headers:
  - apikey: {{ $credentials.SERVICE_ROLE_KEY }}
  - Authorization: Bearer {{ $credentials.SERVICE_ROLE_KEY }}
  - Content-Type: {{ $binary.data.mimeType }}
Send Body: Yes
Body Content Type: RAW/Custom
Body: {{ $binary.data }}

// Response:
{
  "Key": "documents/example.pdf",
  "Id": "uuid-here"
}

// 3. Supabase Node - Store File Metadata
Credential: Supabase
Resource: Row
Operation: Insert
Table: file_metadata
Columns:
  - storage_path: documents/{{ $json.fileName }}
  - original_url: {{ $json.file_url }}
  - mime_type: {{ $binary.data.mimeType }}
  - size_bytes: {{ $binary.data.fileSize }}
  - uploaded_at: {{ $now.toISO() }}

// 4. Generate Public URL (if bucket is public)
// URL format: https://supabase.yourdomain.com/storage/v1/object/public/documents/filename.pdf
```

#### Example 4: Vector Embeddings for AI Search

```javascript
// Create semantic search using Supabase pgvector

// 1. Webhook Trigger - Receive document text
{
  "title": "Getting Started with n8n",
  "content": "n8n is a workflow automation tool..."
}

// 2. OpenAI Node - Generate Embedding
Operation: Create Embeddings
Model: text-embedding-3-small
Input: {{ $json.content }}

// Response: Array of 1536 dimensions

// 3. Supabase Node - Store Document with Embedding
Credential: Supabase
Resource: Row
Operation: Insert
Table: documents
Columns:
  - title: {{ $json.title }}
  - content: {{ $json.content }}
  - embedding: {{ JSON.stringify($json.data[0].embedding) }}

// Note: Table must have vector column:
// CREATE TABLE documents (
//   id bigserial primary key,
//   title text,
//   content text,
//   embedding vector(1536)
// );

// 4. For Searching: Use SQL Function
// Create in Supabase Studio SQL Editor:
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

// 5. HTTP Request Node - Search via RPC
Method: POST
URL: http://supabase-kong:8000/rest/v1/rpc/search_documents
Headers:
  - apikey: {{ $credentials.SERVICE_ROLE_KEY }}
  - Content-Type: application/json
Body:
{
  "query_embedding": {{ JSON.stringify($json.embedding) }},
  "match_threshold": 0.7,
  "match_count": 5
}

// Returns top 5 most similar documents
```

#### Example 5: Real-Time Webhook from Database Changes

```javascript
// Trigger workflow when Supabase data changes

// 1. Enable Realtime in Supabase Studio:
// - Go to Database → Replication
// - Add table 'orders' to publication 'supabase_realtime'

// 2. In n8n: Use Webhook Trigger
// Set up webhook URL: https://n8n.yourdomain.com/webhook/supabase-orders

// 3. Create Database Function in Supabase:
CREATE OR REPLACE FUNCTION notify_n8n_on_order()
RETURNS trigger AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://n8n.yourdomain.com/webhook/supabase-orders',
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

// 4. Create Trigger:
CREATE TRIGGER order_changes
  AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_n8n_on_order();

// 5. n8n Workflow processes webhook automatically
// - Check $json.event (INSERT, UPDATE, DELETE)
// - Access new data in $json.record
// - Send email, update external systems, etc.
```

### Advanced Use Cases

#### Row Level Security (RLS) Setup

Secure your data with PostgreSQL Row Level Security:

```sql
-- Enable RLS on table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own documents
CREATE POLICY "Users can view own documents"
ON documents FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own documents
CREATE POLICY "Users can create own documents"
ON documents FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Admin can see everything
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

#### Database Functions for Complex Logic

```sql
-- Function: Get user statistics
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

-- Call from n8n using HTTP Request:
// POST http://supabase-kong:8000/rest/v1/rpc/get_user_stats
// Body: {"user_uuid": "uuid-here"}
```

### Troubleshooting

**Connection refused / Service not reachable:**

```bash
# Check if Supabase services are running
docker ps | grep supabase

# Should see: supabase-db, supabase-kong, supabase-auth, 
#             supabase-rest, supabase-storage, supabase-realtime, supabase-studio

# Check logs for errors
docker logs supabase-kong --tail 50
docker logs supabase-db --tail 50

# Restart Supabase services
docker compose restart supabase-kong supabase-db supabase-auth supabase-rest
```

**Authentication errors (JWT invalid):**

```bash
# Verify JWT_SECRET matches across all services
grep JWT_SECRET .env

# Check that SERVICE_ROLE_KEY is correct
docker exec supabase-db psql -U postgres -c "SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'jwt_secret';"

# Test API authentication
curl -X GET 'http://localhost:8000/rest/v1/users' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# If 401 Unauthorized, regenerate secrets and restart services
```

**Row Level Security blocking queries:**

```bash
# Issue: Getting empty results even though data exists
# Reason: RLS policies preventing access

# Solution 1: Use SERVICE_ROLE_KEY (bypasses RLS)
# In n8n, use SERVICE_ROLE_KEY instead of ANON_KEY

# Solution 2: Fix RLS policies
# Check policies in Supabase Studio:
# Database → Tables → [table] → Policies

# Solution 3: Temporarily disable RLS for debugging
# In Supabase Studio SQL Editor:
ALTER TABLE your_table DISABLE ROW LEVEL SECURITY;
# WARNING: Only for debugging, re-enable for production!
```

**Vector search not working:**

```bash
# Enable pgvector extension
docker exec supabase-db psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Verify extension is installed
docker exec supabase-db psql -U postgres -c "\dx vector"

# Check vector column type
docker exec supabase-db psql -U postgres -c "\d+ documents"
# Should show: embedding | vector(1536)

# Test vector similarity query
docker exec supabase-db psql -U postgres -d postgres -c "
SELECT id, title, 
       embedding <=> '[0,0,0,...]'::vector AS distance 
FROM documents 
ORDER BY distance 
LIMIT 5;"
```

**Storage upload fails:**

```bash
# Check storage bucket exists
# Supabase Studio → Storage → Buckets

# Create bucket via SQL if needed:
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

# Check file size limits (default: 50MB)
# In .env:
STORAGE_FILE_SIZE_LIMIT=52428800

# Verify S3-compatible storage is configured
docker exec supabase-storage env | grep STORAGE

# Test upload via curl
curl -X POST 'http://localhost:8000/storage/v1/object/documents/test.txt' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: text/plain" \
  --data-binary "Test file content"
```

**Database migrations not applying:**

```bash
# Check migration status
docker exec supabase-db psql -U postgres -c "SELECT * FROM supabase_migrations.schema_migrations;"

# Manually run migrations
cd ai-corekit
docker exec -i supabase-db psql -U postgres < supabase/migrations/your_migration.sql

# Reset database (WARNING: Deletes all data!)
docker compose down supabase-db
docker volume rm ai-corekit_supabase_db_data
docker compose up -d supabase-db
```

**Supabase Pooler keeps restarting:**

```bash
# Issue: supabase-pooler component keeps restarting
# This is a known issue with certain configurations

# Solution: Follow the workaround from GitHub
# https://github.com/supabase/supabase/issues/30210#issuecomment-2456955578

# Check pooler logs for specific error
docker logs supabase-pooler --tail 100

# Temporary workaround: Disable pooler if not needed
# Comment out supabase-pooler in docker-compose.yml
# Most use cases don't require the pooler
```

**Supabase Analytics fails to start:**

```bash
# Issue: supabase-analytics component fails after changing Postgres password
# This happens because Analytics stores password hash

# ⚠️ WARNING: This solution will delete all Analytics data!

# Solution: Reset Analytics data
docker compose down supabase-analytics
docker volume rm ai-corekit_supabase_analytics_data
docker compose up -d supabase-analytics

# Alternative: Keep old password for Postgres
# Or don't change password after initial setup
```

**Services cannot connect to Supabase:**

```bash
# Issue: n8n or other services get "connection refused"
# Common cause: Special characters in POSTGRES_PASSWORD

# Check current password
grep POSTGRES_PASSWORD .env

# If password contains special characters like @ # $ % etc:
# 1. Generate new password without special characters
NEW_PASS=$(openssl rand -base64 32 | tr -d '/@+=' | head -c 24)
echo "New password: $NEW_PASS"

# 2. Update .env file
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASS/" .env

# 3. Restart all Supabase services
docker compose down supabase-db supabase-auth supabase-rest supabase-storage
docker compose up -d supabase-db supabase-auth supabase-rest supabase-storage

# 4. Test connection from n8n
docker exec n8n ping supabase-db
docker exec n8n nc -zv supabase-db 5432
```

### Performance Tips

**Optimize Queries:**

```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Use EXPLAIN to analyze query performance
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 'uuid-here';

-- For vector search, use HNSW index (faster than IVFFlat)
CREATE INDEX ON documents 
USING hnsw (embedding vector_cosine_ops);
```

**Connection Pooling:**

Supabase includes connection pooling via Supavisor, but for high-traffic n8n workflows:

```javascript
// Use connection pooling in n8n
// Instead of multiple Supabase nodes, batch operations:

// ❌ Slow: Loop with individual inserts
// Loop over 100 items → Supabase Insert (100 DB connections)

// ✅ Fast: Single batch insert
// HTTP Request to /rest/v1/table with array of objects
Method: POST
URL: http://supabase-kong:8000/rest/v1/orders
Body: {{ JSON.stringify($items().map(item => item.json)) }}
```

**Caching:**

```sql
-- Use materialized views for expensive queries
CREATE MATERIALIZED VIEW user_stats AS
SELECT 
  user_id,
  COUNT(*) as total_orders,
  SUM(total) as total_spent
FROM orders
GROUP BY user_id;

-- Refresh periodically with pg_cron
SELECT cron.schedule('refresh-user-stats', '0 */6 * * *', 
  'REFRESH MATERIALIZED VIEW user_stats;');

-- Query the view instead of raw table (much faster)
SELECT * FROM user_stats WHERE user_id = 'uuid';
```

### Resources

- **Official Documentation:** https://supabase.com/docs
- **Self-Hosting Guide:** https://supabase.com/docs/guides/self-hosting/docker
- **API Reference:** https://supabase.com/docs/reference/javascript/introduction
- **REST API:** https://supabase.com/docs/guides/api
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

**Security:**
- Always use SERVICE_ROLE_KEY only in backend workflows (n8n)
- Use ANON_KEY for frontend applications with RLS enabled
- Enable Row Level Security on all tables
- Never expose SERVICE_ROLE_KEY in client-side code
- Regularly rotate JWT secrets in production

**Database Design:**
- Use UUID for primary keys: `id uuid DEFAULT gen_random_uuid()`
- Add `created_at` and `updated_at` timestamps
- Enable RLS from the start (harder to add later)
- Use foreign key constraints for referential integrity
- Index frequently queried columns

**API Usage:**
- Use bulk operations instead of loops (faster, fewer connections)
- Implement pagination for large datasets (`range` header)
- Use `select` parameter to fetch only needed columns
- Leverage PostgreSQL functions for complex logic (runs server-side)
- Cache expensive queries using materialized views

**Vector Embeddings:**
- Use `text-embedding-3-small` (1536 dimensions) for balance of quality/cost
- Store embeddings as `halfvec` type to save 50% space
- Use HNSW index for fast similarity search
- Normalize embeddings before storage (use OpenAI's `dimensions` parameter)
- Batch embed multiple documents to reduce API calls

**Monitoring:**
- Monitor database size: `docker exec supabase-db psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('postgres'));"`
- Check connection count: `SELECT count(*) FROM pg_stat_activity;`
- Enable query logging for slow queries
- Set up alerts for disk space and connection limits
- Use Supabase Studio dashboard to monitor performance
