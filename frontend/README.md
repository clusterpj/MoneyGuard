# MoneyGuard Frontend

> Flutter mobile application for MoneyGuard - AI-powered financial intervention system

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release
```

## Project Structure

```
frontend/
├── lib/
│   ├── core/              # Core utilities, constants, config
│   │   ├── config/
│   │   └── theme/
│   ├── features/          # Feature-based modular architecture
│   │   ├── ai_advisor/    # AI advice and intervention logic
│   │   ├── auth/          # Authentication (Login, Register)
│   │   ├── budget/        # Budget management
│   │   ├── dashboard/     # Home screen and summary
│   │   ├── expense/       # Expense tracking & OCR
│   │   └── intervention/  # Gate system components
│   ├── shared/            # Shared widgets and logic
│   └── main.dart          # App entry point
├── test/                  # Unit tests
├── integration_test/      # Integration tests
├── pubspec.yaml          # Dependencies
└── README.md             # This file
```

## Key Dependencies

- **flutter**: Mobile framework
- **hive**: Local database
- **riverpod**: State management
- **google_mlkit_text_recognition**: OCR
- **http**: API client
- **intl**: Internationalization

## Features

- ✅ OCR receipt scanning
- ✅ Quick manual entry
- ✅ Offline-first with Hive
- ✅ 3-gate intervention system
- ✅ Background sync
- ✅ Budget management

## Development

See [main setup guide](../docs/SETUP.md) for detailed instructions.

## License

MIT License - see [LICENSE](../LICENSE)
