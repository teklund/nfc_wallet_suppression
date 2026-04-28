# Native Test Coverage Guide

This document explains how native test coverage is collected and reported for the `nfc_wallet_suppression` Flutter plugin.

## Overview

The plugin now supports code coverage collection for all three layers:
- **Dart**: Using Flutter's built-in coverage tool (lcov format)
- **Android**: Using JaCoCo for Kotlin/Java code
- **iOS**: Using Xcode's built-in coverage tool (xccov)

All coverage reports are automatically uploaded to [Codecov.io](https://codecov.io) during CI/CD runs.

## Android Coverage (JaCoCo)

### Configuration

The Android module uses JaCoCo for code coverage. Configuration is in `android/build.gradle`:

```groovy
apply plugin: "jacoco"

android {
    buildTypes {
        debug {
            testCoverageEnabled = true
        }
    }
    
    testOptions {
        unitTests.all {
            jacoco {
                includeNoLocationClasses = true
                excludes = ['jdk.internal.*']
            }
        }
    }
}

jacoco {
    toolVersion = "0.8.12"
}
```

### Excluded Files

The following files are excluded from Android coverage:
- `**/R.class` - Android resources
- `**/BuildConfig.*` - Build configuration
- `**/*Test*.*` - Test files
- `**/*Fake*.*` - Test doubles (FakeNfcAdapterWrapper)
- `**/*Wrapper*.*` - Test-only wrapper classes

### Local Usage

Generate coverage report locally:

```bash
cd example/android
./gradlew :nfc_wallet_suppression:testDebugUnitTest :nfc_wallet_suppression:jacocoTestReport
```

View reports:
- **XML**: `example/build/nfc_wallet_suppression/reports/jacoco/test/jacocoTestReport.xml`
- **HTML**: `example/build/nfc_wallet_suppression/reports/jacoco/test/html/index.html`

### CI/CD Integration

The GitHub Actions workflow automatically:
1. Runs tests with coverage enabled: `testDebugUnitTest`
2. Generates JaCoCo report: `jacocoTestReport`
3. Uploads XML report to Codecov with flag `android`

```yaml
- name: Run Android tests with coverage
  run: ./gradlew :nfc_wallet_suppression:testDebugUnitTest :nfc_wallet_suppression:jacocoTestReport

- name: Upload Android coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    files: example/build/nfc_wallet_suppression/reports/jacoco/test/jacocoTestReport.xml
    flags: android
    name: android-coverage
```

### Coverage Metrics

Current Android native coverage focuses on:
- `NfcWalletSuppressionPlugin.kt` - Main plugin implementation
- Method call handling
- NFC adapter interactions
- Error handling paths

**Note**: Some methods have low coverage because they require real Android Activity context and NFC hardware. These are covered by integration tests in the example app.

## iOS Coverage (xccov)

### Configuration

iOS coverage is enabled via xcodebuild command-line flag:

```bash
xcodebuild test \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult
```

### Coverage Extraction

Coverage data is extracted from `.xcresult` bundle:

```bash
# Extract coverage in JSON format
xcrun xccov view --report --json TestResults.xcresult > coverage.json

# View coverage summary
xcrun xccov view --report TestResults.xcresult
```

### Local Usage

Run tests with coverage:

```bash
cd example/ios

# Run tests with coverage
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage
xcrun xccov view --report TestResults.xcresult
```

### CI/CD Integration

The GitHub Actions workflow automatically:
1. Runs tests with coverage: `-enableCodeCoverage YES`
2. Extracts coverage: `xcrun xccov view --report --json`
3. Uploads to Codecov with flag `ios`

```yaml
- name: Run iOS tests with coverage
  run: |
    xcodebuild test \
      -enableCodeCoverage YES \
      -resultBundlePath TestResults.xcresult

- name: Convert iOS coverage
  run: xcrun xccov view --report --json TestResults.xcresult > coverage.json

- name: Upload iOS coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    files: example/ios/coverage.json
    flags: ios
    name: ios-coverage
```

### Coverage Metrics

Current iOS native coverage focuses on:
- `NfcWalletSuppressionPlugin.swift` - Main plugin implementation
- PassKit interactions
- Result handling
- Error paths

**Note**: Some iOS methods require real device testing because PassKit APIs are not fully functional in simulators.

## Dart Coverage

### Configuration

Dart coverage uses Flutter's built-in tool:

```bash
flutter test --coverage
```

Generates: `coverage/lcov.info`

### CI/CD Integration

```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    files: coverage/lcov.info
    flags: unittests
    name: flutter-coverage
```

## Codecov Integration

### Coverage Flags

Coverage reports are uploaded with different flags for filtering:

- `unittests` - Dart unit tests (65 tests, 100% coverage)
- `android` - Android native tests (8 tests)
- `ios` - iOS native tests (15 tests)

### Viewing Coverage

1. Visit: https://codecov.io/gh/teklund/nfc_wallet_suppression
2. Filter by flag to see platform-specific coverage
3. View file-level coverage for specific implementations

### Badge

The README includes a Codecov badge showing overall coverage:

```markdown
[![codecov](https://codecov.io/gh/teklund/nfc_wallet_suppression/graph/badge.svg?token=JRPE6FQF2T)](https://codecov.io/gh/teklund/nfc_wallet_suppression)
```

## Coverage Goals

### Current Status

| Layer | Coverage | Notes |
|-------|----------|-------|
| **Dart** | 100% | All source files covered |
| **Android** | ~6% | Only unit-testable code (wrapper tests excluded) |
| **iOS** | TBD | Extracted but not integrated yet |

### Why Low Native Coverage?

Native coverage is lower than Dart because:

1. **Real Hardware Required**: Many NFC and PassKit APIs require real devices
2. **Activity/Context**: Android plugin requires Activity context not available in unit tests
3. **Simulator Limitations**: iOS PassKit doesn't work fully in simulators
4. **Test Focus**: Native tests focus on testable logic (wrappers, method routing)

Native code is validated through:
- ✅ Unit tests for testable logic
- ✅ Integration tests in example app
- ✅ Manual testing on real devices

## Improving Native Coverage

To improve native coverage in the future:

### Android
1. **Instrument Tests**: Add instrumented tests that run on emulator/device
2. **Robolectric**: Use Robolectric for Android framework mocking
3. **More Wrappers**: Wrap more Android APIs for testability

### iOS
1. **Real Device Tests**: Run tests on real devices in CI
2. **More Protocols**: Create protocols for more PassKit interactions
3. **Integration Tests**: Add more integration test scenarios

### Both Platforms
1. **Test Coverage Gates**: Set minimum coverage thresholds
2. **Coverage Trending**: Track coverage over time
3. **Uncovered Code Review**: Regularly review uncovered code paths

## Troubleshooting

### Android Coverage Not Generated

Check that:
- Tests ran successfully: `./gradlew testDebugUnitTest`
- JaCoCo task executed: Look for `:jacocoTestReport` in output
- Exec file exists: `example/build/nfc_wallet_suppression/outputs/unit_test_code_coverage/debugUnitTest/testDebugUnitTest.exec`

### iOS Coverage Not Generated

Check that:
- Coverage flag was used: `-enableCodeCoverage YES`
- Result bundle exists: `TestResults.xcresult`
- xccov command works: `xcrun xccov view --report TestResults.xcresult`

### Codecov Upload Fails

Common issues:
- Missing `CODECOV_TOKEN` secret in GitHub repository settings
- Invalid coverage file format
- Network issues during upload

The workflow uses `fail_ci_if_error: false` so coverage upload failures won't block CI.

## References

- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)
- [Xcode Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [Codecov Documentation](https://docs.codecov.com/)
- [Flutter Test Coverage](https://flutter.dev/docs/testing/overview#test-coverage)

---

*Last Updated: April 2026*  
*Plugin Version: 1.0.0*  
*Branch: phase-4*
