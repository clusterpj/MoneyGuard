# MoneyGuard - Software Requirements Specification (SRS)

**Version:** 1.1 (OCR Pivot)
**Status:** Ready for Implementation  
**Target Market:** Dominican Republic  
**Primary Language:** Spanish (UI), English (Code)

---

## ⚠️ CRITICAL ARCHITECTURE DECISION

**Notification parsing is TOO COMPLEX for MVP** - fragile parsers, permission hell, device compatibility issues, bank app updates break everything.

**NEW STRATEGY: OCR + Manual Entry**
- ✅ OCR receipt scanning (Google ML Kit - free, offline, fast)
- ✅ Quick manual entry (2 taps, 5 seconds)
- ✅ No permissions needed (just camera)
- ✅ Works on ALL devices
- ✅ More reliable and faster to ship

This SRS has been updated to reflect this pragmatic pivot.

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────┐
│     Android Device (Flutter)        │
│  ┌──────────────────────────────┐  │
│  │  SMS Listener Service        │  │
│  │  (Background, Always-On)     │  │
│  └────────────┬─────────────────┘  │
│               │                     │
│  ┌────────────▼─────────────────┐  │
│  │  Expense Parser & Categorizer│  │
│  │  (Local, Regex-Based)        │  │
│  └────────────┬─────────────────┘  │
│               │                     │
│  ┌────────────▼─────────────────┐  │
│  │  Local Database (Hive)       │  │
│  │  (Offline-First Storage)     │  │
│  └────────────┬─────────────────┘  │
│               │                     │
│  ┌────────────▼─────────────────┐  │
│  │  Intervention Gate (Local)   │  │
│  │  Gate 1 & 2: Rule-Based      │  │
│  └────────────┬─────────────────┘  │
│               │                     │
│  ┌────────────▼─────────────────┐  │
│  │  Sync Service                │  │
│  │  (Background Job)            │  │
│  └────────────┬─────────────────┘  │
└───────────────┼───────────────────┘
                │
                │ HTTPS REST API
                │
┌───────────────▼───────────────────┐
│     FastAPI Backend Server        │
│  ┌──────────────────────────────┐ │
│  │  API Gateway                 │ │
│  │  (JWT Auth, Rate Limiting)   │ │
│  └────────────┬─────────────────┘ │
│               │                    │
│  ┌────────────▼─────────────────┐ │
│  │  Intervention Engine         │ │
│  │  Gate 3: AI-Powered          │ │
│  └────────────┬─────────────────┘ │
│               │                    │
│  ┌────────────▼─────────────────┐ │
│  │  LLM Service (DeepSeek)      │ │
│  │  - Drill Sergeant Prompts    │ │
│  │  - Context Builder           │ │
│  └────────────┬─────────────────┘ │
│               │                    │
│  ┌────────────▼─────────────────┐ │
│  │  Analytics Engine            │ │
│  │  (Pattern Detection)         │ │
│  └────────────┬─────────────────┘ │
└───────────────┼───────────────────┘
                │
       ┌────────┴────────┐
       │                 │
┌──────▼──────┐   ┌──────▼──────┐
│ PostgreSQL  │   │ File Cache  │
│ (Primary DB)│   │ (LLM Cache) │
└─────────────┘   └─────────────┘
```

### 1.2 Data Flow Strategy (Simplified for Reality)

**PIVOT**: After investigation, notification parsing is too complex and fragile (app updates break parsers, permission issues, device compatibility). We're going with proven, reliable methods.

**Priority 1: OCR Receipt Scanning (70% of transactions)**
```
User Takes Photo → Google ML Kit OCR → Extract Amount/Merchant → Confirm → Auto-Log
```

**Priority 2: Quick Manual Entry (25% of transactions)**
```
User Opens App → Quick Add (Amount + Category) → Auto-Log (2 taps, 5 seconds)
```

**Priority 3: Voice Input (5%, future enhancement)**
```
User Says "Gasté 1500 en Uber" → STT → Parse → Auto-Log
```

**Why This Works Better:**
- ✅ No permission hell
- ✅ Works on ALL Android devices
- ✅ More reliable than notification parsing
- ✅ Users already take photos of receipts
- ✅ Faster to build and ship
- ✅ No bank dependency

---

## 2. Database Schema (PostgreSQL)

### 2.1 Core Tables

```sql
-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    
    -- Regional Settings
    currency VARCHAR(3) DEFAULT 'DOP',
    timezone VARCHAR(50) DEFAULT 'America/Santo_Domingo',
    language VARCHAR(2) DEFAULT 'es',
    
    -- AI Personality Settings
    intervention_mode VARCHAR(20) DEFAULT 'balanced', -- calm, balanced, aggressive
    ai_voice_enabled BOOLEAN DEFAULT true,
    
    -- Safety Thresholds (in DOP)
    intervention_threshold INTEGER DEFAULT 2000,
    daily_safe_limit INTEGER,
    
    -- Account Status
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================
-- EXPENSES TABLE
-- ============================================
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Transaction Details
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'DOP',
    description TEXT,
    merchant_name VARCHAR(255),
    
    -- Categorization
    category VARCHAR(50) NOT NULL, -- food, transport, entertainment, etc.
    subcategory VARCHAR(50),
    is_essential BOOLEAN DEFAULT false,
    
    -- Source Tracking
    source VARCHAR(20) NOT NULL, -- ocr, manual, voice (future)
    raw_ocr_text TEXT, -- Store original OCR result for learning
    receipt_image_path VARCHAR(255), -- Local path to receipt photo
    ocr_confidence DECIMAL(3, 2), -- 0.00 to 1.00
    
    -- Timing
    transaction_date TIMESTAMP NOT NULL,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- AI Metadata
    auto_categorized BOOLEAN DEFAULT false,
    ai_confidence DECIMAL(3, 2), -- 0.00 to 1.00
    user_corrected BOOLEAN DEFAULT false,
    
    -- Intervention
    intervention_triggered BOOLEAN DEFAULT false,
    intervention_severity VARCHAR(10), -- none, yellow, red
    
    -- Sync Status
    synced_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_transaction_date ON expenses(transaction_date);
CREATE INDEX idx_expenses_category ON expenses(category);
CREATE INDEX idx_expenses_synced ON expenses(synced_at);

-- ============================================
-- CATEGORIES TABLE
-- ============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL = system category
    
    name VARCHAR(50) NOT NULL,
    name_es VARCHAR(50), -- Spanish translation
    icon VARCHAR(50),
    color VARCHAR(7), -- Hex color
    
    is_essential BOOLEAN DEFAULT false,
    is_system BOOLEAN DEFAULT false,
    parent_category_id UUID REFERENCES categories(id),
    
    -- AI Learning
    keywords TEXT[], -- Array of keywords for matching
    merchant_patterns TEXT[], -- Regex patterns for merchants
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_name ON categories(name);

