# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                      │
│              (curl, browser, load testing tools)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                           │
│                    (Optional/Production)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
       ┌────────────┐ ┌────────────┐ ┌────────────┐
       │ Bun Native │ │ Go Native  │ │ Bun + Hono │
       │  Port 3000 │ │ Port 3001  │ │ Port 3002  │
       └────────────┘ └────────────┘ └────────────┘
                │             │             │
                └─────────────┼─────────────┘
                              ▼
                    ┌──────────────────┐
                    │   PostgreSQL     │
                    │    Port 5432     │
                    └──────────────────┘
```

## Implementation Architecture

### Bun Native

```
┌────────────────────────────────────────────┐
│          Bun Native Server                 │
├────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐ │
│  │     Built-in serve() API             │ │
│  │  • Manual routing                    │ │
│  │  • URL parsing                       │ │
│  │  • Request/Response handling         │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│  ┌──────────────────────────────────────┐ │
│  │     Business Logic Layer             │ │
│  │  • Health check                      │ │
│  │  • User operations                   │ │
│  │  • Product operations                │ │
│  │  • Order operations                  │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│  ┌──────────────────────────────────────┐ │
│  │     Database Layer (pg)              │ │
│  │  • Connection pooling                │ │
│  │  • Query execution                   │ │
│  │  • Transaction management            │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

### Go Native

```
┌────────────────────────────────────────────┐
│          Go Native Server                  │
├────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐ │
│  │     net/http Server                  │ │
│  │  • ServeMux routing                  │ │
│  │  • Handler functions                 │ │
│  │  • HTTP/2 support                    │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│  ┌──────────────────────────────────────┐ │
│  │     Business Logic Layer             │ │
│  │  • Health check handler              │ │
│  │  • User handlers                     │ │
│  │  • Product handlers                  │ │
│  │  • Order handlers                    │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│  ┌──────────────────────────────────────┐ │
│  │     Database Layer (database/sql)    │ │
│  │  • Connection pooling                │ │
│  │  • Prepared statements               │ │
│  │  • Transaction support               │ │
│  │  • lib/pq driver                     │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

### Bun + Hono

```
┌────────────────────────────────────────────┐
│        Bun + Hono Server                   │
├────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐ │
│  │     Hono Framework                   │ │
│  │  • Declarative routing               │ │
│  │  • Context object                    │ │
│  │  • Middleware support                │ │
│  │  • Built-in utilities                │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│  ┌──────────────────────────────────────┐ │
│  │     Route Handlers                   │ │
│  │  • Health check                      │ │
│  │  • User routes                       │ │
│  │  • Product routes                    │ │
│  │  • Order routes                      │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│  ┌──────────────────────────────────────┐ │
│  │     Database Layer (pg)              │ │
│  │  • Connection pooling                │ │
│  │  • Query execution                   │ │
│  │  • Transaction management            │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

## Database Schema

```
┌──────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐         ┌─────────────┐               │
│  │   users     │         │  products   │               │
│  ├─────────────┤         ├─────────────┤               │
│  │ id (PK)     │         │ id (PK)     │               │
│  │ username    │         │ name        │               │
│  │ email       │         │ description │               │
│  │ created_at  │         │ price       │               │
│  │ updated_at  │         │ stock_qty   │               │
│  └─────────────┘         │ category    │               │
│        │                 └─────────────┘               │
│        │                       │                        │
│        │                       │                        │
│  ┌─────▼────────┐        ┌────▼──────────┐            │
│  │   orders     │        │  order_items  │            │
│  ├──────────────┤        ├───────────────┤            │
│  │ id (PK)      │◄───────│ id (PK)       │            │
│  │ user_id (FK) │        │ order_id (FK) │            │
│  │ total_amount │        │ product_id(FK)│            │
│  │ status       │        │ quantity      │            │
│  │ created_at   │        │ price         │            │
│  └──────────────┘        └───────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Request Flow

### Simple Query (GET /users/:id)

```
1. Client Request
   ↓
2. Server receives HTTP request
   ↓
3. Route matching
   ↓
4. Extract user ID from URL
   ↓
5. Execute SQL query:
   SELECT * FROM users WHERE id = $1
   ↓
6. Fetch result from database
   ↓
7. Format response as JSON
   ↓
8. Send HTTP response to client
```

### Complex Transaction (POST /orders)

```
1. Client sends JSON payload
   ↓
2. Server receives and parses request
   ↓
3. Validate request body
   ↓
4. Begin database transaction
   ↓
5. For each item:
   a. Check product exists
   b. Verify stock availability
   c. Calculate price
   d. Update stock quantity
   ↓
6. Create order record
   ↓
7. Create order_items records
   ↓
8. Commit transaction
   ↓
9. Return order details
   ↓
