# nfc_wallet_suppression

[![pub package](https://img.shields.io/pub/v/nfc_wallet_suppression.svg)](https://pub.dev/packages/nfc_wallet_suppression)
[![Pub Points](https://img.shields.io/pub/points/nfc_wallet_suppression?color=2E8B57&logo=dart)](https://pub.dev/packages/nfc_wallet_suppression/score)
[![CI](https://github.com/teklund/nfc_wallet_suppression/workflows/CI/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/teklund/nfc_wallet_suppression/graph/badge.svg?token=JRPE6FQF2T)](https://codecov.io/gh/teklund/nfc_wallet_suppression)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/teklund/nfc_wallet_suppression/badge)](https://securityscorecards.dev/viewer/?uri=github.com/teklund/nfc_wallet_suppression)

Keeps Apple Wallet (Apple Pay) and other wallet apps from popping up at NFC
readers while your app is in the foreground.

Near a contactless payment terminal or NFC reader, the phone offers its wallet.
That gets in the way when your app is the one the user should be looking at,
for example while it shows a ticket or loyalty barcode at a gate that also has
an NFC reader.

- **iOS:** asks PassKit to suppress automatic Wallet presentation.
- **Android:** puts NFC into reader mode, which turns off card emulation, so
  wallet apps can't respond to readers.
- **Web and desktop:** calls do nothing; a request returns `notSupported`.

Suppression applies only while your app is in the foreground. It pauses in the
background and resumes when the app returns. The plugin only suppresses the
wallet; it does not read or write NFC tags.

## Contents

- [Installation](#installation)
- [Platform Setup](#platform-setup)
- [API Usage](#api-usage)
- [Migrating from 0.1.x](#migrating-from-01x)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Example App](#example-app)
- [Privacy](#privacy)
- [Contributing](#contributing)
- [Additional Resources](#additional-resources)
- [License](#license)

## Installation

```sh
flutter pub add nfc_wallet_suppression
```

## Platform Setup

### Android

**Minimum:** Android 7.0+ (API 24), the same as Flutter 3.44 requires. Newer
Flutter versions may require more.

**Setup:** none. The plugin adds the `NFC` permission and declares NFC hardware
optional, so your app still installs on devices without NFC.

### iOS

**Minimum:** iOS 13.0+ (this plugin's floor; the PassKit suppression API is available from iOS 9.0+)

Your app's actual minimum is whichever is higher — this plugin's floor or the one your Flutter version requires. Flutter 3.47, for example, requires iOS 15.0.

**Note:** Every iPhone that runs iOS 13 or later has the NFC hardware this needs. iPad and iPod touch have none, so there is nothing to suppress on them.

**Setup:** suppression needs an entitlement that Apple grants per App ID, on request.

1. **Request the entitlement.** Email <apple-pay-inquiries@apple.com> for
   `com.apple.developer.passkit.pass-presentation-suppression`, naming your
   App ID and explaining why your app needs it.
2. **Get it into your provisioning profile.** Follow Apple's approval email.
   Depending on how it is granted, it appears on your App ID's Additional
   Capabilities tab, or as an Additional Entitlements step when you create a
   provisioning profile manually.
3. **Add it to your app.** If the Runner target has no entitlements file yet,
   create `ios/Runner/Runner.entitlements`, and in Xcode set the target's
   **Code Signing Entitlements** (`CODE_SIGN_ENTITLEMENTS`) to
   `Runner/Runner.entitlements` for Debug, Release and Profile. Then add the key:

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

Without the entitlement, `requestSuppression()` returns `denied`.

## API Usage

Request suppression when the screen that needs it appears, not when the user
reaches the reader. On iOS, suppression is not active until the request
completes, and Apple documents that the first request after install shows a
one-time alert that Apple Pay is unavailable.

### Quick Example

```dart
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

final result = await NfcWalletSuppression.requestSuppression();

if (result.isSuppressed) {
  print('Wallet suppressed');
} else {
  // `description` is the platform's own diagnostic text. Log it; never parse it.
  print('Not suppressed: ${result.status.name} (${result.description})');
}

// Check whether suppression is active.
final isSuppressed = await NfcWalletSuppression.isSuppressed();
print('Suppressed: $isSuppressed');

// Release when done. Release is idempotent, so this is safe in a `finally`
// even if the request never succeeded.
await NfcWalletSuppression.releaseSuppression();
```

### Reacting to the status

```dart
final result = await NfcWalletSuppression.requestSuppression();

switch (result.status) {
  case SuppressionStatus.suppressed:
    break; // The wallet stays hidden at NFC readers.
  case SuppressionStatus.nfcDisabled:
    break; // Held: starts by itself once NFC is switched on.
  case SuppressionStatus.notSupported:
    showUnsupportedDeviceUi();
  default:
    if (result.isRetryable) {
      scheduleRetry();
    } else {
      reportProblem(result.description);
    }
}
```

### API Methods

| Method | Returns | Description |
| :--- | :--- | :--- |
| `requestSuppression()` | `Future<SuppressionResult>` | Request wallet suppression |
| `releaseSuppression()` | `Future<SuppressionResult>` | Release suppression |
| `isSuppressed()` | `Future<bool>` | Check if currently suppressed |
| `isSupported()` | `Future<bool>` | Whether suppression can be attempted: NFC hardware (Android) or the Wallet pass library (iOS). A request can still fail, for example in the Simulator or without the iOS entitlement. |

### SuppressionResult

Both suppression methods return a `SuppressionResult`:

| Member | Type | Description |
| :--- | :--- | :--- |
| `status` | `SuppressionStatus` | The machine-readable outcome. Branch on this. |
| `description` | `String?` | The platform's own account of what happened. Diagnostic only — the wording is not part of the API contract and may change. Never parse it. |
| `isSuppressed` | `bool` | `status == suppressed` |
| `isReleased` | `bool` | `status == notSuppressed` |
| `isRetryable` | `bool` | `status == unavailable` |

### SuppressionStatus Values

Not every value can come back from every method. New values may be added
without a major version bump, so **always include a `default` when switching.**

| Status | `request` | `release` | Description |
| :--- | :---: | :---: | :--- |
| `suppressed` | ✔ | | Suppression is held; [Lifetime](#lifetime) says when it is in effect |
| `notSuppressed` | | ✔ | Suppression is off — whether this call ended it or there was nothing to end |
| `nfcDisabled` | ✔ (Android) | | NFC is switched off in settings. The request is held and starts by itself once NFC is on. Wallet apps can't respond to readers while NFC is off either, so prompt the user (`android.settings.NFC_SETTINGS`) only if your app needs NFC itself. |
| `unavailable` | ✔ (Android) | | Transient and retryable — no Activity is attached to the Flutter engine, for example during a configuration change |
| `denied` | ✔ | ✔ (Android) | Refused — iOS: usually a missing entitlement; Android: a `SecurityException` on the NFC call |
| `canceled` | ✔ (iOS) | | The request was canceled before it completed |
| `notSupported` | ✔ | | Suppression isn't supported at all — Android: no NFC hardware; iOS: PassKit reports it unsupported |
| `alreadyPresenting` | ✔ (iOS) | | Wallet is already presenting a pass |
| `unknown` | ✔ | ✔ | Unexpected failure, or no answer in time. The operation may or may not have taken effect — call `isSuppressed()` if you need to know. |

On iOS, `releaseSuppression()` can only report `notSuppressed` in practice:
ending suppression cannot fail, so `unknown` is reachable only if the platform
channel itself does.

### Lifetime

Suppression lasts until you release it or the app is closed. It is not restored
on the next launch, so request it again then. A request that returns
`nfcDisabled` is held too. While it is held, it pauses in the background, and on
Android also while the Activity is paused, as behind the share sheet or a
permission dialog, and while NFC is switched off. It resumes by itself
afterwards. On Android, a tag reader or other code that uses reader mode on the
app's Activity can also leave it held but not in effect; see
[With NFC tag readers](#with-nfc-tag-readers-android).

### With NFC tag readers (Android)

Android keeps one reader mode per activity, so a tag reader such as
`nfc_manager` or `flutter_nfc_kit`, or any other code that uses reader mode on
the app's Activity, takes it over from this plugin. While the tag reader runs,
its own reader mode keeps the wallet away; when it stops, this plugin's
suppression is still held but not in effect. Hand over in order:

1. Release suppression just before starting the tag reader, so that
   `isSuppressed()` returns `false` until you request again.
2. Request suppression again as soon as the tag reader is done, however it
   ended, and after its stop call (such as `stopSession()` or `finish()`) has
   completed. A stop call made after the request clears reader mode again.

Don't request suppression while the tag reader runs: the request replaces its
reader mode, and reading stops.

## Migrating from 0.1.x

1.0.0 requires Flutter 3.44 or later (Dart 3.12).

`requestSuppression()` and `releaseSuppression()` return a `SuppressionResult`
instead of a bare `SuppressionStatus`:

```dart
// 0.1.x
final status = await NfcWalletSuppression.requestSuppression();
if (status == SuppressionStatus.suppressed) { /* ... */ }

// 1.0.0
final result = await NfcWalletSuppression.requestSuppression();
if (result.isSuppressed) { /* ... */ }
// or: result.status == SuppressionStatus.suppressed
```

**The compiler will not reliably catch this.** An explicit type annotation
(`SuppressionStatus status = await ...`) fails to compile, but a bare
comparison does not: comparing a `SuppressionResult` to a `SuppressionStatus`
is reported by `unrelated_type_equality_checks` as an *info*, not an error. Left
unchanged, such a condition simply evaluates to `false` forever.

When upgrading, search for `== SuppressionStatus.` and `!= SuppressionStatus.`
and check each one.

In tests, construct a result instead of mocking it. `SuppressionResult` is a
`final class`, so it can't be implemented, but its constructor is public:

```dart
const result = SuppressionResult(status: SuppressionStatus.suppressed);
```

Two status meanings also changed:

| Situation | 0.1.x | 1.0.0 |
| :--- | :--- | :--- |
| Release when nothing is suppressed | `unavailable` | `notSuppressed` — release is idempotent |
| Android, NFC switched off in settings | `unavailable`, nothing held | `nfcDisabled` — the request is held and starts once NFC is on |

`unavailable` now means only "transient, retry may work" — on Android, no
Activity attached.

The compiler flags the remaining changes:

- `SuppressionStatus.cancelled` is now `SuppressionStatus.canceled`.
- `SuppressionStatus.nfcDisabled` is new, so a `switch` that lists every
  status without a `default` no longer compiles. Add a `default`; more values
  may follow.
- Import `NfcWalletSuppressionPlatform` from
  `package:nfc_wallet_suppression/testing.dart`. `MethodChannelNfcWalletSuppression`
  is removed, and custom implementations and mocks return `SuppressionResult`
  from `requestSuppression()` and `releaseSuppression()`.

## Troubleshooting

| Symptom | Platform | Cause and fix |
| :--- | :--- | :--- |
| `requestSuppression()` returns `denied` | iOS | The app isn't signed with the entitlement. Check that Apple approved it for this App ID, that your provisioning profile includes it, and that `CODE_SIGN_ENTITLEMENTS` points to the file with the key. See [iOS setup](#ios). |
| Signing fails because the provisioning profile doesn't include the entitlement | iOS | The key is in your entitlements file but not in your profile, or Apple approved a different App ID. Regenerate the profile after approval, as in [iOS setup](#ios). |
| `requestSuppression()` returns `notSupported` in the iOS Simulator or an Android emulator | Both | Expected: the Simulator can't suppress Wallet (although `isSupported()` returns `true`), and emulators have no NFC hardware. Test on a device. |
| `requestSuppression()` returns `nfcDisabled` | Android | NFC is switched off. Nothing to fix: the request is held and starts once NFC is on. Ask the user to switch NFC on only if your app needs it. |
| Wallet appears while the app is in the background | Both | Expected: suppression only applies in the foreground, and resumes by itself when the app returns. |
| Wallet appears while the share sheet, a permission dialog, the camera app, a photo picker or a browser tab is over the app | Android | Expected: anything that opens over the app as its own Android activity pauses the app's Activity, which pauses suppression until the user returns. Screens and dialogs Flutter draws itself (routes, `showDialog`, bottom sheets) don't pause it. |
| Wallet appears again after another NFC feature ran | Android | Android keeps one reader mode per activity, so when a tag reader or other code stops reader mode on the app's Activity, this plugin's suppression is still held but not in effect, and `isSuppressed()` still returns `true`. Request again: a request restores it even while it is held. To avoid it, hand over in order; see [With NFC tag readers](#with-nfc-tag-readers-android). |

### Logs

The plugin logs what changes suppression in the background, such as a re-arm
after NFC is switched on, and failures that lose or change suppression.
The native code doesn't log results; log `result.description` if you need it.
In debug builds, Dart logs every Android and iOS result and channel failure with
`dart:developer` (name `nfc_wallet_suppression`), shown in DevTools' Logging view.

**Android**: `adb logcat -s NfcWalletSuppression`. Errors are logged in every
build, background events in debuggable builds. In a release build, switch
background events on with

```bash
adb shell setprop log.tag.NfcWalletSuppression DEBUG
```

and off with `adb shell setprop log.tag.NfcWalletSuppression ""`. To check that
reader mode is on, with the screen on: `adb shell dumpsys nfc | grep mEnableReader`.

**iOS**: in Console.app on a Mac, select the device, search for
`subsystem:dev.teklund.nfc_wallet_suppression`, turn on Action → Include Debug
Messages, and click Start. Errors are stored on the device; background events
show only while streaming.

## Testing

`package:nfc_wallet_suppression/testing.dart` provides
`FakeNfcWalletSuppression` for unit and widget tests. Install it, and calls to
`NfcWalletSuppression` return what you configure:

```dart
import 'package:nfc_wallet_suppression/testing.dart';

NfcWalletSuppressionPlatform.instance = FakeNfcWalletSuppression(
  requestResult: const SuppressionResult(status: SuppressionStatus.denied),
);
```

See the [`testing` library docs](https://pub.dev/documentation/nfc_wallet_suppression/latest/testing/)
for a full example.

## Example App

See the [`example/`](https://github.com/teklund/nfc_wallet_suppression/tree/HEAD/example) directory for a complete working example with lifecycle management and error handling.

```bash
cd example && flutter run
```

## Privacy

This plugin includes a privacy manifest (`ios/nfc_wallet_suppression/Sources/nfc_wallet_suppression/PrivacyInfo.xcprivacy`) that declares:

- **No tracking** (NSPrivacyTracking: false)
- **No data collection** (NSPrivacyCollectedDataTypes: empty)
- **No required reason APIs** (NSPrivacyAccessedAPITypes: empty)
- **No tracking domains** (NSPrivacyTrackingDomains: empty)

The PassKit APIs used for NFC wallet suppression do not access sensitive user data, do not track users, and do not fall under Apple's required reason API categories. The privacy manifest is included as a best practice for App Store compliance.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Additional Resources

[API Docs](https://pub.dev/documentation/nfc_wallet_suppression/latest/) • [Report Issues](https://github.com/teklund/nfc_wallet_suppression/issues) • [CHANGELOG](CHANGELOG.md) • [Apple PassKit](https://developer.apple.com/documentation/passkit) • [Android NFC](https://developer.android.com/guide/topics/connectivity/nfc)

## License

BSD 3-Clause. See [LICENSE](LICENSE).
