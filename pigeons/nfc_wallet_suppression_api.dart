import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/nfc_wallet_suppression_pigeon.dart',
    kotlinOut:
        'android/src/main/kotlin/dev/teklund/nfc_wallet_suppression/NfcWalletSuppressionPigeon.kt',
    kotlinOptions: KotlinOptions(package: 'dev.teklund.nfc_wallet_suppression'),
    swiftOut: 'ios/Classes/NfcWalletSuppressionPigeon.swift',
  ),
)
/// Status result from suppression operations
enum SuppressionStatusCode {
  /// Suppression is active
  suppressed,

  /// Suppression is not active
  notSuppressed,

  /// Device or OS does not support suppression
  notSupported,

  /// Device is already presenting passes
  alreadyPresenting,

  /// User cancelled the suppression request
  cancelled,

  /// User or system denied the suppression request
  denied,

  /// NFC is not available (disabled, missing hardware, etc.)
  unavailable,

  /// Unknown status or error
  unknown,
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
  @async
  SuppressionResult requestSuppression();

  /// Release suppression of the NFC wallet
  ///
  /// Returns a [SuppressionResult] indicating the outcome of the release.
  /// Should be called when NFC operations are complete to restore normal behavior.
  @async
  SuppressionResult releaseSuppression();

  /// Check if NFC wallet is currently suppressed
  ///
  /// Returns true if suppression is currently active, false otherwise.
  @async
  bool isSuppressed();

  /// Check if device supports NFC wallet suppression
  ///
  /// Returns true if the device has the necessary hardware and OS support,
  /// false otherwise. Should be called before attempting to use suppression.
  @async
  bool isSupported();
}
