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
///     expect(result.status, SuppressionStatus.suppressed);
///   });
/// }
/// ```
library;

import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_result.dart';
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
  SuppressionResult _requestResult = const SuppressionResult(
    status: SuppressionStatus.suppressed,
  );
  SuppressionResult _releaseResult = const SuppressionResult(
    status: SuppressionStatus.notSuppressed,
  );

  /// Track method calls for verification in tests
  final List<String> methodCalls = [];

  /// Set whether the device supports NFC wallet suppression
  void setSupported(bool supported) {
    _isSupported = supported;
  }

  /// Set the status that [requestSuppression] will return.
  ///
  /// Pass [description] when a test needs to assert on the diagnostic text the
  /// platform would have supplied.
  void setRequestResult(SuppressionStatus result, {String? description}) {
    _requestResult = SuppressionResult(
      status: result,
      description: description,
    );
  }

  /// Set the status that [releaseSuppression] will return.
  ///
  /// Pass [description] when a test needs to assert on the diagnostic text the
  /// platform would have supplied.
  void setReleaseResult(SuppressionStatus result, {String? description}) {
    _releaseResult = SuppressionResult(
      status: result,
      description: description,
    );
  }

  /// Manually set the suppressed state (simulates an external state change).
  ///
  /// Note: a subsequent [requestSuppression] or [releaseSuppression] call
  /// updates this flag based on that call's configured result, so this override
  /// reflects state only until the next request/release.
  void setSuppressed(bool suppressed) {
    _isCurrentlySuppressed = suppressed;
  }

  /// Reset all state and call history
  void reset() {
    _isCurrentlySuppressed = false;
    _isSupported = true;
    _requestResult = const SuppressionResult(
      status: SuppressionStatus.suppressed,
    );
    _releaseResult = const SuppressionResult(
      status: SuppressionStatus.notSuppressed,
    );
    methodCalls.clear();
  }

  @override
  Future<bool> isSupported() async {
    methodCalls.add('isSupported');
    return _isSupported;
  }

  @override
  Future<SuppressionResult> requestSuppression() async {
    methodCalls.add('requestSuppression');
    // Suppression is active only when the request reports success; any other
    // outcome leaves it inactive. Assigning (rather than only setting `true`)
    // prevents a stale `true` from surviving a later failed request.
    _isCurrentlySuppressed =
        _requestResult.status == SuppressionStatus.suppressed;
    return _requestResult;
  }

  @override
  Future<SuppressionResult> releaseSuppression() async {
    methodCalls.add('releaseSuppression');
    // `notSuppressed` means the release took effect — which now includes the
    // "nothing was suppressed" case, since release is idempotent. Any other
    // result means it did not take effect, so the prior state is preserved.
    if (_releaseResult.status == SuppressionStatus.notSuppressed) {
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

  /// Scenario: suppression is transiently unavailable (e.g., no foreground
  /// Activity on Android). Retryable without any user action.
  static FakeNfcWalletSuppression nfcUnavailable() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.unavailable);
    return fake;
  }

  /// Scenario: NFC hardware is present but switched off in system settings.
  ///
  /// The case an app would respond to by deep-linking the user to NFC settings.
  static FakeNfcWalletSuppression nfcDisabled() {
    final fake = FakeNfcWalletSuppression();
    fake.setSupported(true);
    fake.setRequestResult(SuppressionStatus.nfcDisabled);
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
