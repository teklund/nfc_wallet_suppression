# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0

**Major release with Pigeon migration for type-safe platform channels**

### Added

- ✨ **Pigeon Integration**: Migrated from manual method channels to Pigeon-generated type-safe platform communication
- 🛡️ **Compile-time Safety**: Eliminated string-based error code matching - all status codes are now type-checked enums
- 📚 **MIGRATION.md**: Comprehensive migration guide for upgrading from 0.1.x
- 📚 **PUBLISHING.md**: Complete publishing checklist and procedures
- 🔒 **SECURITY.md**: Security policy and vulnerability reporting guidelines

### Changed

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
- Maintains 100% backward compatibility for public API
- All 69 tests passing with comprehensive edge case coverage

### Migration Notes

**Public API is fully backward compatible** - no code changes required for most users.

If you were directly using internal classes:

```dart
// ❌ Old (no longer exported)
import 'package:nfc_wallet_suppression/src/nfc_wallet_suppression_method_channel.dart';

// ✅ New (use public API)
import 'package:nfc_wallet_suppression/nfc_wallet_suppression.dart';
```

See [MIGRATION.md](MIGRATION.md) for complete migration guide.

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
