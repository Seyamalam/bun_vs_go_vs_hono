#!/bin/bash

# Simple benchmark script using curl for basic performance testing
# This is a lightweight alternative when Apache Bench is not available

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ITERATIONS=1000
OUTPUT_DIR="benchmark_results"

mkdir -p $OUTPUT_DIR

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Simple Benchmark: Bun vs Go vs Bun+Hono${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Iterations per test: $ITERATIONS"
echo ""

# Function to benchmark endpoint
benchmark_endpoint() {
    local name=$1
    local port=$2
    local endpoint=$3
    
    echo -e "${YELLOW}Testing $name - $endpoint${NC}"
    
    local start=$(date +%s%N)
    for i in $(seq 1 $ITERATIONS); do
        curl -s "http://localhost:$port$endpoint" > /dev/null
    done
    local end=$(date +%s%N)
    
    local duration=$(( ($end - $start) / 1000000 )) # Convert to ms
    local avg=$(( $duration / $ITERATIONS ))
    local rps=$(( $ITERATIONS * 1000 / $duration ))
    
    echo -e "${GREEN}  Duration: ${duration}ms (${avg}ms avg)${NC}"
    echo -e "${GREEN}  Requests/sec: ~${rps}${NC}"
    echo ""
    
    # Save results
    echo "$name,$endpoint,$duration,$avg,$rps" >> "$OUTPUT_DIR/results.csv"
}

# Initialize results file
echo "Implementation,Endpoint,Total Time (ms),Avg Time (ms),Requests/sec" > "$OUTPUT_DIR/results.csv"

echo -e "${BLUE}=== Test 1: Health Check ===${NC}"
benchmark_endpoint "bun-native" 3000 "/health"
benchmark_endpoint "go-native" 3001 "/health"
benchmark_endpoint "bun-hono" 3002 "/health"

echo -e "${BLUE}=== Test 2: Get User (Simple Query) ===${NC}"
benchmark_endpoint "bun-native" 3000 "/users/1"
benchmark_endpoint "go-native" 3001 "/users/1"
benchmark_endpoint "bun-hono" 3002 "/users/1"

echo -e "${BLUE}=== Test 3: Get Products (Paginated) ===${NC}"
benchmark_endpoint "bun-native" 3000 "/products?page=1&limit=10"
benchmark_endpoint "go-native" 3001 "/products?page=1&limit=10"
benchmark_endpoint "bun-hono" 3002 "/products?page=1&limit=10"

echo -e "${BLUE}=== Test 4: Get Order Details (Complex Join) ===${NC}"
benchmark_endpoint "bun-native" 3000 "/orders/1"
benchmark_endpoint "go-native" 3001 "/orders/1"
benchmark_endpoint "bun-hono" 3002 "/orders/1"

# Generate summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cat "$OUTPUT_DIR/results.csv" | column -t -s,

echo ""
echo -e "${GREEN}Results saved to $OUTPUT_DIR/results.csv${NC}"
