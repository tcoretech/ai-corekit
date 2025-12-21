# 📈 Metabase - Business Intelligence

### What is Metabase?

Metabase is the most user-friendly open-source business intelligence platform that transforms raw data into actionable insights. Unlike complex BI tools, Metabase features a no-code visual query builder that allows anyone on your team to create dashboards and analyze data. It's perfect for monitoring your entire AI LaunchKit stack, tracking business metrics, and making data-driven decisions without requiring SQL knowledge (though SQL support is available for power users).

### Features

- **No-Code Query Builder:** Drag-and-drop interface for creating charts and dashboards
- **Automatic Insights (X-Ray):** AI-powered data exploration with one click
- **Multi-Database Support:** Connect to PostgreSQL, MySQL, MongoDB, and 20+ databases
- **Beautiful Dashboards:** Customizable, shareable dashboards with real-time updates
- **Scheduled Reports (Pulses):** Automated email/Slack reports on a schedule
- **Public Sharing:** Generate public links for dashboards without authentication
- **Embeddable Charts:** Iframe embedding for external websites
- **SQL Editor:** Full SQL support for advanced users
- **Team Collaboration:** Multi-user access with role-based permissions
- **Mobile-Friendly:** Responsive design works on all devices
- **API Access:** Complete REST API for automation and integration

### Initial Setup

**First Login to Metabase:**

1. Navigate to `https://analytics.yourdomain.com`
2. Complete the setup wizard:
   - Choose your language
   - Create admin account (no pre-configured credentials needed)
   - Set up your organization name
   - Optional: Add your first data source (or skip and add later)
   - Decline usage data collection for privacy
3. Click "Take me to Metabase"

**Important:** Metabase has its own complete user management system with groups and SSO support, so no Basic Auth is configured in Caddy.

### Connect AI LaunchKit Databases

Metabase can connect to all databases in your AI LaunchKit installation for comprehensive analytics:

#### n8n Workflows Database (PostgreSQL)

```
Database Type: PostgreSQL
Host: postgres
Port: 5432
Database: n8n
Username: postgres (or check POSTGRES_USER in .env)
Password: Check POSTGRES_PASSWORD in .env
SSL: Not required (internal network)
```

**Use Cases:**
- Workflow execution analytics
- Error tracking and debugging
- Performance monitoring
- Automation efficiency metrics

#### Supabase Database (PostgreSQL) - If installed

```
Database Type: PostgreSQL
Host: supabase-db
Port: 5432
Database: postgres
Username: postgres
Password: Check POSTGRES_PASSWORD in .env
SSL: Not required
```

**Use Cases:**
- Application data analysis
- User behavior tracking
- Custom application metrics

#### Invoice Ninja (MySQL) - If installed

```
Database Type: MySQL
Host: invoiceninja_db
Port: 3306
Database: invoiceninja
Username: invoiceninja
Password: Check INVOICENINJA_DB_PASSWORD in .env
SSL: Not required
```

**Use Cases:**
- Revenue analytics
- Invoice aging reports
- Customer payment trends
- Financial forecasting

#### Kimai Time Tracking (MySQL) - If installed

```
Database Type: MySQL
Host: kimai_db
Port: 3306
Database: kimai
Username: kimai
Password: Check KIMAI_DB_PASSWORD in .env
SSL: Not required
```

**Use Cases:**
- Team productivity analysis
- Project profitability tracking
- Time allocation reports
- Billable hours tracking

#### Baserow/NocoDB - If installed

Connect through PostgreSQL backend:

```
Database Type: PostgreSQL
Host: postgres
Port: 5432
Database: baserow or nocodb
Username: postgres
Password: Check POSTGRES_PASSWORD in .env
```

**Use Cases:**
- Custom business data analysis
- CRM metrics
- Lead tracking
- Project management analytics

### n8n Integration Setup

**Internal URL for n8n:** `http://metabase:3000`

**Method 1: API Integration (Recommended)**

