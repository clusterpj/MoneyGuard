# Database Migration History

## PostgreSQL Migration to Docker (December 8, 2025)

### What Changed
Migrated from **system-installed PostgreSQL** to **Docker-containerized PostgreSQL** for better isolation and portability.

### Before Migration
- PostgreSQL 16 running as system service
- Database: `moneyguard`
- Host: localhost:5432
- Data location: `/var/lib/postgresql/`

### After Migration
- PostgreSQL 16-alpine running in Docker container
- Container name: `moneyguard-db`
- Database: `moneyguard` (same)
- Host: localhost:5432 (same port mapping)
- Data location: Docker volume `moneyguard_postgres_data`

### Migration Steps Performed
1. Created `docker-compose.yml` for PostgreSQL service
2. Backed up existing database: `db-backups/moneyguard_backup_20251208_185614.sql` (74KB)
3. Stopped system PostgreSQL service
4. Started PostgreSQL container via Docker Compose
5. Restored backup data to Docker container
6. Verified data integrity (4 users, 420 expenses, 5 categories, 4 budgets)

### Data Preserved
All data was successfully migrated:
- ✅ Users (4 records)
- ✅ Expenses (420 records)
- ✅ Categories (5 records)
- ✅ Budgets (4 records)
- ✅ Alembic migrations (current: 755612d5825b)

### Current Architecture

```
Frontend (Flutter)
    ↓ HTTP
Backend (FastAPI on host)
    ↓ PostgreSQL protocol
Database (PostgreSQL in Docker)
```

### Connection Details

**Backend → Database:**
- URL: `postgresql://postgres:Pl3T0r@x@localhost:5432/moneyguard`
- Port: 5432 (mapped from container to host)

**Frontend → Backend:**
- URL: `http://localhost:8000/api/v1`
- Works at home (192.168.1.100) and work (10.0.100.100)

### Managing the Database

**Start/Stop:**
```bash
# Start
docker compose up -d postgres

# Stop
docker compose down

# View status
docker compose ps
```

**Access Database:**
```bash
# PostgreSQL shell
docker exec -it moneyguard-db psql -U postgres -d moneyguard

# Using helper script
./scripts/docker-helpers.sh shell
```

**Backups:**
```bash
# Create backup
docker exec moneyguard-db pg_dump -U postgres moneyguard > db-backups/backup_$(date +%Y%m%d).sql

# Using helper script
./scripts/docker-helpers.sh backup
```

**Restore:**
```bash
docker exec -i moneyguard-db psql -U postgres -d moneyguard < db-backups/backup_file.sql
```

### System PostgreSQL Status
- Service: Stopped (can be restarted if needed)
- Command: `sudo systemctl start postgresql`
- Note: Not needed for MoneyGuard anymore

### Benefits of Docker Migration
1. **Isolation** - Database runs independently from system
2. **Portability** - Same setup works on any machine with Docker
3. **Easy Reset** - Can quickly destroy/recreate database
4. **Version Control** - Locked to PostgreSQL 16-alpine
5. **Simplified Management** - Docker Compose handles everything

### Rollback Instructions
If needed to rollback to system PostgreSQL:

```bash
# 1. Stop Docker container
docker compose down

# 2. Start system PostgreSQL
sudo systemctl start postgresql

# 3. Restore backup to system database
sudo -u postgres psql moneyguard < db-backups/moneyguard_backup_20251208_185614.sql

# 4. Update backend .env to use system PostgreSQL (already correct)
DATABASE_URL=postgresql://postgres:Pl3T0r@x@localhost:5432/moneyguard
```

### Files Created/Modified

**Created:**
- `/docker-compose.yml` - Docker Compose configuration
- `/backend/Dockerfile` - Backend container definition (optional)
- `/backend/.dockerignore` - Build optimization
- `/.dockerignore` - Root dockerignore
- `/DOCKER.md` - Docker management documentation
- `/scripts/docker-helpers.sh` - Helper script for common tasks
- `/db-backups/` - Backup directory

**Modified:**
- `/frontend/lib/core/config/config.dart` - Changed API URL to localhost

### Known Issues
- Docker Desktop UI may not show `moneyguard-db` container (UI bug)
- Container is running and accessible via CLI (`docker ps`)
- Workaround: Use command line tools instead of Docker Desktop UI

### Verification Commands

```bash
# Check container is running
docker ps | grep moneyguard

# Test database connection
docker exec moneyguard-db pg_isready -U postgres

# Check data
docker exec moneyguard-db psql -U postgres -d moneyguard -c "SELECT COUNT(*) FROM expenses;"

# Test backend connectivity
curl http://localhost:8000/health
```

### Environment Variables
No changes to `.env` files required - backend still connects to `localhost:5432`

### Backup Schedule Recommendation
- Daily: Automated backup via cron
- Before changes: Manual backup
- Weekly: Verify backup restoration

### Documentation References
- Docker setup: `/DOCKER.md`
- Helper scripts: `/scripts/docker-helpers.sh --help`
- Original backup: `/db-backups/moneyguard_backup_20251208_185614.sql`
