# 🕸️ Neo4j - Native Graph Database Platform

### What is Neo4j?

Neo4j is the world's leading native graph database, storing data as nodes (entities), relationships (connections), and properties instead of tables or documents. Unlike relational databases that use JOINs, relationships in Neo4j are first-class citizens stored natively, enabling millions of relationship traversals per second. With the declarative Cypher query language (similar to SQL but optimized for graphs), you can write complex relationship queries intuitively using ASCII-art style syntax. Perfect for knowledge graphs, fraud detection, recommendation engines, social networks, and AI applications.

### Features

- **🔗 Native Graph Storage**: Relationships as first-class citizens - no JOINs needed
- **⚡ Extremely Fast**: Millions of traversals per second with optimized graph algorithms
- **🔍 Cypher Query Language**: Intuitive, ASCII-art based query language (like visual drawing)
- **🎯 Schema-Optional**: Flexible data modeling without fixed schemas
- **🔄 ACID-Compliant**: Full transactional safety and data integrity
- **📊 Built-in Browser UI**: Web-based interface for query development and visualization
- **🌐 Horizontally Scalable**: Clustering and sharding for enterprise workloads

### Initial Setup

**First Login to Neo4j:**

1. **Access Neo4j Browser:**
```
https://neo4j.yourdomain.com
```

2. **Initial Login Credentials:**
- **Connect URL:** `neo4j://neo4j:7687` (Bolt protocol)
- **Username:** `neo4j`
- **Password:** Check `.env` file for `NEO4J_AUTH` (format: `neo4j/password`)

```bash
# Check password from server
grep NEO4J_AUTH /root/ai-corekit/.env
# Example output: NEO4J_AUTH=neo4j/your-password-here
```

3. **Change Default Password (First Login):**
Neo4j will prompt you to change the password on first connection.
- Old password: `neo4j` (or from `.env`)
- New password: Choose a strong password

4. **Explore Sample Data (Optional):**
```cypher
// In Neo4j Browser, try the built-in movie database
:play movies

// Follow the guide and run the CREATE statements
// Then try your first query:
MATCH (m:Movie {title: "The Matrix"})
RETURN m
```

### Cypher Query Language Basics

Cypher uses ASCII-art syntax to represent graph patterns:

**Nodes** - Represented with parentheses `()`
```cypher
// Create a person node
CREATE (p:Person {name: "Alice", age: 30})

// Find all person nodes
MATCH (p:Person)
RETURN p.name, p.age
```

**Relationships** - Represented with arrows `-->`
```cypher
// Create nodes and relationship
CREATE (alice:Person {name: "Alice"})
CREATE (bob:Person {name: "Bob"})
CREATE (alice)-[:KNOWS {since: 2020}]->(bob)

// Find friends
MATCH (alice:Person {name: "Alice"})-[:KNOWS]->(friend)
RETURN friend.name
```

**Patterns** - Combine nodes and relationships
```cypher
// Find friends of friends
MATCH (person:Person {name: "Alice"})-[:KNOWS]->()-[:KNOWS]->(fof)
RETURN fof.name

// Find shortest path
MATCH path = shortestPath(
  (alice:Person {name: "Alice"})-[:KNOWS*]-(bob:Person {name: "Bob"})
)
RETURN path
```

**Common Operations:**
```cypher
// CREATE - Insert data
CREATE (n:Node {property: "value"})

// MATCH - Find patterns
MATCH (n:Label {property: "value"})
RETURN n

// WHERE - Filter results
MATCH (p:Person)
WHERE p.age > 25
RETURN p.name

// SET - Update properties
MATCH (p:Person {name: "Alice"})
SET p.age = 31

// DELETE - Remove nodes/relationships
MATCH (p:Person {name: "Bob"})
DETACH DELETE p  // DETACH removes relationships first

// ORDER BY - Sort results
MATCH (p:Person)
RETURN p.name, p.age
ORDER BY p.age DESC

// LIMIT - Limit results
MATCH (p:Person)
RETURN p
LIMIT 10
```

### n8n Integration Setup

**Methods to Integrate Neo4j with n8n:**

1. **HTTP Request Node** (Direct Bolt/HTTP API)
2. **Community Node** (Install n8n-nodes-neo4j)
3. **Code Node** (Custom JavaScript with neo4j-driver)

#### Method 1: HTTP Request Node

Neo4j provides an HTTP API for Cypher queries.

**Internal URL:** `http://neo4j:7474/db/neo4j/tx/commit`

**HTTP Request Configuration:**
```javascript
Method: POST
URL: http://neo4j:7474/db/neo4j/tx/commit
Authentication: Basic Auth
  Username: neo4j
  Password: {{ $env.NEO4J_PASSWORD }}
Headers:
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

**Response Format:**
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

#### Method 2: Community Node (Recommended)

Install the Neo4j community node for better integration.

**Installation:**
```
n8n UI → Settings → Community Nodes → Install
Package: n8n-nodes-neo4j
```

**Credential Setup:**
- **Name:** Neo4j Credentials
- **Scheme:** `neo4j` or `bolt`
- **Host:** `neo4j`
- **Port:** `7687`
- **Username:** `neo4j`
- **Password:** From `.env` file
- **Database:** `neo4j` (default)

### Example Workflows

#### Example 1: Knowledge Graph Builder

Build a knowledge graph from structured data.

**Workflow Structure:**
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

2. **Code Node - Prepare Cypher Statements**
   ```javascript
   const entities = $json.entities;
   const relationships = $json.relationships;
   
   // Generate CREATE statements for entities
   const entityStatements = entities.map(e => 
     `MERGE (n:${e.type} {name: '${e.name}'}) ` +
     `SET n.role = '${e.role || ''}'`
   );
   
   // Generate CREATE statements for relationships
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

