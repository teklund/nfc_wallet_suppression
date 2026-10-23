import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_default_platform.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_pigeon_impl.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_stub.dart';

void main() {
  group('defaultPlatform', () {
    for (final platform in TargetPlatform.values) {
      final native =
          platform == TargetPlatform.android || platform == TargetPlatform.iOS;

      test('is ${native ? 'native' : 'the stub'} on ${platform.name}', () {
        expect(
          defaultPlatform(platform, isWeb: false),
          native
              ? isA<PigeonNfcWalletSuppression>()
              : isA<StubNfcWalletSuppression>(),
        );
      });

      test('is the stub on the web, whatever the OS (${platform.name})', () {
        expect(
          defaultPlatform(platform, isWeb: true),
          isA<StubNfcWalletSuppression>(),
        );
      });
    }
  });
}
