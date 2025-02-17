import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nfc_wallet_suppression_platform_interface.dart';

/// An implementation of [NfcWalletSuppressionPlatform] that uses method channels.
class MethodChannelNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nfc_wallet_suppression');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
