import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/dev/teklund/nfc_wallet_suppression/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'dev.teklund.nfc_wallet_suppression'),
    swiftOut:
        'ios/nfc_wallet_suppression/Sources/nfc_wallet_suppression/Messages.g.swift',
  ),
)
/// Wire form of the public `SuppressionStatus`, whose docs define each value.
enum SuppressionStatusCode {
  /// Suppression is active
  suppressed,

  /// Suppression is not active
  notSuppressed,

  /// Device or OS does not support suppression
  notSupported,

  /// Device is already presenting passes
  alreadyPresenting,

  /// The request was canceled before it completed
  canceled,

  /// User or system denied the suppression request
  denied,

  /// Suppression could not be attempted right now, but may succeed later.
  ///
  /// Transient and retryable — e.g. no foreground Activity on Android. This
  /// deliberately does *not* cover disabled NFC, which is [nfcDisabled].
  unavailable,

  /// Unknown status or error
  unknown,

  /// NFC hardware is present but switched off in system settings.
  ///
  /// Distinct from [unavailable] and [notSupported] because it is the one
  /// condition the user can fix: an app can deep-link to NFC settings and
  /// prompt them to enable it.
  nfcDisabled,
}

/// Result of a suppression operation with status and optional message
class SuppressionResult {
  const SuppressionResult({required this.status, this.message});

  /// The status of the suppression operation
  final SuppressionStatusCode status;

  /// Optional human-readable message providing additional context
  final String? message;
}

/// Host API for NFC wallet suppression
///
/// This API allows Flutter apps to suppress the automatic presentation
/// of NFC wallet apps (Apple Wallet, Google Pay, etc.) during NFC operations.
@HostApi()
abstract class NfcWalletSuppressionApi {
  /// Request suppression of the NFC wallet
  ///
  /// Returns a [SuppressionResult] indicating the outcome of the request.
  /// On iOS, this uses PassKit's automatic pass presentation suppression.
  /// On Android, this uses NFC reader mode to prevent wallet apps.
  // Callbacks, not @async: @async starts each call in its own Swift Task, which keeps
  // arrival order only with the Swift 6 compiler, and a release must never overtake a request.
  @asyncCallback
  SuppressionResult requestSuppression();

  /// Release suppression of the NFC wallet
  ///
  /// Returns a [SuppressionResult] indicating the outcome of the release.
  /// Should be called when NFC operations are complete to restore normal behavior.
  @asyncCallback
  SuppressionResult releaseSuppression();

  /// Whether suppression is in effect; see `NfcWalletSuppression.isSuppressed`.
  bool isSuppressed();

  /// Whether this device can suppress wallet presentation; see
  /// `NfcWalletSuppression.isSupported`.
  bool isSupported();
}
