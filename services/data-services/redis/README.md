### What is Redis?

Redis (REmote DIctionary Server) is an open-source, in-memory data structure store used as a database, cache, message broker, and streaming engine. Unlike traditional databases that store data on disk, Redis keeps everything in RAM, enabling sub-millisecond response times and handling millions of requests per second. In AI CoreKit, Redis powers caching layers, session storage, job queues, and real-time features across multiple services.

Redis supports rich data types including strings, hashes, lists, sets, sorted sets, bitmaps, and streams. With atomic operations and Lua scripting, Redis enables complex workflows while maintaining blazing-fast performance.

### Features

- ✅ **In-Memory Performance** - Sub-millisecond latency with data stored in RAM
- ✅ **Rich Data Structures** - Strings, hashes, lists, sets, sorted sets, bitmaps, streams
- ✅ **Atomic Operations** - Thread-safe operations without race conditions
- ✅ **Pub/Sub Messaging** - Real-time message broadcasting for event-driven architectures
- ✅ **Persistence Options** - RDB snapshots and AOF (Append-Only File) for data durability
- ✅ **Lua Scripting** - Execute complex operations atomically on the server side
- ✅ **Expiration/TTL** - Automatic key expiration for cache management
- ✅ **Transactions** - Multi-command transactions with WATCH for optimistic locking
- ✅ **Replication** - Master-replica replication for high availability
- ✅ **Clustering** - Horizontal scaling across multiple nodes

### Initial Setup

Redis is automatically installed and configured during AI CoreKit installation.

**Access Redis:**

```bash
# Access Redis CLI
docker exec -it redis redis-cli

# Test connection
docker exec redis redis-cli PING
# Should return: PONG

# Check Redis info
docker exec redis redis-cli INFO
```

**Important Configuration:**

```bash
# Redis runs on default port 6379 (internal only)
# No password required for internal Docker network connections

# Check Redis configuration
docker exec redis redis-cli CONFIG GET maxmemory
docker exec redis redis-cli CONFIG GET maxmemory-policy
```

**Basic Redis Commands:**

```bash
# Set a key
docker exec redis redis-cli SET mykey "Hello Redis"

# Get a key
docker exec redis redis-cli GET mykey

# Set with expiration (TTL)
docker exec redis redis-cli SETEX mykey 60 "expires in 60 seconds"

# Check remaining TTL
docker exec redis redis-cli TTL mykey

# Delete a key
docker exec redis redis-cli DEL mykey

# List all keys (use with caution in production!)
docker exec redis redis-cli KEYS "*"
```

### n8n Integration Setup

Redis is accessible from n8n using the native Redis node.

**Internal URL for n8n:** `redis` (hostname) on port `6379`

**Create Redis Credentials in n8n:**

1. In n8n, go to **Credentials** → **New Credential**
2. Search for **Redis**
3. Fill in:
   - **Password:** Leave empty (no password for internal connections)
   - **Host:** `redis` (Docker service name)
   - **Port:** `6379` (default)
   - **Database Number:** `0` (default)

**Available Redis Operations in n8n:**
- **Delete** - Remove a key
- **Get** - Retrieve value
- **Incr** - Increment counter
- **Info** - Redis server info
- **Keys** - Find keys by pattern
- **Pop** - Remove and return element from list
- **Push** - Add element to list
- **Set** - Store key-value pair
- **Set Expire** - Set TTL on key

### Example Workflows

#### Example 1: Rate Limiting API Requests

```javascript
// Implement rate limiting to prevent API abuse

// 1. Webhook Trigger - Receive API request

// 2. Code Node - Extract user identifier
const userId = $json.headers['x-user-id'] || $json.query.user_id;
const rateKey = `rate_limit:${userId}`;

return {
  userId: userId,
  rateKey: rateKey,
  timestamp: Date.now()
};

// 3. Redis Node - Check current request count
Operation: Get
Key: {{$json.rateKey}}

// 4. Code Node - Calculate rate limit
const currentCount = parseInt($input.item.json.value || '0');
const limit = 100; // 100 requests per hour
const ttl = 3600; // 1 hour in seconds

if (currentCount >= limit) {
  // Rate limit exceeded
  return {
    allowed: false,
    remaining: 0,
    resetTime: Date.now() + (ttl * 1000),
    message: 'Rate limit exceeded. Try again later.'
  };
}

return {
  allowed: true,
  currentCount: currentCount,
  remaining: limit - currentCount - 1,
  key: $('Code Node').json.rateKey
};

// 5. IF Node - Check if allowed
{{$json.allowed}} equals true

// TRUE BRANCH:
// 6. Redis Node - Increment counter
Operation: Incr
Key: {{$('Code Node').json.rateKey}}

// 7. Redis Node - Set expiration on first request
Operation: Set Expire
Key: {{$('Code Node').json.rateKey}}
TTL: 3600

// 8. HTTP Request - Forward to actual API
// ... process request ...

// 9. Respond with success + rate limit headers
Headers:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: {{$('Code Node').json.remaining}}
  X-RateLimit-Reset: {{$('Code Node').json.resetTime}}

// FALSE BRANCH:
// 10. Respond with 429 Too Many Requests
Status Code: 429
Body: {{$('Code Node').json.message}}
```

