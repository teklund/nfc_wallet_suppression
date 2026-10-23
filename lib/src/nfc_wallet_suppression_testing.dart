/// Testing utilities for the nfc_wallet_suppression plugin.
///
/// Install a [FakeNfcWalletSuppression] as the platform implementation to
/// control what the plugin returns in tests:
///
/// ```dart
/// import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
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
///   test('handles a denied request', () async {
///     fake.requestResult =
///         const SuppressionResult(status: SuppressionStatus.denied);
///
///     final result = await NfcWalletSuppression.requestSuppression();
///     expect(result.status, SuppressionStatus.denied);
///   });
/// }
/// ```
library;

import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_result.dart';
import 'nfc_wallet_suppression_status.dart';

/// A fake [NfcWalletSuppressionPlatform] for tests.
///
/// Set what each method returns through the constructor or the properties.
/// Like the real plugin, a request updates [suppressed] from its result, and a
/// successful release clears it.
class FakeNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// Creates a fake for a supported device on which requests and releases
  /// succeed, unless configured otherwise.
  FakeNfcWalletSuppression({
    this.supported = true,
    this.requestResult = const SuppressionResult(
      status: SuppressionStatus.suppressed,
    ),
    this.releaseResult = const SuppressionResult(
      status: SuppressionStatus.notSuppressed,
    ),
    this.suppressed = false,
  });

  /// What [isSupported] returns.
  bool supported;

  /// What [requestSuppression] returns.
  SuppressionResult requestResult;

  /// What [releaseSuppression] returns.
  SuppressionResult releaseResult;

  /// Whether suppression is held, as [isSuppressed] reports it.
  bool suppressed;

  /// The platform methods called so far, in order.
  final List<String> methodCalls = [];

  @override
  Future<bool> isSupported() async {
    methodCalls.add('isSupported');
    return supported;
  }

  @override
  Future<SuppressionResult> requestSuppression() async {
    methodCalls.add('requestSuppression');
    suppressed = requestResult.isSuppressed;
    return requestResult;
  }

  @override
  Future<SuppressionResult> releaseSuppression() async {
    methodCalls.add('releaseSuppression');
    // Any other result means the release did not take effect.
    if (releaseResult.isReleased) suppressed = false;
    return releaseResult;
  }

  @override
  Future<bool> isSuppressed() async {
    methodCalls.add('isSuppressed');
    return suppressed;
  }
}
