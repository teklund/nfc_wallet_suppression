# Testing Guide

This guide shows how to test your app when using the `nfc_wallet_suppression` plugin.

## Quick Start

Import the testing utilities in your test files:

```dart
import 'package:nfc_wallet_suppression/testing.dart';
```

## Using FakeNfcWalletSuppression

`FakeNfcWalletSuppression` replaces the platform implementation, so the plugin
returns what you configure:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/testing.dart';

void main() {
  late FakeNfcWalletSuppression fake;

  setUp(() {
    fake = FakeNfcWalletSuppression();
    NfcWalletSuppressionPlatform.instance = fake;
  });

  test('your test here', () async {
    // Use the plugin normally in your test
    final result = await NfcWalletSuppression.requestSuppression();

    expect(result.status, SuppressionStatus.suppressed);
  });
}
```

## Configuring the Fake

By default the fake is a supported device on which requests and releases
succeed. Change that through the constructor or the properties:

| Property        | Controls                             | Default                                     |
| --------------- | ------------------------------------ | ------------------------------------------- |
| `supported`     | What `isSupported()` returns         | `true`                                      |
| `requestResult` | What `requestSuppression()` returns  | A result with `SuppressionStatus.suppressed`    |
| `releaseResult` | What `releaseSuppression()` returns  | A result with `SuppressionStatus.notSuppressed` |
| `suppressed`    | What `isSuppressed()` returns        | `false`                                     |

Like the real plugin, `requestSuppression()` sets `suppressed` from its result,
and a successful `releaseSuppression()` clears it.

```dart
// A device without NFC hardware
final fake = FakeNfcWalletSuppression(
  supported: false,
  requestResult: const SuppressionResult(status: SuppressionStatus.notSupported),
);

// Change the behavior mid-test, with a description to assert on
fake.requestResult = const SuppressionResult(
  status: SuppressionStatus.denied,
  description: 'Entitlement missing',
);
```

For a fresh fake in every test, create it in `setUp()`.

## Tracking Method Calls

The fake tracks all method calls in the `methodCalls` list:

```dart
test('tracks method calls', () async {
  await NfcWalletSuppression.isSupported();
  await NfcWalletSuppression.requestSuppression();
  
  expect(fake.methodCalls, [
    'isSupported',
    'requestSuppression',
  ]);
});
```

## Test Scenarios

Each scenario is a `requestResult` (or `releaseResult`) with the matching status:

| Scenario                                   | Configure                                              |
| ------------------------------------------ | ------------------------------------------------------ |
| Device without NFC hardware                | `supported: false`, request status `notSupported`      |
| NFC switched off in settings (Android)     | Request status `nfcDisabled`, to test your "turn NFC on" prompt |
| Transiently unavailable, e.g. no Activity  | Request status `unavailable`                           |
| Refused, e.g. missing iOS entitlement      | Request status `denied`                                |
| Wallet already presenting a pass (iOS)     | Request status `alreadyPresenting`                     |
| Release failed                             | Release status `unknown`                               |

```dart
fake.requestResult = const SuppressionResult(status: SuppressionStatus.nfcDisabled);
```

## Complete Example

Here's a complete test suite for a hypothetical NFC reader widget:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/testing.dart';

void main() {
  group('NfcReaderWidget', () {
    late FakeNfcWalletSuppression fake;

    setUp(() {
      fake = FakeNfcWalletSuppression();
      NfcWalletSuppressionPlatform.instance = fake;
    });

    test('starts NFC reading with suppression', () async {
      // Your widget code here
      await startNfcReading();

      // Verify suppression was requested
      expect(fake.methodCalls, contains('requestSuppression'));
    });

    test('handles unsupported device gracefully', () async {
      fake.supported = false;
      fake.requestResult =
          const SuppressionResult(status: SuppressionStatus.notSupported);

      await startNfcReading();

      // Verify your error handling
      expect(errorShown, 'NFC not supported');
    });

    test('handles NFC disabled', () async {
      fake.requestResult =
          const SuppressionResult(status: SuppressionStatus.nfcDisabled);

      await startNfcReading();

      // Verify appropriate message shown
      expect(messageShown, 'Please enable NFC');
    });

    test('releases suppression when done', () async {
      await startNfcReading();
      await stopNfcReading();

      // Verify suppression was released
      expect(fake.methodCalls, contains('releaseSuppression'));
    });
  });
}
```

## Widget Testing

For widget tests, set up the fake in `setUp()`:

```dart
testWidgets('my widget test', (WidgetTester tester) async {
  NfcWalletSuppressionPlatform.instance = FakeNfcWalletSuppression();

  await tester.pumpWidget(MyApp());
  
  // Your test code...
});
```

## Integration Testing

For integration tests on real devices, you don't need the fake. The plugin will use the real platform implementation:

```dart
// integration_test/nfc_test.dart
import 'package:integration_test/integration_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real NFC suppression test', (WidgetTester tester) async {
    // No fake needed - uses real platform
    final supported = await NfcWalletSuppression.isSupported();
    
    if (supported) {
      final result = await NfcWalletSuppression.requestSuppression();
      expect(result, isA<SuppressionResult>());
    }
  });
}
```

## Best Practices

1. **Always use `setUp()` to initialize the fake** - Ensures clean state for each test
2. **Use test scenarios for common cases** - More readable than manual configuration
3. **Verify method calls when testing state changes** - Ensures your code calls the plugin correctly
4. **Reset between tests if reusing a fake** - Prevents test pollution
5. **Use real integration tests for device validation** - Complements unit tests

## Running Tests

### Unit Tests (Dart)

Run all Dart unit tests:

```bash
flutter test
```

Run with coverage:

```bash
flutter test --coverage
```

Run a specific test file:

```bash
flutter test test/nfc_wallet_suppression_test.dart
```

### Native Tests

For the Android (JUnit) and iOS (XCTest) tests, use the commands CI runs: see
"Run locally" under each platform in [docs/NATIVE_COVERAGE.md](docs/NATIVE_COVERAGE.md).

### Integration Tests

Run integration tests on a connected device or simulator:

```bash
cd example
flutter test integration_test/
```

Run comprehensive integration tests:

```bash
cd example
flutter test integration_test/comprehensive_integration_test.dart
```

## Test Coverage

All hand-written Dart files in `lib/` have **100% line coverage**. Generated files
(`*.g.*`, such as pigeon's `messages.g.dart`) are excluded from coverage (see `codecov.yml`).

To view detailed coverage:

```bash
flutter test --coverage
# Install lcov if needed: brew install lcov (macOS)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## See Also

- [Example test file](test/nfc_wallet_suppression_testing_test.dart) - Complete examples
- [Main README](README.md) - Plugin usage documentation
- [API Documentation](https://pub.dev/documentation/nfc_wallet_suppression/latest/)
