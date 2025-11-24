# MoneyGuard - MVP Implementation Plan

**Goal**: Launch a working product in 4 weeks that proves the core value proposition  
**Target**: 10 beta users in Santiago logging expenses and receiving interventions  
**Success Metric**: 80%+ user retention after 7 days

---

## MVP Philosophy: "Minimum Viable Firewall"

**What We're Building:**
A financial defense system that:
1. ✅ Automatically logs expenses from bank notifications
2. ✅ Warns users BEFORE they overspend (3-gate intervention)
3. ✅ Works offline-first
4. ✅ Has a "Drill Sergeant" AI personality

**What We're NOT Building (Yet):**
- ❌ Advanced analytics/charts
- ❌ Goal tracking
- ❌ Bill reminders
- ❌ Recurring expense detection
- ❌ Budget optimization AI
- ❌ Voice input (manual entry is fine for MVP)
- ❌ Geofencing
- ❌ Multiple currency support
- ❌ Social features

---

## The 4-Week Sprint Plan

### **Week 1: Foundation (Backend + Database)**

**Backend Setup (Days 1-3)**
```

Day 3: Intervention Engine (Backend)
├── Build 3-gate logic
├── Integrate DeepSeek API
├── POST /intervention/check endpoint
└── Test with mock data
```

**Deliverables:**
- ✅ Working backend deployed on Railway
- ✅ 5 API endpoints functional
- ✅ DeepSeek integration working
- ✅ Database schema created

**Database Tables (MVP Only):**
```sql
-- Week 1 Schema (Minimal)
users
expenses
budgets
interventions
notification_parse_log
```

Skip these for MVP:
- budget_allocations (use simple total budget)
- upcoming_bills (manual input only)
- user_patterns (collect data, analyze later)
- categories (use hardcoded system categories)
- notifications (use local Flutter notifications)

---

### **Week 2: Flutter App (Core Features)**

**Flutter Setup (Days 1-2)**
```
Day 1: Project Structure
├── Initialize Flutter project
├── Set up Hive for local storage
├── Create data models (User, Expense, Budget)
├── Set up Riverpod providers
└── Build basic UI (auth screens)

Day 2: Authentication Flow
├── Login screen
├── Register screen
├── JWT token management
├── Auto-login on app start
└── API service layer
```

**OCR + Manual Entry (Days 3-5)**
```
Day 3: Quick Manual Entry
├── FAB with "Add Expense" options
├── Quick amount buttons (50, 100, 200, 500...)
├── Category selection (one-tap)
├── Save and intervention check
└── Test full flow

Day 4: OCR Receipt Scanning
├── Integrate Google ML Kit
├── Camera / Gallery picker
├── OCR text extraction
├── Parse amount + merchant
└── Confirmation screen with edits

Day 5: Polish Entry Flows
├── Improve OCR parsing accuracy
├── Add receipt photo storage
├── Loading states and animations
├── Error handling for bad photos
└── Tips screen for better scans
```

**Deliverables:**
- ✅ Flutter app compiles and runs
- ✅ User can register/login
- ✅ Quick manual entry works (5 seconds)
- ✅ OCR scanning extracts amounts (80%+ accuracy)
- ✅ Confirmation screen for OCR results

---

### **Week 3: Intervention System + Sync**

**Local Intervention (Days 1-2)**
```
Day 1: Gate 1 & 2 (Local Checks)
├── Implement amount threshold check
├── Calculate safe-to-spend locally
├── Show local warnings for small amounts
└── No backend call needed

Day 2: Gate 3 (AI Intervention)
├── API call to /intervention/check
├── Show intervention dialog (red/yellow)
├── TTS for AI message (optional)
└── Log user response (proceeded/cancelled)
```

**Sync Engine (Days 3-4)**
```
Day 3: Background Sync
├── Sync expenses to backend when online
├── Mark expenses as synced
├── Handle conflicts (server wins for MVP)
└── Show sync status in UI

Day 4: Budget Management
├── Simple budget creation screen
├── Enter total monthly budget
├── Calculate daily safe-to-spend
└── Show budget status on home screen
```

**Home Dashboard (Day 5)**
```
Day 5: Dashboard UI
├── Today's spending
├── Safe-to-spend amount
├── Recent transactions (last 10)
├── Budget progress bar
└── Quick-add expense button (manual fallback)
```

**Deliverables:**
- ✅ Full intervention flow working
- ✅ Expenses sync to backend
- ✅ Budget creation works
- ✅ Home dashboard functional
- ✅ App works offline

