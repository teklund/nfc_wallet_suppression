/// A Flutter plugin that keeps Apple Wallet (Apple Pay) and other wallet apps
/// from popping up at NFC readers while your app is in the foreground.
///
/// Near a contactless payment terminal or NFC reader, the phone offers its
/// wallet. Suppression holds it back while your app is the one the user should
/// be looking at, for example while it shows a ticket barcode at a gate that
/// also has an NFC reader. It does not read or write NFC tags.
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
