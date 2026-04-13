import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
import 'package:nfc_wallet_suppression/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock that allows setting return values for error testing
class ErrorScenarioMockPlatform
    with MockPlatformInterfaceMixin
    implements NfcWalletSuppressionPlatform {
  SuppressionStatus _nextRequestStatus = SuppressionStatus.suppressed;
  SuppressionStatus _nextReleaseStatus = SuppressionStatus.notSuppressed;
  bool _isSupported = true;

  void setNextRequestStatus(SuppressionStatus status) {
    _nextRequestStatus = status;
  }

  void setNextReleaseStatus(SuppressionStatus status) {
    _nextReleaseStatus = status;
  }

  void setIsSupported(bool supported) {
    _isSupported = supported;
  }

  @override
  Future<SuppressionStatus> requestSuppression() {
    return Future.value(_nextRequestStatus);
  }

  @override
  Future<SuppressionStatus> releaseSuppression() {
    return Future.value(_nextReleaseStatus);
  }

  @override
  Future<bool> isSuppressed() {
    return Future.value(false);
  }

  @override
  Future<bool> isSupported() {
    return Future.value(_isSupported);
  }
}

void main() {
  group('NfcWalletSuppression Error Handling', () {
    late ErrorScenarioMockPlatform mockPlatform;

    setUp(() {
      mockPlatform = ErrorScenarioMockPlatform();
      NfcWalletSuppressionPlatform.instance = mockPlatform;
    });

    test('requestSuppression handles denied status', () async {
      mockPlatform.setNextRequestStatus(SuppressionStatus.denied);
      expect(
        await NfcWalletSuppression.requestSuppression(),
        SuppressionStatus.denied,
      );
    });

    test('requestSuppression handles unavailable status', () async {
      mockPlatform.setNextRequestStatus(SuppressionStatus.unavailable);
      expect(
        await NfcWalletSuppression.requestSuppression(),
        SuppressionStatus.unavailable,
      );
    });

    test('requestSuppression handles notSupported status', () async {
      mockPlatform.setNextRequestStatus(SuppressionStatus.notSupported);
      expect(
        await NfcWalletSuppression.requestSuppression(),
        SuppressionStatus.notSupported,
      );
    });

    test('requestSuppression handles alreadyPresenting status', () async {
      mockPlatform.setNextRequestStatus(SuppressionStatus.alreadyPresenting);
      expect(
        await NfcWalletSuppression.requestSuppression(),
        SuppressionStatus.alreadyPresenting,
      );
    });

    test('releaseSuppression handles failure status', () async {
      mockPlatform.setNextReleaseStatus(SuppressionStatus.unknown);
      expect(
        await NfcWalletSuppression.releaseSuppression(),
        SuppressionStatus.unknown,
      );
    });

    test('isSupported handles false', () async {
      mockPlatform.setIsSupported(false);
      expect(await NfcWalletSuppression.isSupported(), false);
    });
  });
}
