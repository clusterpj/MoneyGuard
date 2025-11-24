# MoneyGuard API Documentation

> **Complete API reference for the MoneyGuard backend**

Base URL: `https://api.moneyguard.app/api/v1` (production)  
Local: `http://localhost:8000/api/v1` (development)

---

## Table of Contents

- [Authentication](#authentication)
- [Expenses](#expenses)
- [Budgets](#budgets)
- [Intervention](#intervention)
- [User](#user)
- [Error Handling](#error-handling)

---

## Authentication

### Register

Create a new user account.

```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "Juan Pérez",
  "phone": "+1809-555-0123"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "email": "user@example.com",
    "name": "Juan Pérez",
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "expires_in": 3600
  }
}
```

### Login

Authenticate and get access token.

```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "expires_in": 3600
  }
}
```

---

## Expenses

All expense endpoints require authentication. Include the access token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Create Expense

```http
POST /expenses
```

**Request Body:**
```json
{
  "amount": 1500.00,
  "description": "Compra en Supermercado Nacional",
  "category": "food",
  "source": "ocr",
  "raw_ocr_text": "SUPERMERCADO NACIONAL\nTOTAL: RD$1,500.00",
  "ocr_confidence": 0.85,
  "transaction_date": "2025-11-24T14:30:00Z"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "amount": 1500.00,
    "description": "Compra en Supermercado Nacional",
    "category": "food",
    "source": "ocr",
    "transaction_date": "2025-11-24T14:30:00Z",
    "created_at": "2025-11-24T14:31:00Z"
  }
}
```

### List Expenses

```http
GET /expenses?page=1&limit=20&category=food&start_date=2025-11-01&end_date=2025-11-30
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `category` (optional): Filter by category
- `start_date` (optional): Filter by date range
- `end_date` (optional): Filter by date range

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "expenses": [
      {
        "id": "uuid",
        "amount": 1500.00,
        "description": "Compra en Supermercado Nacional",
        "category": "food",
        "transaction_date": "2025-11-24T14:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "pages": 3
    }
  }
}
```

### Bulk Sync

Sync multiple expenses from mobile app.

```http
POST /expenses/bulk
```

**Request Body:**
```json
{
  "expenses": [
    {
      "local_id": "uuid-1",
      "amount": 1500.00,
      "category": "food",
      "source": "ocr",
      "transaction_date": "2025-11-24T14:30:00Z"
    },
    {
      "local_id": "uuid-2",
      "amount": 500.00,
      "category": "transport",
      "source": "manual",
      "transaction_date": "2025-11-24T15:00:00Z"
    }
  ]
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "synced_count": 2,
    "failed_count": 0,
    "expenses": [
      {
        "local_id": "uuid-1",
        "server_id": "server-uuid-1",
        "synced_at": "2025-11-24T15:05:00Z"
      },
      {
        "local_id": "uuid-2",
        "server_id": "server-uuid-2",
        "synced_at": "2025-11-24T15:05:00Z"
      }
    ]
  }
}
```

---

## Budgets

### Get Current Budget

```http
GET /budgets/current
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "total_amount": 30000.00,
    "safe_to_spend": 18000.00,
    "spent_amount": 12000.00,
    "start_date": "2025-11-01",
    "end_date": "2025-11-30",
    "days_remaining": 6
  }
}
```

### Create/Update Budget

```http
POST /budgets
```

**Request Body:**
```json
{
  "total_amount": 30000.00,
  "period": "monthly",
  "start_date": "2025-12-01"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "total_amount": 30000.00,
    "period": "monthly",
    "start_date": "2025-12-01",
    "end_date": "2025-12-31"
  }
}
```

---

## Intervention

### Check Intervention

The core feature! Check if AI should intervene before a purchase.

```http
POST /intervention/check
```

**Request Body:**
```json
{
  "amount": 3500.00,
  "category": "entertainment",
  "merchant": "GameStop",
  "description": "Quiero comprar un GPU"
}
```

**Response (RED Alert):** `200 OK`
```json
{
  "success": true,
  "data": {
    "should_intervene": true,
    "severity": "red",
    "gate_results": {
      "gate_1": "failed",
      "gate_2": "failed",
      "gate_3": "triggered"
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

**Response (GREEN - Safe):** `200 OK`
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

### Intervention Feedback

Log user's decision after intervention.

```http
POST /intervention/feedback
```

**Request Body:**
```json
{
  "intervention_id": "uuid",
  "user_proceeded": false,
  "user_response": "cancelled"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Feedback recorded"
}
```

---

## User

### Get Profile

```http
GET /user/profile
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Juan Pérez",
    "intervention_mode": "balanced",
    "intervention_threshold": 2000,
    "created_at": "2025-11-01T10:00:00Z"
  }
}
```

### Update Settings

```http
PATCH /user/settings
```

**Request Body:**
```json
{
  "intervention_mode": "aggressive",
  "intervention_threshold": 1500
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Settings updated"
}
```

---

## Error Handling

### Error Response Format

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or missing access token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 422 | Invalid request data |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

### Example Error Response

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": {
      "amount": ["Must be a positive number"],
      "category": ["Must be one of: food, transport, entertainment, ..."]
    }
  }
}
```

---

## Rate Limiting

- **Default**: 60 requests per minute per user
- **Intervention endpoint**: 10 requests per minute
- **Bulk sync**: 5 requests per minute

Rate limit headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1638360000
```

---

## Pagination

List endpoints support pagination:

**Request:**
```http
GET /expenses?page=2&limit=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total": 45,
    "pages": 3,
    "has_next": true,
    "has_prev": true
  }
}
```

---

## Versioning

The API is versioned via the URL path: `/api/v1/`

Breaking changes will result in a new version: `/api/v2/`

---

**Last Updated**: November 24, 2025