#### Example 2: Caching Database Queries

```javascript
// Cache expensive database queries in Redis

// 1. Webhook or Schedule Trigger

// 2. Code Node - Generate cache key
const query = $json.query || 'SELECT * FROM products WHERE category = "electronics"';
const cacheKey = `cache:query:${require('crypto').createHash('md5').update(query).digest('hex')}`;

return {
  query: query,
  cacheKey: cacheKey
};

// 3. Redis Node - Try to get cached result
Operation: Get
Key: {{$json.cacheKey}}

// 4. IF Node - Check if cache hit
{{$json.value}} is not empty

// CACHE HIT (TRUE BRANCH):
// 5. Code Node - Parse cached data
return {
  source: 'cache',
  data: JSON.parse($input.item.json.value),
  cached: true
};

// CACHE MISS (FALSE BRANCH):
// 6. Postgres Node - Execute query
Query: {{$('Code Node').json.query}}

// 7. Code Node - Prepare cache data
const results = $input.all();
const cacheData = JSON.stringify(results);

return {
  source: 'database',
  data: results,
  cacheData: cacheData,
  cacheKey: $('Code Node').json.cacheKey
};

// 8. Redis Node - Store in cache
Operation: Set
Key: {{$json.cacheKey}}
Value: {{$json.cacheData}}
TTL: 3600  // Cache for 1 hour

// 9. Merge Branch - Return results
// (Both branches converge here with data)

// Performance improvement:
// - First request: ~100ms (database query)
// - Cached requests: ~5ms (Redis lookup)
// - 20x faster response time!
```

#### Example 3: Session Management for Multi-User Application

```javascript
// Store and manage user sessions in Redis

// WORKFLOW 1: User Login - Create Session

// 1. Webhook Trigger - POST /api/login
Body: {"username": "user@example.com", "password": "***"}

// 2. Postgres Node - Verify credentials
Query: SELECT id, username, role FROM users WHERE email = $1 AND password_hash = crypt($2, password_hash)
Parameters: [{{$json.username}}, {{$json.password}}]

// 3. IF Node - Check if user found
{{$json.id}} exists

// 4. Code Node - Generate session
const crypto = require('crypto');
const sessionId = crypto.randomBytes(32).toString('hex');
const sessionData = {
  userId: $input.item.json.id,
  username: $input.item.json.username,
  role: $input.item.json.role,
  loginTime: new Date().toISOString(),
  lastActivity: new Date().toISOString()
};

return {
  sessionId: sessionId,
  sessionKey: `session:${sessionId}`,
  sessionData: JSON.stringify(sessionData),
  userId: sessionData.userId
};

// 5. Redis Node - Store session
Operation: Set
Key: {{$json.sessionKey}}
Value: {{$json.sessionData}}
TTL: 86400  // 24 hours

// 6. Respond with session token
Status: 200
Body: {
  "success": true,
  "sessionId": "{{$json.sessionId}}",
  "expiresIn": 86400
}
Headers:
  Set-Cookie: session_id={{$json.sessionId}}; HttpOnly; Secure; Max-Age=86400


// WORKFLOW 2: Validate Session on Each Request

// 1. Webhook Trigger - Any API request

// 2. Code Node - Extract session ID
const sessionId = $json.headers.cookie?.match(/session_id=([^;]+)/)?.[1] 
                  || $json.headers['x-session-id'];

return {
  sessionId: sessionId,
  sessionKey: `session:${sessionId}`
};

// 3. Redis Node - Get session data
Operation: Get
Key: {{$json.sessionKey}}

// 4. IF Node - Check if valid session
{{$json.value}} is not empty

// TRUE BRANCH - Valid session:
// 5. Code Node - Parse and update session
const session = JSON.parse($input.item.json.value);
session.lastActivity = new Date().toISOString();

return {
  session: session,
  sessionKey: $('Code Node').json.sessionKey,
  sessionData: JSON.stringify(session)
};

// 6. Redis Node - Update last activity
Operation: Set
Key: {{$json.sessionKey}}
Value: {{$json.sessionData}}
TTL: 86400  // Refresh TTL

// 7. Continue with authorized request...

// FALSE BRANCH - Invalid/expired session:
// 8. Respond 401 Unauthorized
Status: 401
Body: {"error": "Invalid or expired session"}


// WORKFLOW 3: Logout - Destroy Session

// 1. Webhook Trigger - POST /api/logout

// 2. Code Node - Extract session ID
const sessionId = $json.headers['x-session-id'];
return { sessionKey: `session:${sessionId}` };

// 3. Redis Node - Delete session
Operation: Delete
Key: {{$json.sessionKey}}

// 4. Respond with success
Status: 200
Body: {"success": true, "message": "Logged out successfully"}
```

