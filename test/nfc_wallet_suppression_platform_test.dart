import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSupportedPlatform extends NfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> isSupported() async => true;

  @override
  Future<SuppressionStatus> requestSuppression() async =>
      SuppressionStatus.suppressed;

  @override
  Future<SuppressionStatus> releaseSuppression() async =>
      SuppressionStatus.notSuppressed;

  @override
  Future<bool> isSuppressed() async => false;
}

class MockUnsupportedPlatform extends NfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<SuppressionStatus> requestSuppression() async =>
      SuppressionStatus.notSupported;

  @override
  Future<SuppressionStatus> releaseSuppression() async =>
      SuppressionStatus.notSupported;

  @override
  Future<bool> isSuppressed() async => false;
}

class MockUnavailablePlatform extends NfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> isSupported() async => true;

  @override
  Future<SuppressionStatus> requestSuppression() async =>
      SuppressionStatus.unavailable;

  @override
  Future<SuppressionStatus> releaseSuppression() async =>
      SuppressionStatus.unavailable;

  @override
  Future<bool> isSuppressed() async => false;
}

void main() {
  group('Platform Support Tests', () {
    test('isSupported returns true on platform with NFC capability', () async {
      final platform = MockSupportedPlatform();
      NfcWalletSuppressionPlatform.instance = platform;

      final supported = await NfcWalletSuppression.isSupported();

      expect(supported, true);
    });

    test(
      'isSupported returns false on platform without NFC capability',
      () async {
        final platform = MockUnsupportedPlatform();
        NfcWalletSuppressionPlatform.instance = platform;

        final supported = await NfcWalletSuppression.isSupported();

        expect(supported, false);
      },
    );

    test(
      'requestSuppression on supported platform returns suppressed status',
      () async {
        final platform = MockSupportedPlatform();
        NfcWalletSuppressionPlatform.instance = platform;

        final status = await NfcWalletSuppression.requestSuppression();

        expect(status, SuppressionStatus.suppressed);
      },
    );

    test(
      'requestSuppression on unsupported platform returns notSupported status',
      () async {
        final platform = MockUnsupportedPlatform();
        NfcWalletSuppressionPlatform.instance = platform;

        final status = await NfcWalletSuppression.requestSuppression();

        expect(status, SuppressionStatus.notSupported);
      },
    );

    test(
      'requestSuppression on platform with unavailable NFC returns unavailable',
      () async {
        final platform = MockUnavailablePlatform();
        NfcWalletSuppressionPlatform.instance = platform;

        final status = await NfcWalletSuppression.requestSuppression();

        expect(status, SuppressionStatus.unavailable);
      },
    );

    test('isSupported can be checked before requesting suppression', () async {
      final platform = MockUnsupportedPlatform();
      NfcWalletSuppressionPlatform.instance = platform;

      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        final status = await NfcWalletSuppression.requestSuppression();
        expect(status, SuppressionStatus.notSupported);
      }

      expect(supported, false);
    });

    test('supported platform allows normal suppression lifecycle', () async {
      final platform = MockSupportedPlatform();
      NfcWalletSuppressionPlatform.instance = platform;

      // Verify support
      final supported = await NfcWalletSuppression.isSupported();
      expect(supported, true);

      // Request suppression
      final requestStatus = await NfcWalletSuppression.requestSuppression();
      expect(requestStatus, SuppressionStatus.suppressed);

      // Release suppression
      final releaseStatus = await NfcWalletSuppression.releaseSuppression();
      expect(releaseStatus, SuppressionStatus.notSuppressed);
    });

    test(
      'unsupported platform maintains consistent unsupported state',
      () async {
        final platform = MockUnsupportedPlatform();
        NfcWalletSuppressionPlatform.instance = platform;

        final supported = await NfcWalletSuppression.isSupported();
        final requestStatus = await NfcWalletSuppression.requestSuppression();
        final releaseStatus = await NfcWalletSuppression.releaseSuppression();
        final isSuppressed = await NfcWalletSuppression.isSuppressed();

        expect(supported, false);
        expect(requestStatus, SuppressionStatus.notSupported);
        expect(releaseStatus, SuppressionStatus.notSupported);
        expect(isSuppressed, false);
      },
    );
  });
}