10. Send HTTP response
```

## Concurrency Model

### Bun Native & Bun + Hono

```
┌────────────────────────────────────┐
│    Single-threaded Event Loop     │
├────────────────────────────────────┤
│                                    │
│  Request 1 ─┐                     │
│             │                     │
│  Request 2 ─┼─► Event Loop ─┐    │
│             │               │    │
│  Request 3 ─┘               ▼    │
│                      ┌────────────┤
│                      │  Async I/O │
│                      │  • DB calls│
│                      │  • Network │
│                      └────────────┤
└────────────────────────────────────┘
```

### Go Native

```
┌────────────────────────────────────┐
│      Goroutine-based Concurrency  │
├────────────────────────────────────┤
│                                    │
│  Request 1 ──► Goroutine 1 ──► DB │
│                                    │
│  Request 2 ──► Goroutine 2 ──► DB │
│                                    │
│  Request 3 ──► Goroutine 3 ──► DB │
│                                    │
│  Request N ──► Goroutine N ──► DB │
│                                    │
└────────────────────────────────────┘
```

## Connection Pooling

All implementations use connection pooling:

```
┌────────────────────────────────────┐
│       Application Servers          │
└────────────────────────────────────┘
                │
                │ Multiple connections
                ▼
┌────────────────────────────────────┐
│       Connection Pool              │
│                                    │
│  [Conn1] [Conn2] ... [ConnN]      │
│  (Max: 20 connections)             │
└────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────┐
│       PostgreSQL Server            │
└────────────────────────────────────┘
```

Configuration:
- Max connections: 20
- Idle connections: 10 (Go)
- Connection reuse: Enabled

## Deployment Options

### Docker Container

```
┌─────────────────────────────────────┐
│       Docker Container              │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐ │
│  │  Bun/Go Runtime               │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │  Application Code             │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │  Dependencies                 │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
              │
              ▼
    ┌──────────────────┐
    │   Network Bridge │
    └──────────────────┘
              │
              ▼
    ┌──────────────────┐
    │  PostgreSQL      │
    │  Container       │
    └──────────────────┘
```

### Kubernetes

```
┌─────────────────────────────────────────┐
│            Kubernetes Cluster           │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐ │
│  │      Ingress Controller           │ │
│  └───────────────────────────────────┘ │
│                  │                      │
│  ┌───────────────▼─────────────────┐  │
│  │       Service (LoadBalancer)    │  │
│  └───────────────┬─────────────────┘  │
│                  │                      │
│  ┌───────────────▼─────────────────┐  │
│  │   Deployment (3 replicas)       │  │
│  │  ┌─────┐ ┌─────┐ ┌─────┐       │  │
│  │  │ Pod │ │ Pod │ │ Pod │       │  │
│  │  └─────┘ └─────┘ └─────┘       │  │
│  └───────────────┬─────────────────┘  │
│                  │                      │
│  ┌───────────────▼─────────────────┐  │
│  │     PostgreSQL StatefulSet      │  │
│  │  ┌─────────────────────────┐   │  │
│  │  │  Persistent Volume      │   │  │
│  │  └─────────────────────────┘   │  │
│  └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Monitoring & Observability

```
┌────────────────────────────────────────┐
│         Application Servers            │
│  • Logs                                │
│  • Metrics                             │
│  • Traces                              │
└────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│       OpenTelemetry Collector          │
└────────────────────────────────────────┘
                │
        ┌───────┼───────┐
        ▼       ▼       ▼
    ┌────┐  ┌────┐  ┌─────┐
    │Logs│  │Metr│  │Trace│
    │(Loki)│(Prom)│(Jaeger)
    └────┘  └────┘  └─────┘
```

## Performance Bottlenecks

Common bottlenecks across all implementations:

1. **Database Connection Pool**
   - Limited to 20 connections
   - Can be increased if needed

2. **Database Queries**
   - Complex joins can be slow
   - Proper indexing is critical

3. **Network I/O**
   - Latency to database
   - Client connection overhead

4. **JSON Serialization**
   - Large payloads
   - Deep object structures

## Optimization Strategies

1. **Database Level**
   - Add indexes
   - Optimize queries
   - Use materialized views
   - Implement caching (Redis)

2. **Application Level**
   - Connection pooling
   - Query result caching
   - Response compression
   - Request batching

3. **Infrastructure Level**
   - Horizontal scaling
   - Load balancing
   - CDN for static assets
   - Database replication

## Security Considerations

```
┌────────────────────────────────────────┐
│         Security Layers                │
├────────────────────────────────────────┤
│  1. TLS/HTTPS (Transport)              │
│  2. Authentication (JWT/OAuth)         │
│  3. Input Validation                   │
│  4. SQL Injection Prevention           │
│     (Parameterized queries)            │
│  5. Rate Limiting                      │
│  6. CORS Configuration                 │
│  7. Security Headers                   │
└────────────────────────────────────────┘
```

Current implementation includes:
- ✅ Parameterized SQL queries
- ✅ Input validation (POST endpoints)
- ⚠️ No authentication (example project)
- ⚠️ No rate limiting (example project)
- ⚠️ No HTTPS (development setup)

For production, add:
- Authentication/Authorization
- Rate limiting
- HTTPS/TLS
- Request validation
- CORS configuration
- Security headers
