import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nfc_wallet_suppression_status.dart';
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
  Future<SuppressionStatus> requestSuppression() async {
    try {
      final msg = await methodChannel.invokeMethod<String?>(
        'requestSuppression',
      );

      if (msg != null) {
        if (kDebugMode) {
          print(msg);
        }
      }
      return SuppressionStatus.suppressed;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e.message ?? "No error message supplied");
      }
      return _suppressionStatus(e.code);
    }
  }

  /// Releases the suppression of the NFC wallet.
  ///
  /// Returns `true` if the suppression was successfully released, `false` otherwise.
  @override
  Future<SuppressionStatus> releaseSuppression() async {
    try {
      final msg = await methodChannel.invokeMethod<String>(
        'releaseSuppression',
      );

      if (msg != null) {
        if (kDebugMode) {
          print(msg);
        }
      }
      return SuppressionStatus.notSuppressed;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e.message ?? "No error message supplied");
      }
      return _suppressionStatus(e.code);
    }
  }

  SuppressionStatus _suppressionStatus(String code) {
    switch (code) {
      case "NOT_SUPPORTED":
        return SuppressionStatus.notSupported;
      case "ALREADY_PRESENTING":
        return SuppressionStatus.alreadyPresenting;
      case "CANCELLED":
        return SuppressionStatus.cancelled;
      case "DENIED":
        return SuppressionStatus.denied;
      case "UNAVAILABLE":
        return SuppressionStatus.unavailable;
      case "UNKNOWN":
      default:
        if (kDebugMode) {
          print("Unknown code: $code");
        }
        return SuppressionStatus.unknown;
    }
  }

  /// Checks if the NFC wallet is currently suppressed.
  ///
  /// Returns `true` if the wallet is suppressed, `false` otherwise.
  @override
  Future<bool> isSuppressed() async {
    final success = await methodChannel.invokeMethod<bool>('isSuppressed');
    return success ?? false;
  }
}
