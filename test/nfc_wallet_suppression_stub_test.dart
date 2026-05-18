import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_platform_interface.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_status.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StubNfcWalletSuppression', () {
    late StubNfcWalletSuppression stub;

    setUp(() {
      stub = StubNfcWalletSuppression();
    });

    test('is a NfcWalletSuppressionPlatform', () {
      expect(stub, isA<NfcWalletSuppressionPlatform>());
    });

    group('requestSuppression', () {
      test('returns notSupported', () async {
        final result = await stub.requestSuppression();
        expect(result, SuppressionStatus.notSupported);
      });
    });

    group('releaseSuppression', () {
      test('returns notSuppressed', () async {
        final result = await stub.releaseSuppression();
        expect(result, SuppressionStatus.notSuppressed);
      });
    });

    group('isSuppressed', () {
      test('returns false', () async {
        final result = await stub.isSuppressed();
        expect(result, false);
      });
    });

    group('isSupported', () {
      test('returns false', () async {
        final result = await stub.isSupported();
        expect(result, false);
      });
    });

    group('platform registration', () {
      test('can be set as platform instance', () {
        NfcWalletSuppressionPlatform.instance = stub;
        expect(
          NfcWalletSuppressionPlatform.instance,
          isA<StubNfcWalletSuppression>(),
        );
      });

      test('registerWith sets instance to StubNfcWalletSuppression', () {
        StubNfcWalletSuppression.registerWith();
        expect(
          NfcWalletSuppressionPlatform.instance,
          isA<StubNfcWalletSuppression>(),
        );
      });
    });
  });
}
