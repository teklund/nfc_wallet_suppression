/// Stops Apple Wallet and other wallet apps from appearing at NFC readers
/// while your app is in the foreground.
///
/// Call [NfcWalletSuppression.requestSuppression] before the phone is held to
/// an NFC reader, and [NfcWalletSuppression.releaseSuppression] when you are
/// done:
///
/// ```dart
/// final result = await NfcWalletSuppression.requestSuppression();
/// if (result.isSuppressed) {
///   // Hold the phone to the NFC reader.
/// }
/// await NfcWalletSuppression.releaseSuppression();
/// ```
///
/// Release when you are done, whatever the request returned;
/// [NfcWalletSuppression.releaseSuppression] shows how to make that certain
/// with `finally`.
///
/// Both calls return a [SuppressionResult]; branch on its [SuppressionStatus].
/// For tests, import `package:nfc_wallet_suppression/testing.dart`.
///
/// @docImport 'src/nfc_wallet_suppression.dart';
/// @docImport 'src/nfc_wallet_suppression_result.dart';
/// @docImport 'src/nfc_wallet_suppression_status.dart';
library;

export 'src/nfc_wallet_suppression.dart';
export 'src/nfc_wallet_suppression_result.dart';
export 'src/nfc_wallet_suppression_status.dart';