3. **HTTP Request Node - Execute in Neo4j**
   ```javascript
   Method: POST
   URL: http://neo4j:7474/db/neo4j/tx/commit
   Authentication: Basic Auth (neo4j credentials)
   Body: {
     "statements": [
       {
         "statement": "{{ $json.cypher }}"
       }
     ]
   }
   ```

4. **Code Node - Verify Graph**
   ```javascript
   // Query to visualize the graph
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

**Use Case**: CRM systems, organization charts, project dependencies.

#### Example 2: Recommendation Engine

Find recommendations based on graph patterns.

**Workflow Structure:**
1. **Webhook Trigger**
   ```javascript
   Input: {
     "user": "Alice",
     "type": "product_recommendations"
   }
   ```

2. **HTTP Request - Find Recommendations**
   ```javascript
   Method: POST
   URL: http://neo4j:7474/db/neo4j/tx/commit
   Body: {
     "statements": [
       {
         "statement": `
           // Find products that similar users also bought
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

3. **Code Node - Format Recommendations**
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

4. **Send Recommendations** - Email or API response

**Use Case**: E-commerce recommendations, content suggestions, social connections.

#### Example 3: Fraud Detection

Detect suspicious patterns in transaction networks.

**Workflow Structure:**
1. **Schedule Trigger** (Every hour)

2. **HTTP Request - Find Suspicious Patterns**
   ```javascript
   Method: POST
   URL: http://neo4j:7474/db/neo4j/tx/commit
   Body: {
     "statements": [
       {
         "statement": `
           // Find circular money transfers (potential money laundering)
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

3. **Code Node - Analyze Risk**
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
       totalAmount: pattern.row[2].reduce((sum, amt) => sum + amt, 0),
       riskScore: pattern.row[3] * 10  // Higher circles = higher risk
     }));
   
   return [{
     json: {
       alertsFound: highRisk.length,
       highRiskAccounts: highRisk
     }
   }];
   ```

4. **IF Node - Check if Alerts Exist**
5. **Alert Path** - Notify fraud team via Slack/Email

**Use Case**: Banking fraud detection, insurance claims analysis, network security.

### Troubleshooting

**Issue 1: Cannot Connect to Neo4j Browser**

```bash
# Check if Neo4j is running
corekit ps | grep neo4j

# Check logs for errors
corekit logs neo4j --tail 100

# Check if ports are accessible
corekit port neo4j 7474
corekit port neo4j 7687
```

**Solution:**
- Verify Caddy is routing correctly to Neo4j
- Check `.env` file for correct `NEO4J_AUTH` format
- Try accessing directly: `http://localhost:7474` (if port is exposed)

**Issue 2: Authentication Failed**

```bash
# Check current password in .env
grep NEO4J_AUTH /root/ai-corekit/.env

# If password was changed in Neo4j but not in .env:
# Option 1: Update .env file
nano /root/ai-corekit/.env
# Change NEO4J_AUTH=neo4j/your-new-password

# Option 2: Reset Neo4j completely (WARNING: Deletes all data)
corekit down neo4j
docker volume rm ai-corekit_neo4j_data
corekit up -d neo4j
```

**Solution:**
- Ensure username is `neo4j` (cannot be changed)
- Password format in .env: `NEO4J_AUTH=neo4j/yourpassword`
- No spaces around the `=` sign

**Issue 3: Query Runs Slowly**

```bash
# Check container resources
docker stats neo4j --no-stream

# Check query performance in Neo4j Browser
# Run with EXPLAIN or PROFILE:
EXPLAIN MATCH (n:Person) RETURN n

# Check if indexes exist
SHOW INDEXES
```

**Solution:**
- Create indexes on frequently queried properties:
  ```cypher
  CREATE INDEX person_name FOR (p:Person) ON (p.name)
  CREATE INDEX product_id FOR (p:Product) ON (p.id)
  ```
- Use constraints for unique properties:
  ```cypher
  CREATE CONSTRAINT user_email FOR (u:User) REQUIRE u.email IS UNIQUE
  ```
- Optimize query patterns (avoid unbounded relationships `[:KNOWS*]`)

**Issue 4: Out of Memory**

```bash
# Check memory usage
docker stats neo4j

# View Neo4j configuration
corekit exec neo4j cat /var/lib/neo4j/conf/neo4j.conf | grep memory
```

**Solution:**
- Increase heap memory in `docker-compose.yml`:
  ```yaml
  neo4j:
    environment:
      - NEO4J_dbms_memory_heap_max__size=2G
      - NEO4J_dbms_memory_pagecache_size=1G
  ```
- Restart Neo4j:
  ```bash
  corekit restart neo4j
  ```

**Issue 5: Cannot Delete Node (Relationship Constraint)**

```cypher
// Error: Cannot delete node<123>, because it still has relationships
DELETE n

// Solution: Use DETACH DELETE to remove relationships first
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

### Resources

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
