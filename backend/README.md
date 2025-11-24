# MoneyGuard Backend

> FastAPI backend for MoneyGuard - AI-powered financial intervention system

## Quick Start

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment
cp ../.env.example .env
# Edit .env with your configuration

# Run migrations
alembic upgrade head

# Start server
uvicorn app.main:app --reload
```

Visit http://localhost:8000/docs for API documentation.

## Project Structure

```
backend/
├── app/
│   ├── api/              # API endpoints
│   │   ├── v1/
│   │   │   ├── auth.py
│   │   │   ├── expenses.py
│   │   │   ├── budgets.py
│   │   │   └── intervention.py
│   │   └── deps.py       # Dependencies
│   ├── core/             # Core config
│   │   ├── config.py
│   │   ├── security.py
│   │   └── database.py
│   ├── db/               # Database models
│   │   └── models.py
│   ├── services/         # Business logic
│   │   ├── intervention.py
│   │   ├── llm.py
│   │   └── budget.py
│   ├── schemas/          # Pydantic schemas
│   └── main.py           # App entry point
├── tests/                # Tests
├── alembic/              # Database migrations
├── requirements.txt      # Dependencies
├── requirements-dev.txt  # Dev dependencies
└── README.md            # This file
```

## Key Dependencies

- **fastapi**: Web framework
- **sqlalchemy**: ORM
- **alembic**: Database migrations
- **pydantic**: Data validation
- **python-jose**: JWT tokens
- **httpx**: HTTP client (for DeepSeek API)

## Features

- ✅ JWT authentication
- ✅ 3-gate intervention engine
- ✅ DeepSeek LLM integration
- ✅ PostgreSQL database
- ✅ RESTful API
- ✅ Auto-generated docs

## Development

See [main setup guide](../docs/SETUP.md) for detailed instructions.

## Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test
pytest tests/test_intervention.py
```

## Deployment

Deploy to Railway:

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
railway up
```

## License

MIT License - see [LICENSE](../LICENSE)