#### Example 4: Job Queue with Background Processing

```javascript
// Use Redis lists as a job queue for background tasks

// PRODUCER WORKFLOW - Add Jobs to Queue

// 1. Webhook or Schedule Trigger

// 2. Code Node - Create job payload
const jobs = [
  {
    id: Date.now(),
    type: 'send_email',
    data: {
      to: 'user@example.com',
      subject: 'Welcome!',
      body: 'Thanks for signing up'
    }
  },
  {
    id: Date.now() + 1,
    type: 'generate_report',
    data: {
      reportType: 'monthly',
      userId: 12345
    }
  }
];

return jobs.map(job => ({
  json: {
    queueKey: 'jobs:pending',
    jobData: JSON.stringify(job)
  }
}));

// 3. Redis Node - Push job to queue
Operation: Push
Key: {{$json.queueKey}}
Value: {{$json.jobData}}
Position: Right  // RPUSH - add to end of queue


// CONSUMER WORKFLOW - Process Jobs

// 1. Schedule Trigger - Every 10 seconds

// 2. Redis Node - Pop job from queue (blocking)
Operation: Pop
Key: jobs:pending
Position: Left  // LPOP - remove from front of queue

// 3. IF Node - Check if job exists
{{$json.value}} is not empty

// 4. Code Node - Parse job
const job = JSON.parse($input.item.json.value);

return {
  jobId: job.id,
  jobType: job.type,
  jobData: job.data
};

// 5. Switch Node - Route by job type
{{$json.jobType}}
  Case: send_email → Send Email Branch
  Case: generate_report → Generate Report Branch
  Case: process_data → Process Data Branch

// SEND EMAIL BRANCH:
// 6a. SMTP Node - Send email
To: {{$json.jobData.to}}
Subject: {{$json.jobData.subject}}
Body: {{$json.jobData.body}}

// 7a. Redis Node - Mark job complete
Operation: Set
Key: job:{{$json.jobId}}:status
Value: completed
TTL: 3600  // Keep status for 1 hour

// GENERATE REPORT BRANCH:
// 6b. Postgres Node - Fetch report data
// 7b. Generate PDF
// 8b. Upload to storage
// 9b. Mark complete...

// Job queue benefits:
// - Decouple producers from consumers
// - Handle traffic spikes gracefully
// - Retry failed jobs
// - Scale workers independently
```

#### Example 5: Real-Time Pub/Sub Notifications

```javascript
// Use Redis Pub/Sub for real-time event broadcasting

// PUBLISHER WORKFLOW - Send Notifications

// 1. Webhook Trigger - Order placed event

// 2. Code Node - Create notification
const notification = {
  type: 'order_placed',
  orderId: $json.orderId,
  userId: $json.userId,
  amount: $json.total,
  timestamp: new Date().toISOString(),
  message: `New order #${$json.orderId} for $${$json.total}`
};

return {
  channel: 'notifications:orders',
  message: JSON.stringify(notification)
};

// 3. Execute Command Node - Publish to Redis channel
Command: docker
Arguments: exec redis redis-cli PUBLISH {{$json.channel}} '{{$json.message}}'

// Or use HTTP Request to Redis REST API (if available)
// Or integrate with a service that listens to Redis Pub/Sub


// SUBSCRIBER WORKFLOW - Listen for Notifications
// Note: n8n doesn't have native Redis Pub/Sub trigger
// But you can use Redis Trigger node with polling or external service

