# Changelog

All notable changes to MoneyGuard will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planning
- Complete MVP implementation (Weeks 1-4)
- Backend API with intervention engine
- Flutter app with OCR scanning
- 3-gate intervention system
- Beta launch with 10 users

## [0.1.0] - 2025-11-24

### Added
- **Backend Foundation**:
    - Initialized FastAPI project structure with `app/core`, `app/api`, `app/db`.
    - Configured dependencies (`fastapi`, `sqlalchemy`, `alembic`, `pydantic`).
    - Set up environment configuration with Pydantic Settings.
    - Created PostgreSQL database `moneyguard`.
- **Core API Endpoints**:
    - Implemented CRUD operations for `Expenses` and `Budgets`.
    - Created Pydantic schemas for data validation.
    - Added pagination support for expense listing.
- **Authentication System**:
    - Implemented JWT-based authentication (`login`, `register`).
    - Added secure password hashing with `bcrypt`.
    - Created `User` and `Token` Pydantic schemas.
    - Implemented `get_current_user` dependency for protected routes.
- **Database Schema**:
    - Implemented SQLAlchemy models: `User`, `Category`, `Expense`, `Budget`.
    - Configured Alembic for migrations.
    - Applied initial migration to create tables.
- **Documentation**:
    - Created `docs/ARCHITECTURE.md`, `docs/API.md`, `docs/SETUP.md`.
    - Reorganized documentation structure.
- **Repository**:
    - Added `README.md`, `LICENSE`, `CONTRIBUTING.md`, `.gitignore`.
    - Set up GitHub Actions workflows for Flutter and Backend.

### Documentation
- Technical specification (SRS)
- MVP implementation plan (4-week sprint)
- OCR pivot decision rationale
- Architecture overview
- API documentation structure

### Infrastructure
- GitHub Actions CI/CD workflows
- Issue and PR templates
- EditorConfig for consistent coding styles
- Environment variable templates

---

## Version History

### Upcoming Releases

#### v0.2.0 - MVP Backend (Week 1)
- FastAPI backend setup
- PostgreSQL database schema
- JWT authentication
- Core API endpoints (auth, expenses, intervention)
- DeepSeek LLM integration

#### v0.3.0 - MVP Frontend (Week 2)
- Flutter app structure
- OCR receipt scanning (Google ML Kit)
- Quick manual entry
- Local storage (Hive)
- Authentication flow

#### v0.4.0 - Integration (Week 3)
- 3-gate intervention system
- Background sync
- Budget management
- Home dashboard
- Offline-first functionality

#### v0.5.0 - Beta Launch (Week 4)
- UI/UX polish
- Onboarding flow
- Bug fixes
- Beta testing with 10 users
- Feedback collection

#### v1.0.0 - Public Release
- Stable MVP release
- Production-ready backend
- Polished UI
- Comprehensive testing
- Play Store submission

---

## Release Notes Format

Each release will include:

### Added
- New features and capabilities

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in future releases

### Removed
- Features that have been removed

### Fixed
- Bug fixes

### Security
- Security improvements and vulnerability fixes

---

## Links

- [Repository](https://github.com/yourusername/moneyguard)
- [Issues](https://github.com/yourusername/moneyguard/issues)
- [Releases](https://github.com/yourusername/moneyguard/releases)