```javascript
// HTTP Request Node - Create API Session
Method: POST
URL: http://metabase:3000/api/session
Body (JSON):
{
  "username": "admin@yourdomain.com",
  "password": "{{$env.METABASE_ADMIN_PASSWORD}}"
}

// Response contains session token:
{
  "id": "session-token-here"
}

// Use this token in subsequent requests:
Headers:
  X-Metabase-Session: {{$json.id}}
```

**Method 2: Database Write-Through**

Write metrics directly to a PostgreSQL table that Metabase monitors:

```javascript
// HTTP Request Node - Insert metrics
Method: POST
URL: http://postgres:5432
// Use PostgreSQL Node or SQL Execute Node
Query: |
  INSERT INTO metrics_log (metric_name, value, timestamp)
  VALUES ($1, $2, NOW())
Parameters: ['workflow_executions', {{$json.count}}]
```

### Example Workflows

#### Example 1: n8n Workflow Analytics Dashboard

Monitor your automation performance:

```sql
-- Dashboard Query 1: Daily Workflow Executions
-- Shows execution trends over time

SELECT 
  DATE(started_at) as date,
  COUNT(*) as total_executions,
  SUM(CASE WHEN finished = true THEN 1 ELSE 0 END) as successful,
  SUM(CASE WHEN finished = false THEN 1 ELSE 0 END) as failed,
  ROUND(SUM(CASE WHEN finished = true THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) as success_rate
FROM execution_entity
WHERE started_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;

-- Visualization: Line chart with date on X-axis, executions on Y-axis

-- Dashboard Query 2: Most Active Workflows
-- Identifies your most-used automations

SELECT 
  w.name as workflow_name,
  COUNT(e.id) as execution_count,
  ROUND(AVG(EXTRACT(EPOCH FROM (e.stopped_at - e.started_at))), 2) as avg_duration_seconds,
  ROUND(SUM(CASE WHEN e.finished = true THEN 1 ELSE 0 END)::float / COUNT(*) * 100, 2) as success_rate
FROM execution_entity e
JOIN workflow_entity w ON e.workflow_id = w.id
WHERE e.started_at > NOW() - INTERVAL '7 days'
GROUP BY w.name
ORDER BY execution_count DESC
LIMIT 10;

-- Visualization: Bar chart sorted by execution count

-- Dashboard Query 3: Error Analysis
-- Helps identify and fix recurring issues

SELECT 
  w.name as workflow_name,
  e.execution_error->>'message' as error_message,
  COUNT(*) as error_count,
  MAX(e.started_at) as last_occurrence
FROM execution_entity e
JOIN workflow_entity w ON e.workflow_id = w.id
WHERE e.finished = false
  AND e.started_at > NOW() - INTERVAL '24 hours'
  AND e.execution_error IS NOT NULL
GROUP BY w.name, e.execution_error->>'message'
ORDER BY error_count DESC;

-- Visualization: Table with drill-down capability

-- Dashboard Query 4: Performance Over Time
-- Track automation performance trends

SELECT 
  DATE_TRUNC('hour', started_at) as hour,
  COUNT(*) as executions,
  ROUND(AVG(EXTRACT(EPOCH FROM (stopped_at - started_at))), 2) as avg_duration,
  MAX(EXTRACT(EPOCH FROM (stopped_at - started_at))) as max_duration
FROM execution_entity
WHERE started_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', started_at)
ORDER BY hour;

-- Visualization: Multi-series line chart

-- Create Dashboard:
-- 1. Create each query as a "Question" in Metabase
-- 2. Add all questions to a new Dashboard
-- 3. Arrange and resize visualizations
-- 4. Add filters (date range, workflow name)
-- 5. Set auto-refresh interval (e.g., every 5 minutes)
```

#### Example 2: Cross-Service Business Dashboard

Unified view of your entire business:

```sql
-- Revenue Analytics (Invoice Ninja)

-- Query 1: Monthly Recurring Revenue Trend
SELECT 
  DATE_FORMAT(date, '%Y-%m') as month,
  SUM(amount) as revenue,
  COUNT(DISTINCT client_id) as active_customers,
  ROUND(SUM(amount) / COUNT(DISTINCT client_id), 2) as arpu
FROM invoices
WHERE status_id = 4 -- Paid status
  AND is_recurring = 1
  AND date > DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY month;

-- Query 2: Revenue by Customer
SELECT 
  c.name as customer_name,
  SUM(i.amount) as total_revenue,
  COUNT(i.id) as invoice_count,
  MAX(i.date) as last_invoice_date
FROM invoices i
JOIN clients c ON i.client_id = c.id
WHERE i.status_id = 4
  AND i.date > DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY c.name
ORDER BY total_revenue DESC
LIMIT 20;

-- Query 3: Outstanding Invoices (Aging Report)
SELECT 
  CASE 
    WHEN DATEDIFF(NOW(), due_date) <= 0 THEN 'Not Due'
    WHEN DATEDIFF(NOW(), due_date) <= 30 THEN '1-30 Days'
    WHEN DATEDIFF(NOW(), due_date) <= 60 THEN '31-60 Days'
    WHEN DATEDIFF(NOW(), due_date) <= 90 THEN '61-90 Days'
    ELSE '90+ Days'
  END as aging_bucket,
  COUNT(*) as invoice_count,
  SUM(balance) as total_amount
FROM invoices
WHERE status_id IN (2, 3) -- Sent or Partial
GROUP BY aging_bucket
ORDER BY 
  CASE aging_bucket
    WHEN 'Not Due' THEN 1
    WHEN '1-30 Days' THEN 2
    WHEN '31-60 Days' THEN 3
    WHEN '61-90 Days' THEN 4
    ELSE 5
  END;

-- Time Tracking Analytics (Kimai)

-- Query 4: Team Productivity
SELECT 
  u.username,
  COUNT(DISTINCT t.project_id) as projects_worked,
  ROUND(SUM(t.duration) / 3600, 2) as total_hours,
  ROUND(SUM(t.rate * t.duration / 3600), 2) as billable_amount
FROM timesheet t
JOIN kimai2_users u ON t.user = u.id
WHERE t.end_time > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.username
ORDER BY total_hours DESC;

-- Query 5: Project Profitability
SELECT 
  p.name as project_name,
  ROUND(SUM(t.duration) / 3600, 2) as hours_spent,
  ROUND(SUM(t.rate * t.duration / 3600), 2) as cost,
  -- Compare with revenue from Invoice Ninja (requires JOIN)
  ROUND((SELECT SUM(amount) FROM invoices WHERE project_id = p.id), 2) as revenue,
  ROUND((SELECT SUM(amount) FROM invoices WHERE project_id = p.id) - 
        SUM(t.rate * t.duration / 3600), 2) as profit
FROM timesheet t
JOIN kimai2_projects p ON t.project_id = p.id
WHERE t.end_time > DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY p.name
ORDER BY profit DESC;

-- Create Combined Dashboard:
-- 1. Add revenue charts (line chart for trends)
-- 2. Add customer table (sortable)
-- 3. Add aging report (pie chart)
-- 4. Add team productivity (bar chart)
-- 5. Add project profitability (combo chart)
-- 6. Add filters: date range, customer, project
-- 7. Link questions together (drill-through)
```

#### Example 3: Automated Report Distribution

Send weekly analytics to stakeholders:

```javascript
// n8n Workflow: Weekly Metabase Report

// 1. Schedule Trigger - Every Monday at 9 AM

// 2. HTTP Request Node - Create Metabase session
Method: POST
URL: http://metabase:3000/api/session
Body (JSON):
{
  "username": "{{$env.METABASE_USER}}",
  "password": "{{$env.METABASE_PASSWORD}}"
}

// 3. Set Variable Node - Store session token
Name: metabase_session
Value: {{$json.id}}

// 4. HTTP Request Node - Get dashboard data
Method: GET
URL: http://metabase:3000/api/dashboard/1
Headers:
  X-Metabase-Session: {{$vars.metabase_session}}

// 5. Code Node - Format report
const dashboard = $input.first().json;
const cards = dashboard.ordered_cards;

let reportHtml = `
<html>
<body>
  <h1>Weekly Analytics Report</h1>
  <p>Generated: ${new Date().toLocaleString()}</p>
  <h2>Key Metrics:</h2>
