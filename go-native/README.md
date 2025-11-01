# Go Native Implementation

Go implementation using standard library and minimal dependencies.

## Features

- Standard library `net/http` for HTTP server
- `database/sql` with `lib/pq` driver for PostgreSQL
- Native Go concurrency and performance
- Strong typing and compile-time safety

## Running

```bash
# Download dependencies
go mod download

# Run server
go run main.go

# Or build and run
go build -o server main.go
./server

# With custom port
PORT=3001 go run main.go
```

## Dependencies

- `github.com/lib/pq`: PostgreSQL driver for Go's database/sql

## Architecture

- Handler functions for each endpoint
- Standard `http.ServeMux` for routing
- Connection pooling with `database/sql`
- Transaction support with Begin/Commit/Rollback

## Performance Characteristics

**Strengths:**
- Excellent concurrency with goroutines
- Compiled binary for fast execution
- Low memory footprint
- Native performance with minimal GC overhead

**Trade-offs:**
- More verbose than dynamic languages
- Requires compilation step
- Manual JSON marshaling/unmarshaling

## Building

```bash
# Build for current platform
go build -o server main.go

# Build for Linux
GOOS=linux GOARCH=amd64 go build -o server-linux main.go

# Build for macOS
GOOS=darwin GOARCH=amd64 go build -o server-macos main.go
```