---

### **Week 4: Polish + Beta Launch**

**Polish (Days 1-2)**
```
Day 1: UI/UX Improvements
├── Add loading states
├── Error handling and retry logic
├── Empty states for lists
├── Improve colors/spacing
└── Add app icon

Day 2: Onboarding Flow
├── Welcome screen explaining MoneyGuard
├── Budget setup wizard
├── Notification permission explanation
└── Test transaction to verify parser
```

**Testing + Fixes (Days 3-4)**
```
Day 3: Self-Testing
├── Test all flows end-to-end
├── Fix critical bugs
├── Test offline functionality
├── Test intervention triggers
└── Verify sync works correctly

Day 4: Beta Prep
├── Create APK for distribution
├── Write beta tester instructions
├── Set up feedback form (Google Forms)
└── Monitor DeepSeek costs
```

**Beta Launch (Day 5)**
```
Day 5: Launch to 10 Users
├── Recruit 10 Santiago friends/colleagues
├── Send APK + instructions
├── Create WhatsApp group for feedback
├── Monitor backend logs
└── Track daily active users
```

**Deliverables:**
- ✅ Polished MVP app
- ✅ 10 beta users onboarded
- ✅ Feedback collection system
- ✅ Monitoring dashboard for costs/errors

---

## MVP Feature Matrix

| Feature | Status | Complexity | Priority |
|---------|--------|------------|----------|
| User Authentication | ✅ Build | Low | P0 |
| OCR Receipt Scanning | ✅ Build | Medium | P0 |
| Quick Manual Entry | ✅ Build | Low | P0 |
| Local Storage (Hive) | ✅ Build | Low | P0 |
| Simple Budget Creation | ✅ Build | Low | P0 |
| 3-Gate Intervention | ✅ Build | Medium | P0 |
| AI "Drill Sergeant" Mode | ✅ Build | Medium | P0 |
| Background Sync | ✅ Build | Medium | P0 |
| Home Dashboard | ✅ Build | Low | P0 |
| Expense List View | ✅ Build | Low | P0 |
| | | | |
| Voice Input | ❌ Post-MVP | Medium | P1 |
| Improved OCR Accuracy | ❌ Post-MVP | Medium | P1 |
| Analytics/Charts | ❌ Post-MVP | Medium | P1 |
| Bill Reminders | ❌ Post-MVP | Low | P2 |
| Goal Tracking | ❌ Post-MVP | Medium | P2 |
| Bank API Integration | ❌ Post-MVP | High | P3 |

---

## Technical Stack (Simplified for MVP)

### Backend
```
FastAPI (Python 3.11+)
PostgreSQL (Railway managed)
DeepSeek API (your $40 credit)
JWT for auth
```

**No Redis, No RabbitMQ, No S3** - Keep it simple!

### Frontend
```
Flutter 3.16+
Hive (local storage)
Riverpod (state management)
flutter_notification_listener (notifications)
http (API calls)
```

### Infrastructure
```
Railway ($5/month - includes PostgreSQL + hosting)
Domain (optional, use Railway subdomain)
```

**Total Monthly Cost: $5-10** (excluding your time)

---

## MVP Database Schema (Simplified)

