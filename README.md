# MoneyGuard 🛡️💰

> **Your AI-Powered Financial Firewall**  
> Stop overspending before it happens with intelligent intervention and OCR receipt scanning.

[![Status](https://img.shields.io/badge/status-MVP%20Development-yellow)](https://github.com/yourusername/moneyguard)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-009688?logo=fastapi)](https://fastapi.tiangolo.com)

---

## 🎯 What is MoneyGuard?

MoneyGuard is a **financial defense system** that prevents overspending through AI-powered interventions. Unlike traditional budgeting apps that show you charts *after* you've overspent, MoneyGuard **warns you in real-time** before you make a purchase you can't afford.

### The Problem

You're about to buy something. You *think* you can afford it. But you forgot:
- Rent is due in 3 days
- You have $200 left for groceries this week
- You already overspent on entertainment this month

**MoneyGuard stops you** with a clear, direct message: *"NO. You have rent in 3 days. If you buy this, you'll have RD$400 left for food. Leave it."*

---

## ✨ Key Features

### 🤖 3-Gate AI Intervention System
- **Gate 1**: Amount threshold check (instant, local)
- **Gate 2**: Safe-to-spend calculation (instant, local)
- **Gate 3**: AI-powered context analysis (DeepSeek LLM)

Only triggers expensive AI calls when necessary, keeping costs under $5/month.

### 📸 OCR Receipt Scanning
- Snap a photo of any receipt
- Google ML Kit extracts amount and merchant (80-90% accuracy)
- Confirm or edit in 2 seconds
- Works offline, no API costs

### ⚡ Quick Manual Entry
- 2 taps, 5 seconds to log an expense
- Pre-set amount buttons (50, 100, 200, 500...)
- One-tap category selection
- Perfect for cash purchases

### 🔒 Offline-First Architecture
- All core features work without internet
- Background sync when online
- Local Hive database for instant access
- Never lose data

### 🎭 Adaptive AI Personality
- **Calm Mode**: Gentle suggestions
- **Balanced Mode**: Direct and honest
- **Drill Sergeant Mode**: Aggressive intervention (default for Dominican market)

---

## 🏗️ Tech Stack

### Frontend (Mobile)
- **Flutter 3.16+** - Cross-platform mobile framework
- **Hive** - Fast, offline-first local database
- **Riverpod** - State management
- **Google ML Kit** - On-device OCR (free, offline)

### Backend (API)
- **FastAPI** - High-performance Python web framework
- **PostgreSQL** - Primary database
- **DeepSeek V3** - Cost-effective LLM ($0.14 per 1M tokens)
- **Railway** - Deployment platform

### Infrastructure
- **Railway** - Backend hosting + managed PostgreSQL
- **GitHub Actions** - CI/CD pipelines

**Total Monthly Cost**: $5-10 (excluding development time)

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.16 or higher
- Python 3.11 or higher
- Docker & Docker Compose (for Database)
- DeepSeek API key

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/moneyguard.git
cd moneyguard
```

### 2. Backend Setup
```bash
# Start Database via Docker
docker compose up -d postgres

cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your database URL and API keys

# Run migrations
alembic upgrade head

# Start the server
uvicorn app.main:app --reload
```

### 3. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

For detailed setup instructions, see [docs/SETUP.md](docs/SETUP.md).

---

## 📱 Screenshots

> Coming soon - App is currently in MVP development

---

## 🗺️ Roadmap

### ✅ MVP (Weeks 1-4)
- [x] Project planning and architecture
- [ ] Backend API with intervention engine
- [ ] Flutter app with OCR scanning
- [ ] Quick manual entry
- [ ] 3-gate intervention system
- [ ] Beta launch with 10 users

### 🔄 v1.1 (Weeks 5-6)
- [ ] Voice input for expenses
- [ ] Improved OCR accuracy
- [ ] Basic spending analytics
- [ ] Enhanced AI prompts

### 🎯 v1.2 (Weeks 7-8)
- [ ] Analytics dashboard
- [ ] Bill reminders
- [ ] CSV export
- [ ] Dark mode

### 🚀 v2.0 (Month 3+)
- [ ] Goal tracking
- [ ] Recurring expense detection
- [ ] Budget optimization AI
- [ ] Savings challenges
- [ ] Premium features

See [ROADMAP.md](ROADMAP.md) for detailed timeline.

---

## 📚 Documentation

- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design and data flow
- **[API Documentation](docs/API.md)** - Complete API reference
- **[Setup Guide](docs/SETUP.md)** - Development environment setup
- **[Technical Specification](docs/architecture/technical-specification.md)** - Detailed SRS
- **[MVP Implementation Plan](docs/guides/mvp-implementation.md)** - 4-week sprint plan
- **[OCR Pivot Decision](docs/architecture/ocr-pivot-decision.md)** - Why we chose OCR over notification parsing

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎯 Target Market

**Primary**: Dominican Republic  
**Language**: Spanish UI, English codebase  
**Currency**: Dominican Peso (DOP)

---

## 💡 Why MoneyGuard?

### The Unique Value Proposition

1. **Prevention > Tracking** - Stop overspending before it happens, not after
2. **OCR > Manual Entry** - 10 seconds to log vs 60 seconds typing
3. **Offline-First** - Works everywhere, syncs when possible
4. **AI That Cares** - Adaptive personality that learns your patterns
5. **Cost-Effective** - $5-10/month to run, not $50+

### What Makes It Different

Most budgeting apps are **reactive** - they show you pretty charts after you've already overspent.

MoneyGuard is **proactive** - it intervenes in real-time with context-aware AI that knows:
- Your upcoming bills
- Your spending patterns
- Your weak categories
- Your current financial state

---

## 📞 Contact

**Project Lead**: Pedro Jimenez  
**Email**: your.email@example.com  
**Project Link**: [https://github.com/yourusername/moneyguard](https://github.com/yourusername/moneyguard)

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Amazing cross-platform framework
- [FastAPI](https://fastapi.tiangolo.com) - Lightning-fast Python web framework
- [DeepSeek](https://www.deepseek.com) - Cost-effective LLM provider
- [Google ML Kit](https://developers.google.com/ml-kit) - Free, offline OCR
- [Railway](https://railway.app) - Simple deployment platform

---

<div align="center">

**Built with ❤️ for the Dominican Republic**

[Report Bug](https://github.com/yourusername/moneyguard/issues) · [Request Feature](https://github.com/yourusername/moneyguard/issues) · [Documentation](docs/)

</div>
