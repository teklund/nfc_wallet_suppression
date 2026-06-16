import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  group('SuppressionStatus', () {
    test('enum contains all expected values', () {
      expect(SuppressionStatus.values.length, 8);
      expect(
        SuppressionStatus.values,
        contains(SuppressionStatus.notSuppressed),
      );
      expect(SuppressionStatus.values, contains(SuppressionStatus.suppressed));
      expect(SuppressionStatus.values, contains(SuppressionStatus.unavailable));
      expect(SuppressionStatus.values, contains(SuppressionStatus.denied));
      expect(SuppressionStatus.values, contains(SuppressionStatus.cancelled));
      expect(
        SuppressionStatus.values,
        contains(SuppressionStatus.notSupported),
      );
      expect(
        SuppressionStatus.values,
        contains(SuppressionStatus.alreadyPresenting),
      );
      expect(SuppressionStatus.values, contains(SuppressionStatus.unknown));
    });
  });
}
