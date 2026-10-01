import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_result.dart';
import 'nfc_wallet_suppression_status.dart';

/// Provides a mechanism to suppress the system's NFC wallet behavior.
///
/// This plugin allows you to temporarily prevent the operating system from
/// automatically presenting wallet passes (like Apple Pay cards, transit cards,
/// etc.) when an NFC tag is detected. This is useful when your app needs to
/// read NFC tags without interference from the system wallet.
///
/// ## Platform Support
///
/// - **iOS**: Requires iOS 13.0+ on iPhone 7 or later with NFC hardware.
///   Requires the `com.apple.developer.passkit.pass-presentation-suppression`
///   entitlement from Apple.
///
/// - **Android**: Requires Android 5.0+ (API 21) with NFC hardware enabled.
///   The NFC permission is automatically added to your app's manifest.
///
/// ## Usage Example
///
/// ```dart
/// import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
///
/// // Request suppression when you need to read NFC tags
/// final result = await NfcWalletSuppression.requestSuppression();
///
/// if (result.isSuppressed) {
///   // Now you can read NFC tags without wallet interference
///   // ... your NFC reading code ...
/// } else if (result.status == SuppressionStatus.denied) {
///   // User denied the permission
/// } else if (result.status == SuppressionStatus.notSupported) {
///   // Device doesn't support wallet suppression
/// }
///
/// // Always release suppression when done
/// await NfcWalletSuppression.releaseSuppression();
/// ```
///
/// See also:
/// - [SuppressionResult] for the shape of what these methods return
/// - [SuppressionStatus] for all possible status values
/// - [requestSuppression] to suppress wallet presentation
/// - [releaseSuppression] to restore wallet functionality
/// - [isSuppressed] to check current suppression state
class NfcWalletSuppression {
  /// Requests suppression of the system's NFC wallet behavior.
  ///
  /// When called, this method requests the operating system to temporarily
  /// stop automatically presenting wallet passes when NFC tags are detected.
  /// This allows your app to read NFC tags without competition from the
  /// system wallet.
  ///
  /// **Important:** On iOS, this may prompt the user for permission. Rapid or
  /// overlapping calls are safe: on both platforms a call made while suppression
  /// is already active returns [SuppressionStatus.suppressed] without re-arming.
  /// On iOS, overlapping (un-awaited) calls made while a request is in flight
  /// share that request's result.
  ///
  /// Calls do not have to be awaited before the next one is issued. Operations
  /// run in the order you issued them, and each caller is told the outcome of
  /// its own operation, so interleaving (e.g., request, release, request without
  /// awaiting) leaves suppression in the state the last operation asked for.
  /// [isSuppressed] still reports the live state.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a [SuppressionResult]. Its
  /// [SuppressionResult.status] is one of:
  ///
  /// | Status | iOS | Android |
  /// |---|---|---|
  /// | [SuppressionStatus.suppressed] — suppression is active | ✔ | ✔ |
  /// | [SuppressionStatus.notSupported] — no suppression capability at all; iOS: PassKit reports it unsupported, Android: no NFC hardware | ✔ | ✔ |
  /// | [SuppressionStatus.nfcDisabled] — NFC hardware present but switched off; deep-link the user to settings | | ✔ |
  /// | [SuppressionStatus.unavailable] — transient; no foreground Activity | | ✔ |
  /// | [SuppressionStatus.denied] — iOS: refused by the user or system (includes a missing entitlement); Android: a `SecurityException` | ✔ | ✔ |
  /// | [SuppressionStatus.alreadyPresenting] — the wallet is already showing a pass | ✔ | |
  /// | [SuppressionStatus.cancelled] — the request was cancelled before it completed | ✔ | |
  /// | [SuppressionStatus.unknown] — unexpected failure, or no answer in time; call [isSuppressed] if you need the live state | ✔ | ✔ |
  ///
  /// [SuppressionStatus.notSuppressed] is never returned here — it belongs to
  /// [releaseSuppression]. New values may be added without a major version bump,
  /// so always include a fallback when switching.
  ///
  /// ## Platform Behavior
  ///
  /// **iOS:**
  /// - Uses PassKit's `requestAutomaticPassPresentationSuppression`
  /// - May show a system permission dialog on first use
  /// - Suppression persists until explicitly released
  /// - Survives configuration changes (screen rotation)
  ///
  /// **Android:**
  /// - Uses the NFC Adapter's reader mode (`enableReaderMode`), which takes over
  ///   the NFC stack and suppresses wallet / host-card-emulation apps
  /// - No permission prompt required
  /// - Automatically restored after activity recreation
  /// - Requires NFC to be enabled in device settings
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await NfcWalletSuppression.requestSuppression();
  ///
  /// switch (result.status) {
  ///   case SuppressionStatus.suppressed:
  ///     print('Wallet suppressed successfully');
  ///   case SuppressionStatus.nfcDisabled:
  ///     // The one failure the user can fix — offer to open NFC settings.
  ///     promptToEnableNfc();
  ///   case SuppressionStatus.denied:
  ///     print('User denied permission');
  ///   case SuppressionStatus.notSupported:
  ///     print('Device does not support wallet suppression');
  ///   default:
  ///     print('Failed: ${result.status} (${result.description})');
  /// }
  /// ```
  ///
  /// See also:
  /// - [releaseSuppression] to restore wallet functionality
  /// - [isSuppressed] to check if currently suppressed
  static Future<SuppressionResult> requestSuppression() {
    return NfcWalletSuppressionPlatform.instance.requestSuppression();
  }

