import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'nfc_wallet_suppression_pigeon.dart';
import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_status.dart';

/// Pigeon-based implementation of [NfcWalletSuppressionPlatform]
///
/// This implementation uses Pigeon-generated type-safe platform channels
/// to communicate with native iOS and Android code, eliminating string-based
/// error code matching and providing compile-time safety.
class PigeonNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// The Pigeon-generated API instance
  @visibleForTesting
  final NfcWalletSuppressionApi api;

  /// Creates a [PigeonNfcWalletSuppression] with an optional generated API injection
  PigeonNfcWalletSuppression({NfcWalletSuppressionApi? api})
    : api = api ?? NfcWalletSuppressionApi();

  @override
  Future<SuppressionStatus> requestSuppression() async {
    try {
      final result = await api.requestSuppression();

      if (result.message != null && kDebugMode) {
        developer.log(result.message!, name: 'nfc_wallet_suppression');
      }

      return _convertStatus(result.status);
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error requesting suppression: $e',
          name: 'nfc_wallet_suppression',
          error: e,
        );
      }
      return SuppressionStatus.unknown;
    }
  }

  @override
  Future<SuppressionStatus> releaseSuppression() async {
    try {
      final result = await api.releaseSuppression();

      if (result.message != null && kDebugMode) {
        developer.log(result.message!, name: 'nfc_wallet_suppression');
      }

      return _convertStatus(result.status);
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error releasing suppression: $e',
          name: 'nfc_wallet_suppression',
          error: e,
        );
      }
      return SuppressionStatus.unknown;
    }
  }

  @override
  Future<bool> isSuppressed() async {
    try {
      return await api.isSuppressed();
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error checking suppression status: $e',
          name: 'nfc_wallet_suppression',
          error: e,
        );
      }
      return false;
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      return await api.isSupported();
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error checking platform support: $e',
          name: 'nfc_wallet_suppression',
          error: e,
        );
      }
      return false;
    }
  }

  /// Converts Pigeon-generated status to plugin status enum
  ///
  /// This provides a mapping between the Pigeon enum and the public API enum,
  /// maintaining backward compatibility with existing code.
  SuppressionStatus _convertStatus(SuppressionStatusCode status) {
    switch (status) {
      case SuppressionStatusCode.suppressed:
        return SuppressionStatus.suppressed;
      case SuppressionStatusCode.notSuppressed:
        return SuppressionStatus.notSuppressed;
      case SuppressionStatusCode.notSupported:
        return SuppressionStatus.notSupported;
      case SuppressionStatusCode.alreadyPresenting:
        return SuppressionStatus.alreadyPresenting;
      case SuppressionStatusCode.cancelled:
        return SuppressionStatus.cancelled;
      case SuppressionStatusCode.denied:
        return SuppressionStatus.denied;
      case SuppressionStatusCode.unavailable:
        return SuppressionStatus.unavailable;
      case SuppressionStatusCode.unknown:
        return SuppressionStatus.unknown;
    }
  }
}
