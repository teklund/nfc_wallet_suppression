# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Changed

- 🤖 **Android Built-in Kotlin migration (Flutter 3.44+)**: The Android build no
  longer unconditionally applies the Kotlin Gradle Plugin. From AGP 9 onward Kotlin
  is provided by AGP itself; KGP is now applied conditionally (only for AGP < 9) so
  the plugin keeps building on both new and older toolchains. The deprecated
  `kotlinOptions` block was replaced with the modern `kotlin.compilerOptions` DSL.
  No change to the supported Flutter range — the plugin still targets Flutter 3.35.0+.
- ⬆️ **Example toolchain bump**: Example app updated to Gradle 8.14, Android Gradle
  Plugin 8.11.1, and Kotlin 2.2.20 to track currently-supported build tooling.

## 1.0.0

Major release with Pigeon migration for type-safe platform channels.

### Added

- ✨ **Pigeon Integration**: Migrated from manual method channels to Pigeon-generated type-safe platform communication
- 🛡️ **Compile-time Safety**: Eliminated string-based error code matching - all status codes are now type-checked enums
- 🌐 **Multi-platform support**: Added stub implementations for web, macOS, Linux, and Windows — `requestSuppression` returns `SuppressionStatus.notSupported`, `releaseSuppression` returns `SuppressionStatus.notSuppressed`
- 📚 **PUBLISHING.md**: Complete publishing checklist and procedures
- 🔒 **SECURITY.md**: Security policy and vulnerability reporting guidelines

### Changed

- **Baseline Bump**: Minimum SDK requirements raised to Flutter 3.35.0+ and Dart 3.9.0+
- **BREAKING (Internal)**: Platform interface now uses `PigeonNfcWalletSuppression` instead of `MethodChannelNfcWalletSuppression`
- **Improved Error Handling**: Platform errors are now returned as structured `SuppressionResult` objects instead of thrown exceptions
- **Enhanced Logging**: Better structured error messages with full context from platform code
- **Code Quality**: Reduced manual string matching and type coercion throughout codebase

### Fixed

- 🐛 **Type Safety**: Eliminated possibility of typos in error code strings between platforms
- 🐛 **Error Context**: Platform errors now include detailed messages in structured format

### Technical Details

- Uses Pigeon v22.7+ for code generation
- Generated platform channel code for iOS (Swift) and Android (Kotlin)
- **Breaking API Changes**: `SuppressionStatus` replaces bool returns, and Dart SDK minimum is now 3.9.0.
- Comprehensive test coverage: Dart unit tests, Android JVM tests, and iOS XCTest suite

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
