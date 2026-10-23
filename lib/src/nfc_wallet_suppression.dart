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
/// - **iOS**: Requires iOS 13.0+ on iPhone. Every iPhone that runs iOS 13 has
///   the NFC hardware for contactless Apple Pay; iPad and iPod touch don't, so
///   there is nothing to suppress on them. Requires the
///   `com.apple.developer.passkit.pass-presentation-suppression` entitlement
///   from Apple.
///
/// - **Android**: Requires Android 5.0+ (API 21) with NFC hardware enabled.
///   The NFC permission is automatically added to your app's manifest.
///
/// ## Suppression lifecycle
///
/// - A successful [requestSuppression] holds suppression until you call
///   [releaseSuppression] or the app is closed. Requesting again while it is
///   held reports on that hold rather than adding another, so one release
///   ends it.
/// - Suppression only takes effect while your app is in the foreground. In
///   the background the wallet works normally, and suppression resumes by
///   itself when the app returns. On Android the same applies while NFC is
///   switched off.
/// - Call [releaseSuppression] once you are done, whatever the request
///   returned. It is always safe, and it is the only way to be sure no
///   suppression is left held.
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
///   // Refused, on iOS usually a missing entitlement
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
abstract final class NfcWalletSuppression {
  /// Requests suppression of the system's NFC wallet behavior.
  ///
  /// When called, this method requests the operating system to temporarily
  /// stop automatically presenting wallet passes when NFC tags are detected.
  /// This allows your app to read NFC tags without competition from the
  /// system wallet.
  ///
  /// **Important:** On iOS, Apple documents that the first request after the app
  /// is installed shows a one-time system alert that Apple Pay is unavailable,
  /// which apps can't customize. Rapid or overlapping calls are safe: a call made while suppression is held reports
  /// on that hold instead of adding another (see "Suppression lifecycle" on
  /// [NfcWalletSuppression]). It returns [SuppressionStatus.suppressed] while
  /// the hold is in effect. On Android with NFC switched off it returns
  /// [SuppressionStatus.nfcDisabled] instead, and the hold resumes once NFC is
  /// back on. On iOS, overlapping (un-awaited) calls made while a request is in
  /// flight share that request's result.
  ///
  /// Calls do not have to be awaited before the next one is issued. Operations
  /// run in the order you issued them, and each caller is told the outcome of
  /// its own operation, so interleaving (e.g., request, release, request without
  /// awaiting) leaves suppression in the state the last operation asked for.
  /// [isSuppressed] still reports the current state.
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
  /// | [SuppressionStatus.denied] — iOS: usually a missing entitlement; Android: a `SecurityException` | ✔ | ✔ |
  /// | [SuppressionStatus.alreadyPresenting] — the wallet is already showing a pass | ✔ | |
  /// | [SuppressionStatus.canceled] — the request was canceled before it completed | ✔ | |
  /// | [SuppressionStatus.unknown] — unexpected failure, or no answer in time; call [isSuppressed] if you need the current state | ✔ | ✔ |
  ///
  /// [SuppressionStatus.notSuppressed] is never returned here — it belongs to
  /// [releaseSuppression]. New values may be added without a major version bump,
  /// so always include a fallback when switching.
  ///
  /// ## Platform Behavior
  ///
  /// **iOS:**
  /// - Uses PassKit's `requestAutomaticPassPresentationSuppression`
  /// - The first request after the app is installed shows a one-time alert that
  ///   Apple Pay is unavailable
  /// - Paused by iOS while the app is in the background, and restored when it
  ///   returns
  /// - Survives configuration changes (screen rotation)
  ///
  /// **Android:**
  /// - Uses the NFC Adapter's reader mode (`enableReaderMode`), which takes over
  ///   the NFC stack and suppresses wallet / host-card-emulation apps
  /// - No permission prompt required
  /// - Paused by Android while the app is in the background, and restored when
  ///   it returns
  /// - Restored automatically after activity recreation and when NFC is
  ///   switched back on
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
  ///     print('Suppression was refused');
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
  /// state: it returns [SuppressionStatus.notSuppressed] whether or not the hold
  /// was in effect at that moment (for example while NFC is switched off on
  /// Android). Use [isSuppressed] to query whether suppression is in effect.
  /// Both platforms behave identically here.
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
  /// Returns `true` if a held suppression is in effect while the app is in the
  /// foreground, or `false` otherwise. A held suppression is not always in
  /// effect (see "Suppression lifecycle" on [NfcWalletSuppression]), so this can
  /// be `false` between a successful [requestSuppression] and
  /// [releaseSuppression]. The result is a snapshot that can change as soon as
  /// it is returned.
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
  /// - May still return `true` right after [releaseSuppression] completes, and
  ///   while the app is moving to the background; PassKit updates the state a
  ///   moment later
  ///
  /// **Android:**
  /// - Returns `true` only while suppression is held, an activity is attached
  ///   and NFC is enabled
  /// - Returns `false` while NFC is switched off, even though the hold resumes
  ///   once NFC is switched back on
  /// - May still return `true` while the app is in the background, where
  ///   Android pauses suppression, and for a moment after NFC is switched on,
  ///   before reader mode is back
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
  /// - Reports whether the Wallet pass library is available
  ///   (`PKPassLibrary.isPassLibraryAvailable`)
  /// - A *necessary* condition, not a guarantee: PassKit cannot report the
  ///   entitlement up front, so [requestSuppression] can still return
  ///   [SuppressionStatus.notSupported] or [SuppressionStatus.denied]
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
