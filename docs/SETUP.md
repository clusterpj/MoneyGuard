# Development Setup Guide

> **Complete guide to setting up your MoneyGuard development environment**

## Table of Contents

- [Prerequisites](#prerequisites)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [Database Setup](#database-setup)
- [Running Locally](#running-locally)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

1. **Flutter 3.16+**
   ```bash
   # Check version
   flutter --version
   
   # If not installed, visit: https://flutter.dev/docs/get-started/install
   ```

2. **Python 3.11+**
   ```bash
   # Check version
   python --version
   
   # If not installed, visit: https://www.python.org/downloads/
   ```

3. **PostgreSQL 14+**
   ```bash
   # Check version
   psql --version
   
   # Or use Railway for managed database
   ```

4. **Git**
   ```bash
   git --version
   ```

### Optional Tools

- **Android Studio** - For Android development
- **Xcode** - For iOS development (macOS only)
- **VSCode** - Recommended editor
- **Postman** - For API testing

---

## Backend Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/moneyguard.git
cd moneyguard
```

### 2. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies
```

### 4. Set Up Environment Variables

```bash
cp ../.env.example .env
```

Edit `.env` with your configuration:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/moneyguard

# JWT
JWT_SECRET_KEY=your-secret-key-here

# DeepSeek API
DEEPSEEK_API_KEY=your-api-key-here

# App Settings
DEBUG=true
ENVIRONMENT=development
```

### 5. Initialize Database

```bash
# Create database
createdb moneyguard

# Run migrations
alembic upgrade head

# Seed default categories (optional)
python scripts/seed_categories.py
```

### 6. Run the Backend

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Visit: http://localhost:8000/docs for API documentation

---

## Frontend Setup

### 1. Navigate to Frontend Directory

```bash
cd frontend
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Endpoint

Edit `lib/core/config.dart`:

```dart
class Config {
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  // For physical device, use your computer's IP:
  // static const String apiBaseUrl = 'http://192.168.1.100:8000/api/v1';
}
```

### 4. Run the App

```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Or specify device
flutter run -d <device-id>
```

---

## Database Setup

### Option 1: Local PostgreSQL

#### Install PostgreSQL

**macOS (Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download from https://www.postgresql.org/download/windows/

#### Create Database

```bash
# Connect to PostgreSQL
psql postgres

# Create user
CREATE USER moneyguard WITH PASSWORD 'your_password';

# Create database
CREATE DATABASE moneyguard OWNER moneyguard;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE moneyguard TO moneyguard;

# Exit
\q
```

### Option 2: Railway (Recommended for MVP)

1. Sign up at https://railway.app
2. Create new project
3. Add PostgreSQL database
4. Copy connection string to `.env`

```bash
DATABASE_URL=postgresql://postgres:password@containers-us-west-xxx.railway.app:5432/railway
```

---

## Running Locally

### Start Backend

```bash
cd backend
source venv/bin/activate  # Windows: venv\Scripts\activate
uvicorn app.main:app --reload
```

Backend will run on: http://localhost:8000

### Start Frontend

```bash
cd frontend
flutter run
```

App will launch on connected device/emulator.

### Verify Setup

1. **Backend Health Check**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Create Test User**
   ```bash
   curl -X POST http://localhost:8000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "Test123!",
       "name": "Test User"
     }'
   ```

3. **Login from App**
   - Open app
   - Use test credentials
   - Should see home dashboard

---

## Testing

### Backend Tests

```bash
cd backend

# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_intervention.py

# Run specific test
pytest tests/test_intervention.py::test_gate_1_amount_check
```

### Frontend Tests

```bash
cd frontend

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/domain/intervention_test.dart
```

### Integration Tests

```bash
# Backend integration tests
cd backend
pytest tests/integration/

# Flutter integration tests
cd frontend
flutter test integration_test/
```

---

## Troubleshooting

### Backend Issues

#### "ModuleNotFoundError"
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### "Database connection failed"
```bash
# Check PostgreSQL is running
pg_isready

# Verify DATABASE_URL in .env
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL
```

#### "Port 8000 already in use"
```bash
# Find process using port 8000
lsof -i :8000

# Kill process
kill -9 <PID>

# Or use different port
uvicorn app.main:app --reload --port 8001
```

### Frontend Issues

#### "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

#### "No devices found"
```bash
# For Android
flutter emulators
flutter emulators --launch <emulator-id>

# For iOS (macOS only)
open -a Simulator
```

#### "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### "Cannot connect to backend"
```bash
# For emulator, use 10.0.2.2 instead of localhost
# For physical device, use your computer's IP address

# Find your IP
# macOS/Linux:
ifconfig | grep "inet "

# Windows:
ipconfig
```

### Database Issues

#### "Role does not exist"
```bash
# Create PostgreSQL user
createuser -s moneyguard
```

#### "Database does not exist"
```bash
# Create database
createdb moneyguard
```

#### "Migration failed"
```bash
# Reset database (CAUTION: deletes all data)
alembic downgrade base
alembic upgrade head
```

---

## Development Workflow

### Daily Workflow

1. **Pull latest changes**
   ```bash
   git pull origin main
   ```

2. **Update dependencies**
   ```bash
   # Backend
   cd backend && pip install -r requirements.txt
   
   # Frontend
   cd frontend && flutter pub get
   ```

3. **Run migrations**
   ```bash
   cd backend && alembic upgrade head
   ```

4. **Start development**
   ```bash
   # Terminal 1: Backend
   cd backend && uvicorn app.main:app --reload
   
   # Terminal 2: Frontend
   cd frontend && flutter run
   ```

### Before Committing

1. **Format code**
   ```bash
   # Backend
   cd backend && black . && flake8
   
   # Frontend
   cd frontend && dart format . && flutter analyze
   ```

2. **Run tests**
   ```bash
   # Backend
   cd backend && pytest
   
   # Frontend
   cd frontend && flutter test
   ```

3. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/your-feature
   ```

---

## IDE Setup

### VSCode (Recommended)

Install extensions:
- Flutter
- Dart
- Python
- PostgreSQL
- GitLens

Workspace settings (`.vscode/settings.json`):
```json
{
  "editor.formatOnSave": true,
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "[dart]": {
    "editor.rulers": [80]
  }
}
```

### Android Studio

1. Install Flutter plugin
2. Install Dart plugin
3. Configure Flutter SDK path
4. Create virtual device (AVD)

---

## Next Steps

- Read [Architecture Documentation](ARCHITECTURE.md)
- Review [API Documentation](API.md)
- Check [Contributing Guidelines](../CONTRIBUTING.md)
- Join development discussions

---

**Need Help?**

- Open an issue: https://github.com/yourusername/moneyguard/issues
- Check existing issues
- Read the docs

**Last Updated**: November 24, 2025
