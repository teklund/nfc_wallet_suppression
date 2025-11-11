import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_status.dart';

/// An implementation of [NfcWalletSuppressionPlatform] that uses method channels.
class MethodChannelNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// Creates a method channel implementation.
  ///
  /// The [channel] parameter allows injecting a custom MethodChannel for testing.
  /// If not provided, uses the default channel name.
  MethodChannelNfcWalletSuppression({MethodChannel? channel})
      : methodChannel =
            channel ?? const MethodChannel('nfc_wallet_suppression');

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel;

  /// Requests suppression of the NFC wallet.
  ///
  /// Returns `true` if the suppression was successfully requested, `false` otherwise.
  @override
  Future<SuppressionStatus> requestSuppression() async {
    try {
      final msg = await methodChannel.invokeMethod<String?>(
        'requestSuppression',
      );

      if (msg != null && kDebugMode) {
        developer.log(msg, name: 'nfc_wallet_suppression');
      }
      return SuppressionStatus.suppressed;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        developer.log(
          'Request suppression error: ${e.message ?? "No error message"}',
          name: 'nfc_wallet_suppression',
          error: e,
        );
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

      if (msg != null && kDebugMode) {
        developer.log(msg, name: 'nfc_wallet_suppression');
      }
      return SuppressionStatus.notSuppressed;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        developer.log(
          'Release suppression error: ${e.message ?? "No error message"}',
          name: 'nfc_wallet_suppression',
          error: e,
        );
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
          developer.log(
            'Unknown suppression status code: $code',
            name: 'nfc_wallet_suppression',
          );
        }
        return SuppressionStatus.unknown;
    }
  }

  /// Checks if the NFC wallet is currently suppressed.
  ///
  /// Returns `true` if the wallet is suppressed, `false` otherwise.
  @override
  Future<bool> isSuppressed() async {
    try {
      final success = await methodChannel.invokeMethod<bool>('isSuppressed');
      return success ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error checking suppression status: ${e.message ?? "No error message"}',
          name: 'nfc_wallet_suppression',
          error: e,
        );
      }
      // Return false on error - assume not suppressed if we can't determine state
      return false;
    }
  }

  /// Checks if the device supports NFC wallet suppression.
  ///
  /// Returns `true` if the device has NFC hardware and OS support, `false` otherwise.
  @override
  Future<bool> isSupported() async {
    try {
      final supported = await methodChannel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error checking platform support: ${e.message ?? "No error message"}',
          name: 'nfc_wallet_suppression',
          error: e,
        );
      }
      // Return false on error - assume not supported if we can't determine capability
      return false;
    }
  }
}
