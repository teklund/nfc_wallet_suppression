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
# Builds the plugin pods first; without it the Runner target can't build.
cd example
flutter build ios --debug --simulator --no-codesign

# Use the id of any iPhone from `xcrun simctl list devices available`. A name
# alone matches only simulators on the newest installed iOS runtime.
cd ios
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,id=<simulator id>' \
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

# Optional HTML report; genhtml comes with lcov (brew install lcov)
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

`Run Tests & Coverage (stable)` in `ci.yml` uploads `coverage/lcov.info` to Codecov with `flags: dart`. The 3.44.x matrix entry generates coverage but doesn't upload, to avoid duplicate uploads.

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

## Current Coverage

| Layer   | Coverage | Notes                                                                                                                        |
| ------- | -------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Dart    | high     | Every hand-written file in `lib/`                                                                                            |
| Android | high     | The plugin runs against a fake suppressor; `SystemWalletSuppressor` runs against static mocks of `NfcAdapter` and `ContextCompat` |
| iOS     | high     | The plugin runs against a fake PassKit library and scheduler                                                                 |

Pigeon-generated files are ignored on every platform (see `codecov.yml`); pigeon tests its own output. Local JaCoCo and xccov reports still include them.

## What Unit Tests Can't Cover

- Real NFC hardware, and Android's reader-mode behavior across devices and versions
- Real PassKit suppression, which needs a physical iPhone and the entitlement

These are checked on real devices. `integration_tests.yml` runs only on demand until #24 re-enables it.

## Improving Native Coverage

- Re-enable `integration_tests.yml` on pull requests (#24)
- Once coverage is stable, switch `codecov.yml` from `informational: true` to enforcing

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
