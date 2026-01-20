// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isSuppressed default state', (WidgetTester tester) async {
    final bool suppressed = await NfcWalletSuppression.isSuppressed();
    // Default state should be false (not suppressed)
    expect(suppressed, false);
  });

  testWidgets('full request and release lifecycle',
      (WidgetTester tester) async {
    // Verify initial state is not suppressed
    bool suppressed = await NfcWalletSuppression.isSuppressed();
    expect(suppressed, false, reason: 'Initial state should be not suppressed');

    // Request suppression
    final requestStatus = await NfcWalletSuppression.requestSuppression();

    // Verify suppression was either successful or device doesn't support it
    expect(
      [
        SuppressionStatus.suppressed,
        SuppressionStatus.notSupported,
        SuppressionStatus.unavailable,
        SuppressionStatus.denied
      ],
      contains(requestStatus),
      reason: 'Request should return a valid status',
    );

    // Only continue with lifecycle test if suppression was successful
    if (requestStatus == SuppressionStatus.suppressed) {
      // Verify suppression is active
      suppressed = await NfcWalletSuppression.isSuppressed();
      expect(suppressed, true, reason: 'Should be suppressed after request');

      // Release suppression
      final releaseStatus = await NfcWalletSuppression.releaseSuppression();
      expect(
        [SuppressionStatus.notSuppressed, SuppressionStatus.unavailable],
        contains(releaseStatus),
        reason: 'Release should return a valid status',
      );

      // Verify suppression is no longer active
      suppressed = await NfcWalletSuppression.isSuppressed();
      expect(suppressed, false,
          reason: 'Should not be suppressed after release');
    }
  });
}
