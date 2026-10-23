import 'package:flutter/foundation.dart';

import 'nfc_wallet_suppression_pigeon_impl.dart';
import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_stub.dart';

/// The implementation for [platform]: native on Android and iOS, and the stub
/// everywhere else, including the web.
///
/// [isWeb] is checked first: on the web, [platform] is the browser's OS.
NfcWalletSuppressionPlatform defaultPlatform(
  TargetPlatform platform, {
  required bool isWeb,
}) {
  if (!isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS)) {
    return PigeonNfcWalletSuppression();
  }
  return StubNfcWalletSuppression();
}
