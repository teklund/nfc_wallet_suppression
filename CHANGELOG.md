# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

The first stable release. Compared with 0.1.1, requests and releases return a
`SuppressionResult`, and some statuses changed meaning; see "Migrating from
0.1.x" in the README.

### Added

- `SuppressionResult`, returned by requests and releases: the status, the
  platform's diagnostic `description`, and `isSuppressed`, `isReleased` and
  `isRetryable`.
- `NfcWalletSuppression.isSupported()`.
- `SuppressionStatus.nfcDisabled`: Android with NFC switched off, the one
  failure the user can fix.
- `package:nfc_wallet_suppression/testing.dart` with `FakeNfcWalletSuppression`
  for unit and widget tests.
- Web, macOS, Linux and Windows: calls do nothing and a request returns
  `notSupported`, instead of throwing `MissingPluginException`.
- Swift Package Manager support on iOS.
- Android: support for Android Gradle Plugin 9 with built-in Kotlin.

### Changed

- **Breaking**: Requires Flutter 3.44, Dart 3.12 and iOS 13.0 (was iOS 12.0).
- **Breaking**: `requestSuppression()` and `releaseSuppression()` return a
  `SuppressionResult` instead of a `SuppressionStatus`.
- **Breaking**: `unavailable` now means only "transient, retry may work": on
  Android, no Activity attached. NFC switched off returns `nfcDisabled`, and a
  device without NFC returns `notSupported`.
- **Breaking**: Release is idempotent: with nothing held it returns
  `notSuppressed` instead of `unavailable`.
- **Breaking**: `SuppressionStatus.cancelled` is renamed `canceled`.
- **Breaking**: `NfcWalletSuppression` is an `abstract final class`.
- **Breaking**: The main library exports only `NfcWalletSuppression`,
  `SuppressionResult` and `SuppressionStatus`. `NfcWalletSuppressionPlatform`
  moved to `testing.dart`.
- A request while suppression is held reports on that hold instead of starting
  another, and overlapping calls run in the order they were made.
- Android: no longer plays the system sound when a tag is held to the phone.
- No longer logs in release builds.
- Requires `plugin_platform_interface` 2.1.7 or later.

### Removed

- **Breaking**: `MethodChannelNfcWalletSuppression`. Use
  `FakeNfcWalletSuppression` or a mock of `NfcWalletSuppressionPlatform`.

### Fixed

- Android: suppression is restored after the Activity is recreated and when NFC
  is switched back on. Before, it stayed off while `isSuppressed()` reported
  `true`.
- iOS: a second request no longer strands the first. It used to overwrite the
  token, so release could not end the first one.
- iOS: results reach Flutter on the main thread.
- iOS: a request PassKit never answers completes with `unknown` after 5 seconds
  instead of hanging.
- iOS: the privacy manifest is now bundled. 0.1.1 shipped it unused.

## 1.0.0-dev.1

Pre-release of 1.0.0, published to test the release pipeline. Its changes are
listed under Unreleased.

## 0.1.1

- **DOCS** Clarified that NFC permission is automatically included via plugin manifest (no app-level declaration needed)

- First stable release of the `nfc_wallet_suppression` plugin.
- **DOCS** Updated readme

## 0.0.2-beta

- Enhances error handling within the NFC wallet suppression plugin and refactors the code for better
  clarity.
- **iOS:** Improved error handling for iOS.
- **Android:** Got a working implementation of the NFC wallet suppression plugin.

## 0.0.1-beta

- Initial release of the `nfc_wallet_suppression` plugin.
- **iOS:** Added NFC wallet suppression using PassKit (request, release, check status).
- **Android:** Added NFC wallet suppression using NfcAdapter (request, release, check status).
