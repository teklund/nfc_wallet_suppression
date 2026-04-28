import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock implementation to test the abstract platform interface
class MockPlatformImplementation extends NfcWalletSuppressionPlatform
    with MockPlatformInterfaceMixin {
  // Inherits all unimplemented methods to test they throw UnimplementedError
}

void main() {
  group('NfcWalletSuppressionPlatform', () {
    late MockPlatformImplementation mockPlatform;

    setUp(() {
      mockPlatform = MockPlatformImplementation();
    });

    test('requestSuppression throws UnimplementedError by default', () {
      expect(() => mockPlatform.requestSuppression(), throwsUnimplementedError);
    });

    test('releaseSuppression throws UnimplementedError by default', () {
      expect(() => mockPlatform.releaseSuppression(), throwsUnimplementedError);
    });

    test('isSuppressed throws UnimplementedError by default', () {
      expect(() => mockPlatform.isSuppressed(), throwsUnimplementedError);
    });

    test('isSupported throws UnimplementedError by default', () {
      expect(() => mockPlatform.isSupported(), throwsUnimplementedError);
    });

    test('instance can be set and retrieved', () {
      final originalInstance = NfcWalletSuppressionPlatform.instance;

      // Set new instance
      NfcWalletSuppressionPlatform.instance = mockPlatform;
      expect(NfcWalletSuppressionPlatform.instance, equals(mockPlatform));

      // Restore original
      NfcWalletSuppressionPlatform.instance = originalInstance;
    });

    test('instance can be set with MockPlatformInterfaceMixin', () {
      // Verify that a proper mock implementation can be set
      expect(
        () => NfcWalletSuppressionPlatform.instance = mockPlatform,
        returnsNormally,
      );
      expect(NfcWalletSuppressionPlatform.instance, equals(mockPlatform));
    });
  });
}