`;

// Extract metrics from dashboard cards
for (const card of cards) {
  const cardData = card.card;
  reportHtml += `
    <div style="margin: 20px 0; padding: 15px; border: 1px solid #ddd;">
      <h3>${cardData.name}</h3>
      <p>${cardData.description || ''}</p>
      <img src="https://analytics.yourdomain.com/api/card/${cardData.id}/query/png?session=${metabase_session}" width="600" />
    </div>
  `;
}

reportHtml += `
</body>
</html>
`;

return [{
  json: {
    subject: `Weekly Analytics Report - ${new Date().toLocaleDateString()}`,
    html: reportHtml
  }
}];

// 6. Send Email Node
To: team@yourdomain.com, executives@yourdomain.com
Subject: {{$json.subject}}
Body (HTML): {{$json.html}}
Attachments: Optional PDF export

// 7. Slack Node - Post summary
Channel: #analytics
Message: |
  📊 **Weekly Analytics Report Ready**
  
  Dashboard: https://analytics.yourdomain.com/dashboard/1
  
  Highlights:
  • Total Executions: [metric]
  • Revenue: [metric]
  • Team Hours: [metric]
  
  Full report sent to team email.

// 8. HTTP Request Node - Logout from Metabase
Method: DELETE
URL: http://metabase:3000/api/session
Headers:
  X-Metabase-Session: {{$vars.metabase_session}}
```

#### Example 4: Alert on Anomalies

Automated alerts for unusual patterns:

```javascript
// n8n Workflow: Anomaly Detection

// 1. Schedule Trigger - Every hour

// 2. HTTP Request Node - Login to Metabase
Method: POST
URL: http://metabase:3000/api/session
Body (JSON):
{
  "username": "{{$env.METABASE_USER}}",
  "password": "{{$env.METABASE_PASSWORD}}"
}

// 3. HTTP Request Node - Execute monitoring query
Method: POST
URL: http://metabase:3000/api/card/5/query
Headers:
  X-Metabase-Session: {{$json.id}}

// Query checks workflow failure rate
// Returns: {failure_rate: 25.5, failed_count: 10}

// 4. IF Node - Check if failure rate exceeds threshold
Condition: {{$json.data.rows[0][0]}} > 20  // 20% failure rate

// IF TRUE:

// 5. Code Node - Analyze errors
const failureRate = $json.data.rows[0][0];
const failedCount = $json.data.rows[0][1];
const topErrors = $json.data.rows.slice(0, 5);

return [{
  json: {
    alert_type: 'High Failure Rate',
    failure_rate: failureRate,
    failed_count: failedCount,
    top_errors: topErrors,
    severity: failureRate > 30 ? 'Critical' : 'Warning',
    timestamp: new Date().toISOString()
  }
}];

// 6. HTTP Request Node - Create incident ticket
Method: POST
URL: http://vikunja:3456/api/v1/tasks
Body (JSON):
{
  "title": "⚠️ High Workflow Failure Rate: {{$json.failure_rate}}%",
  "description": |
    Failure Rate: {{$json.failure_rate}}%
    Failed Executions: {{$json.failed_count}}
    
    Top Errors:
    {{$json.top_errors}}
    
    Dashboard: https://analytics.yourdomain.com/dashboard/1
  "priority": 3,
  "labels": ["alert", "automation", "{{$json.severity}}"],
  "due_date": "{{$now.plus({hours: 4}).toISO()}}"
}

// 7. Slack Alert - Immediate notification
Channel: #alerts
Message: |
  🚨 **{{$json.alert_type}}** 🚨
  
  Failure Rate: {{$json.failure_rate}}%
  Failed Count: {{$json.failed_count}}
  Severity: {{$json.severity}}
  
  [View Dashboard](https://analytics.yourdomain.com/dashboard/1)
  [View Ticket](https://vikunja.yourdomain.com/tasks/{{$json.task_id}})

// 8. Email Alert - For critical severity only
IF: {{$json.severity}} === 'Critical'
To: oncall@yourdomain.com
Subject: CRITICAL: Workflow Failure Alert
Priority: High

// 9. HTTP Request Node - Logout
Method: DELETE
URL: http://metabase:3000/api/session
Headers:
  X-Metabase-Session: {{$vars.metabase_session}}
```

