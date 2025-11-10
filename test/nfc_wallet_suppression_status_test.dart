import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  group('SuppressionStatus', () {
    test('enum contains all expected values', () {
      expect(SuppressionStatus.values.length, 8);
      expect(
          SuppressionStatus.values, contains(SuppressionStatus.notSuppressed));
      expect(SuppressionStatus.values, contains(SuppressionStatus.suppressed));
      expect(SuppressionStatus.values, contains(SuppressionStatus.unavailable));
      expect(SuppressionStatus.values, contains(SuppressionStatus.denied));
      expect(SuppressionStatus.values, contains(SuppressionStatus.cancelled));
      expect(
          SuppressionStatus.values, contains(SuppressionStatus.notSupported));
      expect(SuppressionStatus.values,
          contains(SuppressionStatus.alreadyPresenting));
      expect(SuppressionStatus.values, contains(SuppressionStatus.unknown));
    });

    test('enum values have correct names', () {
      expect(SuppressionStatus.notSuppressed.name, 'notSuppressed');
      expect(SuppressionStatus.suppressed.name, 'suppressed');
      expect(SuppressionStatus.unavailable.name, 'unavailable');
      expect(SuppressionStatus.denied.name, 'denied');
      expect(SuppressionStatus.cancelled.name, 'cancelled');
      expect(SuppressionStatus.notSupported.name, 'notSupported');
      expect(SuppressionStatus.alreadyPresenting.name, 'alreadyPresenting');
      expect(SuppressionStatus.unknown.name, 'unknown');
    });

    test('enum values are distinct', () {
      final values = SuppressionStatus.values.toSet();
      expect(values.length, SuppressionStatus.values.length);
    });

    test('enum can be compared for equality', () {
      expect(
          SuppressionStatus.suppressed == SuppressionStatus.suppressed, isTrue);
      expect(SuppressionStatus.suppressed == SuppressionStatus.notSuppressed,
          isFalse);
    });

    test('enum can be used in switch statements', () {
      String getDescription(SuppressionStatus status) {
        switch (status) {
          case SuppressionStatus.notSuppressed:
            return 'not suppressed';
          case SuppressionStatus.suppressed:
            return 'suppressed';
          case SuppressionStatus.unavailable:
            return 'unavailable';
          case SuppressionStatus.denied:
            return 'denied';
          case SuppressionStatus.cancelled:
            return 'cancelled';
          case SuppressionStatus.notSupported:
            return 'not supported';
          case SuppressionStatus.alreadyPresenting:
            return 'already presenting';
          case SuppressionStatus.unknown:
            return 'unknown';
        }
      }

      expect(getDescription(SuppressionStatus.suppressed), 'suppressed');
      expect(getDescription(SuppressionStatus.notSupported), 'not supported');
      expect(getDescription(SuppressionStatus.unknown), 'unknown');
    });
  });
}
