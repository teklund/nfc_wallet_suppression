import 'nfc_wallet_suppression_platform_interface.dart';

class NfcWalletSuppression {
  Future<String?> getPlatformVersion() {
    return NfcWalletSuppressionPlatform.instance.getPlatformVersion();
  }

  Future<bool?> requestSuppression() {
    return NfcWalletSuppressionPlatform.instance.requestSuppression();
  }

  Future<bool?> releaseSuppression() {
    return NfcWalletSuppressionPlatform.instance.releaseSuppression();
  }

  Future<bool?> isSuppressed() {
    return NfcWalletSuppressionPlatform.instance.isSuppressed();
  }
}
