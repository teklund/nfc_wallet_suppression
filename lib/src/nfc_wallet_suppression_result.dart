import 'package:flutter/foundation.dart';

import 'nfc_wallet_suppression_status.dart';

/// The result of a suppression operation.
///
/// Carries the machine-readable [status] you branch on, plus the platform's own
/// [description] of what happened, which is useful in logs and bug reports but
/// is not meant to be shown to users or parsed.
///
/// You never construct this yourself; the plugin returns it.
@immutable
class SuppressionResult {
  /// Creates a result. Exposed mainly so tests and fakes can build one.
  const SuppressionResult({required this.status, this.description});

  /// What happened.
  ///
  /// See [SuppressionStatus] — new values may be added without a major version
  /// bump, so always include a fallback when switching on this.
  final SuppressionStatus status;

  /// A human-readable description of the outcome, as reported by the platform.
  ///
  /// Diagnostic only: the wording is not part of the API contract and may change
  /// between releases or differ between iOS and Android. Never branch on it —
  /// branch on [status].
  ///
  /// `null` when the platform gave no detail.
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuppressionResult &&
          other.status == status &&
          other.description == description;

  @override
  int get hashCode => Object.hash(status, description);

  @override
  String toString() =>
      'SuppressionResult(status: $status, description: $description)';
}

/// Convenience predicates over a [SuppressionResult].
///
/// These live in an extension rather than on the class so that adding more of
/// them later stays non-breaking.
extension SuppressionResultGetters on SuppressionResult {
  /// Whether automatic wallet presentation is now suppressed.
  ///
  /// True for a successful `requestSuppression`, including the already-active
  /// case.
  bool get isSuppressed => status == SuppressionStatus.suppressed;

  /// Whether suppression is now released.
  ///
  /// True for a successful `releaseSuppression`, including when there was
  /// nothing to release.
  bool get isReleased => status == SuppressionStatus.notSuppressed;

  /// Whether retrying could plausibly succeed once something changes.
  ///
  /// [SuppressionStatus.nfcDisabled] needs the user to switch NFC on;
  /// [SuppressionStatus.unavailable] is transient and may clear on its own.
  /// Deliberately excludes [SuppressionStatus.unknown], where the operation may
  /// already have taken effect — check `isSuppressed()` before retrying that.
  bool get isRetryable =>
      status == SuppressionStatus.nfcDisabled ||
      status == SuppressionStatus.unavailable;
}