-- ============================================
-- BUDGETS TABLE
-- ============================================
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    name VARCHAR(100) NOT NULL,
    period VARCHAR(20) NOT NULL, -- weekly, monthly, custom
    
    -- Date Range
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Budget Amounts
    total_amount DECIMAL(12, 2) NOT NULL,
    safe_to_spend DECIMAL(12, 2), -- Calculated: total - upcoming_bills
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_budgets_user_id ON budgets(user_id);
CREATE INDEX idx_budgets_period ON budgets(start_date, end_date);

-- ============================================
-- BUDGET ALLOCATIONS TABLE
-- ============================================
CREATE TABLE budget_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    
    allocated_amount DECIMAL(12, 2) NOT NULL,
    spent_amount DECIMAL(12, 2) DEFAULT 0,
    
    is_flexible BOOLEAN DEFAULT true, -- AI can adjust this
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_budget_allocations_budget_id ON budget_allocations(budget_id);

-- ============================================
-- UPCOMING BILLS TABLE
-- ============================================
CREATE TABLE upcoming_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    name VARCHAR(100) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    due_date DATE NOT NULL,
    category VARCHAR(50) DEFAULT 'utilities',
    
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern VARCHAR(20), -- monthly, weekly
    
    is_paid BOOLEAN DEFAULT false,
    paid_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_upcoming_bills_user_id ON upcoming_bills(user_id);
CREATE INDEX idx_upcoming_bills_due_date ON upcoming_bills(due_date);

-- ============================================
-- INTERVENTIONS TABLE
-- ============================================
CREATE TABLE interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expense_id UUID REFERENCES expenses(id) ON DELETE SET NULL,
    
    -- Trigger Context
    proposed_amount DECIMAL(12, 2) NOT NULL,
    proposed_category VARCHAR(50) NOT NULL,
    
    -- Gate Results
    gate_1_passed BOOLEAN, -- Amount threshold
    gate_2_passed BOOLEAN, -- Context check
    gate_3_triggered BOOLEAN, -- AI called
    
    -- Decision
    should_intervene BOOLEAN NOT NULL,
    severity VARCHAR(10) NOT NULL, -- none, yellow, red
    
    -- AI Response
    ai_message TEXT,
    ai_reasoning TEXT,
    tokens_used INTEGER,
    
    -- User Action
    user_proceeded BOOLEAN, -- Did they buy anyway?
    user_response VARCHAR(20), -- cancelled, modified, ignored
    
    -- Timing
    responded_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interventions_user_id ON interventions(user_id);
CREATE INDEX idx_interventions_created_at ON interventions(created_at);

-- ============================================
-- USER PATTERNS TABLE (AI Learning)
-- ============================================
CREATE TABLE user_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Spending Personality
    risk_level VARCHAR(20) DEFAULT 'moderate', -- conservative, moderate, aggressive
    impulse_categories TEXT[], -- Categories user overspends on
    weak_times JSONB, -- Times of day/week when user overspends
    
    -- Success Tracking
    successful_interventions INTEGER DEFAULT 0,
    ignored_interventions INTEGER DEFAULT 0,
    intervention_acceptance_rate DECIMAL(3, 2), -- 0.00 to 1.00
    
    -- Financial Health
    avg_daily_spending DECIMAL(12, 2),
    avg_monthly_spending DECIMAL(12, 2),
    savings_rate DECIMAL(3, 2),
    
    last_calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_patterns_user_id ON user_patterns(user_id);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    type VARCHAR(30) NOT NULL, -- morning_brief, intervention, achievement, alert
    priority VARCHAR(10) NOT NULL, -- low, medium, high
    
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    
    -- Delivery
    scheduled_for TIMESTAMP NOT NULL,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    
    -- Action Required
    action_required BOOLEAN DEFAULT false,
    action_type VARCHAR(30), -- open_app, review_expense, update_budget
    action_data JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for);
CREATE INDEX idx_notifications_delivered ON notifications(delivered_at);

-- ============================================
-- OCR PARSING LOG (Debugging & Learning)
-- ============================================
CREATE TABLE ocr_parse_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    raw_ocr_text TEXT NOT NULL,
    receipt_image_path VARCHAR(255),
    received_at TIMESTAMP NOT NULL,
    
    -- Parse Results
    parse_success BOOLEAN NOT NULL,
    extracted_amount DECIMAL(12, 2),
    extracted_merchant VARCHAR(255),
    extracted_date TIMESTAMP,
    confidence_score DECIMAL(3, 2),
    
    -- If Failed
    error_reason TEXT,
    
    -- If Succeeded
    expense_id UUID REFERENCES expenses(id),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ocr_parse_log_user_id ON ocr_parse_log(user_id);
CREATE INDEX idx_ocr_parse_log_received_at ON ocr_parse_log(received_at);
CREATE INDEX idx_ocr_parse_log_success ON ocr_parse_log(parse_success);

-- ============================================
-- JOB QUEUE (Simple Background Jobs)
-- ============================================
CREATE TABLE job_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type VARCHAR(50) NOT NULL, -- sync_expenses, calculate_patterns, send_notification
    payload JSONB NOT NULL,
    
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    priority INTEGER DEFAULT 5, -- 1 (highest) to 10 (lowest)
    
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    error_message TEXT,
    
    scheduled_for TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_job_queue_status ON job_queue(status, scheduled_for);

-- ============================================
-- SYSTEM METRICS (Cost Tracking)
-- ============================================
CREATE TABLE system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_date DATE NOT NULL,
    
    -- Usage Stats
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    total_expenses INTEGER DEFAULT 0,
    total_interventions INTEGER DEFAULT 0,
    
    -- AI Usage
    llm_calls_total INTEGER DEFAULT 0,
    llm_tokens_used INTEGER DEFAULT 0,
    llm_cost_usd DECIMAL(10, 4) DEFAULT 0,
    
    -- Performance
    avg_response_time_ms INTEGER,
    error_rate DECIMAL(3, 2),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(metric_date)
);

