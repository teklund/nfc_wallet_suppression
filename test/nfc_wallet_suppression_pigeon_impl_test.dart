import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_pigeon.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_pigeon_impl.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_platform_interface.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_status.dart';

// Mock implementation for testing
class MockNfcWalletSuppressionApi extends NfcWalletSuppressionApi {
  SuppressionResult? mockRequestResult;
  SuppressionResult? mockReleaseResult;
  bool? mockIsSuppressed;
  bool? mockIsSupported;
  Object? mockException;

  void reset() {
    mockRequestResult = null;
    mockReleaseResult = null;
    mockIsSuppressed = null;
    mockIsSupported = null;
    mockException = null;
  }

  @override
  Future<SuppressionResult> requestSuppression() async {
    if (mockException != null) {
      // ignore: only_throw_errors
      throw mockException!;
    }
    return mockRequestResult ??
        SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: 'Success',
        );
  }

  @override
  Future<SuppressionResult> releaseSuppression() async {
    if (mockException != null) {
      // ignore: only_throw_errors
      throw mockException!;
    }
    return mockReleaseResult ??
        SuppressionResult(
          status: SuppressionStatusCode.notSuppressed,
          message: 'Released',
        );
  }

  @override
  Future<bool> isSuppressed() async {
    if (mockException != null) {
      // ignore: only_throw_errors
      throw mockException!;
    }
    return mockIsSuppressed ?? false;
  }

  @override
  Future<bool> isSupported() async {
    if (mockException != null) {
      // ignore: only_throw_errors
      throw mockException!;
    }
    return mockIsSupported ?? true;
  }
}

