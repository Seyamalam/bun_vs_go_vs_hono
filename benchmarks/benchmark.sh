#!/bin/bash

# Benchmark script for comparing Bun, Go, and Bun+Hono
# This script uses Apache Bench (ab) to test the servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REQUESTS=10000
CONCURRENCY=100
OUTPUT_DIR="benchmark_results"

# Create output directory
mkdir -p $OUTPUT_DIR

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Benchmark: Bun vs Go vs Bun+Hono${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Requests: $REQUESTS"
echo "Concurrency: $CONCURRENCY"
echo ""

# Function to run benchmark
run_benchmark() {
    local name=$1
    local port=$2
    local endpoint=$3
    local method=$4
    local data=$5
    
    echo -e "${YELLOW}Testing $name - $endpoint${NC}"
    
    if [ "$method" = "POST" ]; then
        ab -n $REQUESTS -c $CONCURRENCY -p "$data" -T "application/json" \
           "http://localhost:$port$endpoint" > "$OUTPUT_DIR/${name}_${endpoint//\//_}.txt" 2>&1
    else
        ab -n $REQUESTS -c $CONCURRENCY \
           "http://localhost:$port$endpoint" > "$OUTPUT_DIR/${name}_${endpoint//\//_}.txt" 2>&1
    fi
    
    # Extract key metrics
    local rps=$(grep "Requests per second:" "$OUTPUT_DIR/${name}_${endpoint//\//_}.txt" | awk '{print $4}')
    local mean_time=$(grep "Time per request:" "$OUTPUT_DIR/${name}_${endpoint//\//_}.txt" | head -1 | awk '{print $4}')
    
    echo -e "${GREEN}  Requests/sec: $rps${NC}"
    echo -e "${GREEN}  Mean time: $mean_time ms${NC}"
    echo ""
}

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    echo -e "${RED}Apache Bench (ab) is not installed. Installing...${NC}"
    sudo apt-get update && sudo apt-get install -y apache2-utils
fi

# Test 1: Health Check (Simplest endpoint)
echo -e "${BLUE}=== Test 1: Health Check ===${NC}"
run_benchmark "bun-native" 3000 "/health" "GET"
run_benchmark "go-native" 3001 "/health" "GET"
run_benchmark "bun-hono" 3002 "/health" "GET"

# Test 2: Simple Database Query
echo -e "${BLUE}=== Test 2: Get User (Simple Query) ===${NC}"
run_benchmark "bun-native" 3000 "/users/1" "GET"
run_benchmark "go-native" 3001 "/users/1" "GET"
run_benchmark "bun-hono" 3002 "/users/1" "GET"

# Test 3: Paginated Query
echo -e "${BLUE}=== Test 3: Get Products (Paginated) ===${NC}"
run_benchmark "bun-native" 3000 "/products?page=1&limit=10" "GET"
run_benchmark "go-native" 3001 "/products?page=1&limit=10" "GET"
run_benchmark "bun-hono" 3002 "/products?page=1&limit=10" "GET"

# Test 4: Complex Query with Joins
echo -e "${BLUE}=== Test 4: Get Order Details (Complex Join) ===${NC}"
run_benchmark "bun-native" 3000 "/orders/1" "GET"
run_benchmark "go-native" 3001 "/orders/1" "GET"
run_benchmark "bun-hono" 3002 "/orders/1" "GET"

# Generate summary report
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Generating Summary Report${NC}"
echo -e "${BLUE}========================================${NC}"

cat > "$OUTPUT_DIR/summary.md" << 'EOF'
# Benchmark Results: Bun vs Go vs Bun+Hono

## Test Configuration
- Requests: 10,000 per test
- Concurrency: 100 concurrent connections
- Database: PostgreSQL

## Results Summary

### Test 1: Health Check (No Database)
| Implementation | Requests/sec | Mean Time (ms) |
|---------------|--------------|----------------|
EOF

# Helper function to extract and format metrics
extract_metrics() {
    local file=$1
    local rps=$(grep "Requests per second:" "$file" 2>/dev/null | awk '{print $4}' || echo "N/A")
    local mean=$(grep "Time per request:" "$file" 2>/dev/null | head -1 | awk '{print $4}' || echo "N/A")
    echo "| $(basename $file .txt) | $rps | $mean |"
}

# Add metrics to summary
for impl in bun-native go-native bun-hono; do
    extract_metrics "$OUTPUT_DIR/${impl}__health.txt" >> "$OUTPUT_DIR/summary.md"
done

cat >> "$OUTPUT_DIR/summary.md" << 'EOF'

### Test 2: Get User (Simple Database Query)
| Implementation | Requests/sec | Mean Time (ms) |
|---------------|--------------|----------------|
EOF

for impl in bun-native go-native bun-hono; do
    extract_metrics "$OUTPUT_DIR/${impl}__users_1.txt" >> "$OUTPUT_DIR/summary.md"
done

cat >> "$OUTPUT_DIR/summary.md" << 'EOF'

### Test 3: Get Products (Paginated Query)
| Implementation | Requests/sec | Mean Time (ms) |
|---------------|--------------|----------------|
EOF

for impl in bun-native go-native bun-hono; do
    extract_metrics "$OUTPUT_DIR/${impl}__products_page=1_limit=10.txt" >> "$OUTPUT_DIR/summary.md"
done

cat >> "$OUTPUT_DIR/summary.md" << 'EOF'

### Test 4: Get Order Details (Complex Join)
| Implementation | Requests/sec | Mean Time (ms) |
|---------------|--------------|----------------|
EOF

for impl in bun-native go-native bun-hono; do
    extract_metrics "$OUTPUT_DIR/${impl}__orders_1.txt" >> "$OUTPUT_DIR/summary.md"
done

cat >> "$OUTPUT_DIR/summary.md" << 'EOF'

## Analysis

Results show performance comparison across three implementations:
1. **Bun Native**: Pure Bun with built-in features
2. **Go Native**: Go with standard library
3. **Bun + Hono**: Bun with Hono framework

Each test measures different aspects of performance from simple responses to complex database operations.
EOF

echo ""
echo -e "${GREEN}Benchmarking complete! Results saved to $OUTPUT_DIR/summary.md${NC}"
cat "$OUTPUT_DIR/summary.md"
