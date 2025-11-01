# Bun + Hono Implementation

Bun runtime with Hono web framework for convenient routing and middleware.

## Features

- Hono framework for elegant routing
- Same PostgreSQL setup as Bun Native
- Express-like API for familiarity
- Middleware support for extensibility

## Running

```bash
# Install dependencies
bun install

# Run server
bun src/server.ts

# Or with custom port
PORT=3002 bun src/server.ts
```

## Dependencies

- `hono`: Fast, lightweight web framework
- `pg`: PostgreSQL client
- `@types/pg`: TypeScript types for pg

## Architecture

- Hono app instance with route handlers
- Clean, declarative routing
- Context object for request/response handling
- Same PostgreSQL pooling as Bun Native

## Performance Characteristics

**Strengths:**
- Framework convenience without major performance penalty
- Clean, maintainable code
- Middleware ecosystem
- Type-safe with TypeScript

**Trade-offs:**
- Slight overhead compared to pure Bun
- Framework learning curve
- Additional dependency

## Why Hono?

Hono is specifically designed for edge runtimes and is extremely lightweight. It provides:
- Minimal overhead
- Fast routing
- Web standard APIs
- Excellent TypeScript support

This project was created using `bun init` in bun v1.3.1. [Bun](https://bun.com) is a fast all-in-one JavaScript runtime.
