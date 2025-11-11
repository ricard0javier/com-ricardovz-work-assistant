# Work Assistant

This project builds and deploys tools that can be used to automate and aid day-to-day tasks using the latest technology available.

The tools in this project are deployed using Docker Compose, allowing you to start and stop individual services in isolation. All services persist data at `~/.work-assistant/{service_name}` and share the same network for inter-service communication. Shared resources like databases are reused to minimize resource consumption.

## Features

- **Multi-service orchestration** via Docker Compose
- **Data persistence** - All data survives container restarts
- **Shared network** - Services communicate on the same VLAN
- **Resource optimization** - Shared databases and infrastructure
- **Simple management** - Makefile commands for common operations

## Services

This project includes the following services:

- **N8N** - Workflow automation platform (Port: 5678)
- **Prefect** - Workflow orchestration engine (Port: 4200)
- **MongoDB** - Document database (Port: 27017)
- **PostgreSQL** - Relational database shared by N8N and Prefect (Port: 5432)
- **Redpanda** - Kafka-compatible event streaming (Port: 19092)
- **Redpanda Console** - UI for Redpanda management (Port: 8080)
- **Browserless** - Headless browser service (Port: 3000)
- **OpenWebUI** - Web UI for LLMs (Port: 3001)
- **Nginx** - Web server for static content (Port: 9080)

## Prerequisites

- Docker and Docker Compose
- Conda (for Python environment management)
- Make (optional, for using Makefile commands)

## Getting Started

### Environment Variables

Copy the example environment file and configure as needed:

```bash
cp .env.example .env
```

Key configuration variables:

#### MongoDB Configuration

- `MONGODB_URI` - MongoDB connection string (default: `mongodb://admin:admin@localhost:27017/?directConnection=true`)
- `MONGODB_DATABASE` - Database name (default: `demo`)

#### PostgreSQL Configuration

- `POSTGRES_HOST` - PostgreSQL host (default: `localhost`)
- `POSTGRES_PORT` - PostgreSQL port (default: `5432`)
- `POSTGRES_USER` - PostgreSQL user (default: `postgres`)
- `POSTGRES_PASSWORD` - PostgreSQL password (default: `postgres`)

#### N8N Configuration

- `N8N_USER` - N8N basic auth username (default: `admin`)
- `N8N_PASSWORD` - N8N basic auth password (default: `admin`)

#### Kafka/Redpanda Configuration

- `KAFKA_BOOTSTRAP_SERVERS` - Kafka bootstrap servers (default: `localhost:19092`)
- `KAFKA_AUTO_OFFSET_RESET` - Kafka offset reset policy (default: `earliest`)
- `KAFKA_CONSUMER_GROUP` - Consumer group ID (default: `demo-group`)

#### OpenWebUI Configuration

- `OPENWEBUI_SECRET_KEY` - Secret key for OpenWebUI sessions (default: `default-secret-key-change-in-production`)

#### Logging

- `LOG_LEVEL` - Logging level (default: `INFO`)

### Local Development

1. **Set up Python environment:**

   ```bash
   # Create conda environment
   make conda-env

   # Activate the environment
   conda activate work-assistant
   ```

2. **Configure environment variables:**

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start all services:**

   ```bash
   make dev
   ```

   Note: The `dev` command automatically creates required directories for data persistence. You can also run `make init` manually if needed.

4. **Access services:**

   - N8N: http://localhost:5678
   - Prefect: http://localhost:4200
   - Redpanda Console: http://localhost:8080
   - Browserless: http://localhost:3000
   - OpenWebUI: http://localhost:3001
   - Nginx: http://localhost:9080
   - MongoDB: `mongodb://admin:admin@localhost:27017`
   - PostgreSQL: `postgresql://postgres:postgres@localhost:5432`

5. **Stop all services:**
   ```bash
   make down
   ```

## Development Commands

### Python Environment

- `make conda-env` - Create conda environment from environment.yml (installs all dependencies)
- `make conda-update` - Update conda environment with latest changes
- `make install` - Verify conda environment is set up correctly

### Docker Services

- `make help` - Show all available commands
- `make init` - Create required directories for Docker volumes (automatically run by `dev` and `up`)
- `make dev` - Start all services in development mode (automatically runs `init`)
- `make up` - Start all services
- `make down` - Stop all services
- `make restart` - Restart all services
- `make logs` - Show logs from all services
- `make ps` - Show status of all services
- `make stop-{service}` - Stop a specific service (e.g., `make stop-n8n`)
- `make start-{service}` - Start a specific service (e.g., `make start-n8n`)
- `make logs-{service}` - Show logs for a specific service (e.g., `make logs-n8n`)
- `make clean` - Stop all services and remove volumes (⚠️ **WARNING**: This deletes all data)

## Data Persistence

All service data is persisted to `~/.work-assistant/{service_name}/`:

- `~/.work-assistant/mongodb/` - MongoDB data and config
- `~/.work-assistant/postgres/` - PostgreSQL data
- `~/.work-assistant/n8n/` - N8N workflows and data
- `~/.work-assistant/prefect/` - Prefect flows and data
- `~/.work-assistant/redpanda/` - Redpanda data
- `~/.work-assistant/browserless/` - Browserless data
- `~/.work-assistant/openwebui/` - OpenWebUI data
- `./shared/nginx/data/` - Nginx static content (project directory)

This ensures your data survives container restarts and system reboots.

## Project Structure

```
.
├── docker-compose.yml      # Docker Compose configuration
├── Makefile                # Development commands
├── environment.yml         # Conda environment specification (Python dependencies)
├── .env.example           # Example environment variables
├── .gitignore             # Git ignore rules
├── .dockerignore          # Docker ignore rules
├── scripts/               # Utility scripts
│   └── init-multiple-databases.sh  # PostgreSQL multi-database init
├── shared/                # Shared resources
│   └── nginx/            # Nginx static content
│       └── data/         # Static files served by Nginx
├── src/                   # Source code
│   ├── __init__.py
│   └── config/           # Configuration management
│       ├── __init__.py
│       └── settings.py   # Application settings
└── tests/                # Test suite
    ├── __init__.py
    └── test_config.py   # Configuration tests
```

## Architecture

- **Shared Network**: All services communicate on `work-assistant-network`
- **Shared Databases**: PostgreSQL serves both N8N and Prefect
- **Service Isolation**: Each service runs in its own container with independent lifecycle
- **Health Checks**: Critical services include health checks for reliable startup ordering

## Notes

- Services use `restart: unless-stopped` to automatically restart on system boot
- Health checks ensure proper service dependencies
- PostgreSQL automatically creates multiple databases (n8n, prefect) on first run
- All data persists to `~/.work-assistant/` to survive restarts
- Docker images use specific version tags (not `latest`) for stability and reproducibility

## Image Versions

All images are pinned to specific versions for stability:

- **MongoDB Atlas Local**: `8.2.1` (latest version)
- **PostgreSQL**: `18.0-alpine` (latest 18.x)
- **Redpanda**: `v25.2.10` (latest v25.x)
- **Redpanda Console**: `v3.2.2` (latest v3.x)
- **N8N**: `1.119.0` (latest 1.x)
- **Prefect**: `3.5.0-python3.14` (latest 3.x)
- **Browserless**: `1.61.1-chrome-stable` (latest 1.x)
- **OpenWebUI**: `main` (latest main branch)
- **Nginx**: `1.29.3` (latest 1.x)

To update images, modify `docker-compose.yml` and run `docker-compose pull` followed by `docker-compose up -d`.
