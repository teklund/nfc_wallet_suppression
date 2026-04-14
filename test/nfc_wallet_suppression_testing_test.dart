import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/testing.dart';

/// Example tests demonstrating how to use the testing utilities
void main() {
  group('FakeNfcWalletSuppression', () {
    late FakeNfcWalletSuppression fake;

    setUp(() {
      fake = FakeNfcWalletSuppression();
      NfcWalletSuppressionPlatform.instance = fake;
    });

    test('tracks method calls', () async {
      await NfcWalletSuppression.isSupported();
      await NfcWalletSuppression.requestSuppression();
      await NfcWalletSuppression.isSuppressed();
      await NfcWalletSuppression.releaseSuppression();

      expect(fake.methodCalls, [
        'isSupported',
        'requestSuppression',
        'isSuppressed',
        'releaseSuppression',
      ]);
    });

    test('can simulate suppression lifecycle', () async {
      fake.setSupported(true);
      fake.setRequestResult(SuppressionStatus.suppressed);

      final supported = await NfcWalletSuppression.isSupported();
      expect(supported, true);

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.suppressed);

      final suppressed = await NfcWalletSuppression.isSuppressed();
      expect(suppressed, true);

      await NfcWalletSuppression.releaseSuppression();
      final notSuppressed = await NfcWalletSuppression.isSuppressed();
      expect(notSuppressed, false);
    });

    test('can simulate device without NFC', () async {
      fake.setSupported(false);
      fake.setRequestResult(SuppressionStatus.notSupported);

      final supported = await NfcWalletSuppression.isSupported();
      expect(supported, false);

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.notSupported);
    });

    test('can simulate NFC disabled', () async {
      fake.setSupported(true);
      fake.setRequestResult(SuppressionStatus.unavailable);

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.unavailable);
    });

    test('can manually set suppressed state', () async {
      // Simulate external state change
      fake.setSuppressed(true);

      final suppressed = await NfcWalletSuppression.isSuppressed();
      expect(suppressed, true);
    });

    test('can simulate release result', () async {
      fake.setReleaseResult(SuppressionStatus.unknown);

      final status = await NfcWalletSuppression.releaseSuppression();
      expect(status, SuppressionStatus.unknown);
    });

    test('reset clears state and call history', () async {
      fake.setSupported(false);
      fake.setRequestResult(SuppressionStatus.unavailable);
      fake.setReleaseResult(SuppressionStatus.unknown);
      fake.setSuppressed(true);
      await NfcWalletSuppression.requestSuppression();

      fake.reset();

      expect(fake.methodCalls, isEmpty);
      expect(await NfcWalletSuppression.isSupported(), true);
      expect(await NfcWalletSuppression.requestSuppression(), SuppressionStatus.suppressed);
      expect(await NfcWalletSuppression.releaseSuppression(), SuppressionStatus.notSuppressed);
      expect(await NfcWalletSuppression.isSuppressed(), false);
    });
  });

  group('NfcWalletSuppressionTestScenarios', () {
    test('supportedDevice scenario', () async {
      final fake = NfcWalletSuppressionTestScenarios.supportedDevice();
      NfcWalletSuppressionPlatform.instance = fake;

      final supported = await NfcWalletSuppression.isSupported();
      expect(supported, true);

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.suppressed);
    });

    test('unsupportedDevice scenario', () async {
      final fake = NfcWalletSuppressionTestScenarios.unsupportedDevice();
      NfcWalletSuppressionPlatform.instance = fake;

      final supported = await NfcWalletSuppression.isSupported();
      expect(supported, false);

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.notSupported);
    });

    test('nfcUnavailable scenario', () async {
      final fake = NfcWalletSuppressionTestScenarios.nfcUnavailable();
      NfcWalletSuppressionPlatform.instance = fake;

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.unavailable);
    });

    test('userDenied scenario', () async {
      final fake = NfcWalletSuppressionTestScenarios.userDenied();
      NfcWalletSuppressionPlatform.instance = fake;

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.denied);
    });

    test('alreadyPresenting scenario', () async {
      final fake = NfcWalletSuppressionTestScenarios.alreadyPresenting();
      NfcWalletSuppressionPlatform.instance = fake;

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.alreadyPresenting);
    });

    test('userCancelled scenario', () async {
      final fake = NfcWalletSuppressionTestScenarios.userCancelled();
      NfcWalletSuppressionPlatform.instance = fake;

      final status = await NfcWalletSuppression.requestSuppression();
      expect(status, SuppressionStatus.cancelled);
    });
  });
}