### Advanced Metabase Features

#### X-Ray - Automatic Insights

Metabase's AI-powered data exploration:

1. Navigate to your data in "Browse Data"
2. Click on any table
3. Click "X-ray this table"
4. Metabase automatically generates:
   - Distribution charts for all columns
   - Time series if date columns exist
   - Correlation analysis between fields
   - Suggested questions based on data patterns

**Use Cases:**
- Explore new data sources quickly
- Discover hidden patterns
- Generate initial dashboard ideas
- Validate data quality

#### Pulses - Scheduled Reports

Automated report delivery:

1. Create or open a dashboard
2. Click "Sharing" → "Dashboard Subscriptions"
3. Configure schedule:
   - Frequency: Daily, Weekly, Monthly
   - Time: Choose delivery time
   - Recipients: Email addresses or Slack channels
   - Format: Charts inline or attached as PDF
4. Reports sent automatically with latest data

**Use Cases:**
- Daily sales reports
- Weekly team metrics
- Monthly executive summaries
- Automated compliance reports

#### Public Sharing & Embedding

Share dashboards externally:

```javascript
// Enable in Admin → Settings → Public Sharing

// 1. Generate public link for dashboard
// Dashboard → Sharing → Create public link
// URL: https://analytics.yourdomain.com/public/dashboard/UUID

// 2. Embed in website with iframe:
<iframe
  src="https://analytics.yourdomain.com/public/dashboard/YOUR-UUID"
  frameborder="0"
  width="100%"
  height="600"
  allowtransparency
  sandbox="allow-scripts allow-same-origin"
></iframe>

// 3. Add parameters to iframe URL:
src="https://analytics.yourdomain.com/public/dashboard/UUID?param1=value1"

// 4. Secure embedding with signed URLs:
// Generate signed URL via API for time-limited access
```

**Use Cases:**
- Client-facing dashboards
- Public metrics pages
- Embedded analytics in SaaS apps
- Investor reporting

#### Models - Data Abstraction Layer

Create clean, reusable data models:

1. Browse Data → Select table → Turn into Model
2. Define cleaned column names
3. Hide technical columns
4. Add descriptions and metadata
5. Set up relationships between models
6. Use models as base for questions

**Benefits:**
- Non-technical users can query data easily
- Consistent metric definitions
- Faster query performance
- Centralized business logic

### Performance Optimization

#### For Large Datasets

```yaml
# Increase Java heap in docker-compose.yml
environment:
  - JAVA_OPTS=-Xmx2g -Xms2g  # Increase from 1g to 2g
  - MB_QUERY_TIMEOUT_MINUTES=10  # Increase timeout for long queries
  - MB_DB_CONNECTION_TIMEOUT_MS=10000  # Connection timeout
```

#### Enable Query Caching

1. Admin → Settings → Caching
2. Enable caching globally
3. Set TTL (Time To Live):
   - Real-time dashboards: 1 minute
   - Daily reports: 24 hours
   - Historical data: 7 days
4. Enable "Adaptive Caching" for automatic optimization
5. Monitor cache hit rate in Admin → Troubleshooting

#### Create Materialized Views

For frequently accessed aggregations:

```sql
-- Create materialized view in PostgreSQL
CREATE MATERIALIZED VIEW workflow_daily_stats AS
SELECT 
  DATE(started_at) as date,
  COUNT(*) as executions,
  AVG(EXTRACT(EPOCH FROM (stopped_at - started_at))) as avg_duration,
  SUM(CASE WHEN finished = true THEN 1 ELSE 0 END) as successful
FROM execution_entity
GROUP BY DATE(started_at);

-- Create index on date column
CREATE INDEX idx_workflow_daily_stats_date 
ON workflow_daily_stats(date);

-- Refresh daily via n8n workflow
REFRESH MATERIALIZED VIEW workflow_daily_stats;

-- Query materialized view in Metabase (much faster)
SELECT * FROM workflow_daily_stats 
WHERE date > NOW() - INTERVAL '30 days';
```

