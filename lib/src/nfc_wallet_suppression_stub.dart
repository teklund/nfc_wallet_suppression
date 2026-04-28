import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_status.dart';

/// Stub implementation of [NfcWalletSuppressionPlatform] for unsupported platforms.
///
/// This implementation is used on platforms that don't support NFC wallet
/// suppression (web, macOS, Linux, Windows). All methods return appropriate
/// "not supported" responses without throwing exceptions.
///
/// This ensures that apps using this plugin on unsupported platforms
/// gracefully degrade instead of crashing with `MissingPluginException`.
class StubNfcWalletSuppression extends NfcWalletSuppressionPlatform {
  /// Creates a stub implementation for unsupported platforms.
  StubNfcWalletSuppression();

  /// Registers this class as the default instance of [NfcWalletSuppressionPlatform].
  ///
  /// On web, Flutter's plugin registrant calls `registerWith(Registrar registrar)`;
  /// on macOS, Linux, and Windows it calls `registerWith()` with no arguments.
  /// The optional [registrar] parameter (typed as `Object?` to avoid pulling in
  /// `flutter_web_plugins` on non-web builds) accommodates both contracts so a
  /// single stub can serve every non-mobile platform. The argument is ignored
  /// because this stub does not need to register any platform channels.
  static void registerWith([Object? registrar]) {
    NfcWalletSuppressionPlatform.instance = StubNfcWalletSuppression();
  }

  @override
  Future<SuppressionStatus> requestSuppression() async {
    return SuppressionStatus.notSupported;
  }

  @override
  Future<SuppressionStatus> releaseSuppression() async {
    return SuppressionStatus.notSuppressed;
  }

  @override
  Future<bool> isSuppressed() async {
    return false;
  }

  @override
  Future<bool> isSupported() async {
    return false;
  }
}
