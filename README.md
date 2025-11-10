# Flutter NFC Wallet Suppression Plugin

[![pub package](https://img.shields.io/pub/v/nfc_wallet_suppression.svg)](https://pub.dev/packages/nfc_wallet_suppression)
[![Pub Points](https://img.shields.io/pub/points/nfc_wallet_suppression?color=2E8B57&logo=dart)](https://pub.dev/packages/nfc_wallet_suppression/score)
[![Flutter Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![Supported Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20Android-blue.svg)](https://flutter.dev)

A lightweight Flutter plugin that **suppresses NFC wallet presentation** — preventing Apple Wallet, Google Wallet, and other payment apps from automatically popping up when your NFC-enabled device detects contactless payment terminals or NFC tags.

**🎯 Problem This Solves:** When users with NFC-enabled phones (iPhone 7+, most modern Android devices) approach an NFC reader while your app is open, the system automatically shows wallet/payment apps. This plugin gives your app exclusive control over NFC interactions instead.

**⚠️ Important Notes:**

- **Only needed for NFC-enabled devices** - Phones without NFC hardware don't have this issue
- **Suppression only** - This plugin does NOT read or write NFC tags
- **Best for:** Loyalty cards, ticketing, access control, and custom NFC experiences

## 📋 Table of Contents

- [Key Features](#key-features)
- [Installation](#installation)
- [Platform Setup](#platform-setup)
- [API Usage](#api-usage)
- [Troubleshooting](#troubleshooting)
- [Example App](#example-app)
- [Contributing](#contributing)
- [License](#license)

---

## Key Features

- ✅ **Suppress NFC wallet presentation** - Stop Apple Wallet/Google Wallet from auto-appearing on NFC-enabled devices
- ✅ **Simple API** - Three methods: request, release, and check suppression status
- ✅ **Cross-platform** - Works on both iOS (PassKit) and Android (NFC Adapter)
- ✅ **Lifecycle-aware** - Automatic cleanup when app backgrounds
- ✅ **Type-safe status** - Detailed status enum for handling different scenarios

---

## Build Status

[![Pull Request](https://github.com/teklund/nfc_wallet_suppression/workflows/Pull%20Request/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/pull_request.yml)
[![Platform Builds](https://github.com/teklund/nfc_wallet_suppression/workflows/Platform%20Builds/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/platform_builds.yml)
[![Integration Tests](https://github.com/teklund/nfc_wallet_suppression/workflows/Integration%20Tests/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/integration_tests.yml)
[![SDK Compatibility Check](https://github.com/teklund/nfc_wallet_suppression/workflows/SDK%20Compatibility%20Check/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/sdk_compatibility.yml)
[![codecov](https://codecov.io/gh/teklund/nfc_wallet_suppression/graph/badge.svg?token=JRPE6FQF2T)](https://codecov.io/gh/teklund/nfc_wallet_suppression)

---

## Installation

```sh
flutter pub add nfc_wallet_suppression
```

---

## Platform Setup

### Android

**Minimum:** Android 5.0+ (API 21)

**Setup:** None required! NFC permission is automatically added. App must be in foreground when requesting suppression.

**Note:** Only suppresses wallet on devices with NFC hardware. Non-NFC devices don't need suppression.

### iOS

**Minimum:** iOS 12.0+ / iPhone 7+

**Note:** Only suppresses wallet on devices with NFC hardware (iPhone 7+). Older iPhones without NFC don't need suppression.

**Setup Required:**

1. **Request Apple Entitlement**
   - Email <apple-pay-inquiries@apple.com>
   - Request `com.apple.developer.passkit.pass-presentation-suppression`
   - Explain your use case (may take several days for approval)

2. **Configure Developer Portal**
   - Enable `Pass Presentation Suppression` in your App ID
   - Regenerate provisioning profiles

3. **Add Entitlement File** (`ios/Runner/Runner.entitlements`):

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.developer.passkit.pass-presentation-suppression</key>
       <true/>
   </dict>
   </plist>
   ```

⚠️ Without the approved entitlement, calls will fail on real iOS devices.

---

## API Usage

### Quick Example

```dart
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

// Request NFC wallet suppression
try {
  SuppressionStatus status = await NfcWalletSuppression.requestSuppression();
  
  if (status == SuppressionStatus.suppressed) {
    print('✓ Suppression active - you can now handle NFC interactions');
  } else {
    print('⚠ Suppression status: ${status.name}');
  }
} catch (error) {
  print('Error requesting NFC wallet suppression: $error');
}

// Check if NFC wallet is currently suppressed
try {
  bool isSuppressed = await NfcWalletSuppression.isSuppressed();
  print('Is NFC wallet suppressed? $isSuppressed');
} catch (e) {
  print('Error checking suppression status: $e');
}

// Release NFC wallet suppression when done
try {
  SuppressionStatus status = await NfcWalletSuppression.releaseSuppression();
  print('Suppression released: ${status.name}');
} catch (e) {
  print('Error releasing NFC wallet suppression: $e');
}
```

### API Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `requestSuppression()` | `Future<SuppressionStatus>` | Request wallet suppression |
| `releaseSuppression()` | `Future<SuppressionStatus>` | Release suppression |
| `isSuppressed()` | `Future<bool>` | Check if currently suppressed |

### SuppressionStatus Values

The `SuppressionStatus` enum represents the result of suppression operations:

| Status | Description |
|--------|-------------|
| `suppressed` | Suppression is successfully active |
| `notSuppressed` | Suppression is not active |
| `unavailable` | Suppression feature is unavailable on this device |
| `denied` | Suppression request was denied (missing entitlements or permissions) |
| `cancelled` | Suppression was cancelled by the system |
| `notSupported` | The platform doesn't support this feature |
| `alreadyPresenting` | Wallet is already presenting (iOS-specific) |
| `unknown` | Status could not be determined |

**Important Notes:**

- ✅ Only affects NFC-enabled devices (iPhone 7+, most modern Android phones)
- ✅ Auto-releases when app backgrounds or closes
- ❌ Does NOT read/write NFC tags
- ❌ Does NOT persist across app restarts
- ⚠️ Best-effort (not guaranteed on all devices due to manufacturer customizations)

## Troubleshooting

**Common Issues:**

| Issue | Platform | Solution |
|-------|----------|----------|
| Entitlement not found | iOS | Ensure Apple approved the entitlement and it's in your provisioning profile |
| NFC not available | Android | Enable NFC in device settings |
| Auto-released | Both | Use `WidgetsBindingObserver` to re-request on app resume |
| Doesn't work on device | iOS | Test on physical iPhone 7+, verify entitlement in Xcode |
| Payment apps still appear | Android | Some manufacturers override behavior, test on multiple devices |

**FAQ:**

- **Does this read NFC tags?** No, it only suppresses wallet presentation.
- **How long does suppression last?** Until released or app backgrounds.
- **Works in simulator?** Limited - always test on physical devices with NFC.

---

## Example App

See the [`example/`](https://github.com/teklund/nfc_wallet_suppression/tree/main/example) directory for a complete working example with lifecycle management and error handling.

```bash
cd example && flutter run
```

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Additional Resources

📖 [API Docs](https://pub.dev/documentation/nfc_wallet_suppression/latest/) •  [Report Issues](https://github.com/teklund/nfc_wallet_suppression/issues) • 📝 [CHANGELOG](CHANGELOG.md) • [Apple PassKit](https://developer.apple.com/documentation/passkit) • [Android NFC](https://developer.android.com/guide/topics/connectivity/nfc)

---

## License

BSD 3-Clause License - See [LICENSE](LICENSE) for details.
