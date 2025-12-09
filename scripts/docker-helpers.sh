#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

BACKUP_DIR="$PROJECT_ROOT/db-backups"
mkdir -p "$BACKUP_DIR"

function show_help() {
    cat << EOF
MoneyGuard Docker Helper Script

Usage: ./scripts/docker-helpers.sh [command]

Commands:
  start           Start all services
  start-db        Start only the database
  stop            Stop all services
  restart         Restart all services
  status          Show status of all containers
  logs            Show logs (add service name for specific service)
  logs-db         Show database logs
  backup          Create a database backup
  restore         Restore database from latest backup
  shell           Open PostgreSQL shell
  psql            Execute a PostgreSQL query (pass query as argument)
  clean           Stop and remove containers (keeps data)
  reset           Stop and remove containers AND volumes (⚠️  deletes data)
  help            Show this help message

Examples:
  ./scripts/docker-helpers.sh start-db
  ./scripts/docker-helpers.sh backup
  ./scripts/docker-helpers.sh psql "SELECT COUNT(*) FROM expenses;"
  ./scripts/docker-helpers.sh logs postgres

EOF
}

function start_all() {
    echo "Starting all services..."
    docker compose up -d
    echo "✓ All services started"
}

function start_db() {
    echo "Starting database..."
    docker compose up -d postgres
    echo "✓ Database started"
}

function stop_all() {
    echo "Stopping all services..."
    docker compose down
    echo "✓ All services stopped"
}

function restart_all() {
    echo "Restarting all services..."
    docker compose restart
    echo "✓ All services restarted"
}

function show_status() {
    echo "Container status:"
    docker compose ps
    echo ""
    echo "Resource usage:"
    docker stats --no-stream moneyguard-db 2>/dev/null || echo "Database container not running"
}

function show_logs() {
    if [ -z "$1" ]; then
        docker compose logs -f
    else
        docker compose logs -f "$1"
    fi
}

function show_db_logs() {
    docker compose logs -f postgres
}

function create_backup() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/moneyguard_backup_$TIMESTAMP.sql"

    echo "Creating backup..."
    docker exec moneyguard-db pg_dump -U postgres moneyguard > "$BACKUP_FILE"

    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo "✓ Backup created: $BACKUP_FILE ($SIZE)"
    else
        echo "✗ Backup failed"
        exit 1
    fi
}

function restore_backup() {
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/moneyguard_backup_*.sql 2>/dev/null | head -1)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "✗ No backup files found in $BACKUP_DIR"
        exit 1
    fi

    echo "Restoring from: $LATEST_BACKUP"
    read -p "This will overwrite the current database. Continue? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec -i moneyguard-db psql -U postgres -d moneyguard < "$LATEST_BACKUP"
        echo "✓ Database restored from $LATEST_BACKUP"
    else
        echo "Restore cancelled"
    fi
}

function open_shell() {
    echo "Opening PostgreSQL shell..."
    echo "Tip: Use \q to exit, \dt to list tables, \d table_name to describe a table"
    docker exec -it moneyguard-db psql -U postgres -d moneyguard
}

function execute_query() {
    if [ -z "$1" ]; then
        echo "✗ Please provide a SQL query"
        echo "Example: ./scripts/docker-helpers.sh psql \"SELECT COUNT(*) FROM expenses;\""
        exit 1
    fi

    docker exec moneyguard-db psql -U postgres -d moneyguard -c "$1"
}

function clean() {
    echo "Cleaning containers (data will be preserved)..."
    read -p "Continue? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose down
        echo "✓ Containers removed. Data is safe in volumes."
    else
        echo "Cancelled"
    fi
}

function reset() {
    echo "⚠️  WARNING: This will DELETE ALL DATABASE DATA!"
    echo "Make sure you have a backup before proceeding."
    read -p "Are you absolutely sure? (type 'yes' to confirm) " -r
    echo

    if [[ $REPLY == "yes" ]]; then
        docker compose down -v
        echo "✓ All containers and volumes removed"
    else
        echo "Reset cancelled"
    fi
}

case "${1:-}" in
    start)
        start_all
        ;;
    start-db)
        start_db
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    logs-db)
        show_db_logs
        ;;
    backup)
        create_backup
        ;;
    restore)
        restore_backup
        ;;
    shell)
        open_shell
        ;;
    psql)
        execute_query "$2"
        ;;
    clean)
        clean
        ;;
    reset)
        reset
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: ${1:-}"
        echo ""
        show_help
        exit 1
        ;;
esac
