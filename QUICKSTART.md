# Quick Start Guide

Get up and running with the benchmark project in 5 minutes!

## Prerequisites

Ensure you have the following installed:
- [Bun](https://bun.sh/) - `curl -fsSL https://bun.sh/install | bash`
- [Go](https://go.dev/) - Version 1.20 or higher
- [Docker](https://www.docker.com/) - For PostgreSQL
- [Docker Compose](https://docs.docker.com/compose/) - Usually included with Docker

## 🚀 Quick Start (Using Makefile)

```bash
# 1. Install all dependencies
make install

# 2. Start PostgreSQL database
make setup-db

# 3. Start all three servers
make start

# 4. Test the endpoints
make test

# 5. Run benchmarks
make benchmark

# 6. Stop everything
make stop
```

## 📖 Manual Setup

### Step 1: Install Dependencies

```bash
# Bun Native
cd bun-native && bun install && cd ..

# Go Native
cd go-native && go mod download && cd ..

# Bun + Hono
cd bun-hono && bun install && cd ..
```

### Step 2: Start PostgreSQL

Using Docker Compose (recommended):
```bash
docker-compose up -d
```

Or using Docker directly:
```bash
docker run --name benchmark-postgres \
  -e POSTGRES_PASSWORD=benchmarkpass \
  -e POSTGRES_USER=benchmarkuser \
  -e POSTGRES_DB=benchmarkdb \
  -p 5432:5432 \
  -d postgres:15

# Wait for PostgreSQL to start
sleep 5

# Apply schema and seed data
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < database/schema.sql
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < database/seed.sql
```

### Step 3: Start Servers

Start all three servers at once:
```bash
./start-servers.sh
```

Or start them individually:

**Bun Native (Port 3000)**
```bash
cd bun-native
bun src/server.ts
```

**Go Native (Port 3001)**
```bash
cd go-native
PORT=3001 go run main.go
```

**Bun + Hono (Port 3002)**
```bash
cd bun-hono
PORT=3002 bun src/server.ts
```

### Step 4: Test Endpoints

Use the test script:
```bash
./test-endpoints.sh
```

Or manually with curl:
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

Replace port `3000` with `3001` (Go) or `3002` (Bun+Hono) to test other implementations.

### Step 5: Run Benchmarks

Simple benchmark:
```bash
cd benchmarks
./simple-benchmark.sh
```

Full benchmark (requires Apache Bench):
```bash
cd benchmarks
./benchmark.sh
```

### Step 6: Stop Everything

Stop all servers:
```bash
./stop-servers.sh
```

Stop database:
```bash
docker-compose down
# Or
docker stop benchmark-postgres
```

## 🔍 Verify Installation

Check that all tools are installed:

```bash
# Check Bun
bun --version

# Check Go
go version

# Check Docker
docker --version

# Check Docker Compose
docker-compose --version
```

## 🆘 Troubleshooting

### Port Already in Use

If you see "port already in use" errors:

```bash
# Find and kill processes on specific ports
lsof -ti:3000 | xargs kill -9
lsof -ti:3001 | xargs kill -9
lsof -ti:3002 | xargs kill -9
lsof -ti:5432 | xargs kill -9
```

### Database Connection Issues

If servers can't connect to PostgreSQL:

1. Check if PostgreSQL is running:
   ```bash
   docker ps | grep postgres
   ```

2. Test database connection:
   ```bash
   docker exec -it benchmark-postgres psql -U benchmarkuser -d benchmarkdb -c "SELECT 1;"
   ```

3. Check logs:
   ```bash
   docker logs benchmark-postgres
   ```

### Bun Not Found

If `bun` command is not found after installation:

```bash
# Source the bash profile
source ~/.bash_profile

# Or add to PATH manually
export PATH="$HOME/.bun/bin:$PATH"
```

### Permission Denied

If scripts fail with permission errors:

```bash
chmod +x start-servers.sh stop-servers.sh test-endpoints.sh
chmod +x benchmarks/*.sh
```

## 📊 What's Next?

- Read [BENCHMARKS.md](BENCHMARKS.md) for detailed performance analysis
- Check individual implementation READMEs:
  - [bun-native/README.md](bun-native/README.md)
  - [go-native/README.md](go-native/README.md)
  - [bun-hono/README.md](bun-hono/README.md)
- Customize endpoints for your use case
- Add your own benchmarks
- Try with different database configurations

## 🤝 Need Help?

- Check the main [README.md](README.md) for detailed documentation
- Review the database schema in [database/schema.sql](database/schema.sql)
- Look at the endpoint implementations in the `src/` directories

## 🎯 Common Tasks

### View Database Data

```bash
docker exec -it benchmark-postgres psql -U benchmarkuser -d benchmarkdb

# Then run SQL commands:
SELECT * FROM users;
SELECT * FROM products;
SELECT * FROM orders;
```

### Reset Database

```bash
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < database/schema.sql
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < database/seed.sql
```

### Clean Everything

```bash
make clean
# Or manually:
./stop-servers.sh
docker-compose down -v
rm -rf benchmarks/benchmark_results
```
