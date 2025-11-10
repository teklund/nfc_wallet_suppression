import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNfcWalletSuppression platform =
      MethodChannelNfcWalletSuppression();
  const MethodChannel channel = MethodChannel('nfc_wallet_suppression');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return false;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isSuppressed', () async {
    expect(await platform.isSuppressed(), isFalse);
  });
}
