/// @docImport 'nfc_wallet_suppression.dart';
/// @docImport 'nfc_wallet_suppression_testing.dart';
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nfc_wallet_suppression_pigeon_impl.dart';
import 'nfc_wallet_suppression_result.dart';

/// The platform implementation behind [NfcWalletSuppression].
///
/// Tests replace [instance] with a [FakeNfcWalletSuppression], or with a mock
/// that mixes in `MockPlatformInterfaceMixin` from
/// `package:plugin_platform_interface`.
abstract class NfcWalletSuppressionPlatform extends PlatformInterface {
  /// Constructs an [NfcWalletSuppressionPlatform].
  NfcWalletSuppressionPlatform() : super(token: _token);

  static final Object _token = Object();

  static NfcWalletSuppressionPlatform _instance = PigeonNfcWalletSuppression();

  /// The implementation the plugin calls: native on Android and iOS, and a
  /// stub that reports `notSupported` on other platforms.
  static NfcWalletSuppressionPlatform get instance => _instance;

  /// Replaces the implementation, for example with a [FakeNfcWalletSuppression]
  /// in tests.
  ///
  /// It must extend this class, or mix in `MockPlatformInterfaceMixin`, which
  /// is accepted only while assertions are enabled, as in tests.
  static set instance(NfcWalletSuppressionPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Requests suppression, as [NfcWalletSuppression.requestSuppression]
  /// describes.
  Future<SuppressionResult> requestSuppression() {
    throw UnimplementedError('requestSuppression() has not been implemented.');
  }

  /// Ends suppression, as [NfcWalletSuppression.releaseSuppression] describes.
  Future<SuppressionResult> releaseSuppression() {
    throw UnimplementedError('releaseSuppression() has not been implemented.');
  }

  /// Whether suppression is in effect, as [NfcWalletSuppression.isSuppressed]
  /// describes.
  Future<bool> isSuppressed() {
    throw UnimplementedError('isSuppressed() has not been implemented.');
  }

  /// Whether this device has what suppression needs, as
  /// [NfcWalletSuppression.isSupported] describes.
  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }
}
