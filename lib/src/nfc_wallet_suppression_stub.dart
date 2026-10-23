import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_result.dart';
import 'nfc_wallet_suppression_status.dart';

/// The implementation on platforms other than Android and iOS, where nothing can
/// be suppressed.
///
/// Without it, calls would go to the Pigeon channel, which has no native side
/// there: requests and releases would report [SuppressionStatus.unknown]
/// instead of a definite answer.
class StubNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// Creates a stub implementation for unsupported platforms.
  StubNfcWalletSuppression();

  @override
  Future<SuppressionResult> requestSuppression() async {
    return const SuppressionResult(
      status: SuppressionStatus.notSupported,
      description: 'NFC wallet suppression is not supported on this platform.',
    );
  }

  @override
  Future<SuppressionResult> releaseSuppression() async {
    return const SuppressionResult(
      status: SuppressionStatus.notSuppressed,
      description: 'Nothing to release; suppression is not supported here.',
    );
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
