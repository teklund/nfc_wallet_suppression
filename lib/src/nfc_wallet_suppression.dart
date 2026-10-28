import 'nfc_wallet_suppression_platform_interface.dart';
import 'nfc_wallet_suppression_result.dart';
import 'nfc_wallet_suppression_status.dart';

/// Static methods that keep Apple Wallet (Apple Pay) and other wallet apps
/// from popping up at NFC readers.
///
/// Requests and releases return a [SuppressionResult]; branch on its
/// [SuppressionStatus].
///
/// ## Platform support
///
/// - **iOS** 13.0+ on iPhone, with the
///   `com.apple.developer.passkit.pass-presentation-suppression` entitlement
///   from Apple. iPad and iPod touch have no NFC, so there is nothing to
///   suppress on them.
/// - **Android** 7.0+ (API 24) with NFC hardware. NFC must be switched on for
///   suppression to take effect.
/// - **Web and desktop**: requests return [SuppressionStatus.notSupported].
///
/// ## Suppression lifecycle
///
/// - A [requestSuppression] that returns [SuppressionStatus.suppressed] or
///   [SuppressionStatus.nfcDisabled] holds suppression until you call
///   [releaseSuppression] or the app is closed. Requesting again while it is
///   held reports on that hold rather than adding another, so one release
///   ends it.
/// - Suppression only takes effect while your app is in the foreground. In
///   the background the wallet works normally, and suppression resumes by
///   itself when the app returns. On Android the same applies while the
///   Activity is paused, as behind the share sheet or a permission dialog,
///   and while NFC is switched off. Flutter reports a paused Activity as
///   `AppLifecycleState.inactive`, but it also reports `inactive` under the
///   notification shade, where suppression stays in effect, and in split
///   screen while the user is in the other app, where it stays in effect on
///   Android 10 and later. On Android, [isSuppressed] tells them apart.
/// - On Android, suppression uses the Activity's one reader mode, so a tag
///   reader or other code that uses reader mode on the same Activity takes it
///   over. Once that code stops, suppression is still held but not in effect,
///   and [isSuppressed] still returns `true`. Release just before starting
///   such code, and request again once its stop call has completed.
abstract final class NfcWalletSuppression {
  /// Requests that the wallet stop popping up at NFC readers.
  ///
  /// Request when the screen that needs it appears, not when the user reaches
  /// the reader: on iOS, suppression is not active until the request
  /// completes. Apple documents that the first request after install shows a
  /// one-time alert that Apple Pay is unavailable.
  ///
  /// Requesting while suppression is held reports on that hold instead of
  /// adding another, and on Android restores suppression if other code stopped
  /// reader mode. Calls don't have to be awaited before the next one: they run
  /// in the order issued, each returns its own outcome, and the last call wins.
  ///
  /// The result's [SuppressionResult.status] is one of:
  ///
  /// | Status | iOS | Android |
  /// |---|---|---|
  /// | [SuppressionStatus.suppressed] — suppression is held; "Suppression lifecycle" on [NfcWalletSuppression] says when it is in effect | ✔ | ✔ |
  /// | [SuppressionStatus.notSupported] — no suppression capability at all; iOS: PassKit reports it unsupported, Android: no NFC hardware | ✔ | ✔ |
  /// | [SuppressionStatus.nfcDisabled] — NFC is switched off; the request is held and starts once NFC is on | | ✔ |
  /// | [SuppressionStatus.unavailable] — transient; no Activity attached | | ✔ |
  /// | [SuppressionStatus.denied] — iOS: usually a missing entitlement; Android: a `SecurityException` | ✔ | ✔ |
  /// | [SuppressionStatus.alreadyPresenting] — the wallet is already showing a pass | ✔ | |
  /// | [SuppressionStatus.canceled] — the request was canceled before it completed | ✔ | |
  /// | [SuppressionStatus.unknown] — unexpected failure, or no answer in time; call [isSuppressed] if you need the current state | ✔ | ✔ |
  ///
  /// New values may be added without a major version bump, so always include
  /// a fallback when switching.
  ///
  /// On iOS this uses PassKit's `requestAutomaticPassPresentationSuppression`.
  /// On Android it puts NFC into reader mode, which turns off card emulation,
  /// so wallet apps can't respond to readers. When a hold is in effect is
  /// under "Suppression lifecycle" on [NfcWalletSuppression].
  ///
  /// ```dart
  /// final result = await NfcWalletSuppression.requestSuppression();
  ///
  /// switch (result.status) {
  ///   case SuppressionStatus.suppressed:
  ///     print('Wallet suppressed successfully');
  ///   case SuppressionStatus.nfcDisabled:
  ///     // Held; prompt to switch NFC on only if your app needs NFC itself.
  ///     print('Suppression starts when NFC is switched on');
  ///   case SuppressionStatus.denied:
  ///     print('Suppression was refused');
  ///   case SuppressionStatus.notSupported:
  ///     print('Device does not support wallet suppression');
  ///   default:
  ///     print('Failed: ${result.status} (${result.description})');
  /// }
  /// ```
  static Future<SuppressionResult> requestSuppression() {
    return NfcWalletSuppressionPlatform.instance.requestSuppression();
  }

