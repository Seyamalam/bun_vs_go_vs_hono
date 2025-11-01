# Contributing Guide

Thank you for considering contributing to this benchmark project!

## How to Contribute

### 1. Adding New Endpoints

To add a new endpoint to all three implementations:

1. **Update Database Schema** (if needed)
   ```sql
   -- Add to database/schema.sql
   CREATE TABLE IF NOT EXISTS new_table (
       id SERIAL PRIMARY KEY,
       -- your columns
   );
   ```

2. **Implement in Bun Native**
   ```typescript
   // Add to bun-native/src/server.ts
   async function handleNewEndpoint() {
       // Your implementation
   }
   
   // Add route in fetch()
   if (path === "/new-endpoint" && method === "GET") {
       return handleNewEndpoint();
   }
   ```

3. **Implement in Go Native**
   ```go
   // Add to go-native/main.go
   func handleNewEndpoint(w http.ResponseWriter, r *http.Request) {
       // Your implementation
   }
   
   // Register in main()
   http.HandleFunc("/new-endpoint", handleNewEndpoint)
   ```

4. **Implement in Bun + Hono**
   ```typescript
   // Add to bun-hono/src/server.ts
   app.get("/new-endpoint", async (c) => {
       // Your implementation
   });
   ```

### 2. Adding New Implementations

Want to add another language/framework? Great!

1. **Create Directory Structure**
   ```bash
   mkdir -p new-implementation/src
   ```

2. **Implement All 5 Endpoints**
   - GET /health
   - GET /users/:id
   - GET /products (with pagination)
   - GET /orders/:id
   - POST /orders

3. **Add to Scripts**
   - Update `start-servers.sh`
   - Update `stop-servers.sh`
   - Update `test-endpoints.sh`
   - Update benchmark scripts

4. **Document Your Implementation**
   - Add README.md
   - Explain unique features
   - Document dependencies
   - Add setup instructions

### 3. Improving Benchmarks

Ideas for better benchmarking:

- Add concurrent load testing
- Measure memory usage
- Profile CPU usage
- Test with different database loads
- Add stress testing
- Measure cold start times
- Test with different payload sizes

Example benchmark addition:

```bash
# Add to benchmarks/
#!/bin/bash
# your-benchmark.sh

# Your benchmark implementation
```

### 4. Improving Documentation

Documentation improvements are always welcome:

- Fix typos
- Add examples
- Clarify instructions
- Add diagrams
- Translate to other languages

### 5. Bug Fixes

If you find a bug:

1. **Create an Issue**
   - Describe the bug
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details

2. **Submit a Pull Request**
   - Reference the issue
   - Add tests if applicable
   - Update documentation

## Development Setup

### Prerequisites

```bash
# Install Bun
curl -fsSL https://bun.sh/install | bash

# Install Go
# Follow: https://go.dev/doc/install

# Install Docker
# Follow: https://docs.docker.com/get-docker/
```

### Quick Start

```bash
# Clone the repository
git clone https://github.com/Seyamalam/bun_vs_go_vs_hono.git
cd bun_vs_go_vs_hono

# Install dependencies
make install

# Start database
make setup-db

# Start servers
make start

# Run tests
make test
```

## Code Style

### TypeScript/Bun

- Use TypeScript for type safety
- Follow ESLint/Prettier conventions
- Use async/await for asynchronous code
- Add comments for complex logic

```typescript
// Good
async function handleUser(userId: string) {
    const result = await pool.query("SELECT * FROM users WHERE id = $1", [userId]);
    return result.rows[0];
}

// Bad
function handleUser(userId) {
    pool.query("SELECT * FROM users WHERE id = " + userId, (err, result) => {
        // callback hell
    });
}
```

### Go

- Follow official Go style guide
- Use `gofmt` for formatting
- Add comments for exported functions
- Handle errors explicitly

```go
// Good
func handleUser(userId string) (User, error) {
    var user User
    err := db.QueryRow("SELECT * FROM users WHERE id = $1", userId).Scan(&user)
    if err != nil {
        return User{}, err
    }
    return user, nil
}

// Bad
func handleUser(userId string) User {
    var user User
    db.QueryRow("SELECT * FROM users WHERE id = " + userId).Scan(&user)
    return user
}
```

## Testing

### Manual Testing

```bash
# Test a specific endpoint
curl http://localhost:3000/users/1

# Test with verbose output
curl -v http://localhost:3000/health

# Test POST endpoint
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"items":[{"product_id":2,"quantity":1}]}'
```

### Automated Testing

Currently, the project uses manual testing via scripts. To add automated tests:

**Bun/TypeScript:**
```typescript
// Add to bun-native/tests/server.test.ts
import { expect, test } from "bun:test";

test("health endpoint returns ok", async () => {
    const response = await fetch("http://localhost:3000/health");
    const data = await response.json();
    expect(data.status).toBe("ok");
});
```

**Go:**
```go
// Add to go-native/main_test.go
func TestHealthEndpoint(t *testing.T) {
    req := httptest.NewRequest("GET", "/health", nil)
    w := httptest.NewRecorder()
    handleHealth(w, req)
    
    if w.Code != http.StatusOK {
        t.Errorf("Expected 200, got %d", w.Code)
    }
}
```

## Pull Request Process

1. **Fork the Repository**

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Write clean code
   - Add tests if applicable
   - Update documentation

4. **Test Your Changes**
   ```bash
   make test
   make benchmark
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add: Brief description of changes"
   ```

   Use conventional commits:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Docs:` for documentation
   - `Refactor:` for code refactoring
   - `Test:` for test additions

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Describe your changes
   - Reference related issues
   - Add screenshots if applicable

## Performance Guidelines

When adding code, consider:

1. **Database Queries**
   - Use parameterized queries (never string concatenation)
   - Add indexes for frequently queried columns
   - Avoid N+1 queries

2. **Memory Usage**
   - Close database connections
   - Avoid memory leaks
   - Use connection pooling

3. **Response Times**
   - Keep endpoints under 100ms when possible
   - Use pagination for large datasets
   - Cache when appropriate

4. **Scalability**
   - Ensure stateless design
   - Use connection pools
   - Consider horizontal scaling

## Adding New Languages/Frameworks

Interested in adding Rust, Python, Java, etc.?

1. **Match the Interface**
   - Implement same 5 endpoints
   - Use same database
   - Return same JSON structure

2. **Add Documentation**
   - README with setup instructions
   - Performance characteristics
   - Pros/cons comparison

3. **Update Main Files**
   - README.md
   - COMPARISON.md
   - Benchmark scripts

4. **Provide Examples**
   ```
   new-language/
   ├── README.md
   ├── src/
   │   └── main.{ext}
   ├── tests/
   └── package.{ext}
   ```

## Questions?

- Open an issue for discussions
- Check existing documentation
- Review code examples

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help each other learn

Thank you for contributing! 🎉
