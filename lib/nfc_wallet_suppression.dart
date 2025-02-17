
import 'nfc_wallet_suppression_platform_interface.dart';

class NfcWalletSuppression {
  Future<String?> getPlatformVersion() {
    return NfcWalletSuppressionPlatform.instance.getPlatformVersion();
  }
}
