# Database Setup

This directory contains the PostgreSQL database schema and seed data for the benchmark project.

## Setup Instructions

### Using Docker (Recommended)

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
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < schema.sql

# Apply seed data
docker exec -i benchmark-postgres psql -U benchmarkuser -d benchmarkdb < seed.sql
```

### Using Local PostgreSQL

```bash
# Create database
createdb -U postgres benchmarkdb

# Apply schema
psql -U postgres -d benchmarkdb -f schema.sql

# Apply seed data
psql -U postgres -d benchmarkdb -f seed.sql
```

## Database Connection String

```
postgresql://benchmarkuser:benchmarkpass@localhost:5432/benchmarkdb
```

## Schema Overview

- **users**: Basic user information
- **products**: Product catalog
- **orders**: Order records with user relationships
- **order_items**: Order line items with product relationships

This schema supports queries of varying complexity for benchmarking purposes.