```sql
-- Users (minimal fields)
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    intervention_threshold INTEGER DEFAULT 2000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Expenses (core tracking with OCR support)
CREATE TABLE expenses (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    amount DECIMAL(12, 2) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    source VARCHAR(20) NOT NULL, -- ocr, manual, voice
    raw_ocr_text TEXT,
    receipt_image_path VARCHAR(255),
    ocr_confidence DECIMAL(3, 2),
    transaction_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Budgets (simple monthly budget)
CREATE TABLE budgets (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    total_amount DECIMAL(12, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Interventions (track AI responses)
CREATE TABLE interventions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    proposed_amount DECIMAL(12, 2) NOT NULL,
    proposed_category VARCHAR(50),
    should_intervene BOOLEAN NOT NULL,
    severity VARCHAR(10) NOT NULL,
    ai_message TEXT,
    tokens_used INTEGER,
    user_proceeded BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- OCR Parse Log (learning data for improving accuracy)
CREATE TABLE ocr_parse_log (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    raw_ocr_text TEXT NOT NULL,
    receipt_image_path VARCHAR(255),
    parse_success BOOLEAN NOT NULL,
    extracted_amount DECIMAL(12, 2),
    confidence_score DECIMAL(3, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**That's it!** Only 5 tables for MVP. Add more later.

---

## MVP API Endpoints (Just 8!)

### Authentication (2 endpoints)
```
POST /api/v1/auth/register
POST /api/v1/auth/login
```

### Expenses (2 endpoints)
```
POST /api/v1/expenses/bulk  # Sync from app
GET  /api/v1/expenses       # List user expenses
```

### Budget (1 endpoint)
```
POST /api/v1/budgets        # Create/update budget
GET  /api/v1/budgets/current
```

### Intervention (1 endpoint)
```
POST /api/v1/intervention/check  # The core feature!
```

### User (1 endpoint)
```
GET /api/v1/user/profile
```

**Total: 8 endpoints** - That's it for MVP!

---

## MVP Flutter Screens (Just 6!)

### 1. Auth Screens
- Login
- Register

### 2. Home Dashboard
- Today's spending
- Safe-to-spend
- Recent transactions
- Quick add button

### 3. Expense List
- All expenses
- Filter by date
- Swipe to delete

### 4. Budget Setup
- Enter monthly budget
- Set threshold for interventions

### 5. Intervention Dialog
- Red/Yellow alert
- AI message
- Proceed/Cancel buttons

### 6. Settings
- User profile
- AI mode (calm/balanced/aggressive)
- Logout

**That's it!** 6 screens total.

---

## Critical Path: What Blocks What

```
Week 1 (Backend)
├── Database Schema → API Endpoints → DeepSeek Integration
└── BLOCKS: Everything else

Week 2 (Flutter Core)
├── Auth Flow → Hive Setup → Notification Listener
└── BLOCKS: Week 3 features

Week 3 (Integration)
├── Intervention System ← Needs Week 1 + Week 2
├── Sync Engine ← Needs Week 1 + Week 2
└── BLOCKS: Beta launch

Week 4 (Polish)
├── Testing ← Needs everything working
└── Beta Launch ← Needs polished app
```

**Key Insight**: You can work on backend (Week 1) and Flutter setup (first half of Week 2) in parallel if needed, but intervention system requires both to be done.

---

## MVP Success Criteria

### Week 1 ✅
- [ ] Backend deployed and accessible
- [ ] Can register a user via API
- [ ] Can call intervention endpoint successfully
- [ ] DeepSeek responds with AI message

### Week 2 ✅
- [ ] App compiles and runs on your phone
- [ ] Can login with test account
- [ ] Quick manual entry works (< 10 seconds)
- [ ] OCR extracts amount from receipts (80%+ accuracy)
- [ ] Confirmation screen allows editing OCR results

#### Backend (FastAPI + PostgreSQL)
- [x] Initialize FastAPI project structure
- [x] Set up PostgreSQL database and Alembic migrations
- [x] Implement User model and JWT Authentication
- [x] Implement Expense and Budget models (CRUD endpoints)
- [x] Integrate DeepSeek API for intervention logic
- [ ] Deploy to Railway (Staging)

### Week 3 ✅
- [ ] When you spend >2000 DOP, intervention triggers
- [ ] AI message displays in dialog
- [ ] Expenses sync to backend when online
- [ ] Budget creation works

### Week 4 ✅
- [ ] 10 users have the APK installed
- [ ] At least 5 users log 1+ expense
- [ ] At least 2 users receive an intervention
- [ ] Total LLM cost < $2 for the week

### Post-MVP (Week 5+)
- [ ] 80%+ users return after 7 days
- [ ] Average 3+ expenses logged per user per day
- [ ] 60%+ users accept intervention suggestions
- [ ] Gather feedback for v1.1 features

---

## MVP Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| OCR parsing accuracy too low | MEDIUM | LOW | Build robust manual editing + confirmation screen |
| Users don't want to take photos | MEDIUM | MEDIUM | Quick manual entry is 5 seconds, zero friction |
| DeepSeek API too expensive | HIGH | LOW | Implement aggressive caching + gates 1&2 |
| Receipt photos too blurry | LOW | MEDIUM | Show tips screen, allow retake |
| Flutter camera issues on some devices | MEDIUM | LOW | Fallback to gallery picker |
| Users find AI too aggressive | LOW | MEDIUM | Easy to change prompt, test with beta group |

---

## Development Environment Setup

### Backend (10 minutes)
```bash
# Create FastAPI project
mkdir moneyguard-backend
cd moneyguard-backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-jose passlib httpx

# Create Railway project
railway init
railway add postgresql
railway up
```

### Frontend (10 minutes)
```bash
# Create Flutter project
flutter create moneyguard
cd moneyguard

