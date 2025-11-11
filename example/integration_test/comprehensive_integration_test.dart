// Comprehensive integration tests for NFC Wallet Suppression plugin
//
// These tests validate real platform behavior on physical devices.
// Note: Some tests may behave differently depending on:
// - iOS: Requires PassKit entitlement and iPhone 7+
// - Android: Requires NFC hardware
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Support', () {
    testWidgets('isSupported returns a boolean value',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();
      expect(supported, isA<bool>());
    });

    testWidgets('isSupported is consistent across multiple calls',
        (WidgetTester tester) async {
      final supported1 = await NfcWalletSuppression.isSupported();
      final supported2 = await NfcWalletSuppression.isSupported();
      final supported3 = await NfcWalletSuppression.isSupported();

      expect(supported1, equals(supported2));
      expect(supported2, equals(supported3));
    });
  });

  group('Suppression Lifecycle', () {
    testWidgets('multiple request/release cycles maintain correct state',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        // Skip test on unsupported platforms
        return;
      }

      // Cycle 1
      await NfcWalletSuppression.requestSuppression();
      await NfcWalletSuppression.releaseSuppression();

      // Cycle 2
      final status2 = await NfcWalletSuppression.requestSuppression();
      if (status2 == SuppressionStatus.suppressed) {
        final suppressed2 = await NfcWalletSuppression.isSuppressed();
        expect(suppressed2, true);
      }
      await NfcWalletSuppression.releaseSuppression();

      // Cycle 3
      final status3 = await NfcWalletSuppression.requestSuppression();
      if (status3 == SuppressionStatus.suppressed) {
        final suppressed3 = await NfcWalletSuppression.isSuppressed();
        expect(suppressed3, true);
      }
      await NfcWalletSuppression.releaseSuppression();

      // Verify final state
      final finalSuppressed = await NfcWalletSuppression.isSuppressed();
      expect(finalSuppressed, false);
    });

    testWidgets('rapid sequential requests are handled correctly',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      // Make multiple rapid requests
      final status1 = await NfcWalletSuppression.requestSuppression();
      final status2 = await NfcWalletSuppression.requestSuppression();
      final status3 = await NfcWalletSuppression.requestSuppression();

      // All should return a valid status
      expect(
        [
          SuppressionStatus.suppressed,
          SuppressionStatus.unavailable,
          SuppressionStatus.denied,
          SuppressionStatus.alreadyPresenting
        ],
        contains(status1),
      );
      expect(
        [
          SuppressionStatus.suppressed,
          SuppressionStatus.unavailable,
          SuppressionStatus.denied,
          SuppressionStatus.alreadyPresenting
        ],
        contains(status2),
      );
      expect(
        [
          SuppressionStatus.suppressed,
          SuppressionStatus.unavailable,
          SuppressionStatus.denied,
          SuppressionStatus.alreadyPresenting
        ],
        contains(status3),
      );

      // Clean up
      await NfcWalletSuppression.releaseSuppression();
    });

    testWidgets('rapid sequential releases are handled correctly',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      // Request suppression first
      await NfcWalletSuppression.requestSuppression();

      // Make multiple rapid releases
      final status1 = await NfcWalletSuppression.releaseSuppression();
      final status2 = await NfcWalletSuppression.releaseSuppression();
      final status3 = await NfcWalletSuppression.releaseSuppression();

      // All should return a valid status
      expect(
        [
          SuppressionStatus.notSuppressed,
          SuppressionStatus.unavailable,
        ],
        contains(status1),
      );
      expect(
        [
          SuppressionStatus.notSuppressed,
          SuppressionStatus.unavailable,
        ],
        contains(status2),
      );
      expect(
        [
          SuppressionStatus.notSuppressed,
          SuppressionStatus.unavailable,
        ],
        contains(status3),
      );
    });

    testWidgets('release without prior request returns valid status',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      // Ensure we start from a clean state
      await NfcWalletSuppression.releaseSuppression();

      // Try to release without requesting
      final status = await NfcWalletSuppression.releaseSuppression();

      expect(
        [
          SuppressionStatus.notSuppressed,
          SuppressionStatus.unavailable,
        ],
        contains(status),
      );
    });
  });

  group('State Consistency', () {
    testWidgets('isSuppressed reflects actual suppression state',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      // Start clean
      await NfcWalletSuppression.releaseSuppression();
      var suppressed = await NfcWalletSuppression.isSuppressed();
      expect(suppressed, false);

      // Request and check
      final requestStatus = await NfcWalletSuppression.requestSuppression();
      if (requestStatus == SuppressionStatus.suppressed) {
        suppressed = await NfcWalletSuppression.isSuppressed();
        expect(suppressed, true);
      }

      // Release and check
      await NfcWalletSuppression.releaseSuppression();
      suppressed = await NfcWalletSuppression.isSuppressed();
      expect(suppressed, false);
    });

    testWidgets('multiple isSuppressed calls return consistent results',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      final status = await NfcWalletSuppression.requestSuppression();

      if (status == SuppressionStatus.suppressed) {
        final check1 = await NfcWalletSuppression.isSuppressed();
        final check2 = await NfcWalletSuppression.isSuppressed();
        final check3 = await NfcWalletSuppression.isSuppressed();

        expect(check1, equals(check2));
        expect(check2, equals(check3));
      }

      // Clean up
      await NfcWalletSuppression.releaseSuppression();
    });
  });

  group('Error Scenarios', () {
    testWidgets('operations on unsupported platform return appropriate status',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (supported) {
        // Skip test on supported platforms
        return;
      }

      // All operations should handle unsupported platform gracefully
      final requestStatus = await NfcWalletSuppression.requestSuppression();
      final releaseStatus = await NfcWalletSuppression.releaseSuppression();
      final isSuppressed = await NfcWalletSuppression.isSuppressed();

      // Should not throw exceptions
      expect(requestStatus, isA<SuppressionStatus>());
      expect(releaseStatus, isA<SuppressionStatus>());
      expect(isSuppressed, isA<bool>());

      // Likely returns notSupported or unavailable
      expect(
        [
          SuppressionStatus.notSupported,
          SuppressionStatus.unavailable,
        ],
        contains(requestStatus),
      );
    });
  });

  group('Concurrent Operations', () {
    testWidgets('concurrent requests and releases are handled safely',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      // Launch multiple operations concurrently
      final futures = <Future>[];

      futures.add(NfcWalletSuppression.requestSuppression());
      futures.add(NfcWalletSuppression.isSuppressed());
      futures.add(NfcWalletSuppression.requestSuppression());

      // Wait for all to complete - should not crash or deadlock
      final results = await Future.wait(futures);

      // All should return valid results
      expect(results.length, 3);

      // Clean up
      await NfcWalletSuppression.releaseSuppression();
    });

    testWidgets('interleaved requests and checks maintain consistency',
        (WidgetTester tester) async {
      final supported = await NfcWalletSuppression.isSupported();

      if (!supported) {
        return;
      }

      await NfcWalletSuppression.requestSuppression();
      await NfcWalletSuppression.isSuppressed();
      await NfcWalletSuppression.requestSuppression();
      await NfcWalletSuppression.isSuppressed();
      await NfcWalletSuppression.releaseSuppression();
      final finalCheck = await NfcWalletSuppression.isSuppressed();

      expect(finalCheck, false);
    });
  });
}
