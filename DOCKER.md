# Docker Setup for MoneyGuard

This document provides instructions for managing the MoneyGuard application using Docker Compose.

## Overview

The Docker setup includes:
- **PostgreSQL 16** - Database running in an Alpine Linux container
- **Backend API** - FastAPI application (optional, can be run separately)

## Prerequisites

- Docker Engine installed
- Docker Compose plugin installed

## Quick Start

### Start the Database Only

```bash
docker compose up -d postgres
```

### Start Everything (Database + Backend)

```bash
docker compose up -d
```

### Stop Services

```bash
docker compose down
```

### Stop and Remove All Data (⚠️ Warning: This deletes the database)

```bash
docker compose down -v
```

## Database Management

### Access PostgreSQL Shell

```bash
docker compose exec postgres psql -U postgres -d moneyguard
```

Or using the container name:

```bash
docker exec -it moneyguard-db psql -U postgres -d moneyguard
```

### Create a Backup

```bash
# Create timestamped backup
docker exec moneyguard-db pg_dump -U postgres moneyguard > db-backups/backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore from Backup

```bash
# Restore specific backup file
docker exec -i moneyguard-db psql -U postgres -d moneyguard < db-backups/backup_YYYYMMDD_HHMMSS.sql
```

### View Database Logs

```bash
docker compose logs -f postgres
```

### Check Database Size

```bash
docker exec moneyguard-db psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('moneyguard'));"
```

## Container Management

### View Running Containers

```bash
docker compose ps
```

### View Container Resource Usage

```bash
docker stats moneyguard-db
```

### Restart Containers

```bash
# Restart all services
docker compose restart

# Restart only PostgreSQL
docker compose restart postgres
```

### View All Logs

```bash
docker compose logs -f
```

## Backend Development

### Run Backend Outside Docker

If you want to run the backend outside Docker but use the containerized database:

```bash
# Ensure PostgreSQL container is running
docker compose up -d postgres

# Navigate to backend directory
cd backend

# Activate virtual environment
source venv/bin/activate  # or 'venv\Scripts\activate' on Windows

# Run the backend
uvicorn app.main:app --reload
```

The backend will connect to the containerized PostgreSQL on `localhost:5432`.

### Run Backend in Docker

```bash
docker compose up -d backend
```

The backend will be available at `http://localhost:8000`.

## Troubleshooting

### Port 5432 Already in Use

If you see an error about port 5432 being in use, stop the system PostgreSQL service:

```bash
sudo systemctl stop postgresql
```

To prevent PostgreSQL from starting on boot:

```bash
sudo systemctl disable postgresql
```

### Container Won't Start

Check logs for errors:

```bash
docker compose logs postgres
```

### Database Connection Issues

Verify the container is healthy:

```bash
docker ps | grep moneyguard-db
```

You should see `(healthy)` in the status column.

Test database connection:

```bash
docker exec moneyguard-db pg_isready -U postgres
```

### Reset Everything

If you want to completely reset the Docker setup:

```bash
# Stop and remove containers, networks, and volumes
docker compose down -v

# Start fresh
docker compose up -d

# Restore your backup
docker exec -i moneyguard-db psql -U postgres -d moneyguard < db-backups/your_backup.sql
```

## Environment Variables

Database connection details are configured in `backend/.env`:

```env
DATABASE_URL=postgresql://postgres:Pl3T0r@x@localhost:5432/moneyguard
```

When running the backend in Docker, it uses the service name instead:

```env
DATABASE_URL=postgresql://postgres:Pl3T0r@x@postgres:5432/moneyguard
```

## Data Persistence

Database data is persisted in a Docker volume named `moneyguard_postgres_data`. This ensures your data survives container restarts.

To view volume details:

```bash
docker volume inspect moneyguard_postgres_data
```

## Backup Directory

Backups are stored in `./db-backups/` directory, which is mounted to the container at `/backups`.

## Useful Commands

### Execute SQL Queries

```bash
docker exec moneyguard-db psql -U postgres -d moneyguard -c "SELECT COUNT(*) FROM expenses;"
```

### List All Databases

```bash
docker exec moneyguard-db psql -U postgres -c "\l"
```

### List All Tables

```bash
docker exec moneyguard-db psql -U postgres -d moneyguard -c "\dt"
```

### Check Table Sizes

```bash
docker exec moneyguard-db psql -U postgres -d moneyguard -c "
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

## Network Information

The services communicate on a bridge network named `moneyguard_moneyguard-network`.

To inspect the network:

```bash
docker network inspect moneyguard_moneyguard-network
```

## Production Considerations

For production deployments:

1. Use secrets management instead of plain text passwords
2. Configure regular automated backups
3. Set up monitoring and alerting
4. Use a reverse proxy (nginx) for the backend
5. Configure SSL/TLS certificates
6. Implement proper logging and log rotation
7. Consider using Docker Swarm or Kubernetes for orchestration

## Migration from System PostgreSQL

If you previously had PostgreSQL installed on your system:

1. Backup was created in `db-backups/moneyguard_backup_20251208_185614.sql`
2. System PostgreSQL service has been stopped
3. Data has been restored to the Docker container
4. System PostgreSQL can be restarted if needed: `sudo systemctl start postgresql`

## Next Steps

- Set up automated backup cron jobs
- Configure monitoring with tools like Prometheus/Grafana
- Implement CI/CD pipelines with Docker
- Set up development/staging/production environments
