/// Testing utilities for nfc_wallet_suppression plugin.
///
/// This library provides test helpers and mocks for easier testing.
/// Import this in your test files when you need to test NFC wallet suppression.
///
/// Example:
/// ```dart
/// import 'package:nfc_wallet_suppression/testing.dart';
///
/// void main() {
///   late FakeNfcWalletSuppression fake;
///
///   setUp(() {
///     fake = FakeNfcWalletSuppression();
///     NfcWalletSuppressionPlatform.instance = fake;
///   });
///
///   test('my test', () async {
///     fake.setSupported(true);
///     fake.setRequestResult(SuppressionStatus.suppressed);
///
///     final result = await NfcWalletSuppression.requestSuppression();
///     expect(result, SuppressionStatus.suppressed);
///   });
/// }
/// ```
library;

import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_status.dart';

/// A fake implementation of [NfcWalletSuppressionPlatform] for testing.
///
/// This allows you to control the behavior of the plugin in tests without
/// needing real NFC hardware or platform-specific code.
///
/// Use [setSupported], [setRequestResult], etc. to configure behavior.
class FakeNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  bool _isCurrentlySuppressed = false;
  bool _isSupported = true;
  SuppressionStatus _requestResult = SuppressionStatus.suppressed;
  SuppressionStatus _releaseResult = SuppressionStatus.notSuppressed;

  /// Track method calls for verification in tests
  final List<String> methodCalls = [];

  /// Set whether the device supports NFC wallet suppression
  void setSupported(bool supported) {
    _isSupported = supported;
  }

  /// Set the result that [requestSuppression] will return
  void setRequestResult(SuppressionStatus result) {
    _requestResult = result;
  }

  /// Set the result that [releaseSuppression] will return
  void setReleaseResult(SuppressionStatus result) {
    _releaseResult = result;
  }

  /// Manually set the suppressed state (simulates external state change)
  void setSuppressed(bool suppressed) {
    _isCurrentlySuppressed = suppressed;
  }

  /// Reset all state and call history
  void reset() {
    _isCurrentlySuppressed = false;
    _isSupported = true;
    _requestResult = SuppressionStatus.suppressed;
    _releaseResult = SuppressionStatus.notSuppressed;
    methodCalls.clear();
  }

  @override
  Future<bool> isSupported() async {
    methodCalls.add('isSupported');
    return _isSupported;
  }

  @override
  Future<SuppressionStatus> requestSuppression() async {
    methodCalls.add('requestSuppression');
    if (_requestResult == SuppressionStatus.suppressed) {
      _isCurrentlySuppressed = true;
    }
    return _requestResult;
  }

  @override
  Future<SuppressionStatus> releaseSuppression() async {
    methodCalls.add('releaseSuppression');
    if (_releaseResult == SuppressionStatus.notSuppressed) {
      _isCurrentlySuppressed = false;
    }
    return _releaseResult;
  }

  @override
  Future<bool> isSuppressed() async {
    methodCalls.add('isSuppressed');
    return _isCurrentlySuppressed;
  }
}

/// Test helper to create common test scenarios
class NfcWalletSuppressionTestScenarios {
  /// Scenario: Device supports NFC and suppression works normally
  static FakeNfcWalletSuppression supportedDevice() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.suppressed);
    fake.setReleaseResult(SuppressionStatus.notSuppressed);
    return fake;
  }

  /// Scenario: Device does not support NFC
  static FakeNfcWalletSuppression unsupportedDevice() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(false);
    fake.setRequestResult(SuppressionStatus.notSupported);
    fake.setReleaseResult(SuppressionStatus.notSupported);
    return fake;
  }

  /// Scenario: NFC is available but currently unavailable (e.g., disabled)
  static FakeNfcWalletSuppression nfcUnavailable() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.unavailable);
    fake.setReleaseResult(SuppressionStatus.unavailable);
    return fake;
  }

  /// Scenario: User denied permission (iOS)
  static FakeNfcWalletSuppression userDenied() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.denied);
    return fake;
  }

  /// Scenario: Already presenting passes (iOS)
  static FakeNfcWalletSuppression alreadyPresenting() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.alreadyPresenting);
    return fake;
  }

  /// Scenario: User cancelled the suppression prompt (iOS)
  static FakeNfcWalletSuppression userCancelled() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.cancelled);
    return fake;
  }
}
