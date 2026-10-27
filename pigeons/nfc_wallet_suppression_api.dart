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

  /// The request was refused.
  denied,

  /// Not attempted right now, but may succeed later.
  unavailable,

  /// Unknown status or error
  unknown,

  /// NFC hardware is present but switched off in system settings.
  ///
  /// The request is held, and suppression starts once NFC is switched on.
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

@HostApi()
abstract class NfcWalletSuppressionApi {
  /// Requests suppression, returning the outcome.
  // Callbacks, not @async: @async starts each call in its own Swift Task, which keeps
  // arrival order only with the Swift 6 compiler, and a release must never overtake a request.
  @asyncCallback
  SuppressionResult requestSuppression();

  /// Ends suppression, returning the outcome.
  @asyncCallback
  SuppressionResult releaseSuppression();

  /// Whether suppression is in effect.
  bool isSuppressed();

  /// Whether suppression can be attempted on this device.
  bool isSupported();
}