  /// Ends suppression, so the wallet pops up at NFC readers again.
  ///
  /// Call it when the screen that needed suppression closes, whatever the
  /// request returned. Release is idempotent: with nothing held it reports
  /// [SuppressionStatus.notSuppressed], so it is safe in a `finally`.
  ///
  /// It reports on the suppression you requested, not on live device state;
  /// use [isSuppressed] for that.
  ///
  /// The result's [SuppressionResult.status] is one of:
  ///
  /// | Status | iOS | Android |
  /// |---|---|---|
  /// | [SuppressionStatus.notSuppressed] — suppression is off, whether this call ended it or there was nothing to end | ✔ | ✔ |
  /// | [SuppressionStatus.denied] — tearing down reader mode threw a `SecurityException`; suppression may still be active | | ✔ |
  /// | [SuppressionStatus.unknown] — unexpected tear-down failure, or the platform channel itself failed; suppression may still be active | ✔ | ✔ |
  ///
  /// On iOS only [SuppressionStatus.notSuppressed] is returned in practice:
  /// ending suppression cannot fail, so [SuppressionStatus.unknown] means the
  /// platform channel itself failed. New values may be added without a major
  /// version bump, so still include a fallback when switching.
  ///
  /// ```dart
  /// try {
  ///   await NfcWalletSuppression.requestSuppression();
  ///   // ... show the ticket at the gate ...
  /// } finally {
  ///   await NfcWalletSuppression.releaseSuppression();
  /// }
  /// ```
  static Future<SuppressionResult> releaseSuppression() {
    return NfcWalletSuppressionPlatform.instance.releaseSuppression();
  }

  /// Whether suppression is in effect right now.
  ///
  /// A held suppression is not always in effect (see "Suppression lifecycle" on
  /// [NfcWalletSuppression]), and the answer is a snapshot that can change as
  /// soon as it is returned. Each platform can also lag or miss a change:
  ///
  /// - **iOS** asks PassKit (`isSuppressingAutomaticPassPresentation`), which
  ///   can still report `true` just after [releaseSuppression] and while the app
  ///   moves to the background.
  /// - **Android** is `true` while the plugin holds suppression and Android
  ///   applies it: `false` while NFC is off, while the Activity is paused (in the
  ///   background, or behind another activity such as the share sheet or a
  ///   permission dialog) and with no Activity attached. It can still be `true`
  ///   briefly after NFC is switched on, and stays `true` after a tag reader or
  ///   other code stops reader mode on the Activity; request again to restore
  ///   suppression.
  static Future<bool> isSuppressed() {
    return NfcWalletSuppressionPlatform.instance.isSuppressed();
  }

  /// Whether suppression can be attempted on this device.
  ///
  /// On Android that is NFC hardware, whether or not NFC is switched on. On iOS
  /// it is the Wallet pass library (`PKPassLibrary.isPassLibraryAvailable`),
  /// which is not a guarantee: it is also `true` in the Simulator, on iPhone and
  /// iPad alike, where nothing can be suppressed, and PassKit can't report the
  /// entitlement up front. Always `false` on web and desktop.
  ///
  /// Use it to decide whether to offer the feature at all; the result of
  /// [requestSuppression] is the definitive answer.
  static Future<bool> isSupported() {
    return NfcWalletSuppressionPlatform.instance.isSupported();
  }
}
