import 'nfc_wallet_suppression_platform_interface.dart';
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
/// final status = await NfcWalletSuppression.requestSuppression();
///
/// if (status == SuppressionStatus.suppressed) {
///   // Now you can read NFC tags without wallet interference
///   // ... your NFC reading code ...
/// } else if (status == SuppressionStatus.denied) {
///   // User denied the permission
/// } else if (status == SuppressionStatus.notSupported) {
///   // Device doesn't support wallet suppression
/// }
///
/// // Always release suppression when done
/// await NfcWalletSuppression.releaseSuppression();
/// ```
///
/// See also:
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
  /// **Important:** On iOS, this may prompt the user for permission. Multiple
  /// rapid calls are safe - the plugin automatically cleans up any existing
  /// suppression before creating a new one.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a [SuppressionStatus]:
  /// - [SuppressionStatus.suppressed]: Successfully suppressed wallet
  /// - [SuppressionStatus.denied]: User denied permission (iOS only)
  /// - [SuppressionStatus.cancelled]: User cancelled the permission prompt (iOS)
  /// - [SuppressionStatus.notSupported]: Device doesn't support suppression
  /// - [SuppressionStatus.alreadyPresenting]: Wallet is already active (iOS)
  /// - [SuppressionStatus.unavailable]: NFC hardware not available
  /// - [SuppressionStatus.unknown]: An unexpected error occurred
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
  /// - Uses NFC Adapter's `enableReaderMode` and `enableForegroundDispatch`
  /// - No permission prompt required
  /// - Automatically restored after activity recreation
  /// - Requires NFC to be enabled in device settings
  ///
  /// ## Example
  ///
  /// ```dart
  /// final status = await NfcWalletSuppression.requestSuppression();
  ///
  /// switch (status) {
  ///   case SuppressionStatus.suppressed:
  ///     print('Wallet suppressed successfully');
  ///     break;
  ///   case SuppressionStatus.denied:
  ///     print('User denied permission');
  ///     break;
  ///   case SuppressionStatus.notSupported:
  ///     print('Device does not support wallet suppression');
  ///     break;
  ///   default:
  ///     print('Failed with status: $status');
  /// }
  /// ```
  ///
  /// See also:
  /// - [releaseSuppression] to restore wallet functionality
  /// - [isSuppressed] to check if currently suppressed
  static Future<SuppressionStatus> requestSuppression() {
    return NfcWalletSuppressionPlatform.instance.requestSuppression();
  }

  /// Releases suppression of the system's NFC wallet behavior.
  ///
  /// Restores the system's ability to automatically present wallet passes when
  /// NFC tags are detected. You should always call this when your NFC reading
  /// session is complete to restore normal wallet functionality.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a [SuppressionStatus]:
  /// - [SuppressionStatus.notSuppressed]: Successfully released suppression
  /// - [SuppressionStatus.unavailable]: No active suppression to release
  /// - [SuppressionStatus.unknown]: An unexpected error occurred
  ///
  /// ## Platform Behavior
  ///
  /// **iOS:**
  /// - Uses PassKit's `endAutomaticPassPresentationSuppression`
  /// - Safe to call even if suppression was never requested
  /// - Returns [SuppressionStatus.unavailable] if no token exists
  ///
  /// **Android:**
  /// - Disables NFC reader mode and foreground dispatch
  /// - Safe to call even if suppression was never requested
  /// - Returns [SuppressionStatus.unavailable] if NFC is disabled
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
  static Future<SuppressionStatus> releaseSuppression() {
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
  /// - Tracks suppression state internally
  /// - State persists across activity recreation (e.g., screen rotation)
  /// - Returns `false` if activity is detached
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
  ///   final status = await NfcWalletSuppression.requestSuppression();
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