CREATE INDEX idx_system_metrics_date ON system_metrics(metric_date);
```

### 2.2 Default Categories (System-Wide)

```sql
INSERT INTO categories (name, name_es, icon, color, is_essential, is_system, keywords) VALUES
('food', 'Comida', '🍔', '#FF6B6B', true, true, ARRAY['restaurant', 'lunch', 'dinner', 'food', 'comida', 'supermercado', 'colmado']),
('transport', 'Transporte', '🚗', '#4ECDC4', true, true, ARRAY['uber', 'taxi', 'gas', 'gasolina', 'parking', 'peaje']),
('utilities', 'Servicios', '💡', '#45B7D1', true, true, ARRAY['electric', 'water', 'internet', 'phone', 'cable', 'luz', 'agua']),
('entertainment', 'Entretenimiento', '🎮', '#FFA07A', false, true, ARRAY['cinema', 'movie', 'game', 'cine', 'juego', 'netflix']),
('shopping', 'Compras', '🛍️', '#98D8C8', false, true, ARRAY['store', 'mall', 'tienda', 'zara', 'amazon']),
('health', 'Salud', '🏥', '#F7B731', true, true, ARRAY['pharmacy', 'doctor', 'hospital', 'farmacia', 'medicina']),
('education', 'Educación', '📚', '#5F27CD', true, true, ARRAY['school', 'course', 'book', 'escuela', 'curso']),
('other', 'Otro', '📦', '#95A5A6', false, true, ARRAY[]);
```

---

## 3. API Endpoints Specification

### 3.1 Authentication Endpoints

```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh-token
POST /api/v1/auth/verify-email
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
```

#### Example: Register

**Request:**
```json
POST /api/v1/auth/register
{
  "email": "jose@example.com",
  "password": "SecurePass123!",
  "name": "Jose Rodriguez",
  "phone": "+1809-555-0123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "email": "jose@example.com",
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 3600
  }
}
```

### 3.2 Expense Endpoints

```
POST   /api/v1/expenses                    # Create expense
GET    /api/v1/expenses                    # List expenses (paginated)
GET    /api/v1/expenses/{id}               # Get single expense
PUT    /api/v1/expenses/{id}               # Update expense
DELETE /api/v1/expenses/{id}               # Delete expense
POST   /api/v1/expenses/bulk               # Bulk create (for sync)
POST   /api/v1/expenses/voice              # Parse voice input
```

#### Example: Bulk Sync

**Request:**
```json
POST /api/v1/expenses/bulk
{
  "expenses": [
    {
      "local_id": "uuid",
      "amount": 1500.00,
      "description": "Compra en Supermercado Nacional",
      "category": "food",
      "source": "sms",
      "transaction_date": "2025-01-15T14:30:00Z",
      "raw_sms_text": "Compra aprobada por RD$1,500.00 en SUPERMERCADO NACIONAL...",
      "bank_name": "popular"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "synced_count": 1,
    "failed_count": 0,
    "expenses": [
      {
        "local_id": "uuid",
        "server_id": "uuid",
        "synced_at": "2025-01-15T14:35:00Z"
      }
    ]
  }
}
```

### 3.3 Intervention Endpoints (Core Feature)

```
POST   /api/v1/intervention/check          # Check if intervention needed
POST   /api/v1/intervention/voice-check    # Voice input: "Can I buy X?"
GET    /api/v1/intervention/history        # User's intervention history
POST   /api/v1/intervention/feedback       # User feedback (proceeded/cancelled)
```

#### Example: Intervention Check

**Request:**
```json
POST /api/v1/intervention/check
{
  "amount": 3500.00,
  "category": "entertainment",
  "merchant": "GameStop",
  "description": "Quiero comprar un GPU"
}
```

**Response (RED Alert):**
```json
{
  "success": true,
  "data": {
    "should_intervene": true,
    "severity": "red",
    "gate_results": {
      "gate_1": "failed",  // Amount > threshold
      "gate_2": "failed",  // Not enough safe money
      "gate_3": "triggered"  // AI called
    },
    "message": "NO. Tienes renta en 4 días. Si compras esto, te quedan RD$400 para comida. Deja eso ahí.",
    "context": {
      "safe_to_spend": 2000.00,
      "upcoming_bills": 12000.00,
      "days_until_next_bill": 4,
      "current_balance": 15500.00
    },
    "intervention_id": "uuid",
    "tokens_used": 150,
    "cost_usd": 0.00021
  }
}
```

**Response (GREEN - Safe):**
```json
{
  "success": true,
  "data": {
    "should_intervene": false,
    "severity": "none",
    "gate_results": {
      "gate_1": "passed",
      "gate_2": "passed",
      "gate_3": "not_triggered"
    },
    "message": "Adelante. Ese gasto está dentro de tu presupuesto.",
    "context": {
      "safe_to_spend": 8000.00,
      "remaining_after": 6500.00
    }
  }
}
```

### 3.4 Budget Endpoints

```
GET    /api/v1/budgets/current             # Current active budget
POST   /api/v1/budgets                     # Create budget
PUT    /api/v1/budgets/{id}                # Update budget
GET    /api/v1/budgets/{id}/status         # Budget status with spending
POST   /api/v1/budgets/calculate-safe      # Calculate safe-to-spend amount
```

### 3.5 Analytics Endpoints

```
GET    /api/v1/analytics/overview          # Dashboard overview
GET    /api/v1/analytics/spending-trend    # Spending over time
GET    /api/v1/analytics/by-category       # Spending by category
GET    /api/v1/analytics/patterns          # AI-detected patterns
GET    /api/v1/analytics/predictions       # Spending predictions
```

### 3.6 User Endpoints

```
GET    /api/v1/user/profile                # Get user profile
PUT    /api/v1/user/profile                # Update profile
PATCH  /api/v1/user/settings               # Update settings
GET    /api/v1/user/patterns               # User spending patterns
POST   /api/v1/user/ai-mode                # Change AI personality mode
```

### 3.7 Notification Endpoints

```
GET    /api/v1/notifications               # List notifications
PUT    /api/v1/notifications/{id}/read     # Mark as read
POST   /api/v1/notifications/register-fcm  # Register FCM token
GET    /api/v1/notifications/morning-brief # Get morning briefing data
```

---

## 4. LLM Integration Architecture

### 4.1 DeepSeek Provider Interface

```python
from abc import ABC, abstractmethod
from typing import Dict, Optional
from dataclasses import dataclass
from enum import Enum

class InterventionSeverity(Enum):
    NONE = "none"
    YELLOW = "yellow"
    RED = "red"

class AIMood(Enum):
    CALM = "calm"          # Helpful, supportive
    BALANCED = "balanced"  # Direct, honest
    AGGRESSIVE = "aggressive"  # Drill sergeant mode

@dataclass
class InterventionContext:
    user_id: str
    amount: float
    category: str
    safe_to_spend: float
    upcoming_bills: float
    days_until_bill: int
    weak_categories: list[str]
    recent_overspending: bool
    ai_mood: AIMood

@dataclass
class InterventionResponse:
    should_intervene: bool
    severity: InterventionSeverity
    message: str
    reasoning: str
    tokens_used: int
    cost_usd: float

class BaseLLMProvider(ABC):
    
    @abstractmethod
    async def check_intervention(
        self,
        context: InterventionContext
    ) -> InterventionResponse:
        """Check if intervention is needed and generate message"""
        pass
    
    @abstractmethod
    async def generate_morning_brief(
        self,
        user_id: str,
        safe_to_spend: float,
        upcoming_bills: list[Dict]
    ) -> str:
        """Generate morning briefing message"""
        pass
    
    @abstractmethod
    async def parse_voice_expense(
        self,
        transcription: str
    ) -> Dict:
        """Parse voice input to extract expense details"""
        pass
```

### 4.2 DeepSeek Implementation

```python
import httpx
import json
from typing import Dict
from .base import BaseLLMProvider, InterventionContext, InterventionResponse
from .base import InterventionSeverity, AIMood

class DeepSeekProvider(BaseLLMProvider):
    
    def __init__(self, api_key: str, base_url: str = "https://api.deepseek.com"):
        self.api_key = api_key
        self.base_url = base_url
        self.model = "deepseek-chat"
        
        # Cost tracking (DeepSeek V3 pricing)
        self.cost_per_input_token = 0.14 / 1_000_000  # $0.14 per 1M tokens
        self.cost_per_output_token = 0.28 / 1_000_000  # $0.28 per 1M tokens
    
    async def check_intervention(
        self,
        context: InterventionContext
    ) -> InterventionResponse:
        """
        The Drill Sergeant: Adaptive AI intervention
        """
        
        # Build personality-aware prompt
        mood_instructions = self._get_mood_instructions(context.ai_mood)
        
        prompt = f"""
Eres un asesor financiero estricto para un usuario dominicano. Tu trabajo es decidir si debes intervenir en una compra.

CONTEXTO DEL USUARIO:
- Quiere gastar: RD${context.amount:,.2f}
- Categoría: {context.category}
- Dinero seguro disponible: RD${context.safe_to_spend:,.2f}
- Facturas próximas (7 días): RD${context.upcoming_bills:,.2f}
- Días hasta próxima factura: {context.days_until_bill}
- Categorías débiles: {', '.join(context.weak_categories)}
- Gastó de más recientemente: {'Sí' if context.recent_overspending else 'No'}

PERSONALIDAD: {mood_instructions}

REGLAS:
1. Si el gasto > 50% del dinero seguro → INTERVENIR (RED)
2. Si el gasto es en categoría débil Y > 30% del dinero seguro → INTERVENIR (YELLOW)
3. Si tiene facturas en <7 días Y gasto > 20% del dinero seguro → INTERVENIR (YELLOW)
4. Si todo está bien → NO INTERVENIR

Responde SOLO con JSON válido:
{{
  "should_intervene": boolean,
  "severity": "none" | "yellow" | "red",
  "message": "mensaje corto en español (1-2 oraciones)",
  "reasoning": "explicación breve de la decisión"
}}
"""
        
        response = await self._call_api(prompt, max_tokens=200)
        
        # Parse response
        try:
            result = json.loads(response['content'])
            return InterventionResponse(
                should_intervene=result['should_intervene'],
                severity=InterventionSeverity(result['severity']),
                message=result['message'],
                reasoning=result['reasoning'],
                tokens_used=response['tokens_used'],
                cost_usd=response['cost_usd']
            )
        except (json.JSONDecodeError, KeyError) as e:
            # Fallback to safe intervention
            return InterventionResponse(
                should_intervene=True,
                severity=InterventionSeverity.YELLOW,
                message="No puedo analizar esto ahora, pero considera esperar.",
                reasoning=f"Parse error: {str(e)}",
                tokens_used=response.get('tokens_used', 0),
                cost_usd=response.get('cost_usd', 0)
            )
    
    def _get_mood_instructions(self, mood: AIMood) -> str:
        """Get personality instructions based on mood"""
        moods = {
            AIMood.CALM: "Sé amable y educado. Usa frases como 'Te sugiero' o 'Podrías considerar'.",
            AIMood.BALANCED: "Sé directo pero respetuoso. Dile la verdad sin rodeos.",
            AIMood.AGGRESSIVE: "Sé estricto y directo. Usa frases cortas. Nada de 'por favor'. Ejemplo: 'NO. Deja eso ahí.' Si es grave, puedes ser sarcástico pero nunca grosero."
        }
        return moods[mood]
    
    async def generate_morning_brief(
        self,
        user_id: str,
        safe_to_spend: float,
        upcoming_bills: list[Dict]
    ) -> str:
        """Generate motivational morning briefing"""
        
        bills_text = "\n".join([
            f"- {bill['name']}: RD${bill['amount']:,.2f} (Vence: {bill['due_date']})"
            for bill in upcoming_bills[:3]
        ])
        
        prompt = f"""
Genera un mensaje de buenos días para un usuario dominicano.

CONTEXTO:
- Dinero seguro hoy: RD${safe_to_spend:,.2f}
- Próximas facturas:
{bills_text}

REGLAS:
- Mensaje corto (1-2 oraciones)
- Tono motivacional pero realista
- Menciona el dinero disponible
- Si hay facturas cercanas, recuérdaselo

Responde solo el mensaje en español, sin JSON.
"""
        
        response = await self._call_api(prompt, max_tokens=100)
        return response['content']
    
    async def parse_voice_expense(
        self,
        transcription: str
    ) -> Dict:
        """Parse voice input to extract expense details"""
        
        prompt = f"""
El usuario dijo: "{transcription}"

Extrae la información del gasto. Responde SOLO con JSON válido:
{{
  "amount": número (solo el valor, sin símbolos),
  "category": "food" | "transport" | "entertainment" | "shopping" | "utilities" | "health" | "education" | "other",
  "description": "descripción breve",
  "confidence": 0.0-1.0
}}

Si no puedes extraer el monto, usa "confidence": 0.0
"""
        
        response = await self._call_api(prompt, max_tokens=150)
        
        try:
            return json.loads(response['content'])
        except json.JSONDecodeError:
            return {
                "amount": 0,
                "category": "other",
                "description": transcription,
                "confidence": 0.0
            }
    
    async def _call_api(self, prompt: str, max_tokens: int = 500) -> Dict:
        """Make API call to DeepSeek"""
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": [
                        {"role": "user", "content": prompt}
                    ],
                    "max_tokens": max_tokens,
                    "temperature": 0.3  # Lower for more consistent responses
                },
                timeout=30.0
            )
            
            result = response.json()
            
            # Extract usage info
            usage = result.get('usage', {})
            input_tokens = usage.get('prompt_tokens', 0)
            output_tokens = usage.get('completion_tokens', 0)
            
            # Calculate cost
            cost_usd = (
                input_tokens * self.cost_per_input_token +
                output_tokens * self.cost_per_output_token
            )
            
            return {
                'content': result['choices'][0]['message']['content'],
                'tokens_used': input_tokens + output_tokens,
                'input_tokens': input_tokens,
                'output_tokens': output_tokens,
                'cost_usd': cost_usd
            }
