import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_status.dart';

/// Stub implementation of [NfcWalletSuppressionPlatform] for unsupported platforms.
///
/// This implementation is used on platforms that don't support NFC wallet
/// suppression (web, macOS, Linux, Windows). All methods return appropriate
/// "not supported" responses without throwing exceptions.
///
/// This ensures that apps using this plugin on unsupported platforms
/// gracefully degrade instead of crashing with `MissingPluginException`.
class StubNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// Creates a stub implementation for unsupported platforms.
  StubNfcWalletSuppression();

  /// Registers this class as the default instance of [NfcWalletSuppressionPlatform].
  static void registerWith() {
    NfcWalletSuppressionPlatform.instance = StubNfcWalletSuppression();
  }

  @override
  Future<SuppressionStatus> requestSuppression() async {
    return SuppressionStatus.notSupported;
  }

  @override
  Future<SuppressionStatus> releaseSuppression() async {
    return SuppressionStatus.notSuppressed;
  }

  @override
  Future<bool> isSuppressed() async {
    return false;
  }

  @override
  Future<bool> isSupported() async {
    return false;
  }
}
