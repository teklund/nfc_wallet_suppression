# CI/CD Testing Strategy

This document explains the testing strategy for the `nfc_wallet_suppression` Flutter plugin.

## Overview

CI is consolidated into a single workflow, `ci.yml`, supplemented by an integration test workflow:

| Workflow                  | Purpose                              | Tests / Builds                                  | Frequency        |
| ------------------------- | ------------------------------------ | ----------------------------------------------- | ---------------- |
| **ci.yml**                | PR validation + main branch CI       | Format, analyze, pigeon codegen drift, Dart tests, native tests, platform builds, Pub Score, publish dry-run | Every PR / push  |
| **integration_tests.yml** | E2E testing on real-ish devices      | Flutter integration tests                        | Manual only; re-enabling tracked in #24 |

## How ci.yml Runs

`.github/workflows/ci.yml` is the source of truth for its jobs, and each run's summary page on GitHub shows the exact job graph. The rules that shape it:

- **Analyze Code** and **Pigeon Codegen Drift** wait for **Check Formatting**.
- **Check Changes** and **Dependency Review** (pull requests only) run on their own. Everything else waits for **Analyze Code**: Dart tests, Pub Score Check, Publish Dry Run and the platform jobs.
- Platform jobs (native tests and builds) run only when **Check Changes** finds changes for that platform.
- Jobs with a `flutter-version` matrix run on both the minimum supported Flutter version and `stable`.
- **Android Native Tests** also runs once on `stable` with AGP 9's built-in Kotlin on, the other branch of the plugin's `build.gradle`.
- **CI Success** is the one required check: it fails if any job failed or was cancelled, and treats skipped jobs as passing.

Codecov uploads happen from three jobs and are tagged with these flags (see `codecov.yml`):

- `dart` — uploaded by **Run Tests & Coverage** (stable matrix entry only, to avoid duplicates)
- `android` — uploaded by **Android Native Tests**
- `ios` — uploaded by **iOS Native Tests**

## Where Tests Run

| Test Type           | Where                          |
| ------------------- | ------------------------------ |
| Dart unit tests     | `Run Tests & Coverage`         |
| Android native      | `Android Native Tests`         |
| iOS native          | `iOS Native Tests`             |
| Integration tests   | `integration_tests.yml`        |

## When to Run Which Tests

**During development (local):**

```bash
# Quick feedback — Dart only
flutter test

# Full pre-push
flutter test
cd example/android && ./gradlew :nfc_wallet_suppression:testDebugUnitTest
# iOS: see docs/NATIVE_COVERAGE.md ("Run locally") for the full xcodebuild invocation
```

**On every PR (automated):** ci.yml runs the relevant subset based on changed paths. All required jobs must pass before merge.

**On main branch (automated):** Same as PR; validates the merge.

## Coverage Collection

| Job                         | Dart Coverage           | Android Coverage    | iOS Coverage         |
| --------------------------- | ----------------------- | ------------------- | -------------------- |
| Run Tests & Coverage (stable) | Uploaded as `dart` flag | —                   | —                    |
| Run Tests & Coverage (3.44.x) | Generated, not uploaded | —                   | —                    |
| Android Native Tests        | —                       | Uploaded as `android` flag | —             |
| iOS Native Tests            | —                       | —                   | Uploaded as `ios` flag |

Codecov status checks (`codecov/project`, `codecov/patch`) are currently `informational: true` while the 1.0.0 baseline stabilizes; they will flip to enforcing per the schedule in `codecov.yml`.

## Troubleshooting

### Build Failures

1. Check Flutter doctor output in failure logs.
2. Verify Gradle / CocoaPods / SPM dependencies resolved.
3. For Android: confirm the Java toolchain is JDK 17 (set in `example/android/app/build.gradle.kts` via `java { toolchain { languageVersion = 17 } }`).

### Coverage Upload Issues

- Verify `CODECOV_TOKEN` secret is set in repository settings.
- Codecov uploads use `fail_ci_if_error: false`, so a transient upload failure won't block CI.
- If `ios` flag shows zero coverage, confirm `codecov.yml`'s flag scope still matches the iOS source location (currently `ios/nfc_wallet_suppression/Sources/`).

---

_Plugin Version: 1.0.0_