### Tips for Metabase + n8n Integration

1. **Use Internal URLs:** From n8n, always use `http://metabase:3000`, not the external URL
2. **API Authentication:** Store Metabase session tokens in n8n credentials with expiry handling
3. **Query Optimization:** Use Metabase's query caching for frequently accessed data
4. **Permissions:** Set up groups in Metabase for different access levels (Admin, Analyst, Viewer)
5. **Models First:** Create Metabase models for clean data abstraction
6. **Collections:** Organize dashboards/questions in collections matching your team structure
7. **Alerts:** Configure Metabase alerts to trigger n8n webhooks for automation
8. **Versioning:** Export dashboard definitions as JSON for version control
9. **Testing:** Use Metabase's question preview to validate queries before dashboarding
10. **Documentation:** Add descriptions to all questions and dashboards for team clarity

### Common Use Cases

#### SaaS Metrics Dashboard

```sql
-- MRR Tracking
SELECT 
  DATE_TRUNC('month', subscription_date) as month,
  SUM(amount) as mrr,
  COUNT(DISTINCT customer_id) as customers,
  ROUND(SUM(amount) / COUNT(DISTINCT customer_id), 2) as arpu
FROM subscriptions
WHERE status = 'active'
GROUP BY month;

-- Churn Analysis
SELECT 
  DATE_TRUNC('month', cancelled_date) as month,
  COUNT(*) as churned_customers,
  ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM customers) * 100, 2) as churn_rate
FROM subscriptions
WHERE status = 'cancelled'
GROUP BY month;

-- User Engagement (from n8n logs)
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as daily_active_users,
  COUNT(*) as total_actions
FROM user_activity_log
GROUP BY date;
```

#### Team Performance Dashboard

```sql
-- Automation Efficiency
SELECT 
  u.name as team_member,
  COUNT(w.id) as workflows_created,
  SUM(e.executions) as total_executions,
  ROUND(AVG(e.success_rate), 2) as avg_success_rate
FROM users u
LEFT JOIN workflows w ON u.id = w.creator_id
LEFT JOIN workflow_stats e ON w.id = e.workflow_id
GROUP BY u.name;

-- Project Completion
SELECT 
  project_name,
  COUNT(*) as total_tasks,
  SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) as completed,
  ROUND(SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) as completion_rate
FROM tasks
GROUP BY project_name;

-- Resource Allocation (from Kimai)
SELECT 
  project,
  ROUND(SUM(duration) / 3600, 2) as hours_allocated,
  COUNT(DISTINCT user_id) as team_members,
  ROUND(SUM(billable_duration) / SUM(duration) * 100, 2) as billable_percentage
FROM time_entries
WHERE date > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY project;
```

#### Financial Dashboard

```sql
-- Revenue by Product/Service
SELECT 
  product_name,
  COUNT(DISTINCT customer_id) as customers,
  SUM(amount) as total_revenue,
  ROUND(AVG(amount), 2) as avg_transaction
FROM invoices
WHERE status = 'paid'
  AND date > DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY product_name
ORDER BY total_revenue DESC;

-- Cash Flow Projection
SELECT 
  DATE_FORMAT(due_date, '%Y-%m') as month,
  SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as received,
  SUM(CASE WHEN status IN ('sent', 'partial') THEN balance ELSE 0 END) as expected,
  SUM(CASE WHEN status IN ('sent', 'partial') AND due_date < NOW() THEN balance ELSE 0 END) as overdue
FROM invoices
WHERE due_date >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
  AND due_date <= DATE_ADD(NOW(), INTERVAL 3 MONTH)
GROUP BY DATE_FORMAT(due_date, '%Y-%m')
ORDER BY month;

-- Expense Categorization
SELECT 
  category,
  COUNT(*) as transaction_count,
  SUM(amount) as total_spent,
  ROUND(AVG(amount), 2) as avg_transaction
FROM expenses
WHERE date > DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY category
ORDER BY total_spent DESC;
```

### Troubleshooting

#### Metabase Container Won't Start

