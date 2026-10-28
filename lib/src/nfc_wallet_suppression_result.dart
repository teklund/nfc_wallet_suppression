import 'package:flutter/foundation.dart';

import 'nfc_wallet_suppression_status.dart';

/// The result of a suppression operation.
///
/// Carries the machine-readable [status] you branch on, plus the platform's own
/// [description] of what happened, which is useful in logs and bug reports but
/// is not meant to be shown to users or parsed.
///
/// The plugin returns these; tests can construct one directly. The class is
/// `final`, so it can't be implemented or extended — mocks included — which is
/// what lets members be added later without a breaking change.
@immutable
final class SuppressionResult {
  /// Creates a result, for tests and fakes that need one.
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

  /// Whether suppression is now held.
  ///
  /// True for a successful `requestSuppression`, including the already-held
  /// case.
  bool get isSuppressed => status == SuppressionStatus.suppressed;

  /// Whether suppression is now released.
  ///
  /// True for a successful `releaseSuppression`, including when there was
  /// nothing to release.
  bool get isReleased => status == SuppressionStatus.notSuppressed;

  /// Whether retrying could plausibly succeed once something changes.
  ///
  /// True only for [SuppressionStatus.unavailable], which is transient and may
  /// clear on its own. [SuppressionStatus.nfcDisabled] needs no retry: the
  /// request is held and starts once NFC is switched on. Deliberately excludes
  /// [SuppressionStatus.unknown], where the operation may already have taken
  /// effect — check `isSuppressed()` before retrying that.
  bool get isRetryable => status == SuppressionStatus.unavailable;

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
