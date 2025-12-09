# Contributing to MoneyGuard

First off, thank you for considering contributing to MoneyGuard! 🎉

MoneyGuard is an open-source project aimed at helping people take control of their finances through AI-powered intervention. Every contribution helps make financial wellness more accessible.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)

---

## 🤝 Code of Conduct

This project adheres to a simple code of conduct:

- **Be respectful** - Treat everyone with respect and kindness
- **Be constructive** - Provide helpful feedback and suggestions
- **Be collaborative** - Work together to improve the project
- **Be inclusive** - Welcome contributors of all backgrounds and skill levels

---

## 🎯 How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

**When reporting a bug, include:**
- Clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots (if applicable)
- Device/OS information
- App version

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

### Suggesting Features

We love feature suggestions! Before creating a feature request:

1. Check if it's already been suggested
2. Consider if it aligns with the project's goals
3. Think about how it would benefit users

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Contributing Code

We welcome code contributions! Here are some areas where you can help:

- **Frontend (Flutter)**
  - UI/UX improvements
  - New screens or widgets
  - Performance optimizations
  - Accessibility features

- **Backend (FastAPI)**
  - API endpoints
  - Database optimizations
  - AI/LLM improvements
  - Security enhancements

- **Documentation**
  - Improve existing docs
  - Add code examples
  - Translate to other languages
  - Create tutorials

- **Testing**
  - Write unit tests
  - Add integration tests
  - Improve test coverage

---

## 🔧 Development Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/moneyguard.git
cd moneyguard
git remote add upstream https://github.com/ORIGINAL_OWNER/moneyguard.git
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch naming conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding tests
- `chore/` - Maintenance tasks

### 3. Set Up Development Environment

**Backend:**
```bash
# Start Database
docker compose up -d postgres

cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies
```

**Frontend:**
```bash
cd frontend
flutter pub get
```

### 4. Make Your Changes

- Write clean, readable code
- Follow the coding standards (see below)
- Add tests for new features
- Update documentation as needed

### 5. Test Your Changes

**Backend:**
```bash
cd backend
pytest
black . --check
flake8
```

**Frontend:**
```bash
cd frontend
flutter test
flutter analyze
dart format --set-exit-if-changed .
```

### 6. Commit Your Changes

Follow our [commit message guidelines](#commit-message-guidelines).

```bash
git add .
git commit -m "feat: add OCR confidence threshold setting"
```

### 7. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## 📝 Coding Standards

### Dart/Flutter

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` before committing
- Run `flutter analyze` to catch issues
- Prefer composition over inheritance
- Use meaningful variable names
- Add comments for complex logic

**Example:**
```dart
// Good
final double safeToSpendAmount = budget.total - upcomingBills;

// Bad
final double amt = b.t - ub;
```

### Python

- Follow [PEP 8](https://pep8.org/)
- Use `black` for formatting (line length: 88)
- Use type hints for function signatures
- Write docstrings for public functions
- Keep functions small and focused

**Example:**
```python
# Good
def calculate_safe_to_spend(
    budget: Budget,
    upcoming_bills: list[Bill]
) -> Decimal:
    """Calculate the safe-to-spend amount.
    
    Args:
        budget: User's current budget
        upcoming_bills: List of upcoming bills
        
    Returns:
        Safe amount user can spend
    """
    total_bills = sum(bill.amount for bill in upcoming_bills)
    return budget.total_amount - total_bills
```

### General Principles

- **DRY** - Don't Repeat Yourself
- **KISS** - Keep It Simple, Stupid
- **YAGNI** - You Aren't Gonna Need It
- **Single Responsibility** - One function, one purpose
- **Write tests** - Especially for critical features

---

## 💬 Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, no logic change)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks
- `perf` - Performance improvements

### Examples

```bash
feat(ocr): add confidence threshold setting

Allow users to set minimum OCR confidence threshold
in settings. Defaults to 0.8.

Closes #123
```

```bash
fix(intervention): handle null budget gracefully

Previously crashed when user had no active budget.
Now shows appropriate message and suggests creating one.

Fixes #456
```

```bash
docs(api): update intervention endpoint examples

Added examples for all severity levels (none, yellow, red)
and clarified response format.
```

### Scope (Optional)

- `frontend` - Flutter app changes
- `backend` - API/server changes
- `ocr` - OCR-related changes
- `intervention` - Intervention system
- `auth` - Authentication
- `db` - Database changes
- `ci` - CI/CD changes

---

## 🔄 Pull Request Process

### Before Submitting

- [ ] Code follows the style guidelines
- [ ] All tests pass
- [ ] Added tests for new features
- [ ] Updated documentation
- [ ] Commit messages follow guidelines
- [ ] Branch is up to date with main

### PR Checklist

Use the [PR template](.github/PULL_REQUEST_TEMPLATE.md) which includes:

- Description of changes
- Type of change (bug fix, feature, etc.)
- Testing performed
- Screenshots (for UI changes)
- Related issues

### Review Process

1. **Automated Checks** - CI/CD runs tests and linters
2. **Code Review** - Maintainer reviews your code
3. **Feedback** - Address any requested changes
4. **Approval** - Once approved, PR will be merged
5. **Cleanup** - Delete your branch after merge

### Getting Your PR Merged Faster

- Keep PRs small and focused
- Write clear descriptions
- Respond to feedback promptly
- Be patient and respectful

---

## 🧪 Testing Guidelines

### Unit Tests

- Test individual functions/methods
- Mock external dependencies
- Aim for 80%+ coverage

### Integration Tests

- Test feature flows end-to-end
- Test API endpoints
- Test database operations

### Widget Tests (Flutter)

- Test UI components
- Test user interactions
- Test state changes

---

## 📚 Additional Resources

- [Project Documentation](docs/)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)
- [Setup Guide](docs/SETUP.md)

---

## ❓ Questions?

- Open a [GitHub Discussion](https://github.com/yourusername/moneyguard/discussions)
- Check existing [Issues](https://github.com/yourusername/moneyguard/issues)
- Read the [Documentation](docs/)

---

## 🎉 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to MoneyGuard! 🙏