```

### 4.3 LLM Service Manager

```python
from typing import Optional
from .deepseek import DeepSeekProvider
from .base import BaseLLMProvider, InterventionContext

class LLMService:
    """
    Central LLM service with caching and cost tracking
    """
    
    def __init__(self, provider: BaseLLMProvider):
        self.provider = provider
        self.cache = {}  # Simple in-memory cache (use Redis in production)
        self.total_cost = 0.0
        self.total_calls = 0
    
    async def check_intervention(
        self,
        context: InterventionContext,
        use_cache: bool = True
    ) -> InterventionResponse:
        """
        Check intervention with caching
        """
        
        # Create cache key
        cache_key = f"{context.user_id}:{context.amount}:{context.category}:{context.safe_to_spend}"
        
        # Check cache (5 minute TTL)
        if use_cache and cache_key in self.cache:
            cached = self.cache[cache_key]
            if (time.time() - cached['timestamp']) < 300:  # 5 minutes
                return cached['response']
        
        # Call LLM
        response = await self.provider.check_intervention(context)
        
        # Update metrics
        self.total_calls += 1
        self.total_cost += response.cost_usd
        
        # Cache response
        if use_cache:
            self.cache[cache_key] = {
                'response': response,
                'timestamp': time.time()
            }
        
        return response
    
    def get_metrics(self) -> Dict:
        """Get cost and usage metrics"""
        return {
            'total_calls': self.total_calls,
            'total_cost_usd': round(self.total_cost, 4),
            'avg_cost_per_call': round(self.total_cost / max(self.total_calls, 1), 6)
        }
