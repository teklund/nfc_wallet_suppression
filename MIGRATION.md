# Migration Guide

This guide helps you migrate between major versions of the `nfc_wallet_suppression` plugin.

---

## Migrating from 0.1.x to 1.0.0

### Overview

Version 1.0.0 is the first production-ready release with improved stability, comprehensive testing, and enhanced documentation. The public API remains **fully backward compatible** - no code changes are required for most users.

### What's New

#### ✅ Improved Stability

- Fixed iOS token management race conditions
- Fixed Android state persistence across configuration changes
- Enhanced error handling across all platforms

#### ✅ New Features

- `isSupported()` method to check platform capability before use
- Comprehensive error status reporting via `SuppressionStatus` enum
- Better logging with `dart:developer` for debugging

#### ✅ Enhanced Documentation

- Complete API documentation with examples
- Platform-specific notes and limitations
- Privacy manifest documentation for iOS

#### ✅ Production Ready

- CI/CD pipeline with automated testing
- Native platform tests (iOS XCTest, Android JUnit)
- Comprehensive integration tests
- Security and privacy review

### Breaking Changes

#### For Plugin Users (Public API)

**None!** The public API is fully compatible.

```dart
// This code works in both 0.1.x and 1.0.0
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

final plugin = NfcWalletSuppression();

// All methods work the same
final status = await plugin.requestSuppression();
await plugin.releaseSuppression();
final suppressed = await plugin.isSuppressed();
```

#### For Advanced Users (Internal API)

If you were directly importing internal implementation files, these are no longer exported:

```dart
// ❌ No longer works in 1.0.0
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_method_channel.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_platform_interface.dart';

// ✅ Use the public API instead
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
```

**Migration:** Use the public `NfcWalletSuppression` class instead of internal implementation classes.

### New Recommended Practices

#### 1. Check Platform Support Before Use

```dart
// ✅ New in 1.0.0 - Check support first
final plugin = NfcWalletSuppression();

if (await plugin.isSupported()) {
  final status = await plugin.requestSuppression();
  if (status == SuppressionStatus.suppressed) {
    // Success
  }
} else {
  // Handle unsupported platform
  print('NFC suppression not supported on this device');
}
```

#### 2. Handle All Status Codes

```dart
// ✅ Handle specific status codes for better UX
final status = await plugin.requestSuppression();

switch (status) {
  case SuppressionStatus.suppressed:
    print('Suppression active');
  case SuppressionStatus.notSupported:
    print('Device does not support NFC suppression');
  case SuppressionStatus.alreadyPresenting:
    print('Cannot suppress - wallet already presenting');
  case SuppressionStatus.denied:
    print('User denied suppression request');
  case SuppressionStatus.unavailable:
    print('NFC not available');
  default:
    print('Unknown status: $status');
}
```

#### 3. Always Release Suppression

```dart
// ✅ Use try-finally to ensure cleanup
final plugin = NfcWalletSuppression();

try {
  await plugin.requestSuppression();
  // Your NFC operations here
} finally {
  await plugin.releaseSuppression();
}
```

### iOS Privacy Requirements

Version 1.0.0 includes a privacy manifest (`PrivacyInfo.xcprivacy`) that declares:

- No data collection
- No tracking
- Required reason API usage (UserDefaults for state persistence)

**Action Required:** If you submit to the App Store, review the [Privacy Manifest section](README.md#ios-privacy-manifest) in the README.

### Android Permissions

No changes to permissions. Continue using:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

### Testing Changes

If you have custom tests that mock the plugin:

```dart
// ✅ Use the testing utilities
import 'package:nfc_wallet_suppression/testing.dart';

void main() {
  testWidgets('test suppression', (tester) async {
    NfcWalletSuppression.setMockInstance(MockNfcWalletSuppression());

    final plugin = NfcWalletSuppression();
    final status = await plugin.requestSuppression();

    expect(status, SuppressionStatus.suppressed);
  });
}
```

### Minimum Requirements

No changes to minimum requirements:

- **Flutter:** `>=3.22.0`
- **Dart:** `>=3.4.0`
- **iOS:** `>=16.0`
- **Android:** API level 19+ (Android 4.4 KitKat)

### Update Steps

1. **Update pubspec.yaml:**

   ```yaml
   dependencies:
     nfc_wallet_suppression: ^1.0.0
   ```

2. **Run pub get:**

   ```bash
   flutter pub get
   ```

3. **Test your app:**

   ```bash
   flutter test
   ```

4. **Optional - Add platform support check:**

   ```dart
   if (await plugin.isSupported()) {
     // Your existing code
   }
   ```

5. **Optional - Improve error handling:**
   Review your error handling to use specific `SuppressionStatus` values instead of generic error handling.

### Troubleshooting

#### Issue: Imports no longer work

**Problem:**

```dart
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_method_channel.dart';
```

**Solution:**

```dart
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
```

#### Issue: Tests failing after upgrade

**Problem:** Custom mocks not working.

**Solution:** Use the provided testing utilities:

```dart
import 'package:nfc_wallet_suppression/testing.dart';
```

### Getting Help

- **Issues:** [GitHub Issues](https://github.com/teklund/nfc_wallet_suppression/issues)
- **Discussions:** [GitHub Discussions](https://github.com/teklund/nfc_wallet_suppression/discussions)
- **Email:** Create an issue on GitHub

### Changelog

For a complete list of changes, see [CHANGELOG.md](CHANGELOG.md).

---

## Future Migrations

### Upcoming in 2.0.0 (Planned)

Future breaking changes may include:

- Migration to Pigeon for type-safe platform channels
- Additional platform support (macOS, Windows)
- Enhanced callback APIs for suppression state changes

We will provide detailed migration guides for all breaking changes.

---

## Need Help?

If you encounter issues during migration:

1. Check the [README](README.md) for updated examples
2. Review [CHANGELOG.md](CHANGELOG.md) for detailed changes
3. Search [existing issues](https://github.com/teklund/nfc_wallet_suppression/issues)
4. Open a new issue with:
   - Your current version
   - Target version
   - Error messages
   - Minimal reproduction code

---

**Last Updated:** January 20, 2026
