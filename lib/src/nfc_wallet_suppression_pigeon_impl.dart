import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

// The generated wire types include their own `SuppressionResult`, distinct from
// the public one this class returns. Prefixed so every use site says which layer
// it belongs to.
import 'nfc_wallet_suppression_pigeon.dart' as pigeon;
import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_result.dart';
import 'nfc_wallet_suppression_status.dart';

/// Pigeon-based implementation of [NfcWalletSuppressionPlatform]
///
/// This implementation uses Pigeon-generated type-safe platform channels
/// to communicate with native iOS and Android code, eliminating string-based
/// error code matching and providing compile-time safety.
class PigeonNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// The Pigeon-generated API instance
  @visibleForTesting
  final pigeon.NfcWalletSuppressionApi api;

  /// Creates a [PigeonNfcWalletSuppression] with an optional generated API injection
  PigeonNfcWalletSuppression({pigeon.NfcWalletSuppressionApi? api})
    : api = api ?? pigeon.NfcWalletSuppressionApi();

  @override
  Future<SuppressionResult> requestSuppression() async {
    try {
      return _convertResult(await api.requestSuppression());
    } catch (e) {
      return _failure('Error requesting suppression', e);
    }
  }

  @override
  Future<SuppressionResult> releaseSuppression() async {
    try {
      return _convertResult(await api.releaseSuppression());
    } catch (e) {
      return _failure('Error releasing suppression', e);
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

  /// Converts a Pigeon result into the public [SuppressionResult].
  ///
  /// The platform's `message` is surfaced as [SuppressionResult.description]
  /// rather than only being logged, so callers can include it in their own
  /// diagnostics.
  SuppressionResult _convertResult(pigeon.SuppressionResult result) {
    if (result.message != null && kDebugMode) {
      developer.log(result.message!, name: 'nfc_wallet_suppression');
    }
    return SuppressionResult(
      status: _convertStatus(result.status),
      description: result.message,
    );
  }

  /// Builds the result for a platform-channel failure.
  ///
  /// The call never reached the platform, or its reply could not be decoded, so
  /// the real outcome is genuinely unknown — suppression may or may not have
  /// changed. The exception text becomes the description so it is not lost.
  SuppressionResult _failure(String context, Object error) {
    if (kDebugMode) {
      developer.log(
        '$context: $error',
        name: 'nfc_wallet_suppression',
        error: error,
      );
    }
    return SuppressionResult(
      status: SuppressionStatus.unknown,
      description: '$context: $error',
    );
  }

  /// Converts Pigeon-generated status to plugin status enum
  ///
  /// This provides a mapping between the Pigeon enum and the public API enum,
  /// maintaining backward compatibility with existing code.
  SuppressionStatus _convertStatus(pigeon.SuppressionStatusCode status) {
    switch (status) {
      case pigeon.SuppressionStatusCode.suppressed:
        return SuppressionStatus.suppressed;
      case pigeon.SuppressionStatusCode.notSuppressed:
        return SuppressionStatus.notSuppressed;
      case pigeon.SuppressionStatusCode.notSupported:
        return SuppressionStatus.notSupported;
      case pigeon.SuppressionStatusCode.alreadyPresenting:
        return SuppressionStatus.alreadyPresenting;
      case pigeon.SuppressionStatusCode.cancelled:
        return SuppressionStatus.cancelled;
      case pigeon.SuppressionStatusCode.denied:
        return SuppressionStatus.denied;
      case pigeon.SuppressionStatusCode.unavailable:
        return SuppressionStatus.unavailable;
      case pigeon.SuppressionStatusCode.unknown:
        return SuppressionStatus.unknown;
      case pigeon.SuppressionStatusCode.nfcDisabled:
        return SuppressionStatus.nfcDisabled;
    }
  }
}
