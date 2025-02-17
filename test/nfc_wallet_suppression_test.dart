import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression_platform_interface.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin
    implements NfcWalletSuppressionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NfcWalletSuppressionPlatform initialPlatform = NfcWalletSuppressionPlatform.instance;

  test('$MethodChannelNfcWalletSuppression is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNfcWalletSuppression>());
  });

  test('getPlatformVersion', () async {
    NfcWalletSuppression nfcWalletSuppressionPlugin = NfcWalletSuppression();
    MockNfcWalletSuppressionPlatform fakePlatform = MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    expect(await nfcWalletSuppressionPlugin.getPlatformVersion(), '42');
  });
}
