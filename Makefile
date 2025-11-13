.PHONY: help clean install init dev up down restart logs ps stop-all start-all

SHELL = /bin/zsh
CONDA_ACTIVATE = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate
ENV_NAME = work-assistant

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Clean build artifacts and volumes
	@echo "Cleaning build artifacts..."
	docker-compose down -v
	# rm -rf ~/.work-assistant
	@echo "Done"

conda-env: ## Create conda environment from environment.yml
	@echo "Creating conda environment..."
	conda env create -f environment.yml
	@echo "Done. Activate with: conda activate work-assistant"

conda-update: ## Update conda environment
	@echo "Updating conda environment..."
	conda env update -f environment.yml --prune
	@echo "Done"

install: ## Verify conda environment is set up (dependencies already installed via conda-env)
	conda env create -f environment.yml --name $(ENV_NAME) || true && \
	$(CONDA_ACTIVATE) $(ENV_NAME) && \
	pip install --upgrade pip

init: ## Create required directories for Docker volumes
	@echo "Creating required directories..."
	@mkdir -p ~/.work-assistant/{mongodb/{data,config},postgres/data,redpanda/data,n8n/data,prefect/data,browserless/data,openwebui/data,traefik/data}
	@mkdir -p ./shared/nginx/data
	@echo "Ensuring proper permissions..."
	@chmod 755 ~/.work-assistant 2>/dev/null || true
	@chmod 755 ~/.work-assistant/postgres 2>/dev/null || true
	@chmod 755 ~/.work-assistant/postgres/data 2>/dev/null || true
	@echo "Directories created successfully"

dev: init ## Start all services in development mode
	@echo "Starting development environment..."
	docker-compose up -d
	@echo "Services started. Access:"
	@echo "  - N8N: http://localhost:5678"
	@echo "  - Prefect: http://localhost:4200"
	@echo "  - Redpanda Console: http://localhost:8080"
	@echo "  - Browserless: http://localhost:3000"
	@echo "  - OpenWebUI: http://localhost:3001"
	@echo "  - Nginx: http://localhost:9080"
	@echo "  - Traefik Dashboard: http://localhost:8081/dashboard/"
	@echo "  - MongoDB: localhost:27017"
	@echo "  - PostgreSQL: localhost:5432"

up: init ## Start all services
	docker-compose up -d

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## Show logs from all services
	docker-compose logs -f

ps: ## Show status of all services
	docker-compose ps

stop-all: ## Stop all services and remove containers
	docker-compose down

start-all: init ## Start all services
	docker-compose up -d

stop-%: ## Stop a specific service (e.g., make stop-n8n)
	docker-compose stop $(patsubst stop-%,%,$@)

start-%: ## Start a specific service (e.g., make start-n8n)
	docker-compose start $(patsubst start-%,%,$@)

logs-%: ## Show logs for a specific service (e.g., make logs-n8n)
	docker-compose logs -f $(patsubst logs-%,%,$@)

