# NFC Wallet Suppression Plugin - Improvement Plan

**Date:** November 6, 2025  
**Version:** 0.1.1 → 1.0.0  
**Estimated Total Time:** 5.5 hours  
**Approach:** Test-Driven Development (TDD) - Write tests first, then implement fixes  
**Production Ready:** Includes CI/CD, migration guide, security review, and pub.dev optimization

---

## 🎯 Overview

This document outlines a comprehensive plan to address all identified issues in the `nfc_wallet_suppression` Flutter plugin before releasing version 1.0.0. Issues are categorized by severity and organized into phases for systematic implementation.

---

## 📊 Issue Summary

| Severity | Count | Estimated Time |
|----------|-------|----------------|
| 🔴 Critical | 5 | 30-45 min |
| 🟡 High Priority | 5 | 45-60 min |
| 🟢 Medium Priority | 5 | 30 min |
| 🧪 Testing | 6 | 60-90 min |
| 🚀 Production Ready | 5 | 95 min |
| **Total** | **26** | **~5.5 hours** |

---

## 🔴 Phase 1: Critical Fixes (Must Fix Before 1.0)

### 1. Fix Library Exports

- **File:** `lib/nfc_wallet_suppression.dart`
- **Issue:** Exposes internal implementation details that should be private
- **Fix:** Remove exports of `method_channel` and `platform_interface`
- **Impact:** Breaking change for anyone directly using internal classes (unlikely)
- **Time:** 5 min

```dart
// BEFORE
export 'src/nfc_wallet_suppression_method_channel.dart';
export 'src/nfc_wallet_suppression_platform_interface.dart';

// AFTER
// Only export public API
```

---

### 2. Fix iOS Token Management Race Condition

- **File:** `ios/Classes/NfcWalletSuppressionPlugin.swift`
- **Issue:** Multiple rapid calls can create token leaks and race conditions
- **Fix:** Add guard to check for existing token and properly release before creating new one
- **Impact:** Prevents memory leaks and undefined behavior
- **Time:** 10 min

```swift
// Add guard before creating new token
if let existingToken = suppressionToken {
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: existingToken)
    suppressionToken = nil
}
```

---

### 3. Fix Android State Persistence Issue

- **File:** `android/src/main/kotlin/dev/teklund/nfc_wallet_suppression/NfcWalletSuppressionPlugin.kt`
- **Issue:** Suppression state lost on activity recreation (e.g., screen rotation)
- **Fix:** Implement state saving/restoration mechanism
- **Impact:** Ensures suppression survives configuration changes
- **Time:** 15 min

**Options:**

1. Use SharedPreferences to persist state
2. Use instance state bundle
3. Re-establish suppression on activity recreation

---

### 4. Fix Duplicate Test Name

- **File:** `test/nfc_wallet_suppression_test.dart`
- **Issue:** Two tests named `isSuppressed_defaultFalse` will conflict
- **Fix:** Rename third test to `isSuppressed_falseAfterRelease`
- **Impact:** Tests will run correctly
- **Time:** 2 min

```dart
// Line ~52
test('isSuppressed_falseAfterRelease', () async {
```

---

### 5. Fix Integration Test Expectations

- **File:** `example/integration_test/plugin_integration_test.dart`
- **Issue:** Test expects `true` but default state is `false`
- **Fix:** Change expectation to `false` or add proper setup
- **Impact:** Integration tests will pass
- **Time:** 3 min

```dart
testWidgets('isSuppressed test', (WidgetTester tester) async {
  final bool suppressed = await NfcWalletSuppression.isSuppressed();
  expect(suppressed, false); // Default should be false
});
```

---

## 🟡 Phase 2: High Priority (Should Fix Soon)

### 6. Add Comprehensive API Documentation

- **File:** `lib/src/nfc_wallet_suppression.dart`
- **Issue:** Missing detailed dartdoc comments on public methods
- **Fix:** Add complete documentation with examples, platform notes, exceptions
- **Impact:** Better developer experience, improved pub.dev score
- **Time:** 15 min

**Documentation should include:**

- Method purpose and use cases
- Platform-specific behavior differences
- Return value descriptions for each status
- Exception scenarios
- Code examples
- See-also references

