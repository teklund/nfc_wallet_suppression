# Testing Guide

This guide shows how to test your app when using the `nfc_wallet_suppression` plugin.

## Quick Start

Import the testing utilities in your test files:

```dart
import 'package:nfc_wallet_suppression/testing.dart';
```

## Using FakeNfcWalletSuppression

The `FakeNfcWalletSuppression` class provides a controllable fake implementation for testing:

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
    // Configure the fake behavior
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.suppressed);
    
    // Use the plugin normally in your test
    final result = await NfcWalletSuppression.requestSuppression();
    
    expect(result, SuppressionStatus.suppressed);
  });
}
```

## Configuration Methods

Control the fake's behavior with these methods:

### `setSupported(bool supported)`

Set whether NFC is supported on the device.

```dart
fake.setSupported(true);  // Simulate device with NFC
fake.setSupported(false); // Simulate device without NFC
```

### `setRequestResult(SuppressionStatus result)`

Set what `requestSuppression()` will return.

```dart
fake.setRequestResult(SuppressionStatus.suppressed);
fake.setRequestResult(SuppressionStatus.unavailable);
fake.setRequestResult(SuppressionStatus.denied);
```

### `setReleaseResult(SuppressionStatus result)`

Set what `releaseSuppression()` will return.

```dart
fake.setReleaseResult(SuppressionStatus.notSuppressed);
```

### `setSuppressed(bool suppressed)`

Manually set the suppressed state (simulates external changes).

```dart
fake.setSuppressed(true);  // Simulate suppression becoming active
fake.setSuppressed(false); // Simulate suppression becoming inactive
```

### `reset()`

Clear all state and call history.

```dart
fake.reset(); // Start fresh
```

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

Use pre-configured scenarios for common test cases:

### Supported Device

```dart
final fake = NfcWalletSuppressionTestScenarios.supportedDevice();
NfcWalletSuppressionPlatform.instance = fake;

// Device has NFC and suppression works normally
```

### Unsupported Device

```dart
final fake = NfcWalletSuppressionTestScenarios.unsupportedDevice();
NfcWalletSuppressionPlatform.instance = fake;

// Device does not have NFC hardware
```

### NFC Unavailable

```dart
final fake = NfcWalletSuppressionTestScenarios.nfcUnavailable();
NfcWalletSuppressionPlatform.instance = fake;

// Device has NFC but it's disabled or unavailable
```

### User Denied (iOS)

```dart
final fake = NfcWalletSuppressionTestScenarios.userDenied();
NfcWalletSuppressionPlatform.instance = fake;

// User denied permission to suppress wallet
```

### Already Presenting (iOS)

```dart
final fake = NfcWalletSuppressionTestScenarios.alreadyPresenting();
NfcWalletSuppressionPlatform.instance = fake;

// System is already presenting passes
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
      fake.setSupported(true);
      fake.setRequestResult(SuppressionStatus.suppressed);

      // Your widget code here
      await startNfcReading();

      // Verify suppression was requested
      expect(fake.methodCalls, contains('requestSuppression'));
    });

    test('handles unsupported device gracefully', () async {
      final fake = NfcWalletSuppressionTestScenarios.unsupportedDevice();
      NfcWalletSuppressionPlatform.instance = fake;

      await startNfcReading();

      // Verify your error handling
      expect(errorShown, 'NFC not supported');
    });

    test('handles NFC disabled', () async {
      fake.setSupported(true);
      fake.setRequestResult(SuppressionStatus.unavailable);

      await startNfcReading();

      // Verify appropriate message shown
      expect(messageShown, 'Please enable NFC');
    });

    test('releases suppression when done', () async {
      fake.setSupported(true);

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
  final fake = FakeNfcWalletSuppression();
  NfcWalletSuppressionPlatform.instance = fake;
  fake.setSupported(true);

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
      expect(result, isA<SuppressionStatus>());
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

## See Also

- [Example test file](../test/nfc_wallet_suppression_testing_test.dart) - Complete examples
- [Main README](../README.md) - Plugin usage documentation
- [API Documentation](https://pub.dev/documentation/nfc_wallet_suppression/latest/)
