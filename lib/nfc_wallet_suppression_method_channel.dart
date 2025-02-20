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
    try {
      final msg = await methodChannel.invokeMethod<String?>(
        'requestSuppression',
      );

      if (msg != null) {
        if (kDebugMode) {
          print(msg);
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e.message ?? "No error message supplied");
      }

      if (e.code == "404") return null;

      return false;
    }

    return true;
  }

  /// Releases the suppression of the NFC wallet.
  ///
  /// Returns `true` if the suppression was successfully released, `false` otherwise.
  @override
  Future<bool?> releaseSuppression() async {
    try {
      final msg = await methodChannel.invokeMethod<String>(
        'releaseSuppression',
      );

      if (msg != null) {
        if (kDebugMode) {
          print(msg);
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e.message ?? "No error message supplied");
      }

      if (e.code == "404") return null;

      return false;
    }
    return true;
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
