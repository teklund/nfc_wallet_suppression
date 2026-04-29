# Native Test Coverage Guide

How code coverage is collected and reported for the `nfc_wallet_suppression` Flutter plugin.

## Overview

The plugin collects coverage for all three layers and uploads each as a separate Codecov flag so regressions in one platform don't get hidden by gains in another:

- **Dart** — Flutter's built-in coverage (lcov), uploaded as flag `dart`
- **Android** — JaCoCo (XML), uploaded as flag `android`
- **iOS** — Xcode `xccov` (JSON), uploaded as flag `ios`

All three flags are also defined in `codecov.yml` with path scoping and carryforward, so a missing upload from one job (e.g. Android skipped on a Dart-only PR) doesn't drop coverage for that platform to zero.

## Android Coverage (JaCoCo)

JaCoCo configuration lives in `android/build.gradle`:

```groovy
apply plugin: "jacoco"

android {
    buildTypes {
        debug {
            testCoverageEnabled = true
        }
    }

    testOptions {
        unitTests.returnDefaultValues = true   // android.* stubs return null/0 instead of throwing
        unitTests.all {
            useJUnitPlatform()
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

tasks.register('jacocoTestReport', JacocoReport) {
    dependsOn 'testDebugUnitTest'
    reports {
        xml.required = true
        html.required = true
        xml.outputLocation.set(layout.buildDirectory.file("reports/jacoco/test/jacocoTestReport.xml"))
        html.outputLocation.set(layout.buildDirectory.dir("reports/jacoco/test/html"))
    }
    // ... source / class / execution data wiring ...
}
```

### Excluded from Android coverage

- `**/R.class`, `**/R$*.class`, `**/BuildConfig.*`, `**/Manifest*.*` — generated
- `**/*Test*.*`, `**/*Fake*.*` — test code

### Run locally

```bash
cd example/android
./gradlew :nfc_wallet_suppression:testDebugUnitTest \
          :nfc_wallet_suppression:jacocoTestReport
```

Reports:

- XML: `example/build/nfc_wallet_suppression/reports/jacoco/test/jacocoTestReport.xml`
- HTML: `example/build/nfc_wallet_suppression/reports/jacoco/test/html/index.html`

### CI

The `Android Native Tests` job in `ci.yml`:

1. Runs `:nfc_wallet_suppression:testDebugUnitTest :nfc_wallet_suppression:jacocoTestReport`
2. Uploads the XML report to Codecov with `flags: android`

## iOS Coverage (xccov)

iOS coverage is enabled by `xcodebuild test -enableCodeCoverage YES` and extracted from the resulting `.xcresult` bundle.

### Run locally

```bash
cd example/ios
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=<simulator>,OS=latest' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Human-readable summary
xcrun xccov view --report TestResults.xcresult

# JSON for upload
xcrun xccov view --report --json TestResults.xcresult > coverage.json
```

### CI

The `iOS Native Tests` job in `ci.yml`:

1. Runs `xcodebuild test … -enableCodeCoverage YES`
2. Extracts JSON via `xcrun xccov view --report --json`
3. Uploads the JSON to Codecov with `flags: ios`

`codecov.yml` scopes the iOS flag to `ios/nfc_wallet_suppression/Sources/`, matching the SPM-based source layout introduced in 1.0.0.

## Dart Coverage

```bash
flutter test --coverage   # generates coverage/lcov.info
```

`Run Tests & Coverage (stable)` in `ci.yml` uploads `coverage/lcov.info` to Codecov with `flags: dart`. The 3.35.x matrix entry generates coverage but doesn't upload, to avoid duplicate uploads.

## Codecov Integration

### Flags

- `dart` — scope `lib/`
- `android` — scope `android/src/main/`
- `ios` — scope `ios/nfc_wallet_suppression/Sources/`

`carryforward: true` is set on all three so a missing upload preserves the last-known value rather than collapsing the score.

### Status checks

`codecov/project` and `codecov/patch` are currently `informational: true` while the 1.0.0 baseline stabilizes. After enough post-merge data has accumulated, they flip to enforcing. Project target: `auto` with `threshold: 1%`. Patch target: `60%`.

### Viewing coverage

- Dashboard: https://codecov.io/gh/teklund/nfc_wallet_suppression
- Badge in `README.md`

## Current Coverage (1.0.0 baseline)

| Layer   | Coverage | Notes                                                                |
| ------- | -------- | -------------------------------------------------------------------- |
| Dart    | high     | Pigeon-generated bridge + small public API; `*pigeon.dart` ignored   |
| Android | low      | Only the no-NFC-hardware path is exercised in JVM unit tests         |
| iOS     | low      | PassKit suppression APIs require a real device for end-to-end paths  |

Project coverage at the 1.0.0 cut: ~45%. The dominant gap is `NfcWalletSuppressionPlugin.kt`'s success/failure paths, which are tracked separately for follow-up — see the GitHub issue on improving native test coverage.

## Why native coverage is lower

- **Real hardware required** for many NFC and PassKit code paths
- **Activity / Context** dependence on Android — true unit tests would need Robolectric or static-mocking of `NfcAdapter.getDefaultAdapter()`
- **Simulator limitations** for iOS PassKit suppression
- Native tests today focus on testable wrappers and the no-hardware path

Native code is also validated through:

- Integration tests in the example app (`integration_tests.yml`)
- Manual testing on real devices

## Improving native coverage

### Android

- Static-mock `NfcAdapter.getDefaultAdapter()` (Mockito 5.x supports this) to exercise success/failure paths beyond the null-adapter branch
- Add Robolectric-based tests for Activity-dependent flows
- Consider instrumented tests for hardware-tied logic

### iOS

- Add real-device CI runs for PassKit-dependent paths
- Extend the existing PassKit protocol mocks for non-success branches
- More integration tests in the example app

### Both

- Once native coverage stabilizes, flip `codecov.yml` from `informational: true` to enforcing

## Troubleshooting

### Android coverage missing

- Tests ran successfully? `./gradlew testDebugUnitTest`
- JaCoCo task ran? Look for `:jacocoTestReport` in output
- Exec file present? `example/build/nfc_wallet_suppression/outputs/unit_test_code_coverage/debugUnitTest/testDebugUnitTest.exec`

### iOS coverage missing

- `-enableCodeCoverage YES` set on the `xcodebuild test` call?
- `TestResults.xcresult` bundle produced?
- `xcrun xccov view --report TestResults.xcresult` shows data?

### Codecov upload fails

- Is `CODECOV_TOKEN` configured in GitHub secrets?
- Coverage file format valid?
- Workflow uses `fail_ci_if_error: false`, so upload failures don't fail CI — but they also won't update Codecov.

## References

- [JaCoCo](https://www.jacoco.org/jacoco/trunk/doc/)
- [Xcode Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [Codecov](https://docs.codecov.com/)
- [Flutter Test Coverage](https://flutter.dev/docs/testing/overview#test-coverage)

---

_Plugin Version: 1.0.0_
