import 'nfc_wallet_suppression_platform_interface.dart';

/// Provides a mechanism to suppress the system's NFC wallet behavior.
///
/// This class allows you to temporarily prevent the system from showing its NFC
/// wallet UI when an NFC tag is detected.
class NfcWalletSuppression {
  /// Requests suppression of the system's NFC wallet behavior.
  ///
  /// Returns `true` if suppression was successfully requested, `false` if
  /// suppression could not be requested, and `null` if the platform does not
  /// support suppression.
  static Future<bool?> requestSuppression() {
    return NfcWalletSuppressionPlatform.instance.requestSuppression();
  }

  /// Releases suppression of the system's NFC wallet behavior.
  ///
  /// Returns `true` if suppression was successfully released, `false` if
  /// suppression could not be released, and `null` if the platform does not
  /// support suppression.
  static Future<bool?> releaseSuppression() {
    return NfcWalletSuppressionPlatform.instance.releaseSuppression();
  }

  /// Checks if the system's NFC wallet behavior is currently suppressed.
  static Future<bool?> isSuppressed() {
    return NfcWalletSuppressionPlatform.instance.isSuppressed();
  }
}
