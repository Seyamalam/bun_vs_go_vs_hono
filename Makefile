.PHONY: help install setup-db start stop test benchmark clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install dependencies for all implementations
	@echo "Installing Bun Native dependencies..."
	@cd bun-native && bun install
	@echo "Installing Bun+Hono dependencies..."
	@cd bun-hono && bun install
	@echo "Installing Go dependencies..."
	@cd go-native && go mod download
	@echo "All dependencies installed!"

setup-db: ## Set up PostgreSQL database with Docker
	@echo "Starting PostgreSQL container..."
	@docker-compose up -d postgres
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	@echo "Database is ready!"

start: ## Start all three servers
	@./start-servers.sh

stop: ## Stop all servers
	@./stop-servers.sh

test: ## Test all endpoints
	@./test-endpoints.sh

benchmark: ## Run simple benchmark
	@cd benchmarks && ./simple-benchmark.sh

benchmark-full: ## Run full benchmark with Apache Bench (requires ab)
	@cd benchmarks && ./benchmark.sh

clean: ## Clean up containers and generated files
	@echo "Stopping servers..."
	@./stop-servers.sh || true
	@echo "Stopping Docker containers..."
	@docker-compose down -v
	@echo "Cleaning benchmark results..."
	@rm -rf benchmarks/benchmark_results
	@echo "Clean complete!"

dev-bun: ## Run Bun Native server in development mode
	@cd bun-native && bun --watch src/server.ts

dev-go: ## Run Go Native server in development mode
	@cd go-native && PORT=3001 go run main.go

dev-hono: ## Run Bun+Hono server in development mode
	@cd bun-hono && PORT=3002 bun --watch src/server.ts

build-go: ## Build Go binary
	@cd go-native && go build -o server main.go
	@echo "Binary created at go-native/server"

all: install setup-db start ## Install, setup database, and start all servers
