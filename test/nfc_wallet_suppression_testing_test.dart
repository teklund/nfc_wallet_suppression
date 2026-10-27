import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/testing.dart';

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

    test('defaults to a supported device where everything succeeds', () async {
      expect(await NfcWalletSuppression.isSupported(), true);
      expect(
        (await NfcWalletSuppression.requestSuppression()).status,
        SuppressionStatus.suppressed,
      );
      expect(await NfcWalletSuppression.isSuppressed(), true);

      expect(
        (await NfcWalletSuppression.releaseSuppression()).status,
        SuppressionStatus.notSuppressed,
      );
      expect(await NfcWalletSuppression.isSuppressed(), false);
    });

    test('takes its configuration from the constructor', () async {
      NfcWalletSuppressionPlatform.instance = FakeNfcWalletSuppression(
        supported: false,
        requestResult: const SuppressionResult(
          status: SuppressionStatus.notSupported,
        ),
        releaseResult: const SuppressionResult(
          status: SuppressionStatus.unknown,
        ),
        suppressed: true,
      );

      expect(await NfcWalletSuppression.isSupported(), false);
      expect(await NfcWalletSuppression.isSuppressed(), true);
      expect(
        (await NfcWalletSuppression.releaseSuppression()).status,
        SuppressionStatus.unknown,
      );
      expect(
        (await NfcWalletSuppression.requestSuppression()).status,
        SuppressionStatus.notSupported,
      );
    });

    test('returns any configured request status', () async {
      for (final status in SuppressionStatus.values) {
        fake.requestResult = SuppressionResult(status: status);
        expect(
          (await NfcWalletSuppression.requestSuppression()).status,
          status,
        );
      }
    });

    test('returns the configured description', () async {
      fake.requestResult = const SuppressionResult(
        status: SuppressionStatus.nfcDisabled,
        description: 'NFC is disabled',
      );

      final result = await NfcWalletSuppression.requestSuppression();
      expect(result.description, 'NFC is disabled');
      expect(result.isRetryable, false);
    });

    test('reports a suppressed state set directly', () async {
      fake.suppressed = true;

      expect(await NfcWalletSuppression.isSuppressed(), true);
    });

    test('a failed request clears a previously suppressed state', () async {
      await NfcWalletSuppression.requestSuppression();
      expect(await NfcWalletSuppression.isSuppressed(), true);

      // A later request that fails must not leave a stale `true`.
      fake.requestResult = const SuppressionResult(
        status: SuppressionStatus.denied,
      );
      await NfcWalletSuppression.requestSuppression();
      expect(await NfcWalletSuppression.isSuppressed(), false);
    });

    test('a failed release keeps suppression active', () async {
      await NfcWalletSuppression.requestSuppression();

      fake.releaseResult = const SuppressionResult(
        status: SuppressionStatus.unknown,
      );
      await NfcWalletSuppression.releaseSuppression();
      expect(
        await NfcWalletSuppression.isSuppressed(),
        true,
        reason: 'A failed release must not clear suppression',
      );
    });

    test(
      'releasing when nothing is suppressed is an idempotent success',
      () async {
        final result = await NfcWalletSuppression.releaseSuppression();
        expect(result.isReleased, true);
        expect(await NfcWalletSuppression.isSuppressed(), false);
      },
    );
  });
}
