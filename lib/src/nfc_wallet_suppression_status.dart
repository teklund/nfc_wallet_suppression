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
  /// Transient and retryable — for example, no foreground Activity on Android.
  /// This does *not* mean NFC is switched off; that is [nfcDisabled].
  unavailable,

  /// The user or the system refused the request.
  ///
  /// On iOS this includes a missing
  /// `com.apple.developer.passkit.pass-presentation-suppression` entitlement.
  denied,

  /// The request was cancelled before it completed.
  cancelled,

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
  /// to know the live state.
  unknown,

  /// NFC hardware is present but switched off in system settings.
  ///
  /// The one failure the user can fix directly, which is why it is separate from
  /// [unavailable] and [notSupported]: an app can deep-link to NFC settings
  /// (`android.settings.NFC_SETTINGS`) and prompt them to enable it.
  ///
  /// Android only. iOS exposes no equivalent state.
  nfcDisabled,
}