// Alternative: Use webhook + external subscriber
// External script listens to Redis Pub/Sub and sends webhooks to n8n

// Example external subscriber (Node.js):
/*
const redis = require('redis');
const axios = require('axios');

const subscriber = redis.createClient({
  host: 'redis',
  port: 6379
});

subscriber.subscribe('notifications:orders');

subscriber.on('message', (channel, message) => {
  const notification = JSON.parse(message);
  
  // Send to n8n webhook
  axios.post('https://n8n.yourdomain.com/webhook/order-notification', notification);
});
*/

// 1. Webhook Trigger - Receives notifications from subscriber

// 2. Switch Node - Route by notification type
{{$json.type}}
  Case: order_placed → Notify warehouse
  Case: payment_received → Send confirmation email
  Case: order_shipped → Update tracking

// 3. Take appropriate action based on notification type

// Pub/Sub use cases:
// - Real-time dashboards
// - Chat applications
// - Live updates
// - Event broadcasting
// - Microservices communication
```

### Advanced Use Cases

#### Leaderboard with Sorted Sets

```bash
# Sorted sets are perfect for leaderboards, rankings, priority queues

# Add players with scores
docker exec redis redis-cli ZADD leaderboard 1500 "player1"
docker exec redis redis-cli ZADD leaderboard 2300 "player2"
docker exec redis redis-cli ZADD leaderboard 1800 "player3"

# Get top 10 players
docker exec redis redis-cli ZREVRANGE leaderboard 0 9 WITHSCORES

# Get player rank
docker exec redis redis-cli ZREVRANK leaderboard "player2"

# Increment player score
docker exec redis redis-cli ZINCRBY leaderboard 100 "player1"

# Get players in score range
docker exec redis redis-cli ZRANGEBYSCORE leaderboard 1500 2000 WITHSCORES
```

#### Distributed Locking

```bash
# Prevent race conditions in distributed systems

# Acquire lock (SET with NX and EX)
docker exec redis redis-cli SET lock:resource:123 "worker-1" NX EX 30
# Returns OK if lock acquired, nil if already locked

# Release lock (only if you own it)
docker exec redis redis-cli EVAL "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end" 1 lock:resource:123 "worker-1"

# Use case: Ensure only one worker processes a job
# - Worker tries to acquire lock before processing
# - If successful, process job and release lock
# - If failed, skip job (another worker is handling it)
```

#### Cache Eviction Policies

```bash
# Configure how Redis handles memory limits

# Check current policy
docker exec redis redis-cli CONFIG GET maxmemory-policy

# Set eviction policy
docker exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Available policies:
# - noeviction: Return errors when memory limit reached
# - allkeys-lru: Evict least recently used keys
# - allkeys-lfu: Evict least frequently used keys
# - volatile-lru: Evict LRU keys with TTL set
# - volatile-lfu: Evict LFU keys with TTL set
# - volatile-ttl: Evict keys with shortest TTL
# - allkeys-random: Evict random keys
# - volatile-random: Evict random keys with TTL

# Set memory limit
docker exec redis redis-cli CONFIG SET maxmemory 256mb
```

### Troubleshooting

**Connection refused / Cannot connect to Redis:**

```bash
# Check if Redis is running
docker ps | grep redis

# Check Redis logs
docker logs redis --tail 100

# Test Redis connection
docker exec redis redis-cli PING
# Should return: PONG

# Restart Redis
docker compose restart redis

# Test from n8n container
docker exec n8n ping redis
# Should successfully ping
```

**Redis memory issues / Out of memory:**

```bash
# Check memory usage
docker exec redis redis-cli INFO memory

# Key metrics to check:
# - used_memory_human: Total memory used by Redis
# - used_memory_rss_human: Resident set size (physical RAM)
# - maxmemory_human: Memory limit
# - mem_fragmentation_ratio: Memory fragmentation

# Check largest keys
docker exec redis redis-cli --bigkeys

# Clear all keys (DANGER! Use with caution)
docker exec redis redis-cli FLUSHALL

# Set memory limit
docker exec redis redis-cli CONFIG SET maxmemory 512mb

# Enable LRU eviction
docker exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

**Slow Redis performance:**