  /// Releases suppression of the system's NFC wallet behavior.
  ///
  /// Restores the system's ability to automatically present wallet passes when
  /// NFC tags are detected. You should always call this when your NFC reading
  /// session is complete to restore normal wallet functionality.
  ///
  /// Release is idempotent. Calling it when nothing is suppressed is a success,
  /// not an error — you asked for suppression to be off and it is off — so a
  /// `finally { release() }` block never has to know whether the matching
  /// request succeeded.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a [SuppressionResult]. Its
  /// [SuppressionResult.status] is one of:
  ///
  /// | Status | iOS | Android |
  /// |---|---|---|
  /// | [SuppressionStatus.notSuppressed] — suppression is off, whether this call ended it or there was nothing to end | ✔ | ✔ |
  /// | [SuppressionStatus.denied] — tearing down reader mode threw a `SecurityException`; suppression may still be active | | ✔ |
  /// | [SuppressionStatus.unknown] — unexpected tear-down failure, or the platform channel itself failed; suppression may still be active | ✔ | ✔ |
  ///
  /// On iOS this can only ever be [SuppressionStatus.notSuppressed] in practice:
  /// ending suppression cannot fail, so [SuppressionStatus.unknown] is reachable
  /// only if the platform channel does. New values may be added without a major
  /// version bump, so still include a fallback when switching.
  ///
  /// Release reports on the suppression *you* requested, not on live device
  /// state: it returns [SuppressionStatus.notSuppressed] even if suppression had
  /// already lapsed in the meantime (e.g. the app was backgrounded or the user
  /// turned NFC off). Use [isSuppressed] to query whether suppression is
  /// actually in effect right now. Both platforms behave identically here.
  ///
  /// ## Platform Behavior
  ///
  /// **iOS:**
  /// - Uses PassKit's `endAutomaticPassPresentationSuppression`
  /// - Safe to call even if suppression was never requested
  ///
  /// **Android:**
  /// - Disables NFC reader mode
  /// - Safe to call even if suppression was never requested
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   await NfcWalletSuppression.requestSuppression();
  ///   // ... read NFC tags ...
  /// } finally {
  ///   // Always release suppression when done
  ///   await NfcWalletSuppression.releaseSuppression();
  /// }
  /// ```
  ///
  /// See also:
  /// - [requestSuppression] to suppress wallet presentation
  /// - [isSuppressed] to check current state
  static Future<SuppressionResult> releaseSuppression() {
    return NfcWalletSuppressionPlatform.instance.releaseSuppression();
  }

  /// Checks if the system's NFC wallet behavior is currently suppressed.
  ///
  /// Returns `true` if wallet presentation is currently suppressed (i.e., after
  /// a successful call to [requestSuppression] and before [releaseSuppression]),
  /// or `false` otherwise.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a [bool]:
  /// - `true`: Wallet is currently suppressed
  /// - `false`: Wallet is not suppressed (default state)
  ///
  /// ## Platform Behavior
  ///
  /// **iOS:**
  /// - Uses PassKit's static `isSuppressingAutomaticPassPresentation` method
  /// - Accurately reflects system-wide suppression state
  ///
  /// **Android:**
  /// - Returns `true` only while suppression is active, an activity is attached,
  ///   and NFC is still enabled
  /// - Suppression is re-armed across activity recreation (e.g., screen rotation)
  /// - Returns `false` if the activity is detached or NFC was turned off
  ///
  /// ## Example
  ///
  /// ```dart
  /// final suppressed = await NfcWalletSuppression.isSuppressed();
  ///
  /// if (suppressed) {
  ///   print('Wallet is currently suppressed');
  /// } else {
  ///   print('Wallet is active (not suppressed)');
  /// }
  /// ```
  ///
  /// See also:
  /// - [requestSuppression] to suppress wallet
  /// - [releaseSuppression] to release suppression
  static Future<bool> isSuppressed() {
    return NfcWalletSuppressionPlatform.instance.isSuppressed();
  }

  /// Checks if the device supports NFC wallet suppression.
  ///
  /// Returns `true` if the device has the necessary hardware and operating
  /// system support for NFC wallet suppression, or `false` otherwise.
  ///
  /// ## Platform Requirements
  ///
  /// **iOS:**
  /// - Requires iOS 13.0 or later
  /// - Requires iPhone 7 or later (NFC hardware)
  /// - Requires the PassKit entitlement
  ///
  /// Note: on iOS this reflects Wallet pass-library availability — a *necessary*
  /// condition, not a guarantee that suppression will succeed (PassKit exposes no
  /// API to query suppression capability or the entitlement up front). A `true`
  /// result can still be followed by [SuppressionStatus.notSupported] or
  /// [SuppressionStatus.denied] from [requestSuppression].
  ///
  /// **Android:**
  /// - Requires Android 5.0+ (API 21)
  /// - Requires NFC hardware
  /// - Does not require NFC to be enabled (checks hardware only)
  ///
  /// ## Use Case
  ///
  /// Call this method before attempting to use wallet suppression features
  /// to provide appropriate UI or fallback behavior when the feature is
  /// not available.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (await NfcWalletSuppression.isSupported()) {
  ///   // Show NFC suppression UI
  ///   final result = await NfcWalletSuppression.requestSuppression();
  ///   // ...
  /// } else {
  ///   // Show message that device doesn't support this feature
  ///   print('NFC wallet suppression not supported on this device');
  /// }
  /// ```
  ///
  /// See also:
  /// - [requestSuppression] to suppress wallet if supported
  static Future<bool> isSupported() {
    return NfcWalletSuppressionPlatform.instance.isSupported();
  }
}
