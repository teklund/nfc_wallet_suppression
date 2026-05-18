import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nfc_wallet_suppression_pigeon_impl.dart';
import 'nfc_wallet_suppression_status.dart';

/// An interface for a platform-specific implementation of the `nfc_wallet_suppression` plugin.
///
/// This class provides methods to request and release suppression of the NFC wallet.
/// The platform-specific implementation should provide their own class that
/// extends this one to be able to call the platform specific API.
abstract class NfcWalletSuppressionPlatform extends PlatformInterface {
  /// Constructs a NfcWalletSuppressionPlatform.
  NfcWalletSuppressionPlatform() : super(token: _token);

  static final Object _token = Object();

  static NfcWalletSuppressionPlatform _instance = PigeonNfcWalletSuppression();

  /// The default instance of [NfcWalletSuppressionPlatform] to use.
  ///
  /// Defaults to [PigeonNfcWalletSuppression].
  static NfcWalletSuppressionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NfcWalletSuppressionPlatform] when
  /// they register themselves.
  static set instance(NfcWalletSuppressionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Request suppression of the NFC wallet.
  ///
  /// Returns a [SuppressionStatus] indicating the result of the operation.
  Future<SuppressionStatus> requestSuppression() {
    throw UnimplementedError('requestSuppression() has not been implemented.');
  }

  /// Release suppression of the NFC wallet.
  ///
  /// Returns a [SuppressionStatus] indicating the result of the operation.
  Future<SuppressionStatus> releaseSuppression() {
    throw UnimplementedError('releaseSuppression() has not been implemented.');
  }

  /// Check if the NFC wallet is currently suppressed.
  ///
  /// Returns `true` if the wallet is currently suppressed, `false` otherwise.
  Future<bool> isSuppressed() {
    throw UnimplementedError('isSuppressed() has not been implemented.');
  }

  /// Check if the device supports NFC wallet suppression.
  ///
  /// Returns `true` if the device has the necessary hardware and OS support
  /// for wallet suppression, `false` otherwise.
  ///
  /// This is useful to check before attempting to request suppression,
  /// allowing you to provide appropriate UI or fallback behavior.
  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }
}
