# Contributing to NFC Wallet Suppression

Thank you for your interest in contributing to NFC Wallet Suppression! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.22.0 or higher
- [Dart SDK](https://dart.dev/get-dart) ^3.7.0 or higher
- Git
- Xcode (for iOS development on macOS)
- Android Studio or Android SDK (for Android development)

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/nfc_wallet_suppression.git
   cd nfc_wallet_suppression
   ```

3. **Install dependencies**:

   ```bash
   flutter pub get
   ```

4. **Verify the setup** by running tests:

   ```bash
   flutter test
   ```

5. **Build example app** to test on platform:

   ```bash
   cd example
   flutter pub get
   flutter run
   ```

## Making Changes

### Branch Strategy

- Create a new branch for your feature/fix:

  ```bash
  git checkout -b feature/your-feature-name
  # or
  git checkout -b fix/issue-description
  ```

### Commit Messages

Follow conventional commit format for both **commit messages** and **pull request titles**:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `test:` for adding/updating tests
- `refactor:` for code refactoring
- `style:` for formatting changes
- `chore:` for maintenance tasks
- `ci:` for CI/CD changes
- `perf:` for performance improvements
- `build:` for build system changes

Example:

```text
feat: add support for filtering by multiple tags

- Allow JSON array input for tags parameter
- Update argument parser to handle array format
- Add validation for tag format
```

> **Note:** Pull request titles are automatically validated to ensure they follow this format.

## Testing

### Running Tests

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
cd example
flutter test integration_test/
```

### Writing Tests

- Add unit tests for new features in the `test/` directory
- Add integration tests in `example/integration_test/` directory
- Follow the existing test structure and naming conventions
- Test both success and error cases
- Mock platform-specific dependencies where appropriate

Example test structure:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  group('NfcWalletSuppression', () {
    test('requestSuppression should return status', () async {
      // Arrange
      // Act
      final status = await NfcWalletSuppression.requestSuppression();
      // Assert
      expect(status, isNotNull);
    });

    test('should throw exception for invalid calls', () async {
      // Test error cases
    });
  });
}
```

## Code Style

### Dart/Flutter Style Guidelines

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code:

  ```bash
  dart format .
  ```

- Run the linter:

  ```bash
  flutter analyze
  ```

### Code Organization

- Keep functions small and focused
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Follow the existing project structure:
  - `lib/` - Main plugin code
  - `lib/src/` - Internal implementation
  - `ios/` - iOS-specific code (Swift)
  - `android/` - Android-specific code (Kotlin)
  - `example/` - Example Flutter app
  - `test/` - Unit and widget tests
  - `example/integration_test/` - Integration tests

### Documentation

- Add dartdoc comments for public classes and methods:

  ```dart
  /// Requests NFC wallet suppression for iOS/Android devices.
  ///
  /// Returns a [Future] that completes with the [SuppressionStatus].
  /// Throws an exception if suppression cannot be requested.
  Future<SuppressionStatus> requestSuppression() async {
    // Implementation
  }
  ```

## Submitting Changes

### Before Submitting

1. **Format your code**:

   ```bash
   dart format .
   ```

2. **Run linter**:

   ```bash
   flutter analyze
   ```

3. **Run tests**:

   ```bash
   flutter test
   cd example && flutter test integration_test/ && cd ..
   ```

4. **Build example app** on target platforms:

   ```bash
   cd example
   flutter build apk --debug  # Android
   flutter build ios --debug  # iOS (requires Xcode)
   ```

### Pull Request Process

1. **Push your changes** to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub with:
   - Clear title and description
   - Reference any related issues
   - Include screenshots/examples if applicable

3. **Respond to feedback** and make requested changes

4. **Ensure CI passes** - all tests and checks must pass

### Pull Request Template

When creating a PR, please include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests pass locally
- [ ] Documentation updated
```

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Environment information**:
   - Flutter version
   - Dart version
   - iOS/Android version
   - Device or simulator information

2. **Steps to reproduce**:
   - Exact code/steps to trigger the issue
   - Expected behavior
   - Actual behavior

3. **Additional context**:
   - Error messages and stack traces
   - Platform-specific logs (Xcode console, Android Studio logcat)
   - Screenshots if relevant

### Feature Requests

When requesting features:

1. **Describe the problem** the feature would solve
2. **Propose a solution** or approach
3. **Consider alternatives** and their trade-offs
4. **Provide examples** of how it would be used

## Getting Help

- 📖 Check the [README](README.md) for usage instructions
- 🐛 Search [existing issues](https://github.com/teklund/nfc_wallet_suppression/issues) before creating new ones
- 💬 Ask questions in issue discussions
- 📧 Contact maintainers for security-related issues

## Recognition

Contributors will be acknowledged in:

- CHANGELOG.md for their contributions
- GitHub contributors list

Thank you for contributing to NFC Wallet Suppression! 🎉
