# Flutter NFC Wallet Suppression Plugin

This lightweight Flutter plugin provides a way to temporarily suppress the automatic presentation of
payment apps. This is particularly useful in scenarios where you want to prevent the Wallet app from
automatically appearing when the user is near an NFC reader.

## Key Features

* **iOS (PassKit):**
    * **NFC Wallet Suppression:** Temporarily prevent the automatic display of passes from the Apple
      Wallet app when the user is near an NFC reader.
    * **Suppression Control:** Request and release NFC wallet suppression programmatically.
    * **Suppression Status:** Check if NFC wallet suppression is currently active.
* **Android (NFC Adapter):**
    * **NFC Wallet Suppression:** Temporarily prevent payment apps from automatically appearing when
      the user's device is near an NFC reader.
    * **Suppression Control:** Request and release NFC wallet suppression programmatically.
    * **Suppression Status:** Check if NFC wallet suppression is currently active.

---

## How to install

```sh
flutter pub add nfc_wallet_suppression
```

---

## Prerequisites

This plugins needs permissions on android and a bit more on ios to work.

### Android

For Android the only thing you need is the following permission, these permissions is already added
in the plugins AndroidManifest.xml file.

#### NFC Permission (if you need it)

```xml

<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- You need to add following permissions to your AndroidManifest.xml file -->
    <uses-permission android:name="android.permission.NFC" />
    <uses-feature android:name="android.hardware.nfc" android:required="false" />
</manifest>
```

### iOS

For iOS it is a bit more complicated. You need to have the entitlement
`com.apple.developer.passkit.pass-presentation-suppression` but before you can use it you need
special permission from Apple and the only way to get it is to contact
apple-pay-inquiries@apple.com. Then update the app id and provisioning profiles AppleDeveloper
portal before you can use the entitlement in the app.

#### Apple Developer Portal

After you have the permission from Apple you will find
`com.apple.developer.passkit.pass-presentation-suppression` under **Additional Capabilities** in the
Apple Developer portal for you App Identifier. Then you need to update your provisioning profiles to
get this entitlement added (it will be added automatically when editing)

#### Apple Pay Pass Presentation Suppression Entitlement

Use this entitlement to keep your app in the foreground when operating near NFC or other RF readers.
This entitlement enables the requestAutomaticPassPresentationSuppressionWithResponseHandler: method.

In the entitlement’s file, add the `com.apple.developer.passkit.pass-presentation-suppression` key
with a Boolean value of `YES`. You need special permission from Apple to submit apps with this key
enabled. For more information, contact apple-pay-inquiries@apple.com.

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

## How to use

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

## Use Cases

* **Loyalty Programs:** Prevent payment apps from interfering with your app's own loyalty card
  functionality when using NFC.
* **Event Ticketing:** Ensure that your app is the primary interface for event ticket interactions
  using NFC.
* **Access Control:** Manage NFC-based access control systems without payment apps automatically
  taking over.
* **Custom NFC Interactions:** Build unique NFC experiences without payment apps automatically
  taking over.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.