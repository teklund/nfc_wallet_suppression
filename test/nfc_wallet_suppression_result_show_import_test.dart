// Imports only the class and enum, the way a consumer narrowing their namespace
// would. This compiles only because the getters are members of the class: an
// extension's getters are invisible through a `show` clause that omits it.
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart'
    show SuppressionResult, SuppressionStatus;

void main() {
  test('the convenience getters are reachable through a `show` import', () {
    const result = SuppressionResult(status: SuppressionStatus.suppressed);

    expect(result.isSuppressed, isTrue);
    expect(result.isReleased, isFalse);
    expect(result.isRetryable, isFalse);
  });
}
