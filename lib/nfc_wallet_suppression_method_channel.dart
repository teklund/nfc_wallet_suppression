import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nfc_wallet_suppression_platform_interface.dart';

/// An implementation of [NfcWalletSuppressionPlatform] that uses method channels.
class MethodChannelNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nfc_wallet_suppression');

  /// Requests suppression of the NFC wallet.
  ///
  /// Returns `true` if the suppression was successfully requested, `false` otherwise.
  @override
  Future<bool?> requestSuppression() async {
    final success = await methodChannel.invokeMethod<bool>(
      'requestSuppression',
    );
    return success;
  }

  /// Releases the suppression of the NFC wallet.
  ///
  /// Returns `true` if the suppression was successfully released, `false` otherwise.
  @override
  Future<bool?> releaseSuppression() async {
    final success = await methodChannel.invokeMethod<bool>(
      'releaseSuppression',
    );
    return success;
  }

  /// Checks if the NFC wallet is currently suppressed.
  ///
  /// Returns `true` if the wallet is suppressed, `false` otherwise.
  @override
  Future<bool?> isSuppressed() async {
    final success = await methodChannel.invokeMethod<bool>('isSuppressed');
    return success;
  }
}