```

---

## 5. OCR + Manual Entry Implementation

### 5.1 OCR Receipt Scanning (Google ML Kit)

**Why Google ML Kit:**
- ✅ Works offline (on-device processing)
- ✅ Free (no API costs)
- ✅ Fast (<2 seconds)
- ✅ Decent accuracy (80-90%)
- ✅ Already integrated in Flutter

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScannerService {
  final textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  
  Future<Map<String, dynamic>?> scanReceipt() async {
    // 1. Take photo or pick from gallery
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (image == null) return null;
    
    // 2. Run OCR
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    
    // 3. Parse the text
    final parsed = _parseReceiptText(recognizedText.text);
    
    // 4. Return extracted data for user confirmation
    return parsed;
  }
  
  Map<String, dynamic>? _parseReceiptText(String text) {
    print('OCR Result: $text'); // Debug
    
    // Extract amount (Dominican Peso format)
    final amountPatterns = [
      RegExp(r'TOTAL[:\s]*RD\$?\s?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'RD\$\s?([\d,]+\.?\d*)'),
      RegExp(r'([\d,]+\.\d{2})\s*$', multiLine: true), // Last line with decimals
    ];
    
    double? amount;
    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        amount = double.tryParse(amountStr ?? '0');
        if (amount != null && amount > 0) break;
      }
    }
    
    // Extract merchant name (usually at the top)
    String? merchant;
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      // First line is usually the merchant
      merchant = lines.first.trim();
      
      // Clean up common receipt headers
      merchant = merchant.replaceAll(RegExp(r'FACTURA|TICKET|RECIBO', caseSensitive: false), '').trim();
    }
    
    // Extract date (if present)
    final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final dateMatch = datePattern.firstMatch(text);
    DateTime? transactionDate;
    
    if (dateMatch != null) {
      try {
        int day = int.parse(dateMatch.group(1)!);
        int month = int.parse(dateMatch.group(2)!);
        int year = int.parse(dateMatch.group(3)!);
        
        // Handle 2-digit year
        if (year < 100) year += 2000;
        
        transactionDate = DateTime(year, month, day);
      } catch (e) {
        transactionDate = DateTime.now();
      }
    } else {
      transactionDate = DateTime.now();
    }
    
    if (amount == null || amount <= 0) {
      return null; // Parsing failed
    }
    
    return {
      'amount': amount,
      'merchant': merchant ?? 'Comercio desconocido',
      'transaction_date': transactionDate.toIso8601String(),
      'raw_text': text,
      'confidence': _calculateConfidence(amount, merchant),
    };
  }
  
  double _calculateConfidence(double? amount, String? merchant) {
    double confidence = 0.0;
    
    if (amount != null && amount > 0) confidence += 0.6;
    if (merchant != null && merchant.length > 3) confidence += 0.3;
    if (amount != null && amount < 100000) confidence += 0.1; // Reasonable amount
    
    return confidence;
  }
  
  void dispose() {
    textRecognizer.close();
  }
}
```

### 5.2 Quick Manual Entry

**Design Philosophy:** 2 taps, 5 seconds max

```dart
class QuickAddExpenseSheet extends StatefulWidget {
  @override
  _QuickAddExpenseSheetState createState() => _QuickAddExpenseSheetState();
}

class _QuickAddExpenseSheetState extends State<QuickAddExpenseSheet> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'other';
  String _description = '';
  
  // Quick amount buttons for common purchases
  final _quickAmounts = [50, 100, 200, 500, 1000, 2000];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Cuánto gastaste?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          SizedBox(height: 16),
          
          // Quick amount buttons
          Wrap(
            spacing: 8,
            children: _quickAmounts.map((amount) {
              return ActionChip(
                label: Text('RD\$${amount}'),
                onPressed: () {
                  _amountController.text = amount.toString();
                },
              );
            }).toList(),
          ),
          
          SizedBox(height: 16),
          
          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefix: Text('RD\$ ', style: TextStyle(fontSize: 32)),
              hintText: '0.00',
              border: OutlineInputBorder(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Category quick select
          Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: [
              _categoryChip('food', '🍔', 'Comida'),
              _categoryChip('transport', '🚗', 'Transporte'),
              _categoryChip('shopping', '🛍️', 'Compras'),
              _categoryChip('entertainment', '🎮', 'Diversión'),
              _categoryChip('other', '📦', 'Otro'),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Optional description
          TextField(
            decoration: InputDecoration(
              hintText: '¿Dónde? (opcional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _description = value,
          ),
          
          SizedBox(height: 24),
          
          // Save button
          ElevatedButton(
            onPressed: _saveExpense,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 56),
            ),
            child: Text('Guardar Gasto'),
          ),
        ],
      ),
    );
  }
  
  Widget _categoryChip(String value, String emoji, String label) {
    final isSelected = _selectedCategory == value;
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }
  
  Future<void> _saveExpense() async {
    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }
    
    // Create expense
    final expense = Expense(
      id: Uuid().v4(),
      amount: amount,
      description: _description.isEmpty ? 'Gasto manual' : _description,
      category: _selectedCategory,
      source: 'manual',
      transactionDate: DateTime.now(),
      detectedAt: DateTime.now(),
    );
    
    // Save locally
    await HiveService.saveExpense(expense);
    
    // Check intervention
    await _checkIntervention(expense);
    
    // Close sheet
    Navigator.pop(context);
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('💰 Gasto guardado')),
    );
  }
  
  Future<void> _checkIntervention(Expense expense) async {
    // Gate 1: Amount threshold
    if (expense.amount < 2000) return;
    
    // Gate 2: Context check
    final userData = await HiveService.getUserData();
    final safeToSpend = await _calculateSafeToSpend(userData);
    
    if (expense.amount < safeToSpend * 0.3) return;
    
    // Gate 3: AI check
    final intervention = await ApiService.checkIntervention(
      amount: expense.amount,
      category: expense.category,
    );
    
    if (intervention.shouldIntervene) {
      // Show intervention dialog
      showDialog(
        context: context,
        builder: (context) => InterventionDialog(intervention: intervention),
      );
    }
  }
  
  Future<double> _calculateSafeToSpend(Map<String, dynamic> userData) async {
    final currentBudget = userData['current_budget'] ?? 0.0;
    final spent = await HiveService.getTotalSpent(DateTime.now());
    return currentBudget - spent;
  }
}
```

