import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nfc_wallet_suppression_method_channel.dart';
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

  static NfcWalletSuppressionPlatform _instance =
      MethodChannelNfcWalletSuppression();

  /// The default instance of [NfcWalletSuppressionPlatform] to use.
  ///
  /// Defaults to [MethodChannelNfcWalletSuppression].
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
  /// Returns `true` if the request was successful, `false` if it failed, and `null`
  /// if the platform does not support this method.
  Future<SuppressionStatus> requestSuppression() {
    throw UnimplementedError('requestSuppression() has not been implemented.');
  }

  /// Release suppression of the NFC wallet.
  ///
  /// Returns `true` if the release was successful, `false` if it failed, and `null`
  /// if the platform does not support this method.
  Future<SuppressionStatus> releaseSuppression() {
    throw UnimplementedError('releaseSuppression() has not been implemented.');
  }

  /// Check if the NFC wallet is currently suppressed.
  ///
  /// Returns `true` if the wallet is suppressed, `false` if it is not, and `null`
  /// if the platform does not support this method.
  Future<bool> isSuppressed() {
    throw UnimplementedError('isSuppressed() has not been implemented.');
  }
}
