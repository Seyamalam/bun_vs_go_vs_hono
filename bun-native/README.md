# Bun Native Implementation

Pure Bun implementation using only built-in features.

## Features

- Uses Bun's built-in `serve()` API
- Direct PostgreSQL connection with `pg` package
- Manual routing and request handling
- Minimal abstraction for maximum performance

## Running

```bash
# Install dependencies
bun install

# Run server
bun src/server.ts

# Or with custom port
PORT=3000 bun src/server.ts
```

## Dependencies

- `pg`: PostgreSQL client
- `@types/pg`: TypeScript types for pg

## Architecture

- Direct request handling in the `fetch` function
- Manual URL parsing and route matching
- Connection pooling with configurable pool size
- Transaction support for complex operations

## Performance Characteristics

**Strengths:**
- Minimal overhead
- Direct control over request handling
- Fast JSON parsing with Bun
- Efficient PostgreSQL connection pooling

**Trade-offs:**
- Manual route handling
- Less convenient than framework-based solutions
- More code for complex routing scenarios

This project was created using `bun init` in bun v1.3.1. [Bun](https://bun.com) is a fast all-in-one JavaScript runtime.
