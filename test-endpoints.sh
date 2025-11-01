#!/bin/bash

# Test script to verify all endpoints are working correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing All API Endpoints${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to test endpoint
test_endpoint() {
    local name=$1
    local port=$2
    local method=$3
    local endpoint=$4
    local data=$5
    
    echo -e "${YELLOW}Testing $name - $method $endpoint${NC}"
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:$port$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" "http://localhost:$port$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✓ Success (HTTP $http_code)${NC}"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    else
        echo -e "${RED}✗ Failed (HTTP $http_code)${NC}"
        echo "$body"
    fi
    echo ""
}

# Test each implementation
for impl in "Bun-Native:3000" "Go-Native:3001" "Bun-Hono:3002"; do
    name=$(echo $impl | cut -d: -f1)
    port=$(echo $impl | cut -d: -f2)
    
    echo -e "${BLUE}=== Testing $name (Port $port) ===${NC}"
    echo ""
    
    # Test 1: Health check
    test_endpoint "$name" "$port" "GET" "/health"
    
    # Test 2: Get user
    test_endpoint "$name" "$port" "GET" "/users/1"
    
    # Test 3: Get products (paginated)
    test_endpoint "$name" "$port" "GET" "/products?page=1&limit=5"
    
    # Test 4: Get products (with category filter)
    test_endpoint "$name" "$port" "GET" "/products?category=Electronics"
    
    # Test 5: Get order details
    test_endpoint "$name" "$port" "GET" "/orders/1"
    
    # Test 6: Create order (commented out to avoid modifying database during tests)
    # test_endpoint "$name" "$port" "POST" "/orders" '{"user_id":1,"items":[{"product_id":2,"quantity":1}]}'
    
    echo -e "${BLUE}======================================${NC}"
    echo ""
done

echo -e "${GREEN}All endpoint tests completed!${NC}"
echo -e "${YELLOW}Note: POST /orders test is commented out to avoid database modifications${NC}"