### 5.3 Home Screen with FAB (Floating Action Button)

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MoneyGuard')),
      
      body: Column(
        children: [
          _buildDashboard(),
          _buildRecentExpenses(),
        ],
      ),
      
      // Floating Action Button with options
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseOptions(context),
        icon: Icon(Icons.add),
        label: Text('Agregar Gasto'),
      ),
    );
  }
  
  void _showAddExpenseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Escanear Recibo'),
              subtitle: Text('Foto de la factura'),
              onTap: () async {
                Navigator.pop(context);
                final result = await ReceiptScannerService().scanReceipt();
                if (result != null) {
                  _showConfirmExpense(context, result);
                }
              },
            ),
            
            Divider(),
            
            ListTile(
              leading: Icon(Icons.edit, color: Colors.green),
              title: Text('Entrada Rápida'),
              subtitle: Text('Escribir monto'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: QuickAddExpenseSheet(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showConfirmExpense(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ConfirmExpenseSheet(scannedData: data),
    );
  }
}
```

### 5.4 Confirm Scanned Expense

```dart
class ConfirmExpenseSheet extends StatefulWidget {
  final Map<String, dynamic> scannedData;
  
  ConfirmExpenseSheet({required this.scannedData});
  
  @override
  _ConfirmExpenseSheetState createState() => _ConfirmExpenseSheetState();
}

class _ConfirmExpenseSheetState extends State<ConfirmExpenseSheet> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  String _selectedCategory = 'other';
  
  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.scannedData['amount']?.toString() ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.scannedData['merchant'] ?? '',
    );
    
    // Auto-categorize based on merchant
    _selectedCategory = _guessCategory(widget.scannedData['merchant'] ?? '');
  }
  
  @override
  Widget build(BuildContext context) {
    final confidence = widget.scannedData['confidence'] ?? 0.0;
    
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                confidence > 0.7 ? Icons.check_circle : Icons.warning,
                color: confidence > 0.7 ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                'Confirma los datos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto',
              prefix: Text('RD\$ '),
              border: OutlineInputBorder(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Merchant
          TextField(
            controller: _merchantController,
            decoration: InputDecoration(
              labelText: 'Comercio',
              border: OutlineInputBorder(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Category
          Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: [
              _categoryChip('food', '🍔'),
              _categoryChip('transport', '🚗'),
              _categoryChip('shopping', '🛍️'),
              _categoryChip('entertainment', '🎮'),
              _categoryChip('other', '📦'),
            ],
          ),
          
          SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  child: Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _categoryChip(String value, String emoji) {
    return FilterChip(
      selected: _selectedCategory == value,
      label: Text(emoji, style: TextStyle(fontSize: 24)),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }
  
  String _guessCategory(String merchant) {
    final lower = merchant.toLowerCase();
    
    if (lower.contains('super') || lower.contains('colmado')) return 'food';
    if (lower.contains('uber') || lower.contains('gas')) return 'transport';
    if (lower.contains('cine') || lower.contains('game')) return 'entertainment';
    if (lower.contains('mall') || lower.contains('tienda')) return 'shopping';
    
    return 'other';
  }
  
  Future<void> _saveExpense() async {
    // ... same as QuickAddExpenseSheet._saveExpense()
  }
}
```

### 5.5 Required Dependencies

**pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_riverpod: ^2.4.9
  
  # API
  http: ^1.1.0
  
  # OCR
  google_mlkit_text_recognition: ^0.11.0
  image_picker: ^1.0.5
  
  # Utils
  uuid: ^4.2.2
  intl: ^0.19.0
  
  # UI
  flutter_svg: ^2.0.9

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

### 5.6 User Experience Flow

**Flow 1: OCR (70% of use)**
```
1. User taps FAB
2. Sees options: "Escanear Recibo" | "Entrada Rápida"
3. Taps "Escanear Recibo"
4. Camera opens
5. Takes photo of receipt
6. OCR runs (2 seconds)
7. Shows confirmation screen with extracted data
8. User confirms/edits
9. Saves → Intervention check
```

**Flow 2: Quick Add (25% of use)**
```
1. User taps FAB
2. Taps "Entrada Rápida"
3. Sees quick amount buttons (50, 100, 200...)
4. Taps amount or types custom
5. Selects category (one tap)
6. Optional: adds description
7. Saves → Intervention check
```

**Time to Log:**
- OCR: ~10-15 seconds (photo + confirm)
- Quick Add: ~5-8 seconds (type + category + save)

**Much better than notification parsing!**

### 5.7 OCR Tips for Users (Onboarding)

```dart
class OCRTipsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consejos para Escanear')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          _tip(
            '📸',
            'Buena iluminación',
            'Asegúrate de tener luz suficiente',
          ),
          _tip(
            '📐',
            'Recibo plano',
            'Alisa el recibo antes de fotografiar',
          ),
          _tip(
            '🎯',
            'Enfoca el total',
            'El monto total debe estar visible',
          ),
          _tip(
            '✂️',
            'Recorta lo importante',
            'No necesitas toda la factura',
          ),
        ],
      ),
    );
  }
  
  Widget _tip(String emoji, String title, String description) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Text(emoji, style: TextStyle(fontSize: 32)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}
```

---

## 6. Flutter App Architecture

### 6.1 Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── colors.dart
│   │   └── strings.dart
│   │
│   ├── config/
│   │   ├── env_config.dart
│   │   └── api_config.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── text_styles.dart
│   │
│   └── utils/
│       ├── date_formatter.dart
│       ├── currency_formatter.dart
│       └── validators.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── expense_model.dart
│   │   ├── budget_model.dart
│   │   └── intervention_model.dart
│   │
│   ├── repositories/
│   │   ├── expense_repository.dart
│   │   ├── budget_repository.dart
│   │   ├── intervention_repository.dart
│   │   └── auth_repository.dart
│   │
│   └── datasources/
│       ├── local/
│       │   ├── hive_database.dart
│       │   └── hive_boxes.dart
│       │
│       └── remote/
│           ├── api_client.dart
│           └── api_endpoints.dart
│
├── domain/
│   ├── entities/
│   │   ├── expense.dart
│   │   ├── budget.dart
│   │   └── intervention.dart
│   │
│   └── use_cases/
│       ├── log_expense_usecase.dart
│       ├── check_intervention_usecase.dart
│       └── sync_expenses_usecase.dart
│
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── expense_provider.dart
│   │   ├── budget_provider.dart
│   │   └── intervention_provider.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │
│   │   ├── expenses/
│   │   │   ├── expense_list_screen.dart
│   │   │   └── expense_detail_screen.dart
│   │   │
│   │   ├── budget/
│   │   │   ├── budget_screen.dart
│   │   │   └── budget_setup_screen.dart
│   │   │
│   │   ├── intervention/
│   │   │   ├── intervention_dialog.dart
│   │   │   └── voice_check_screen.dart
│   │   │
│   │   └── settings/
│   │       └── settings_screen.dart
│   │
│   └── widgets/
│       ├── common/
│       │   ├── custom_button.dart
│       │   ├── custom_text_field.dart
│       │   └── loading_indicator.dart
│       │
│       └── expense/
│           ├── expense_card.dart
│           └── category_icon.dart
│
└── services/
    ├── ocr_service.dart
    ├── notification_service.dart
    ├── sync_service.dart
    ├── voice_service.dart
    └── api_service.dart
```

### 6.2 Key Data Models

