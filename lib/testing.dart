/// Test support for code that uses `nfc_wallet_suppression`.
///
/// Install a [FakeNfcWalletSuppression] as the platform implementation, and
/// calls to [NfcWalletSuppression] return what you configure instead of
/// reaching the device. In widget tests, install it before `pumpWidget`.
///
/// ```dart
/// import 'package:flutter_test/flutter_test.dart';
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
///   test('reports a denied request', () async {
///     fake.requestResult =
///         const SuppressionResult(status: SuppressionStatus.denied);
///
///     final result = await NfcWalletSuppression.requestSuppression();
///     expect(result.status, SuppressionStatus.denied);
///     expect(fake.methodCalls, ['requestSuppression']);
///   });
/// }
/// ```
///
/// Integration tests on a device need no fake; they use the real plugin.
///
/// @docImport 'src/nfc_wallet_suppression.dart';
/// @docImport 'src/nfc_wallet_suppression_testing.dart';
library;

export 'src/nfc_wallet_suppression_platform_interface.dart';
export 'src/nfc_wallet_suppression_result.dart';
export 'src/nfc_wallet_suppression_status.dart';
export 'src/nfc_wallet_suppression_testing.dart';
