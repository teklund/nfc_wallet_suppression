import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin
    implements NfcWalletSuppressionPlatform {
  bool _isSuppressing = false;

  @override
  Future<SuppressionStatus> requestSuppression() {
    _isSuppressing = true;
    return Future.value(SuppressionStatus.suppressed);
  }

  @override
  Future<SuppressionStatus> releaseSuppression() {
    _isSuppressing = false;
    return Future.value(SuppressionStatus.notSuppressed);
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
  test('isSuppressed_falseAfterRelease', () async {
    MockNfcWalletSuppressionPlatform fakePlatform =
        MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    await NfcWalletSuppression.requestSuppression();
    expect(await NfcWalletSuppression.isSuppressed(), isTrue);
    await NfcWalletSuppression.releaseSuppression();
    expect(await NfcWalletSuppression.isSuppressed(), isFalse);
  });

  test('requestSuppression_returnsSuppressedStatus', () async {
    MockNfcWalletSuppressionPlatform fakePlatform =
        MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    final status = await NfcWalletSuppression.requestSuppression();
    expect(status, SuppressionStatus.suppressed);
  });

  test('releaseSuppression_returnsNotSuppressedStatus', () async {
    MockNfcWalletSuppressionPlatform fakePlatform =
        MockNfcWalletSuppressionPlatform();
    NfcWalletSuppressionPlatform.instance = fakePlatform;

    await NfcWalletSuppression.requestSuppression();
    final status = await NfcWalletSuppression.releaseSuppression();
    expect(status, SuppressionStatus.notSuppressed);
  });
}
