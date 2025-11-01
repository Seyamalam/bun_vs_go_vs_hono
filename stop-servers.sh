#!/bin/bash

# Stop all servers

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Stopping all servers...${NC}"

# Stop servers using saved PIDs
if [ -f /tmp/bun-native.pid ]; then
    PID=$(cat /tmp/bun-native.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "Stopped Bun Native (PID: $PID)"
    fi
    rm /tmp/bun-native.pid
fi

if [ -f /tmp/go-native.pid ]; then
    PID=$(cat /tmp/go-native.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "Stopped Go Native (PID: $PID)"
    fi
    rm /tmp/go-native.pid
fi

if [ -f /tmp/bun-hono.pid ]; then
    PID=$(cat /tmp/bun-hono.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "Stopped Bun+Hono (PID: $PID)"
    fi
    rm /tmp/bun-hono.pid
fi

# Also try to kill any remaining processes on the ports
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
lsof -ti:3002 | xargs kill -9 2>/dev/null || true

echo -e "${GREEN}All servers stopped!${NC}"
