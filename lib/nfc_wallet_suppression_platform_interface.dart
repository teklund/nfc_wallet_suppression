import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nfc_wallet_suppression_method_channel.dart';

abstract class NfcWalletSuppressionPlatform extends PlatformInterface {
  /// Constructs a NfcWalletSuppressionPlatform.
  NfcWalletSuppressionPlatform() : super(token: _token);

  static final Object _token = Object();

  static NfcWalletSuppressionPlatform _instance = MethodChannelNfcWalletSuppression();

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