```bash
# Check for slow commands
docker exec redis redis-cli SLOWLOG GET 10

# Monitor Redis operations in real-time
docker exec redis redis-cli MONITOR
# Press Ctrl+C to stop

# Check current connections
docker exec redis redis-cli CLIENT LIST

# Check latency
docker exec redis redis-cli --latency

# Check if Redis is saving to disk (can cause latency spikes)
docker exec redis redis-cli INFO persistence

# Disable persistence for pure cache (faster, but data loss on restart)
docker exec redis redis-cli CONFIG SET save ""
docker exec redis redis-cli CONFIG SET appendonly no
```

**Keys not expiring:**

```bash
# Check if key has TTL set
docker exec redis redis-cli TTL mykey
# Returns: -2 (key doesn't exist), -1 (no expiration), or seconds remaining

# Set expiration on existing key
docker exec redis redis-cli EXPIRE mykey 3600

# Check expiration frequency
docker exec redis redis-cli CONFIG GET hz
# Higher hz = more frequent expiration checks (default: 10)

# Force immediate expiration check (not recommended in production)
docker exec redis redis-cli DEBUG SLEEP 0
```

**Redis persistence issues:**

```bash
# Check last save time
docker exec redis redis-cli LASTSAVE

# Force save to disk
docker exec redis redis-cli SAVE
# or async:
docker exec redis redis-cli BGSAVE

# Check persistence configuration
docker exec redis redis-cli CONFIG GET save
docker exec redis redis-cli CONFIG GET appendonly

# View AOF (Append-Only File) rewrite info
docker exec redis redis-cli INFO persistence | grep aof

# Disable persistence (cache-only mode)
docker exec redis redis-cli CONFIG SET save ""
docker exec redis redis-cli CONFIG SET appendonly no
```

**Common n8n Redis Node errors:**

```bash
# Error: "Connection timeout"
# Solution: Check Redis is running and accessible
docker compose restart redis

# Error: "WRONGTYPE Operation against a key holding the wrong kind of value"
# Solution: Key exists with different data type, use different key or DEL old key
docker exec redis redis-cli DEL mykey

# Error: "OOM command not allowed when used memory > 'maxmemory'"
# Solution: Increase memory limit or enable eviction policy
docker exec redis redis-cli CONFIG SET maxmemory 512mb
docker exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Resources

- **Official Documentation:** https://redis.io/docs/
- **Commands Reference:** https://redis.io/commands/
- **Data Types:** https://redis.io/docs/data-types/
- **Pub/Sub Guide:** https://redis.io/docs/interact/pubsub/
- **n8n Redis Node:** https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.redis/
- **Redis Best Practices:** https://redis.io/docs/management/optimization/
- **Redis University:** https://university.redis.com/ (free courses)
- **Try Redis:** https://try.redis.io/ (interactive tutorial)

### Best Practices

**Performance:**
- Use pipelining for multiple operations (reduces network round-trips)
- Avoid KEYS command in production (use SCAN instead)
- Use Redis transactions (MULTI/EXEC) for atomic operations
- Set appropriate TTLs on all cache keys
- Monitor memory usage and set maxmemory limits
- Use connection pooling (most Redis clients do this automatically)

**Caching Strategy:**
- Cache-aside pattern: App checks cache, then DB on miss
- Write-through: Write to cache and DB simultaneously
- Write-behind: Write to cache, async write to DB
- Use consistent hashing for distributed caching
- Implement cache warming for critical data
- Add randomization to TTLs to avoid cache stampede

**Data Structures:**
- Use hashes for objects instead of multiple keys
- Use sets for unique items and membership checks
- Use sorted sets for rankings, leaderboards, time-series
- Use lists for queues (LPUSH/RPOP or RPUSH/LPOP)
- Use streams for event logs and message queues

**Security:**
- Don't expose Redis to public internet (internal Docker network only)
- Use Redis ACLs for fine-grained access control (Redis 6+)
- Enable authentication in production environments
- Use TLS for encrypted connections
- Regularly backup RDB files
- Monitor for unusual command patterns

**Memory Management:**
```bash
# Set memory limit
maxmemory 512mb

# Set eviction policy
maxmemory-policy allkeys-lru

# Disable persistence for pure cache
save ""
appendonly no

# Enable compression
# (Redis doesn't compress, but use compressed values in app)
```

**Monitoring:**
- Monitor memory usage, hit rate, evictions
- Set alerts for memory thresholds
- Track slow queries with SLOWLOG
- Monitor connection count and latency
- Use Redis INFO for detailed metrics
- Consider Redis monitoring tools (RedisInsight, Redis Enterprise)
