import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  group('SuppressionResult', () {
    test('description defaults to null', () {
      const result = SuppressionResult(status: SuppressionStatus.suppressed);
      expect(result.status, SuppressionStatus.suppressed);
      expect(result.description, isNull);
    });

    test('value equality covers both fields', () {
      const a = SuppressionResult(
        status: SuppressionStatus.denied,
        description: 'nope',
      );
      const b = SuppressionResult(
        status: SuppressionStatus.denied,
        description: 'nope',
      );
      const differentStatus = SuppressionResult(
        status: SuppressionStatus.unknown,
        description: 'nope',
      );
      const differentDescription = SuppressionResult(
        status: SuppressionStatus.denied,
        description: 'other',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(differentStatus));
      expect(a, isNot(differentDescription));
    });

    test('toString includes both fields', () {
      const result = SuppressionResult(
        status: SuppressionStatus.nfcDisabled,
        description: 'NFC is disabled',
      );

      expect(result.toString(), contains('nfcDisabled'));
      expect(result.toString(), contains('NFC is disabled'));
    });
  });

  group('SuppressionResultGetters', () {
    SuppressionResult of(SuppressionStatus status) =>
        SuppressionResult(status: status);

    test('isSuppressed is true only for suppressed', () {
      for (final status in SuppressionStatus.values) {
        expect(
          of(status).isSuppressed,
          status == SuppressionStatus.suppressed,
          reason: 'isSuppressed was wrong for $status',
        );
      }
    });

    test('isReleased is true only for notSuppressed', () {
      for (final status in SuppressionStatus.values) {
        expect(
          of(status).isReleased,
          status == SuppressionStatus.notSuppressed,
          reason: 'isReleased was wrong for $status',
        );
      }
    });

    test('isRetryable covers exactly the recoverable statuses', () {
      const retryable = {
        SuppressionStatus.nfcDisabled,
        SuppressionStatus.unavailable,
      };

      for (final status in SuppressionStatus.values) {
        expect(
          of(status).isRetryable,
          retryable.contains(status),
          reason: 'isRetryable was wrong for $status',
        );
      }
    });

    test('isRetryable excludes unknown', () {
      // `unknown` means the operation may already have taken effect, so a blind
      // retry could double-apply. Callers should check `isSuppressed()` instead.
      expect(of(SuppressionStatus.unknown).isRetryable, false);
    });

    test('isRetryable excludes notSupported', () {
      // Permanent for the device; retrying can never help.
      expect(of(SuppressionStatus.notSupported).isRetryable, false);
    });
  });
}
