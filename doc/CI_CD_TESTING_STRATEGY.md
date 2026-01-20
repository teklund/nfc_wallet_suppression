# CI/CD Testing Strategy

This document explains the testing strategy across different CI/CD workflows for the `nfc_wallet_suppression` Flutter plugin.

## Overview

The plugin uses multiple GitHub Actions workflows with distinct purposes:

| Workflow                  | Purpose            | Tests               | OS Versions | Frequency |
| ------------------------- | ------------------ | ------------------- | ----------- | --------- |
| **pull_request.yml**      | PR validation      | All (Dart + Native) | Latest      | Every PR  |
| **platform_builds.yml**   | Build verification | None (builds only)  | Current     | Every PR  |
| **sdk_compatibility.yml** | Flutter SDK compat | Dart only           | Current     | Weekly    |
| **integration_tests.yml** | E2E testing        | Integration         | Latest      | Every PR  |

## Workflow Details

### 1. Pull Request Workflow (`pull_request.yml`)

**Purpose:** Comprehensive validation of all code changes

**Test Coverage:**

- ✅ Dart unit tests (69 tests, comprehensive coverage)
- ✅ Android native tests (8 tests)
- ✅ iOS native tests (15 tests)
- ✅ Code formatting
- ✅ Static analysis
- ✅ Package validation

**OS Versions:** Current/Latest

- Android: Latest available in CI
- iOS: Latest available on macos-latest runner

**Coverage Reports:** All three layers uploaded to Codecov

- `unittests` flag - Dart coverage
- `android` flag - Android native coverage
- `ios` flag - iOS native coverage

**When it runs:** On every pull request and push to main/master

---

### 2. Platform Builds Workflow (`platform_builds.yml`)

**Purpose:** Verify that the plugin builds successfully on Android and iOS platforms

**Build Coverage:**

- ✅ Android APK build (debug)
- ✅ Android App Bundle build (debug)
- ✅ iOS app build (debug, no codesign)

**Why separate from tests?**

1. **Speed:** Builds run in parallel with tests for faster CI feedback
2. **Scope:** Focused on compilation/build issues, not functionality
3. **Artifacts:** Generates APK/iOS builds for manual testing if needed
4. **Independence:** Can pass even if tests are being fixed

**No Tests Run:** This workflow only verifies builds compile. All tests run in `pull_request.yml`

**Artifacts:**

- `android-apk` - Debug APK for manual testing
- `ios-build` - iOS app bundle

**When it runs:** On every pull request and push to main/master

---

### 3. SDK Compatibility Workflow (`sdk_compatibility.yml`)

**Purpose:** Detect breaking changes in Flutter SDK (stable & beta channels)

**Test Coverage:**

- ✅ Dart tests only (Flutter SDK compatibility)
- ✅ Code formatting
- ✅ Static analysis

**Why NOT include native tests?**

1. **Focus:** Detects Dart API breaking changes, not native platform changes
2. **Speed:** Runs weekly on schedule, should complete quickly
3. **Redundancy:** Native tests already covered in `pull_request.yml` and `platform_builds.yml`
4. **Native Stability:** Native code rarely affected by Flutter SDK updates

**Flutter Channels Tested:**

- `stable` - Current stable release
- `beta` - Beta channel (early warning of upcoming changes)

**Failure Handling:** Automatically creates GitHub issue on failure

**When it runs:**

- Weekly on Monday at 9:00 AM UTC (scheduled)
- Manual trigger via workflow_dispatch

---

### 4. Integration Tests Workflow (`integration_tests.yml`)

**Purpose:** End-to-end testing with Flutter integration test framework

**Test Coverage:**

- ✅ Full plugin integration tests
- ✅ Example app validation
- ✅ Platform channel communication

**OS Versions:** Current/Latest

**When it runs:** On every pull request and push to main/master

---

## Test Execution Summary

### Total Test Count: **88 Tests**

| Test Type             | Count | Where Executed                              |
| --------------------- | ----- | ------------------------------------------- |
| **Dart Unit Tests**   | 65    | `pull_request.yml`, `sdk_compatibility.yml` |
| **Android Native**    | 8     | `pull_request.yml`                          |
| **iOS Native**        | 15    | `pull_request.yml`                          |
| **Integration Tests** | TBD   | `integration_tests.yml`                     |
| **Builds**            | 3     | `platform_builds.yml` (APK, AAB, iOS)       |

### Per-Workflow Test Execution

**pull_request.yml:** 88 tests (65 Dart + 8 Android + 15 iOS)

- Single execution on current/latest OS

**platform_builds.yml:** No tests - builds only

- Android: APK + App Bundle
- iOS: App build

**sdk_compatibility.yml:** 130 tests (65 Dart × 2 channels)

- Stable channel: 65 tests
- Beta channel: 65 tests

**Total test executions per PR:** ~218 test runs (88 + 130 compatibility)

---

---

## Coverage Collection

### Where Coverage is Collected

| Workflow                  | Dart Coverage              | Android Coverage     | iOS Coverage         |
| ------------------------- | -------------------------- | -------------------- | -------------------- |
| **pull_request.yml**      | ✅ Upload to Codecov       | ✅ Upload to Codecov | ✅ Upload to Codecov |
| **platform_builds.yml**   | ❌ Not collected           | ❌ Not uploaded      | ❌ Not uploaded      |
| **sdk_compatibility.yml** | ✅ Generated, not uploaded | ❌ N/A               | ❌ N/A               |
| **integration_tests.yml** | ✅ Generated, not uploaded | ❌ N/A               | ❌ N/A               |

**Why coverage only from pull_request.yml?**

- Avoid duplicate uploads to Codecov
- pull_request.yml runs on every change (authoritative source)
- Other workflows focus on compatibility, not coverage metrics

---

## Best Practices

### When to Run Which Tests

**During Development (Local):**

```bash
# Quick feedback - Dart tests only
flutter test

# Before commit - All tests
flutter test && \
  cd example/android && ./gradlew testDebugUnitTest && \
  cd ../ios && xcodebuild test ...
```

**Pull Request (Automated):**

- All tests run automatically
- Must pass before merge

**Post-Merge (Automated):**

- Same tests run on main branch
- Validates merge didn't break anything

**Weekly (Automated):**

- SDK compatibility check
- Early warning of Flutter SDK issues

### Continuous Improvement

**Current Status:** ✅ Comprehensive test coverage with OS version matrix

**Future Enhancements:**

1. **Real Device Testing:** Add tests on physical devices (future)
2. **Performance Benchmarks:** Add performance regression tests
3. **Additional OS Versions:** Test mid-range OS versions if needed
4. **More Integration Tests:** Expand E2E test coverage

---

### Troubleshooting

### Build Failures

If platform builds fail:

1. Check Flutter doctor output in failure logs
2. Verify Gradle/CocoaPods dependencies
3. Ensure all native dependencies are compatible
4. Check for platform-specific compilation errors

### Coverage Upload Issues

If Codecov uploads fail in pull_request.yml:

- Verify `CODECOV_TOKEN` secret is set in repository
- Check coverage files were generated
- Review Codecov action logs
- Uploads use `fail_ci_if_error: false` so won't block CI

---

## Workflow Dependency Graph

```
Pull Request → [Format, Analyze, Test (all), Native Tests (min/max OS), Platform Builds] → Merge
                                    ↓
                            Upload to Codecov

Weekly Schedule → SDK Compatibility → Create Issue (on failure)

Manual Trigger → Integration Tests
```

---

_Last Updated: November 2024_  
_Plugin Version: 1.0.0_  
_Branch: phase-4_
