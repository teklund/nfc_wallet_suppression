import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression_method_channel.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin
    implements NfcWalletSuppressionPlatform {
  bool _isSuppressing = false;

  @override
  Future<bool?> requestSuppression() {
    _isSuppressing = true;
    return Future.value(true);
  }

  @override
  Future<bool?> releaseSuppression() {
    _isSuppressing = false;
    return Future.value(true);
  }

  @override
  Future<bool> isSuppressed() {
    return Future.value(_isSuppressing);
  }
}

void main() {
  final NfcWalletSuppressionPlatform initialPlatform =
      NfcWalletSuppressionPlatform.instance;

  test('$MethodChannelNfcWalletSuppression is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNfcWalletSuppression>());
  });

  test('isSuppressed_defaultFalse', () async {
    MockNfcWalletSuppressionPlatform fakePlatform =
        MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    expect(await NfcWalletSuppression.isSuppressed(), isFalse);
  });
  test('isSuppressed_trueWhenSuppressed', () async {
    MockNfcWalletSuppressionPlatform fakePlatform =
        MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    await NfcWalletSuppression.requestSuppression();
    expect(await NfcWalletSuppression.isSuppressed(), isTrue);
  });
  test('isSuppressed_defaultFalse', () async {
    MockNfcWalletSuppressionPlatform fakePlatform =
        MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    await NfcWalletSuppression.requestSuppression();
    expect(await NfcWalletSuppression.isSuppressed(), isTrue);
    await NfcWalletSuppression.releaseSuppression();
    expect(await NfcWalletSuppression.isSuppressed(), isFalse);
  });
}