```dart
// Expense Model
@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double amount;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String category;
  
  @HiveField(4)
  final String source; // ocr, manual, voice
  
  @HiveField(5)
  final String? rawOcrText;
  
  @HiveField(6)
  final String? receiptImagePath;
  
  @HiveField(7)
  final double? ocrConfidence;
  
  @HiveField(8)
  final DateTime transactionDate;
  
  @HiveField(9)
  final DateTime detectedAt;
  
  @HiveField(10)
  final DateTime? syncedAt;
  
  @HiveField(11)
  final bool interventionTriggered;
  
  @HiveField(12)
  final String? interventionSeverity;
  
  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.source,
    this.rawOcrText,
    this.receiptImagePath,
    this.ocrConfidence,
    required this.transactionDate,
    required this.detectedAt,
    this.syncedAt,
    this.interventionTriggered = false,
    this.interventionSeverity,
  });
  
  bool get isSynced => syncedAt != null;
  bool get isFromOcr => source == 'ocr';
  bool get hasReceipt => receiptImagePath != null;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'description': description,
    'category': category,
    'source': source,
    'raw_ocr_text': rawOcrText,
    'receipt_image_path': receiptImagePath,
    'ocr_confidence': ocrConfidence,
    'transaction_date': transactionDate.toIso8601String(),
    'detected_at': detectedAt.toIso8601String(),
    'intervention_triggered': interventionTriggered,
    'intervention_severity': interventionSeverity,
  };
}

// Intervention Model
class Intervention {
  final String id;
  final bool shouldIntervene;
  final String severity; // none, yellow, red
  final String message;
  final Map<String, dynamic> context;
  final int tokensUsed;
  final double costUsd;
  
  Intervention({
    required this.id,
    required this.shouldIntervene,
    required this.severity,
    required this.message,
    required this.context,
    required this.tokensUsed,
    required this.costUsd,
  });
  
  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['intervention_id'],
      shouldIntervene: json['should_intervene'],
      severity: json['severity'],
      message: json['message'],
      context: json['context'],
      tokensUsed: json['tokens_used'],
      costUsd: json['cost_usd'],
    );
  }
}
```

---

## 7. Intervention Engine Implementation

### 7.1 Three-Gate Logic (Backend)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Dict
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.user import User
from app.models.expense import Expense
from app.models.intervention import Intervention
from app.services.llm_service import LLMService, InterventionContext, AIMood
from app.core.auth import get_current_user

router = APIRouter()

class InterventionEngine:
    """
    Three-gate intervention system
    """
    
    def __init__(self, db: Session, llm_service: LLMService):
        self.db = db
        self.llm = llm_service
    
    async def check_intervention(
        self,
        user: User,
        amount: float,
        category: str,
        description: str = ""
    ) -> Dict:
        """
        Run the three-gate check
        """
        
        # Initialize result
        result = {
            'should_intervene': False,
            'severity': 'none',
            'gate_results': {},
            'message': '',
            'context': {},
            'tokens_used': 0,
            'cost_usd': 0.0
        }
        
        # GATE 1: Amount Threshold Check (Free, Instant)
        gate_1_passed = self._gate_1_check(amount, user.intervention_threshold)
        result['gate_results']['gate_1'] = 'passed' if gate_1_passed else 'failed'
        
        if gate_1_passed:
            result['message'] = 'Adelante. Ese gasto está dentro de tu presupuesto.'
            return result
        
        # GATE 2: Context Check (Free, Fast)
        gate_2_result = await self._gate_2_check(user, amount, category)
        result['gate_results']['gate_2'] = 'passed' if gate_2_result['passed'] else 'failed'
        result['context'] = gate_2_result['context']
        
        if gate_2_result['passed']:
            result['message'] = 'Puedes continuar, pero ten cuidado con tu presupuesto.'
            return result
        
        # GATE 3: AI Judgment (Costs Tokens)
        result['gate_results']['gate_3'] = 'triggered'
        
        ai_result = await self._gate_3_check(
            user=user,
            amount=amount,
            category=category,
            context=gate_2_result['context']
        )
        
        result['should_intervene'] = ai_result.should_intervene
        result['severity'] = ai_result.severity.value
        result['message'] = ai_result.message
        result['tokens_used'] = ai_result.tokens_used
        result['cost_usd'] = ai_result.cost_usd
        
        # Log intervention
        await self._log_intervention(
            user_id=user.id,
            amount=amount,
            category=category,
            gate_results=result['gate_results'],
            ai_result=ai_result
        )
        
        return result
    
    def _gate_1_check(self, amount: float, threshold: float) -> bool:
        """
        Gate 1: Simple amount threshold
        Returns True if amount is below threshold (safe)
        """
        return amount < threshold
    
    async def _gate_2_check(self, user: User, amount: float, category: str) -> Dict:
        """
        Gate 2: Context-aware check
        Returns True if spending is safe based on budget/bills
        """
        
        # Get current budget
        current_budget = self._get_current_budget(user.id)
        
        # Get upcoming bills (next 7 days)
        upcoming_bills = self._get_upcoming_bills(user.id, days=7)
        total_bills = sum(bill.amount for bill in upcoming_bills)
        
        # Calculate safe-to-spend
        safe_to_spend = current_budget.total_amount - total_bills if current_budget else 0
        
        # Get user patterns
        user_patterns = self._get_user_patterns(user.id)
        weak_categories = user_patterns.impulse_categories if user_patterns else []
        
        # Check if category is weak
        is_weak_category = category in weak_categories
        
        # Context object
        context = {
            'safe_to_spend': safe_to_spend,
            'upcoming_bills': total_bills,
            'days_until_next_bill': self._days_until_next_bill(upcoming_bills),
            'weak_categories': weak_categories,
            'current_balance': current_budget.total_amount if current_budget else 0
        }
        
        # Decision logic
        if amount > safe_to_spend * 0.5:
            # More than 50% of safe money
            return {'passed': False, 'context': context}
        
        if is_weak_category and amount > safe_to_spend * 0.3:
            # Weak category + more than 30% of safe money
            return {'passed': False, 'context': context}
        
        if total_bills > 0 and amount > safe_to_spend * 0.2:
            # Has upcoming bills + more than 20% of safe money
            return {'passed': False, 'context': context}
        
        return {'passed': True, 'context': context}
    
    async def _gate_3_check(
        self,
        user: User,
        amount: float,
        category: str,
        context: Dict
    ) -> InterventionResponse:
        """
        Gate 3: AI-powered judgment
        """
        
        # Get user's AI mood preference
        ai_mood = AIMood(user.intervention_mode)
        
        # Build intervention context
        intervention_context = InterventionContext(
            user_id=str(user.id),
            amount=amount,
            category=category,
            safe_to_spend=context['safe_to_spend'],
            upcoming_bills=context['upcoming_bills'],
            days_until_bill=context['days_until_next_bill'],
            weak_categories=context['weak_categories'],
            recent_overspending=self._check_recent_overspending(user.id),
            ai_mood=ai_mood
        )
        
        # Call LLM
        return await self.llm.check_intervention(intervention_context)
    
    def _get_current_budget(self, user_id: str):
        """Get user's current active budget"""
        from app.models.budget import Budget
        
        today = datetime.now().date()
        return self.db.query(Budget).filter(
            Budget.user_id == user_id,
            Budget.is_active == True,
            Budget.start_date <= today,
            Budget.end_date >= today
        ).first()
    
    def _get_upcoming_bills(self, user_id: str, days: int = 7):
        """Get bills due in next N days"""
        from app.models.upcoming_bill import UpcomingBill
        
        end_date = datetime.now().date() + timedelta(days=days)
        return self.db.query(UpcomingBill).filter(
            UpcomingBill.user_id == user_id,
            UpcomingBill.due_date <= end_date,
            UpcomingBill.is_paid == False
        ).all()
    
    def _days_until_next_bill(self, bills: list) -> int:
        """Calculate days until next bill"""
        if not bills:
            return 999
        
        next_bill = min(bills, key=lambda b: b.due_date)
        return (next_bill.due_date - datetime.now().date()).days
    
    def _get_user_patterns(self, user_id: str):
        """Get user spending patterns"""
        from app.models.user_pattern import UserPattern
        
        return self.db.query(UserPattern).filter(
            UserPattern.user_id == user_id
        ).first()
    
    def _check_recent_overspending(self, user_id: str, days: int = 7) -> bool:
        """Check if user overspent recently"""
        from app.models.expense import Expense
        
        cutoff_date = datetime.now() - timedelta(days=days)
        
        # Get recent interventions that were ignored
        ignored_interventions = self.db.query(Intervention).filter(
            Intervention.user_id == user_id,
            Intervention.created_at >= cutoff_date,
            Intervention.should_intervene == True,
            Intervention.user_proceeded == True  # User bought anyway
        ).count()
        
        return ignored_interventions > 2
    
    async def _log_intervention(
        self,
        user_id: str,
        amount: float,
        category: str,
        gate_results: Dict,
        ai_result: InterventionResponse
    ):
        """Log intervention to database"""
        from app.models.intervention import Intervention
        
        intervention = Intervention(
            user_id=user_id,
            proposed_amount=amount,
            proposed_category=category,
            gate_1_passed=gate_results['gate_1'] == 'passed',
            gate_2_passed=gate_results['gate_2'] == 'passed',
            gate_3_triggered=gate_results.get('gate_3') == 'triggered',
            should_intervene=ai_result.should_intervene,
            severity=ai_result.severity.value,
            ai_message=ai_result.message,
            ai_reasoning=ai_result.reasoning,
            tokens_used=ai_result.tokens_used
        )
        
        self.db.add(intervention)
        self.db.commit()
        
        # Also log cost to system_metrics
        await self._update_system_metrics(
            tokens_used=ai_result.tokens_used,
            cost_usd=ai_result.cost_usd
        )
    
    async def _update_system_metrics(self, tokens_used: int, cost_usd: float):
        """Update daily system metrics"""
        from app.models.system_metric import SystemMetric
        
        today = datetime.now().date()
        
        metric = self.db.query(SystemMetric).filter(
            SystemMetric.metric_date == today
        ).first()
        
        if not metric:
            metric = SystemMetric(metric_date=today)
            self.db.add(metric)
        
        metric.llm_calls_total += 1
        metric.llm_tokens_used += tokens_used
        metric.llm_cost_usd += cost_usd
        
        self.db.commit()