// Removed TestablePigeonNfcWalletSuppression as we now test the real implementation

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PigeonNfcWalletSuppression', () {
    late PigeonNfcWalletSuppression platform;
    late MockNfcWalletSuppressionApi mockApi;

    setUp(() {
      mockApi = MockNfcWalletSuppressionApi();
      platform = PigeonNfcWalletSuppression(api: mockApi);
    });

    tearDown(() {
      mockApi.reset();
    });

    test('is a NfcWalletSuppressionPlatform', () {
      expect(platform, isA<NfcWalletSuppressionPlatform>());
    });

    group('requestSuppression', () {
      test('returns suppressed on success', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: 'Suppressed',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.suppressed);
      });

      test('returns notSupported status', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.notSupported,
          message: 'Not supported',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.notSupported);
      });

      test('returns alreadyPresenting status', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.alreadyPresenting,
          message: 'Already presenting',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.alreadyPresenting);
      });

      test('returns cancelled status', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.cancelled,
          message: 'Cancelled',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.cancelled);
      });

      test('returns denied status', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.denied,
          message: 'Denied',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.denied);
      });

      test('returns unavailable status', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.unavailable,
          message: 'Unavailable',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.unavailable);
      });

      test('returns unknown status', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.unknown,
          message: 'Unknown',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.unknown);
      });

      test('returns unknown on exception', () async {
        mockApi.mockException = Exception('Test error');

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.unknown);
      });

      test('handles null message gracefully', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: null,
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.suppressed);
      });

      test('handles empty message gracefully', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: '',
        );

        final result = await platform.requestSuppression();
        expect(result, SuppressionStatus.suppressed);
      });
    });

    group('releaseSuppression', () {
      test('returns notSuppressed on success', () async {
        mockApi.mockReleaseResult = SuppressionResult(
          status: SuppressionStatusCode.notSuppressed,
          message: 'Released',
        );

        final result = await platform.releaseSuppression();
        expect(result, SuppressionStatus.notSuppressed);
      });

      test('returns unavailable when no active suppression', () async {
        mockApi.mockReleaseResult = SuppressionResult(
          status: SuppressionStatusCode.unavailable,
          message: 'No active suppression',
        );

        final result = await platform.releaseSuppression();
        expect(result, SuppressionStatus.unavailable);
      });

      test('returns notSupported status', () async {
        mockApi.mockReleaseResult = SuppressionResult(
          status: SuppressionStatusCode.notSupported,
          message: 'Not supported',
        );

        final result = await platform.releaseSuppression();
        expect(result, SuppressionStatus.notSupported);
      });

      test('returns unknown on exception', () async {
        mockApi.mockException = Exception('Test error');

        final result = await platform.releaseSuppression();
        expect(result, SuppressionStatus.unknown);
      });

      test('handles null message gracefully', () async {
        mockApi.mockReleaseResult = SuppressionResult(
          status: SuppressionStatusCode.notSuppressed,
          message: null,
        );

        final result = await platform.releaseSuppression();
        expect(result, SuppressionStatus.notSuppressed);
      });
    });

    group('isSuppressed', () {
      test('returns true when suppressed', () async {
        mockApi.mockIsSuppressed = true;

        final result = await platform.isSuppressed();
        expect(result, true);
      });

      test('returns false when not suppressed', () async {
        mockApi.mockIsSuppressed = false;

        final result = await platform.isSuppressed();
        expect(result, false);
      });

      test('returns false on exception', () async {
        mockApi.mockException = Exception('Test error');

        final result = await platform.isSuppressed();
        expect(result, false);
      });
    });

    group('isSupported', () {
      test('returns true when supported', () async {
        mockApi.mockIsSupported = true;

        final result = await platform.isSupported();
        expect(result, true);
      });

      test('returns false when not supported', () async {
        mockApi.mockIsSupported = false;

        final result = await platform.isSupported();
        expect(result, false);
      });

      test('returns false on exception', () async {
        mockApi.mockException = Exception('Test error');

        final result = await platform.isSupported();
        expect(result, false);
      });
    });

    group('status conversion', () {
      test('converts all status codes correctly', () async {
        final statusTests = <SuppressionStatusCode, SuppressionStatus>{
          SuppressionStatusCode.suppressed: SuppressionStatus.suppressed,
          SuppressionStatusCode.notSuppressed: SuppressionStatus.notSuppressed,
          SuppressionStatusCode.notSupported: SuppressionStatus.notSupported,
          SuppressionStatusCode.alreadyPresenting:
              SuppressionStatus.alreadyPresenting,
          SuppressionStatusCode.cancelled: SuppressionStatus.cancelled,
          SuppressionStatusCode.denied: SuppressionStatus.denied,
          SuppressionStatusCode.unavailable: SuppressionStatus.unavailable,
          SuppressionStatusCode.unknown: SuppressionStatus.unknown,
        };

        for (final entry in statusTests.entries) {
          mockApi.mockRequestResult = SuppressionResult(
            status: entry.key,
            message: 'Test',
          );

          final result = await platform.requestSuppression();
          expect(
            result,
            entry.value,
            reason: 'Failed to convert ${entry.key} to ${entry.value}',
          );
        }
      });
    });

    group('error scenarios', () {
      test('handles generic exception', () async {
        mockApi.mockException = Exception('Generic error');

        expect(await platform.requestSuppression(), SuppressionStatus.unknown);
        expect(await platform.releaseSuppression(), SuppressionStatus.unknown);
      });

      test('handles state error', () async {
        mockApi.mockException = StateError('Invalid state');

        expect(await platform.requestSuppression(), SuppressionStatus.unknown);
        expect(await platform.releaseSuppression(), SuppressionStatus.unknown);
      });

      test('handles argument error', () async {
        mockApi.mockException = ArgumentError('Invalid argument');

        expect(await platform.requestSuppression(), SuppressionStatus.unknown);
        expect(await platform.releaseSuppression(), SuppressionStatus.unknown);
      });

      test('isSuppressed returns false on any exception', () async {
        mockApi.mockException = Exception('Error');
        expect(await platform.isSuppressed(), false);
      });

      test('isSupported returns false on any exception', () async {
        mockApi.mockException = Exception('Error');
        expect(await platform.isSupported(), false);
      });
    });

    group('edge cases', () {
      test('handles rapid successive requestSuppression calls', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: 'Success',
        );

        final results = await Future.wait([
          platform.requestSuppression(),
          platform.requestSuppression(),
          platform.requestSuppression(),
        ]);

        expect(results.every((r) => r == SuppressionStatus.suppressed), true);
      });

      test('handles rapid successive releaseSuppression calls', () async {
        mockApi.mockReleaseResult = SuppressionResult(
          status: SuppressionStatusCode.notSuppressed,
          message: 'Released',
        );

        final results = await Future.wait([
          platform.releaseSuppression(),
          platform.releaseSuppression(),
          platform.releaseSuppression(),
        ]);

        expect(
          results.every((r) => r == SuppressionStatus.notSuppressed),
          true,
        );
      });

      test('handles interleaved operations', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: 'Success',
        );
        mockApi.mockReleaseResult = SuppressionResult(
          status: SuppressionStatusCode.notSuppressed,
          message: 'Released',
        );
        mockApi.mockIsSuppressed = true;
        mockApi.mockIsSupported = true;

        final results = await Future.wait([
          platform.requestSuppression(),
          platform.isSuppressed(),
          platform.releaseSuppression(),
          platform.isSupported(),
        ]);

        expect(results[0], SuppressionStatus.suppressed);
        expect(results[1], true);
        expect(results[2], SuppressionStatus.notSuppressed);
        expect(results[3], true);
      });

      test('state changes do not affect pending operations', () async {
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.suppressed,
          message: 'Success',
        );

        // Start operation
        final future = platform.requestSuppression();

        // Change mock state
        mockApi.mockRequestResult = SuppressionResult(
          status: SuppressionStatusCode.unknown,
          message: 'Changed',
        );

        // Original operation should complete with original result
        final result = await future;
        expect(result, SuppressionStatus.suppressed);
      });
    });

    group('default instance', () {
      test('PigeonNfcWalletSuppression can be instantiated', () {
        final instance = PigeonNfcWalletSuppression();
        expect(instance, isA<NfcWalletSuppressionPlatform>());
      });
    });
  });
}