```bash
# 1. Check logs for errors
docker logs metabase --tail 100

# 2. Common issue: Database migration pending
docker exec metabase java -jar /app/metabase.jar migrate up

# 3. Check disk space
df -h

# 4. Verify metabase_db is running
docker ps | grep metabase_db

# 5. If corrupted, reset Metabase database (loses all settings!)
docker compose down metabase metabase_db
docker volume rm ${PROJECT_NAME:-localai}_metabase_postgres
docker compose up -d metabase metabase_db

# Wait 2-3 minutes for initialization
docker logs metabase --follow
```

#### Can't Connect to Database

```bash
# 1. Verify hostname (use container names, not localhost)
# Correct: postgres
# Wrong: localhost, 127.0.0.1

# 2. Test connection from Metabase container
docker exec metabase ping postgres

# 3. Check database credentials in .env
grep POSTGRES .env

# 4. Verify database is accepting connections
docker exec postgres pg_isready -U postgres

# 5. Check Metabase logs for connection errors
docker logs metabase | grep -i "database"
```

#### Slow Query Performance

```bash
# 1. Add indexes to frequently queried columns
# In PostgreSQL:
docker exec postgres psql -U postgres -d n8n
CREATE INDEX idx_execution_started ON execution_entity(started_at);
CREATE INDEX idx_execution_workflow ON execution_entity(workflow_id);

# 2. Enable Metabase query caching
# Admin → Settings → Caching → Enable

# 3. Consider creating summary tables
# Updated via n8n on schedule

# 4. Monitor query execution time
# Metabase shows query time in bottom right

# 5. Use EXPLAIN ANALYZE to optimize queries
EXPLAIN ANALYZE SELECT ...;
```

#### Memory Issues

```bash
# 1. Check Metabase memory usage
docker stats metabase

# 2. Increase memory allocation in .env
# Default: METABASE_MEMORY=1g
# Recommended: METABASE_MEMORY=2g or 4g

# 3. Restart Metabase
docker compose restart metabase

# 4. Monitor Java heap usage
docker exec metabase java -XX:+PrintFlagsFinal -version | grep HeapSize
```

#### Dashboard Not Updating

```bash
# 1. Check if caching is too aggressive
# Admin → Settings → Caching → Lower TTL values

# 2. Manually refresh dashboard
# Click refresh button in dashboard

# 3. Clear cache for specific question
# Question → Settings → Clear cache

# 4. Check if data source is updating
# Verify in database directly

# 5. Review scheduled Pulse settings
# Dashboard → Subscriptions → Check timing
```

### Resources

- **Documentation:** https://www.metabase.com/docs
- **Learn Metabase:** https://www.metabase.com/learn
- **Community Forum:** https://discourse.metabase.com
- **SQL Templates:** https://www.metabase.com/learn/sql-templates
- **GitHub:** https://github.com/metabase/metabase
- **API Documentation:** https://www.metabase.com/docs/latest/api-documentation
- **Video Tutorials:** https://www.metabase.com/learn/getting-started

### Best Practices

**Dashboard Design:**
- Keep dashboards focused (max 8-10 visualizations)
- Use consistent color schemes
- Add descriptive titles and descriptions
- Include date filters for time-based analysis
- Order visualizations by importance
- Use appropriate chart types for data
- Add context with text cards

**Query Optimization:**
- Filter data before aggregating
- Use indexes on frequently queried columns
- Limit result sets appropriately
- Avoid SELECT * queries
- Use materialized views for complex aggregations
- Cache frequently accessed queries
- Set reasonable query timeouts

**Team Collaboration:**
- Organize content in collections by team/function
- Set up appropriate permissions
- Document queries with comments
- Use consistent naming conventions
- Create reusable saved questions
- Set up alerts for key metrics
- Schedule regular report reviews

**Data Governance:**
- Define metrics centrally using Models
- Document data sources and definitions
- Set up data validation checks
- Regular audit of unused questions
- Archive outdated dashboards
- Version control important queries
- Regular backup of Metabase config

**Security:**
- Use row-level permissions where needed
- Regular credential rotation
- Enable 2FA for admin accounts
- Audit log review
- Secure public links appropriately
- Monitor API usage
- Regular security updates