```

### 7.2 API Endpoint

```python
@router.post("/check")
async def check_intervention(
    request: InterventionCheckRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    llm_service: LLMService = Depends(get_llm_service)
):
    """
    Check if intervention is needed for a purchase
    """
    
    engine = InterventionEngine(db, llm_service)
    
    result = await engine.check_intervention(
        user=current_user,
        amount=request.amount,
        category=request.category,
        description=request.description
    )
    
    return {
        'success': True,
        'data': result
    }
```

---

## 8. Development Roadmap

### Week 1: Foundation
- [ ] Set up FastAPI project structure
- [ ] Create PostgreSQL database and schema
- [ ] Implement user authentication (JWT)
- [ ] Set up Flutter project with Hive
- [ ] Implement basic UI screens (login, home)
- [ ] Research: Collect real notification samples from DR banks

### Week 2: Notification Parsing
- [ ] Implement NotificationListenerService (Flutter)
- [ ] Create bank notification regex patterns (based on real samples)
- [ ] Build local expense logging (Hive)
- [ ] Test with real notifications from DR bank apps
- [ ] Implement background notification processing
- [ ] Create onboarding flow for notification permission

### Week 3: Intervention Engine
- [ ] Build three-gate intervention logic (backend)
- [ ] Integrate DeepSeek API
- [ ] Implement LLM service with caching
- [ ] Create intervention API endpoint
- [ ] Build intervention UI (Flutter dialogs/alerts)

### Week 4: Polish & Beta
- [ ] Implement sync service (background job)
- [ ] Add budget management screens
- [ ] Create analytics dashboard
- [ ] Implement voice input ("Can I buy X?")
- [ ] Morning briefing notification
- [ ] Beta testing with 10 users in Santiago

---

## 9. Cost Projections

### Per-User Monthly Cost (at scale)

| Component | Cost |
|-----------|------|
| LLM (DeepSeek) | $0.02 |
| Database | $0.01 |
| Storage | $0.005 |
| Compute | $0.01 |
| **Total** | **$0.045/user** |

### Infrastructure (1,000 users)

| Service | Monthly Cost |
|---------|--------------|
| Railway (Backend + DB) | $15 |
| Redis (optional) | $0 (in-memory cache) |
| Total Infrastructure | $15 |

**Break-even**: ~350 users at $0.99/month or 100 users at $2.99/month

---

## 10. Success Metrics

### Phase 1 (MVP - Week 4)
- [ ] 95% notification parse success rate
- [ ] <200ms local intervention checks (Gate 1 & 2)
- [ ] <2s AI intervention response (Gate 3)
- [ ] 10 beta users logging expenses daily
- [ ] Support for 3+ Dominican bank apps

### Phase 2 (Growth - Month 2-3)
- [ ] 100 active users
- [ ] 80% user retention (Day 30)
- [ ] 60% intervention acceptance rate
- [ ] <$50/month LLM costs
- [ ] 4.5+ star rating on Play Store

### Phase 3 (Scale - Month 4-6)
- [ ] 1,000 active users
- [ ] 70% user retention (Day 30)
- [ ] $500+/month revenue
- [ ] Expand to 3+ DR banks
- [ ] Launch iOS version

---

## Conclusion

This SRS provides a complete technical blueprint for MoneyGuard with a pragmatic, proven approach. The architecture is:

1. **Cost-Effective**: Three-gate system minimizes LLM costs, OCR is free (Google ML Kit)
2. **Dominican-Focused**: OCR works for ALL banks, no bank-specific dependencies
3. **Intervention-First**: Proactive AI prevents bad decisions in real-time
4. **Scalable**: Simple infrastructure can handle 1,000+ users
5. **Offline-First**: Works without internet for logging and local intervention checks
6. **Ship-Ready**: No permission complexity, no fragile parsers, straightforward UX

**Next Steps**: Begin Week 1 implementation with database schema and FastAPI setup. OCR integration in Week 2.

Ready to code! 🚀
