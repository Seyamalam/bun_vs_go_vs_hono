# Bun vs Go vs Bun+Hono Benchmark

A comprehensive benchmarking project comparing three different server implementations with 5 API endpoints of varying complexity, all connected to a PostgreSQL database.

## 🏗️ Project Structure

```
.
├── database/           # PostgreSQL schema and seed data
├── bun-native/        # Pure Bun implementation
├── go-native/         # Go with standard library
├── bun-hono/          # Bun with Hono framework
├── benchmarks/        # Benchmarking scripts
├── start-servers.sh   # Start all servers
└── stop-servers.sh    # Stop all servers
```

## 📋 Prerequisites

- [Bun](https://bun.sh/) (v1.0+)
- [Go](https://go.dev/) (v1.20+)
- [PostgreSQL](https://www.postgresql.org/) (v12+) or [Docker](https://www.docker.com/)
- [Apache Bench](https://httpd.apache.org/docs/2.4/programs/ab.html) (for benchmarking)

## 🚀 Quick Start

### 1. Set Up Database

#### Using Docker (Recommended)

```bash
# Start PostgreSQL container
docker run --name benchmark-postgres \
  -e POSTGRES_PASSWORD=benchmarkpass \
  -e POSTGRES_USER=benchmarkuser \
  -e POSTGRES_DB=benchmarkdb \
  -p 5432:5432 \
  -d postgres:15

# Wait for PostgreSQL to be ready
sleep 5

# Apply schema
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < database/schema.sql

# Apply seed data
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < database/seed.sql
```

#### Using Local PostgreSQL

```bash
createdb -U postgres benchmarkdb
psql -U postgres -d benchmarkdb -f database/schema.sql
psql -U postgres -d benchmarkdb -f database/seed.sql
```

### 2. Install Dependencies

```bash
# Bun Native
cd bun-native && bun install && cd ..

# Go Native (dependencies already in go.mod)
cd go-native && go mod download && cd ..

# Bun + Hono
cd bun-hono && bun install && cd ..
```

### 3. Start Servers

```bash
./start-servers.sh
```

This will start:
- Bun Native on http://localhost:3000
- Go Native on http://localhost:3001
- Bun+Hono on http://localhost:3002

### 4. Run Benchmarks

```bash
cd benchmarks
./benchmark.sh
```

Results will be saved in `benchmarks/benchmark_results/`

### 5. Stop Servers

```bash
./stop-servers.sh
```

## 🔌 API Endpoints

All three implementations provide the same 5 endpoints:

### 1. Health Check (Simple - No Database)
```bash
GET /health
```
Returns server status and timestamp.

### 2. Get User (Simple Database Query)
```bash
GET /users/:id
```
Fetches a single user by ID.

Example:
```bash
curl http://localhost:3000/users/1
```

### 3. Get Products (Paginated Query with Filtering)
```bash
GET /products?page=1&limit=10&category=Electronics
```
Lists products with pagination and optional category filter.

Example:
```bash
curl "http://localhost:3000/products?page=1&limit=10"
curl "http://localhost:3000/products?category=Electronics"
```

### 4. Get Order Details (Complex Query with Joins)
```bash
GET /orders/:id
```
Fetches order details with user info and all order items (uses joins and aggregation).

Example:
```bash
curl http://localhost:3000/orders/1
```

### 5. Create Order (Complex Transaction)
```bash
POST /orders
Content-Type: application/json

{
  "user_id": 1,
  "items": [
    {"product_id": 1, "quantity": 2},
    {"product_id": 3, "quantity": 1}
  ]
}
```
Creates a new order with transaction handling, stock validation, and updates.

Example:
```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"items":[{"product_id":2,"quantity":1}]}'
```

## 🎯 Benchmark Methodology

The benchmark tests measure:

1. **Health Check**: Pure application overhead (no database)
2. **Simple Query**: Basic database read performance
3. **Paginated Query**: Filtering and pagination overhead
4. **Complex Query**: Join performance and data aggregation
5. **Transaction**: Write performance with validation

Each test runs:
- 10,000 requests
- 100 concurrent connections
- Using Apache Bench (ab)

## 📊 Understanding Results

Results are saved in `benchmarks/benchmark_results/summary.md` and include:

- **Requests/sec**: Throughput (higher is better)
- **Mean Time**: Average response time in ms (lower is better)

## 🏃 Running Individual Servers

### Bun Native
```bash
cd bun-native
bun src/server.ts
```

### Go Native
```bash
cd go-native
go run main.go
```

### Bun + Hono
```bash
cd bun-hono
bun src/server.ts
```

## 🧪 Testing Endpoints Manually

```bash
# Health check
curl http://localhost:3000/health

# Get user
curl http://localhost:3000/users/1

# Get products
curl "http://localhost:3000/products?page=1&limit=5"

# Get order details
curl http://localhost:3000/orders/1

# Create order
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"items":[{"product_id":2,"quantity":1}]}'
```

## 📈 What's Being Compared

### 1. Bun Native
- Uses Bun's built-in `serve()` API
- Direct PostgreSQL connection using `pg` package
- Minimal abstraction, maximum control

### 2. Go Native
- Standard library `net/http`
- `database/sql` with `lib/pq` driver
- Statically typed with excellent concurrency

### 3. Bun + Hono
- Hono web framework for routing
- Same PostgreSQL setup as Bun Native
- Framework convenience vs raw performance

## 🔧 Environment Variables

All servers support:
- `DATABASE_URL`: PostgreSQL connection string
- `PORT`: Server port (defaults: 3000, 3001, 3002)

Example:
```bash
DATABASE_URL="postgresql://user:pass@host:5432/db" bun src/server.ts
```

## 📝 Database Schema

The database includes:
- **users**: User accounts
- **products**: Product catalog
- **orders**: Order records
- **order_items**: Order line items

See `database/schema.sql` for complete schema.

## 🤝 Contributing

Feel free to add more implementations or improve existing ones!

## 📄 License

MIT