---

### 7. Replace print() with Proper Logging

- **File:** `lib/src/nfc_wallet_suppression_method_channel.dart`
- **Issue:** Using `print()` and `kDebugMode` checks in production code
- **Fix:** Replace with `debugPrint()` or remove entirely
- **Impact:** Cleaner production builds, better logging practices
- **Time:** 5 min

```dart
// BEFORE
if (kDebugMode) {
  print(msg);
}

// AFTER
debugPrint('[NfcWalletSuppression] $msg');
// OR remove entirely for production
```

---

### 8. Add Platform Capability Check Method

- **Files:** All platform files
- **Issue:** No way to check if feature is supported before attempting to use
- **Fix:** Add `isSupported()` method
- **Impact:** Better error handling and user experience
- **Time:** 15 min

**Implementation:**

- Add method to platform interface
- iOS: Check PassKit availability
- Android: Check NFC adapter availability
- Return bool indicating support

---

### 9. Update Podspec with Correct Metadata

- **File:** `ios/nfc_wallet_suppression.podspec`
- **Issue:** Placeholder values for homepage and author
- **Fix:** Update with actual GitHub URL and author info
- **Impact:** Required for proper CocoaPods/pub.dev integration
- **Time:** 5 min

```ruby
s.homepage = 'https://github.com/teklund/nfc_wallet_suppression'
s.author = { 'TEklund' => 'email@example.com' }
```

**Note:** Replace `email@example.com` with your actual email address.

---

### 10. Fix CHANGELOG.md Formatting

- **File:** `CHANGELOG.md`
- **Issue:** Linting errors (MD041, MD047)
- **Fix:** Add top-level heading and ensure single trailing newline
- **Impact:** Passes linting, better formatting
- **Time:** 2 min

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## 0.1.1
...
```

---

## 🟢 Phase 3: Polish & Improvements

### 11. Remove Dead Code and Cleanup Android

- **File:** `android/src/main/kotlin/dev/teklund/nfc_wallet_suppression/NfcWalletSuppressionPlugin.kt`
- **Issue:** Commented code and empty callback implementation
- **Fix:** Remove commented line, add explanatory comment for empty callback
- **Impact:** Cleaner codebase
- **Time:** 5 min

```kotlin
// Remove: //binding.addOnNewIntentListener(this)