# Add dependencies to pubspec.yaml
flutter pub add hive hive_flutter
flutter pub add flutter_riverpod
flutter pub add http
flutter pub add flutter_notification_listener
flutter pub add uuid
flutter pub add intl

flutter pub get
```

---

## Daily Standup Template (For Yourself)

```
Date: __________

✅ Yesterday:
- 

🎯 Today:
- 

🚧 Blockers:
- 

💰 Costs So Far:
- Railway: $__
- DeepSeek: $__ (__ calls)

📊 Metrics:
- Lines of code: __
- API endpoints: __/__
- Screens complete: __/__
```

---

## MVP Launch Checklist

### Pre-Launch (Day Before)
- [ ] APK built and tested on 2+ devices
- [ ] Backend deployed and stable
- [ ] Database backed up
- [ ] Monitoring set up (check Railway logs)
- [ ] Beta tester list finalized (10 people)
- [ ] WhatsApp group created
- [ ] Google Form for feedback ready

### Launch Day (Week 4, Day 5)
- [ ] Send APK to beta testers (via WhatsApp/Telegram)
- [ ] Send installation instructions
- [ ] Post in WhatsApp group: "Welcome! Report any issues here"
- [ ] Monitor backend logs every hour
- [ ] Respond to feedback quickly
- [ ] Track who's actually using it

### First Week of Beta
- [ ] Daily check-in with testers
- [ ] Fix critical bugs within 24h
- [ ] Collect notification samples from users' banks
- [ ] Track retention (who comes back day 2, 3, 7)
- [ ] Ask for honest feedback via Google Form

---

## Post-MVP Roadmap (v1.1, v1.2)

### v1.1 (Week 5-6) - "The Improvements"
Based on beta feedback:
- [ ] Add 2-3 more bank parsers
- [ ] Voice input for manual entry
- [ ] Basic spending chart (by category)
- [ ] Improve intervention AI prompts
- [ ] Bug fixes from beta

### v1.2 (Week 7-8) - "The Polish"
- [ ] Analytics dashboard
- [ ] Bill reminders
- [ ] Export expenses to CSV
- [ ] Dark mode
- [ ] Play Store submission prep

### v2.0 (Month 3+) - "The Scale"
- [ ] Goal tracking
- [ ] Recurring expense detection
- [ ] Budget optimization AI
- [ ] Savings challenges
- [ ] Referral system
- [ ] Premium features

---

## Budget Breakdown (First Month)

| Item | Cost |
|------|------|
| Railway (Backend + DB) | $5-10 |
| Domain (optional) | $0-12 |
| DeepSeek API | $2-5 (with optimization) |
| **Total** | **$7-27** |

**Your time**: ~80-100 hours (20-25 hours/week × 4 weeks)

**Break-even**: ~10-20 users at $0.99/month

---

## The MVP Mantra

> "Build the financial firewall that WORKS, not the perfect budgeting app."

**Remember:**
1. **Notification parsing is the moat** - No one else has this in DR
2. **AI intervention is the hook** - People want to be stopped from overspending
3. **Offline-first is the reliability** - Works even without internet
4. **Speed to market wins** - 4 weeks, not 4 months

---

## Next Steps (Right Now!)

### Immediate Actions:
1. **Set up Railway account** - Get your $5 credit
2. **Initialize backend project** - FastAPI boilerplate
3. **Create database schema** - Run SQL from this doc
4. **Collect 3+ notification samples** - From your bank app
5. **Initialize Flutter project** - Basic structure

### This Week:
- [ ] Backend deployed with auth working
- [ ] Flutter app opens and shows login screen
- [ ] You can register an account via the app

### Questions to Answer:
1. Which bank do YOU use? (We'll prioritize that parser)
2. Do you have any test users lined up? (Friends/coworkers)
3. What's your preferred AI mood? (Calm/Balanced/Aggressive)

---

## The MVP Promise

**In 4 weeks, you will have:**
- A working Android app
- That automatically logs expenses from YOUR bank
- With an AI that warns you before overspending
- Used by 10 real people in Santiago
- Costing less than $30/month to run

**And most importantly:**
You'll know if people actually want this.

---

Ready to build? Let's start with Week 1 - Backend setup! 🚀

Want me to generate:
1. **FastAPI project structure** (complete backend)
2. **Database migration scripts** (SQL ready to run)
3. **Flutter project structure** (complete frontend boilerplate)

Which one first?
