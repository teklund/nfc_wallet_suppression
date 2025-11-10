# Flutter NFC Wallet Suppression Plugin

[![pub package](https://img.shields.io/pub/v/nfc_wallet_suppression.svg)](https://pub.dev/packages/nfc_wallet_suppression)
[![Pub Points](https://img.shields.io/pub/points/nfc_wallet_suppression?color=2E8B57&logo=dart)](https://pub.dev/packages/nfc_wallet_suppression/score)
[![Popularity](https://img.shields.io/pub/popularity/nfc_wallet_suppression?logo=dart)](https://pub.dev/packages/nfc_wallet_suppression/score)
[![GitHub stars](https://img.shields.io/github/stars/teklund/nfc_wallet_suppression.svg?style=social)](https://github.com/teklund/nfc_wallet_suppression)
[![Flutter Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Supported Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20Android-blue.svg)](https://flutter.dev)

This lightweight Flutter plugin provides a way to temporarily suppress the automatic presentation of
payment apps. This is particularly useful in scenarios where you want to prevent the Wallet app from
automatically appearing when the user is near an NFC reader.

## 📋 Table of Contents

- [Status](#status)
- [Key Features](#key-features)
- [Installation](#installation)
- [Prerequisites](#prerequisites)
- [API Usage](#api-usage)
- [Platform Support & Limitations](#platform-support--limitations)
- [How It Works](#how-it-works)
- [Use Cases](#use-cases)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Resources](#resources)
- [License](#license)

---

## Status

[![Pull Request](https://github.com/teklund/nfc_wallet_suppression/workflows/Pull%20Request/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/pull_request.yml)
[![Platform Builds](https://github.com/teklund/nfc_wallet_suppression/workflows/Platform%20Builds/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/platform_builds.yml)
[![Integration Tests](https://github.com/teklund/nfc_wallet_suppression/workflows/Integration%20Tests/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/integration_tests.yml)
[![SDK Compatibility Check](https://github.com/teklund/nfc_wallet_suppression/workflows/SDK%20Compatibility%20Check/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/sdk_compatibility.yml)
[![codecov](https://codecov.io/gh/teklund/nfc_wallet_suppression/branch/main/graph/badge.svg)](https://codecov.io/gh/teklund/nfc_wallet_suppression)

---

## Key Features

- **iOS (PassKit):**
  - **NFC Wallet Suppression:** Temporarily prevent the automatic display of passes from the Apple
      Wallet app when the user is near an NFC reader.
  - **Suppression Control:** Request and release NFC wallet suppression programmatically.
  - **Suppression Status:** Check if NFC wallet suppression is currently active.
- **Android (NFC Adapter):**
  - **NFC Wallet Suppression:** Temporarily prevent payment apps from automatically appearing when
      the user's device is near an NFC reader.
  - **Suppression Control:** Request and release NFC wallet suppression programmatically.
  - **Suppression Status:** Check if NFC wallet suppression is currently active.

---

## Installation

```sh
flutter pub add nfc_wallet_suppression
```

---

## Prerequisites

This plugin requires platform-specific setup on iOS. Android setup is automatic.

### Android

NFC permission is automatically included when you add this plugin. No additional configuration needed.

### iOS

For iOS it is a bit more complicated. You need to have the entitlement
`com.apple.developer.passkit.pass-presentation-suppression` but before you can use it you need
special permission from Apple and the only way to get it is to contact
[`apple-pay-inquiries@apple.com`](mailto:apple-pay-inquiries@apple.com). Then update the app id and provisioning profiles AppleDeveloper
portal before you can use the entitlement in the app.

#### Apple Developer Portal

After you have the permission from Apple you will find
`com.apple.developer.passkit.pass-presentation-suppression` under **Additional Capabilities** in the
Apple Developer portal for you App Identifier. Then you need to update your provisioning profiles to
get this entitlement added (it will be added automatically when editing)

#### Apple Pay Pass Presentation Suppression Entitlement

Use this entitlement to keep your app in the foreground when operating near NFC or other RF readers.
This entitlement enables the requestAutomaticPassPresentationSuppressionWithResponseHandler: method.

In the entitlement's file, add the `com.apple.developer.passkit.pass-presentation-suppression` key
with a Boolean value of `YES`. You need special permission from Apple to submit apps with this key
enabled. For more information, contact [`apple-pay-inquiries@apple.com`](mailto:apple-pay-inquiries@apple.com).

```xml
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <!-- You need to add following permissions to your Entitlements file -->
        <key>com.apple.developer.passkit.pass-presentation-suppression</key>
        <true />
    </dict>
</plist>
```

---

## API Usage

### Quick Example

```dart
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

// Request NFC wallet suppression
try {
  SuppressionStatus status = await NfcWalletSuppression.requestSuppression();
  print('NFC wallet suppression request status: $status');
} catch(error) {
  print('Error requesting NFC wallet suppression: $error');
}

// Release NFC wallet suppression
try {
  SuppressionStatus status = await NfcWalletSuppression.releaseSuppression();
  print('NFC wallet suppression release status: $status');
} catch (e) {
  print('Error releasing NFC wallet suppression: $e');
}

// Check if NFC wallet is suppressed
try {
  bool isSuppressed = await NfcWalletSuppression.isSuppressed();
  print('Is NFC wallet suppressed? $isSuppressed');
} catch (e) {
  print('Error checking NFC wallet suppression status: $e');
}
```

### API Methods

- **`requestSuppression()`** - Request NFC wallet suppression
  - Returns: `Future<SuppressionStatus>`
  - Throws: Exception if suppression cannot be requested

- **`releaseSuppression()`** - Release NFC wallet suppression
  - Returns: `Future<SuppressionStatus>`
  - Throws: Exception if suppression cannot be released

- **`isSuppressed()`** - Check if suppression is active
  - Returns: `Future<bool>`
  - Throws: Exception if status cannot be determined

---

## Platform Support & Limitations

⚠️ **Important Notes:**

- **iOS**: Requires special entitlement from Apple. Contact [`apple-pay-inquiries@apple.com`](mailto:apple-pay-inquiries@apple.com) to request the `com.apple.developer.passkit.pass-presentation-suppression` entitlement.
- **iOS**: Suppression is temporary and tied to app lifecycle. It will be automatically released when your app goes to background.
- **Android**: Requires app to have NFC permission and to be in foreground.
- **Android**: Suppression ends when your app is closed or suppression is explicitly released.
- Suppression is **not** a guarantee - system behavior may vary based on device and OS version.

## How It Works

This plugin uses platform-specific APIs to achieve NFC wallet suppression:

### iOS (PassKit)

On iOS, the plugin leverages Apple's **PassKit framework** to control the automatic presentation of
passes.

1. **Requesting Suppression:** When you call `requestSuppression()` from your Flutter app, the
   plugin uses `PKPassLibrary.requestAutomaticPassPresentationSuppression(responseHandler:)` to
   request a temporary suppression of automatic pass presentation.
2. **Suppression Token:** If the request is successful, PassKit returns a
   `PKSuppressionRequestToken`. The plugin stores this token to maintain the suppression.
3. **NFC Wallet Suppressed:** While the suppression token is held, the Apple Wallet app will *not*
   automatically display passes when the user is near an NFC reader. This gives your app the
   opportunity to handle the NFC interaction instead.
4. **Releasing Suppression:** When you call `releaseSuppression()`, the plugin uses
   `PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken:)` and provides the
   stored token. This tells PassKit to release the suppression, and the Wallet app will resume its
   normal behavior.
5. **Check Suppression Status**: The plugin uses
   `PKPassLibrary.isSuppressingAutomaticPassPresentation()` to check if the pass presentation is
   currently suppressed.

### Android (NFC Adapter)

On Android, the plugin uses the **NFC Adapter** to manage NFC interactions.

1. **Requesting Suppression:** When you call `requestSuppression()` from your Flutter app, the
   plugin uses `NfcAdapter.enableForegroundDispatch()` to gain priority over other NFC-listening
   apps. This effectively suppresses the automatic launch of payment apps when an NFC tag is
   detected.
2. **Suppression Active:** While suppression is active, payment apps will not automatically appear
   when the user is near an NFC reader. Your app will have the opportunity to handle the NFC
   interaction instead.
3. **Releasing Suppression:** When you call `releaseSuppression()`, the plugin uses
   `NfcAdapter.disableForegroundDispatch()` to release the suppression. This allows other
   NFC-listening apps, including payment apps, to resume their normal behavior.
4. **Checking Suppression Status:** The `isSuppressed()` method checks if the suppression is
   currently active.

## Troubleshooting

### iOS Issues

#### Entitlement not found error

You need special permission from Apple. Contact [`apple-pay-inquiries@apple.com`](mailto:apple-pay-inquiries@apple.com) and request the entitlement.

#### Suppression doesn't work on device

Ensure you've added the entitlement to your provisioning profile and it's loaded on the device.

#### Works in simulator but not on real device

The entitlement is required on real devices. Simulators may have different behavior.

### Android Issues

#### NFC not available error

Ensure your device has NFC hardware and NFC is enabled in settings.

#### Suppression doesn't work

Ensure your app has NFC permission and is in the foreground (not backgrounded).

### General Issues

#### Why do I need to handle exceptions?

Platform availability, permissions, and state can change. Always wrap calls in try-catch.

#### How long does suppression last?

On iOS: Until your app releases it or goes to background. On Android: Until your app releases it or is closed.

---

## Use Cases

- **Loyalty Programs:** Prevent payment apps from interfering with your app's own loyalty card functionality when using NFC.
- **Event Ticketing:** Ensure that your app is the primary interface for event ticket interactions using NFC.
- **Access Control:** Manage NFC-based access control systems without payment apps automatically taking over.
- **Custom NFC Interactions:** Build unique NFC experiences without payment apps automatically taking over.

---

## Contributing

For guidelines on contributing, see [CONTRIBUTING.md](CONTRIBUTING.md).

Contributions are welcome! Please feel free to submit pull requests or open issues on [GitHub](https://github.com/teklund/nfc_wallet_suppression).

## Resources

- 📖 [API Documentation](https://pub.dev/documentation/nfc_wallet_suppression/latest/)
- 🐛 [Report Issues](https://github.com/teklund/nfc_wallet_suppression/issues)
- 📝 [CHANGELOG](CHANGELOG.md)
- 🤝 [Contributing Guide](CONTRIBUTING.md)
- ⚖️ [License](LICENSE)

---

## License

MIT License - See [LICENSE](LICENSE) for details.
