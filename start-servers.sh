#!/bin/bash

# Start all three servers for benchmarking

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting all servers...${NC}"
echo ""

# Source bash profile to get bun in PATH
source ~/.bash_profile

# Start Bun Native Server (port 3000)
echo -e "${GREEN}Starting Bun Native Server on port 3000...${NC}"
cd bun-native && bun src/server.ts &
BUN_NATIVE_PID=$!
cd ..

# Start Go Native Server (port 3001)
echo -e "${GREEN}Starting Go Native Server on port 3001...${NC}"
cd go-native && PORT=3001 go run main.go &
GO_NATIVE_PID=$!
cd ..

# Start Bun+Hono Server (port 3002)
echo -e "${GREEN}Starting Bun+Hono Server on port 3002...${NC}"
cd bun-hono && PORT=3002 bun src/server.ts &
BUN_HONO_PID=$!
cd ..

# Save PIDs for cleanup
echo $BUN_NATIVE_PID > /tmp/bun-native.pid
echo $GO_NATIVE_PID > /tmp/go-native.pid
echo $BUN_HONO_PID > /tmp/bun-hono.pid

echo ""
echo -e "${GREEN}All servers started!${NC}"
echo "Bun Native: http://localhost:3000 (PID: $BUN_NATIVE_PID)"
echo "Go Native: http://localhost:3001 (PID: $GO_NATIVE_PID)"
echo "Bun+Hono: http://localhost:3002 (PID: $BUN_HONO_PID)"
echo ""
echo "Use ./stop-servers.sh to stop all servers"
echo ""

# Wait a bit for servers to start
sleep 3

# Test if servers are responding
echo "Testing server health..."
curl -s http://localhost:3000/health > /dev/null && echo "✓ Bun Native is responding" || echo "✗ Bun Native failed to start"
curl -s http://localhost:3001/health > /dev/null && echo "✓ Go Native is responding" || echo "✗ Go Native failed to start"
curl -s http://localhost:3002/health > /dev/null && echo "✓ Bun+Hono is responding" || echo "✗ Bun+Hono failed to start"
