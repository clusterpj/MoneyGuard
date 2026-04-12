# MoneyGuard Architecture

> **High-level overview of MoneyGuard's system architecture, design decisions, and technical approach**

## Table of Contents

- [System Overview](#system-overview)
- [Architecture Diagram](#architecture-diagram)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Technology Stack](#technology-stack)
- [Design Decisions](#design-decisions)
- [Security](#security)
- [Performance](#performance)

---

## System Overview

MoneyGuard is a **mobile-first, offline-capable** financial intervention system built on a client-server architecture. The system prioritizes:

1. **Offline-First** - Core features work without internet
2. **Cost-Effective** - Minimize LLM API costs through intelligent gating
3. **Privacy-Focused** - User data stays on device when possible
4. **Fast Response** - Local processing for real-time feedback

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Presentation │  │ Presentation │  │ Presentation │      │
│  │   (Home)     │  │   (OCR)      │  │ (Intervention)│      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐    │
│  │          State Management (Riverpod)                │    │
│  └──────┬──────────────────┬──────────────────┬───────┘    │
│         │                  │                  │              │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐     │
│  │   Domain     │  │   Domain     │  │   Domain     │     │
│  │  (Budget)    │  │  (Expense)   │  │(Intervention)│     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐    │
│  │              Data Layer (Repositories)              │    │
│  └──────┬──────────────────┬──────────────────┬───────┘    │
│         │                  │                  │              │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐     │
│  │    Hive      │  │  Google ML   │  │     HTTP     │     │
│  │   (Local)    │  │   Kit (OCR)  │  │   (Sync)     │     │
│  └──────────────┘  └──────────────┘  └──────┬───────┘     │
│                                              │              │
└──────────────────────────────────────────────┼──────────────┘
                                               │
                                    HTTPS/REST API
                                               │
┌──────────────────────────────────────────────▼──────────────┐
│                    BACKEND (FastAPI)                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            API Gateway (JWT Auth, CORS)              │   │
│  └──────┬───────────────────────────────────────┬───────┘   │
│         │                                       │            │
│  ┌──────▼───────┐  ┌──────────────┐  ┌────────▼────────┐   │
│  │   Expense    │  │    Budget    │  │  Intervention   │   │
│  │   Service    │  │   Service    │  │     Engine      │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬────────┘   │
│         │                  │                   │             │
│         │                  │         ┌─────────▼────────┐   │
│         │                  │         │  3-Gate System   │   │
│         │                  │         │  Gate 1: Amount  │   │
│         │                  │         │  Gate 2: Context │   │
│         │                  │         │  Gate 3: AI/LLM  │   │
│         │                  │         └─────────┬────────┘   │
│         │                  │                   │             │
│         │                  │         ┌─────────▼────────┐   │
│         │                  │         │  DeepSeek API    │   │
│         │                  │         │  (Cached)        │   │
│         │                  │         └──────────────────┘   │
│         │                  │                                 │
│  ┌──────▼──────────────────▼─────────────────────────────┐  │
│  │              PostgreSQL Database                      │  │
│  │  (Users, Expenses, Budgets, Interventions, etc.)      │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## Core Components

### Mobile App (Flutter)

**Clean Architecture with 3 Layers:**

1. **Presentation Layer**
   - UI screens and widgets
   - State management (Riverpod)
   - User input handling

2. **Domain Layer**
   - Business logic
   - Use cases
   - Entity models

3. **Data Layer**
   - Repositories (abstract interfaces)
   - Data sources (local + remote)
   - DTOs and mappers

**Key Features:**
- Offline-first with Hive local database
- Google ML Kit for OCR
- Background sync service
- Local intervention gates (1 & 2)

### Backend (FastAPI)

**Service-Oriented Architecture:**

1. **API Gateway**
   - JWT authentication
   - Rate limiting
   - CORS handling
   - Request validation

2. **Services**
   - Expense service
   - Budget service
   - Intervention engine
   - User service

3. **Data Access**
   - SQLAlchemy ORM
   - PostgreSQL database
   - Alembic migrations

**Key Features:**
- RESTful API design
- 3-gate intervention system
- DeepSeek LLM integration
- Response caching

---

## Data Flow

### Expense Logging (OCR)

```
1. User takes photo
   ↓
2. Google ML Kit extracts text (on-device)
   ↓
3. Parse amount + merchant (local)
   ↓
4. Show confirmation screen
   ↓
5. User confirms/edits
   ↓
6. Save to Hive (local)
   ↓
7. Check intervention (local gates 1 & 2)
   ↓
8. If needed, call backend (gate 3)
   ↓
9. Background sync when online
```

### Intervention Flow

```
1. User about to spend $X
   ↓
2. Gate 1: Amount > threshold? (local, instant)
   ├─ NO → Allow ✅
   └─ YES → Continue to Gate 2
       ↓
3. Gate 2: Safe-to-spend check (local, instant)
   ├─ SAFE → Allow ✅
   └─ RISKY → Continue to Gate 3
       ↓
4. Gate 3: AI Context Analysis (backend, ~1-2s)
   ├─ Build context (budget, bills, patterns)
   ├─ Call DeepSeek API
   ├─ Cache response
   └─ Return intervention message
       ↓
5. Show intervention dialog (RED/YELLOW)
   ↓
6. User decides: Proceed or Cancel
   ↓
7. Log decision for learning
```

**Cost Optimization**: Only ~5-10% of expenses trigger Gate 3 (LLM call)

---

## Technology Stack

### Frontend

| Technology | Purpose | Why? |
|------------|---------|------|
| **Flutter 3.16+** | Mobile framework | Cross-platform, fast, beautiful UI |
| **Dart** | Programming language | Type-safe, productive |
| **Hive** | Local database | Fast, offline-first, no SQL |
| **Riverpod** | State management | Type-safe, testable, reactive |
| **Google ML Kit** | OCR | Free, offline, accurate |
| **http** | API client | Simple, reliable |

### Backend

| Technology | Purpose | Why? |
|------------|---------|------|
| **FastAPI** | Web framework | Fast, modern, auto-docs |
| **Python 3.11+** | Programming language | Productive, great ecosystem |
| **PostgreSQL 14+** | Database | Reliable, feature-rich, JSON support |
| **SQLAlchemy** | ORM | Powerful, flexible |
| **Alembic** | Migrations | Database version control |
| **DeepSeek V3** | LLM | Cost-effective ($0.14/1M tokens) |
| **Pydantic** | Validation | Type-safe, automatic validation |

### Infrastructure

| Technology | Purpose | Why? |
|------------|---------|------|
| **Railway** | Hosting | Simple, affordable, managed DB |
| **GitHub Actions** | CI/CD | Free, integrated, powerful |
| **PostgreSQL (managed)** | Database | Included with Railway |

---

## Design Decisions

### 1. Why OCR Instead of Notification Parsing?

**Decision**: Use OCR receipt scanning as primary input method

**Rationale**:
- ✅ No special permissions needed
- ✅ Works for ALL banks and payment methods
- ✅ More reliable (no app update breakage)
- ✅ Faster to build and maintain
- ✅ Works for cash purchases
- ❌ Notification parsing is fragile and complex

See [OCR Pivot Decision](architecture/ocr-pivot-decision.md) for full analysis.

### 2. Why Offline-First?

**Decision**: Core features work without internet

**Rationale**:
- Users may have poor connectivity
- Instant response is critical for UX
- Reduces backend costs
- Builds user trust

**Implementation**:
- Hive for local storage
- Background sync queue
- Optimistic UI updates
- Conflict resolution (server wins)

### 3. Why 3-Gate System?

**Decision**: Filter expenses through 3 gates before calling LLM

**Rationale**:
- Gate 1 & 2 are free (local logic)
- Only ~5-10% need expensive AI call
- Keeps monthly costs under $5
- Still provides intelligent intervention

**Cost Comparison**:
- Without gates: ~$50/month (every expense)
- With gates: ~$2-5/month (only risky expenses)

### 4. Why DeepSeek Over OpenAI?

**Decision**: Use DeepSeek V3 for LLM

**Rationale**:
- 10x cheaper than GPT-4 ($0.14 vs $1.50 per 1M tokens)
- Good quality for our use case
- Sufficient context window (64K tokens)
- Reliable API

### 5. Why Monorepo?

**Decision**: Keep frontend and backend in same repo

**Rationale**:
- Easier to coordinate changes
- Shared documentation
- Simpler for solo/small team
- Can split later if needed

---

## Security

### Authentication

- **JWT tokens** for API authentication
- **Refresh tokens** for long-lived sessions
- **Password hashing** with bcrypt
- **HTTPS only** in production

### Data Protection

- **Encryption at rest** (PostgreSQL)
- **Encryption in transit** (TLS/HTTPS)
- **Local data** encrypted with Hive encryption
- **No PII** sent to LLM (only amounts and categories)

### API Security

- **Rate limiting** to prevent abuse
- **CORS** configuration
- **Input validation** with Pydantic
- **SQL injection** prevention (ORM)

### Privacy

- **Minimal data collection** - only what's needed
- **No third-party analytics** (for now)
- **User data isolation** - can't see others' data
- **Right to deletion** - can delete account and all data

---

## Performance

### Mobile App

- **Startup time**: < 2 seconds
- **OCR processing**: < 2 seconds per receipt
- **Local intervention check**: < 100ms
- **UI responsiveness**: 60 FPS

### Backend

- **API response time**: < 200ms (without LLM)
- **LLM response time**: 1-2 seconds (cached: < 50ms)
- **Database queries**: < 50ms
- **Concurrent users**: 1000+ (with scaling)

### Optimization Strategies

1. **Caching**
   - LLM response caching (1 hour TTL)
   - Database query caching
   - Static asset caching

2. **Database**
   - Proper indexing
   - Connection pooling
   - Query optimization

3. **Mobile**
   - Lazy loading
   - Image compression
   - Background sync batching

---

## Scalability

### Current Capacity

- **Users**: 1,000-10,000
- **Requests/sec**: 100+
- **Database**: 10GB+
- **Cost**: $5-10/month

### Scaling Strategy

**Vertical Scaling** (first):
- Upgrade Railway plan
- Increase database size
- More memory/CPU

**Horizontal Scaling** (later):
- Load balancer
- Multiple backend instances
- Read replicas for database
- CDN for static assets

---

## Monitoring & Observability

### Metrics to Track

- **User metrics**: DAU, MAU, retention
- **Performance**: Response times, error rates
- **Cost**: LLM tokens used, database size
- **Business**: Interventions triggered, acceptance rate

### Tools (Future)

- **Sentry** for error tracking
- **Grafana** for metrics visualization
- **Railway logs** for debugging

---

## Related Documentation

- [Technical Specification](architecture/technical-specification.md) - Detailed SRS
- [API Documentation](../API.md) - API reference
- [Setup Guide](../SETUP.md) - Development setup

---

**Last Updated**: November 24, 2025
