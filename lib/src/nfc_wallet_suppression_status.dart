/// The outcome of a suppression operation.
///
/// Not every value can be returned by every method. `requestSuppression` and
/// `releaseSuppression` each document the subset they can produce, so switch on
/// the subset the method you called can actually return.
///
/// Adding new values to this enum in the future will *not* be considered a
/// breaking change, so clients should not assume they can exhaustively match
/// statuses. Clients should always include a default or other fallback.
enum SuppressionStatus {
  /// Nothing is being suppressed.
  ///
  /// Returned by a successful `releaseSuppression`, including when there was no
  /// active suppression to release — releasing is idempotent, and the end state
  /// is the same either way.
  notSuppressed,

  /// Automatic wallet presentation is suppressed.
  ///
  /// Returned by a successful `requestSuppression`, including when suppression
  /// was already active.
  suppressed,

  /// Suppression could not be attempted right now, but may succeed later.
  ///
  /// Transient and retryable — for example, no Activity attached on Android.
  /// This does *not* mean NFC is switched off; that is [nfcDisabled].
  unavailable,

  /// The request was refused.
  ///
  /// On iOS this usually means the app lacks the
  /// `com.apple.developer.passkit.pass-presentation-suppression` entitlement;
  /// Apple also allows for a refusal by the user or an internal error. On
  /// Android, the NFC call threw a `SecurityException`.
  denied,

  /// The request was canceled before it completed.
  canceled,

  /// The device or OS cannot suppress wallet presentation at all.
  ///
  /// Permanent for this device — unlike [unavailable] and [nfcDisabled], there
  /// is nothing the user or the app can do about it.
  notSupported,

  /// The wallet is already presenting a pass, so suppression was refused.
  alreadyPresenting,

  /// The outcome could not be determined.
  ///
  /// The platform failed in an unexpected way, or did not answer in time. The
  /// operation may or may not have taken effect; call `isSuppressed` if you need
  /// to know the current state.
  unknown,

  /// NFC hardware is present but switched off in system settings.
  ///
  /// The request is held, and suppression starts by itself once NFC is switched
  /// on. While NFC is off, wallet apps can't respond to readers either, so
  /// prompt the user to switch it on (`android.settings.NFC_SETTINGS`) only if
  /// your app needs NFC itself.
  ///
  /// Android only. iOS exposes no equivalent state.
  nfcDisabled,
}