// Add comment:
// Empty implementation - we only need ReaderCallback for reader mode flags,
// not for actual tag processing
override fun onTagDiscovered(tag: Tag?) {
    // Intentionally empty - suppression only
}
```

---

### 12. Fix README Code Formatting

- **File:** `README.md`
- **Issue:** Missing space after `catch` keyword
- **Fix:** Add space to follow Dart style guide
- **Impact:** Documentation polish
- **Time:** 2 min

```dart
// BEFORE
} catch(error) {

// AFTER
} catch (error) {
```

---

### 13. Document or Clarify Android NFC Permission

- **File:** `CHANGELOG.md` and `README.md`
- **Issue:** Changelog says "Don't require" but permission is declared in plugin manifest
- **Fix:** Clarify in documentation that NFC permission is automatically merged from plugin manifest (required)
- **Impact:** Clearer documentation, accurate changelog
- **Time:** 5 min

**Resolution:**

- Permission **IS needed** and declared in plugin's `AndroidManifest.xml`
- Permission is automatically merged into host app when plugin is added as dependency
- Update CHANGELOG to clarify: "NFC permission is automatically included via plugin manifest (no app-level declaration needed)"
- Update README Android prerequisites to note this automatic inclusion

---

### 14. Add Example App Improvements

- **File:** `example/lib/main.dart`
- **Issue:** Missing `const` keywords, could have better error handling
- **Fix:** Add const where appropriate, improve error display
- **Impact:** Better example quality
- **Time:** 8 min

**Improvements:**

- Add const to Text widgets
- Better error state display
- Add loading states
- Show platform-specific notes

---

### 15. Enable or Document Privacy Manifest

- **File:** `ios/nfc_wallet_suppression.podspec`
- **Issue:** Privacy manifest exists but not enabled in podspec
- **Fix:** Enable resource bundle or document why not needed
- **Impact:** iOS App Store compliance
- **Time:** 5 min

**Options:**

1. Uncomment the `s.resource_bundles` line if needed
2. Add comment explaining PassKit doesn't require special privacy declarations
3. Research if PassKit NFC suppression needs privacy manifest entry

---

## 🧪 Phase 4: Comprehensive Testing (Test-Driven Development)

### 16. Add iOS Token Management Tests

- **File:** `test/nfc_wallet_suppression_ios_test.dart` (new file)
- **Issue:** No tests for iOS token management edge cases
- **Tests to add:**
  - Test rapid consecutive `requestSuppression()` calls don't create multiple tokens
  - Test calling `requestSuppression()` while already suppressed returns appropriate status
  - Test token cleanup on `releaseSuppression()`
  - Test all PassKit result cases (success, denied, cancelled, alreadyPresenting, notSupported)
  - Test `isSuppressed()` accuracy during lifecycle
- **Impact:** Ensures iOS implementation is robust
- **Time:** 20 min

**Test Structure:**

```dart
// Mock PKPassLibrary responses
// Test token lifecycle
// Test race conditions
// Test error scenarios
```

---

### 17. Add Android State Persistence Tests

- **File:** `test/nfc_wallet_suppression_android_test.dart` (new file)
- **Issue:** No tests for Android activity lifecycle and state persistence
- **Tests to add:**
  - Test suppression state survives activity recreation
  - Test NFC adapter availability checks
  - Test behavior when NFC is disabled
  - Test behavior when NFC adapter is null
  - Test foregroundDispatch and readerMode setup/teardown
- **Impact:** Ensures Android implementation handles configuration changes
- **Time:** 20 min

**Test Coverage:**

- Activity lifecycle events
- NFC availability scenarios
- State persistence mechanisms
- Error conditions

---

### 18. Add Platform Support Tests

- **File:** `test/nfc_wallet_suppression_platform_test.dart` (new file)
- **Issue:** No tests for new `isSupported()` method
- **Tests to add:**
  - Test `isSupported()` returns true on iOS with PassKit
  - Test `isSupported()` returns true on Android with NFC
  - Test `isSupported()` returns false on platforms without NFC
  - Test `isSupported()` returns false when feature not available
  - Test behavior when calling methods on unsupported platforms
- **Impact:** Validates platform capability detection
- **Time:** 15 min

---

### 19. Add Comprehensive Error Handling Tests

- **File:** `test/nfc_wallet_suppression_error_test.dart` (new file)
- **Issue:** Limited testing of all `SuppressionStatus` enum values
- **Tests to add:**
  - Test each `SuppressionStatus` enum value is returned correctly
  - Test error code mapping from platform to status
  - Test exception handling for platform errors
  - Test null safety throughout the API
  - Test error messages are descriptive
- **Impact:** Ensures robust error handling
- **Time:** 15 min

**All Status Values to Test:**

- `notSuppressed`
- `suppressed`
- `unavailable`
- `denied`
- `cancelled`
- `notSupported`
- `alreadyPresenting`
- `unknown`

---

### 20. Add Integration Tests

- **File:** `example/integration_test/comprehensive_integration_test.dart` (new file)
- **Issue:** Only one basic integration test exists
- **Tests to add:**
  - Test complete suppression lifecycle (request → check → release)
  - Test multiple request/release cycles
  - Test rapid toggling doesn't break state
  - Test behavior during app backgrounding/foregrounding
  - Test concurrent operations handling
  - Test platform-specific behaviors on real devices
- **Impact:** End-to-end validation of plugin functionality
- **Time:** 25 min

**Real Device Tests:**

- iOS device with PassKit entitlement
- Android device with NFC hardware
- Both platforms without NFC

---

### 21. Add Method Channel Mock Tests

- **File:** `test/nfc_wallet_suppression_method_channel_test.dart` (enhance existing)
- **Issue:** Current method channel tests are minimal
- **Tests to add:**
  - Test all method channel calls with proper mocking
  - Test method channel error propagation
  - Test platform-specific return values
  - Test async behavior and timeouts
  - Test method channel serialization/deserialization
- **Impact:** Validates communication layer
- **Time:** 15 min

---

## � Phase 5: Production Ready (Must Have for 1.0.0)

### 22. Create Migration Guide

- **File:** `MIGRATION.md` (new file)
- **Issue:** Breaking changes need clear migration path from 0.1.1 to 1.0.0
- **Content to include:**
  - Overview of breaking changes (removed internal API exports)
  - Before/after code examples
  - Step-by-step migration instructions
  - FAQ for common issues
  - Timeline and deprecation policy
- **Impact:** Users can upgrade confidently without breaking their apps
- **Time:** 15 min

**Migration Guide Structure:**

```markdown
# Migration Guide: v0.1.1 → v1.0.0

## Breaking Changes
- Internal API exports removed

## How to Migrate
1. Check if you're using removed APIs
2. Replace with public API
3. Test your integration

## Examples
[Before/After code samples]
```

---

### ✅ 23. Add GitHub Actions CI/CD

- **File:** `.github/workflows/ci.yml` (new file)
- **Issue:** No automated testing, analysis, or publishing
- **Workflow to include:**
  - Automated testing on PR (unit + integration tests)
  - Flutter analyze on every commit
  - Code coverage reporting
  - Platform-specific builds (iOS/Android)
  - Automated pub.dev publishing on tag
  - Version validation
- **Impact:** Ensures quality, catches bugs early, automates releases
- **Time:** 30 min

**CI/CD Features:**

- Run on: push, pull_request, release
- Matrix testing: Multiple Flutter versions
- Coverage badges
- Auto-publish to pub.dev on git tags

---

### 24. Create Pub.dev Publishing Checklist

- **File:** `PUBLISHING.md` (new file)
- **Issue:** No formalized process for publishing to pub.dev
- **Checklist to include:**
  - Pre-publish verification steps
  - Version number validation (semantic versioning)
  - CHANGELOG update verification
  - Documentation review
  - Example app testing
  - Package analysis score check (>130/140)
  - Breaking change verification
  - Tag and release process
- **Impact:** Consistent, high-quality releases
- **Time:** 10 min

**Key Checks:**

- [ ] Version bumped correctly
- [ ] CHANGELOG updated
- [ ] All tests passing
- [ ] Documentation complete
- [ ] pub.dev score acceptable
- [ ] No analyzer warnings

---

### 25. Enhance Example App + Add Screenshots

- **File:** `example/lib/main.dart` and `example/screenshots/` (new directory)
- **Issue:** Example app is basic, no visual documentation
- **Enhancements:**
  - Demonstrate all API methods clearly
  - Show proper error handling patterns
  - Add loading states and user feedback
  - Add platform-specific notes in UI
  - Fix const keywords throughout
  - Add app icon and proper styling
- **Screenshots to capture:**
  - Initial state
  - Suppression active state
  - Error states for each SuppressionStatus
  - Platform permission screens
- **Impact:** Better documentation, higher pub.dev score, easier onboarding
- **Time:** 20 min

**Screenshot Requirements:**

- iOS and Android screenshots
- Light/dark mode if applicable
- Error state examples
- Add to README.md

---

### 26. Security & Privacy Review

- **File:** `SECURITY.md` (new file) + update `ios/Resources/PrivacyInfo.xcprivacy`
- **Issue:** NFC handling can be security-sensitive, no formal security documentation
- **Review areas:**
  - NFC data handling (ensure no sensitive data logged)
  - Permission handling security
  - Token management security (iOS)
  - Privacy manifest completeness (iOS)
  - Data retention policies
  - Malicious NFC tag protection
  - Third-party dependencies audit
- **Documentation:**
  - Security policy
  - Responsible disclosure process
  - Privacy data collection statement
  - Supported versions for security updates
- **Impact:** Trust, App Store approval, enterprise adoption
- **Time:** 20 min

**Security Checklist:**

- [ ] No sensitive data in logs
- [ ] Proper token cleanup
- [ ] Privacy manifest accurate
- [ ] No vulnerable dependencies
- [ ] Security policy documented

---

## �📋 Implementation Checklist

### Phase 1 - Critical (30-45 min)

- [ ] Task 1: Fix library exports
- [ ] Task 2: Fix iOS token management
- [ ] Task 3: Fix Android state persistence
- [ ] Task 4: Fix duplicate test name
- [ ] Task 5: Fix integration test
- [ ] Run tests: `flutter test`
- [ ] Commit: "fix: critical issues for v1.0.0"

### Phase 2 - High Priority (45-60 min)

- [ ] Task 6: Add comprehensive API docs
- [ ] Task 7: Replace print() calls
- [ ] Task 8: Add platform capability check
- [ ] Task 9: Update podspec metadata
- [ ] Task 10: Fix CHANGELOG formatting
- [ ] Run tests and analyzer
- [ ] Commit: "feat: improve documentation and add capability checks"

### Phase 3 - Polish (30 min)

- [ ] Task 11: Remove dead code
- [ ] Task 12: Fix README formatting
- [ ] Task 13: Clarify Android permissions
- [ ] Task 14: Improve example app
- [ ] Task 15: Document privacy manifest
- [ ] Run tests and analyzer
- [ ] Commit: "chore: polish and cleanup for v1.0.0"

### Phase 4 - Comprehensive Testing (60-90 min)

- [ ] Task 16: Write iOS token management tests (TDD)
- [ ] Task 17: Write Android state persistence tests (TDD)
- [ ] Task 18: Write platform support tests for `isSupported()`
- [ ] Task 19: Write comprehensive error handling tests
- [ ] Task 20: Write integration tests for complete lifecycle
- [ ] Task 21: Enhance method channel mock tests
- [ ] Run full test suite: `flutter test`
- [ ] Verify test coverage: `flutter test --coverage`
- [ ] Run integration tests on simulator/emulator
- [ ] Commit: "test: add comprehensive test coverage for v1.0.0"

### Phase 5 - Production Ready (95 min)

- [ ] Task 22: Create MIGRATION.md guide for 0.1.1 → 1.0.0
- [x] Task 23: Add GitHub Actions CI/CD workflow
- [ ] Task 24: Create PUBLISHING.md checklist
- [ ] Task 25: Enhance example app with screenshots
- [ ] Task 26: Security & privacy review + SECURITY.md
- [ ] Test CI/CD pipeline with test commit
- [ ] Verify pub.dev dry-run: `dart pub publish --dry-run`
- [ ] Generate coverage badge
- [ ] Take example app screenshots (iOS + Android)
- [ ] Commit: "chore: add production-ready infrastructure for v1.0.0"

### Post-Implementation

- [ ] Update version to 1.0.0 in `pubspec.yaml` and `podspec`
- [ ] Update CHANGELOG with all changes (follow Keep a Changelog format)
- [ ] Run full test suite: `flutter test`
- [ ] Run analyzer: `flutter analyze`
- [ ] Verify formatting: `dart format --set-exit-if-changed .`
- [ ] Test on real iOS device (if available)
- [ ] Test on real Android device (if available)
- [ ] Run pub.dev dry-run: `dart pub publish --dry-run`
- [ ] Verify package score: Check pana analysis
- [ ] Review all documentation for accuracy
- [ ] Create pull request (if using feature branch)
- [ ] Code review
- [ ] Merge to master
- [ ] Tag release: `git tag -a v1.0.0 -m "Release version 1.0.0"`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Publish to pub.dev: `dart pub publish` (or via CI/CD)
- [ ] Create GitHub release with notes
- [ ] Announce release (if applicable)

---

## 🧪 Testing Strategy

### TDD Workflow

For each fix in Phase 1-3, follow this pattern:

1. **Write failing test** that demonstrates the bug/missing feature
2. **Run test** to confirm it fails: `flutter test`
3. **Implement fix** to make test pass
4. **Run test** to confirm it passes
5. **Refactor** if needed while keeping tests green
6. **Commit** with test + implementation

### Unit Tests

```bash
cd /Users/teklund/git/teklund/nfc_wallet_suppression
flutter test
flutter test --coverage
```

**Expected Coverage Targets:**

- Overall: > 80%
- Core API (`nfc_wallet_suppression.dart`): 100%
- Platform interface: 100%
- Method channel: > 90%

### Integration Tests

```bash
cd example
flutter test integration_test/
```

**Platform-Specific Integration Tests:**

```bash
# iOS Simulator
flutter test integration_test/ -d "iPhone 15 Pro"

# Android Emulator
flutter test integration_test/ -d emulator-5554

# Real devices (if available)
flutter test integration_test/ -d <device-id>
```

### Manual Testing Checklist

- [ ] **iOS Device Testing** (with PassKit entitlement)
  - [ ] Request suppression near NFC reader
  - [ ] Verify wallet doesn't appear
  - [ ] Release suppression
  - [ ] Verify wallet appears again
  - [ ] Test rapid request/release cycles
  - [ ] Test app backgrounding/foregrounding
  - [ ] Test all error scenarios

- [ ] **Android Device Testing** (with NFC hardware)
  - [ ] Request suppression near NFC reader
  - [ ] Verify payment apps don't appear
  - [ ] Release suppression
  - [ ] Verify payment apps appear again
  - [ ] Test screen rotation during suppression
  - [ ] Test activity recreation
  - [ ] Test NFC disabled state

- [ ] **Edge Cases**
  - [ ] Multiple rapid request calls
  - [ ] Release without request
  - [ ] Request while already suppressed
  - [ ] Device without NFC hardware
  - [ ] NFC disabled in settings
  - [ ] Insufficient permissions

---

## 📈 Success Metrics

### Code Quality

- [ ] All unit tests pass (100% pass rate)
- [ ] All integration tests pass
- [ ] No analyzer warnings
- [ ] No linting errors
- [ ] No formatting issues
- [ ] API documentation coverage > 90%
- [ ] Test coverage > 80%
- [ ] CI/CD pipeline green

### Pub.dev Score

- [ ] Score > 130/140 (target: 140/140)
- [ ] All static analysis passing (pana)
- [ ] Documentation score at 100%
- [ ] Example score at 100%
- [ ] Test coverage badge added to README
- [ ] Pub.dev topics/tags optimized
- [ ] Screenshots uploaded to pub.dev

### Functional

- [ ] Works reliably on iOS 12.0+
- [ ] Works reliably on Android API 21+
- [ ] No memory leaks
- [ ] State persists across configuration changes
- [ ] Clear error messages for all edge cases
- [ ] All `SuppressionStatus` values tested and working
- [ ] Platform capability detection working correctly

### Testing Metrics

- [ ] **Unit Tests:** Minimum 30 tests (currently 4)
- [ ] **Integration Tests:** Minimum 10 tests (currently 1)
- [ ] **Code Coverage:** > 80% overall
- [ ] **Method Channel Tests:** All methods covered
- [ ] **Platform Tests:** Both iOS and Android covered
- [ ] **Error Scenarios:** All error codes tested
- [ ] **CI/CD Tests:** Automated testing on every commit

### Production Readiness

- [ ] Migration guide complete and clear
- [ ] Security review passed
- [ ] Privacy policy documented
- [ ] CI/CD pipeline operational
- [ ] Publishing checklist followed
- [ ] Example app polished with screenshots
- [ ] All documentation reviewed and accurate

---

## 🚀 Release Notes (Draft for v1.0.0)

### Breaking Changes

- Removed internal API exports (`MethodChannelNfcWalletSuppression`, `NfcWalletSuppressionPlatform`)
  - **Migration:** Use only the public `NfcWalletSuppression` API

### New Features

- Added `isSupported()` method to check platform capability
- Improved error handling and state management
- Enhanced API documentation with examples
- Comprehensive test suite with >80% coverage

### Bug Fixes

- Fixed iOS token management race condition
- Fixed Android state persistence across activity recreation
- Fixed integration tests expecting wrong default state
- Fixed duplicate test names in test suite

### Improvements

- Better logging using `debugPrint()`
- Cleaned up dead code and comments
- Updated metadata and documentation
- Improved example app with better error handling

### Documentation

- Comprehensive API documentation added
- README code examples improved
- CHANGELOG formatting fixed
- Privacy manifest documented

### Testing

- Added 25+ new unit tests
- Added 10+ integration tests
- Test coverage increased from ~30% to >80%
- All platform-specific behaviors tested
- All error scenarios covered
- CI/CD with automated testing

### Production Infrastructure

- Migration guide for smooth upgrades
- GitHub Actions CI/CD pipeline
- Publishing checklist for quality releases
- Enhanced example app with screenshots
- Security and privacy review completed

---

## 📞 Support & Questions

If you have questions about this plan:

1. Review the original analysis document
2. Check Flutter plugin best practices
3. Consult platform-specific documentation:
   - iOS: [PassKit Documentation](https://developer.apple.com/documentation/passkit)
   - Android: [NFC Developer Guide](https://developer.android.com/guide/topics/connectivity/nfc)

---

## 📝 Notes

- All changes should maintain backward compatibility where possible
- Breaking changes should be clearly documented in MIGRATION.md
- Each phase can be committed separately for easier review
- **Follow TDD approach**: Write tests before implementing fixes
- **CI/CD is included**: GitHub Actions for automated testing and publishing
- Consider creating GitHub issues for tracking progress
- Security and privacy are first-class concerns for 1.0.0
- Follow semantic versioning: 1.0.0 indicates stable, production-ready API

## 🎯 Quality & Completeness Goals

### Current State (v0.1.1)

```text
Unit Tests: 4 tests
Integration Tests: 1 test (broken)
Coverage: ~30% (estimated)
Platform Tests: 0
CI/CD: None
Documentation: Basic
Migration Guide: None
Security Review: None
```

### Target State (v1.0.0)

```text
Unit Tests: 30+ tests
Integration Tests: 10+ tests
Coverage: >80%
Platform Tests: iOS + Android specific tests
All error scenarios: Covered
CI/CD: GitHub Actions (testing + publishing)
Documentation: Comprehensive (API docs, migration guide, security)
Migration Guide: Complete
Security Review: Done
Example App: Polished with screenshots
Pub.dev Score: 140/140 (target)
```

### Project File Structure (v1.0.0)

```text
.github/
└── workflows/
    └── ci.yml (new - CI/CD automation)

test/
├── nfc_wallet_suppression_test.dart (existing, enhanced)
├── nfc_wallet_suppression_method_channel_test.dart (existing, enhanced)
├── nfc_wallet_suppression_ios_test.dart (new)
├── nfc_wallet_suppression_android_test.dart (new)
├── nfc_wallet_suppression_platform_test.dart (new)
└── nfc_wallet_suppression_error_test.dart (new)

example/
├── integration_test/
│   ├── plugin_integration_test.dart (existing, fixed)
│   └── comprehensive_integration_test.dart (new)
└── screenshots/ (new)
    ├── ios_initial.png
    ├── ios_suppressed.png
    ├── android_initial.png
    └── android_suppressed.png

MIGRATION.md (new - upgrade guide)
PUBLISHING.md (new - release checklist)
SECURITY.md (new - security policy)
IMPROVEMENT_PLAN.md (this file)
```

## 🔄 Continuous Testing & Development Workflow

### Local Development Commands

```bash
# Run tests on every change
flutter test --watch

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run integration tests
cd example
flutter test integration_test/

# Run analyzer
flutter analyze

# Check formatting
dart format --set-exit-if-changed .

# Run all quality checks (pre-commit)
flutter test && flutter analyze && dart format --set-exit-if-changed .

# Pub.dev dry run
dart pub publish --dry-run

# Check package score locally
dart pub global activate pana
pana --no-warning
```

### CI/CD Automation (GitHub Actions)

The CI pipeline will automatically:

- Run tests on every push and PR
- Generate and upload coverage reports
- Run analyzer and format checks
- Build example app for iOS and Android
- Publish to pub.dev on version tags
- Create GitHub releases with changelog

### Pre-Release Checklist

```bash
# 1. Run full test suite
flutter test

# 2. Verify coverage
flutter test --coverage

# 3. Analyze code
flutter analyze

# 4. Format code
dart format .

# 5. Test example app
cd example && flutter run

# 6. Verify pub.dev package
cd .. && dart pub publish --dry-run

# 7. Check package score
pana --no-warning

# 8. Update version and changelog
# Edit pubspec.yaml and CHANGELOG.md

# 9. Commit and tag
git add .
git commit -m "chore: prepare v1.0.0 release"
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin master --tags

# 10. CI/CD will handle publishing
```
