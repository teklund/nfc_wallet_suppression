# CI/CD Testing Strategy

This document explains the testing strategy for the `nfc_wallet_suppression` Flutter plugin.

## Overview

CI is consolidated into a single workflow, `ci.yml`, supplemented by an integration test workflow:

| Workflow                  | Purpose                              | Tests / Builds                                  | Frequency        |
| ------------------------- | ------------------------------------ | ----------------------------------------------- | ---------------- |
| **ci.yml**                | PR validation + main branch CI       | Format, analyze, Dart tests, native tests, Android/iOS builds, Pub Score, publish dry-run | Every PR / push  |
| **integration_tests.yml** | E2E testing on real-ish devices      | Flutter integration tests                        | Every PR / push  |

`ci.yml` runs change-aware: only the relevant jobs fire when a path doesn't affect them (see `Check Changes` job).

## ci.yml Job Map

```text
Check Changes ─┬─ Check Formatting ──┬─ Analyze Code (3.35.x | stable)
               │                     ├─ Run Tests & Coverage (3.35.x | stable)
               │                     ├─ Pub Score Check
               │                     └─ Publish Dry Run
               │
               ├─ Android Native Tests   (only if android files changed)
               ├─ Build Android          (only if android files changed)
               ├─ Build iOS              (only if ios files changed)
               └─ iOS Native Tests       (only if ios files changed)
```

Codecov uploads happen from three jobs and are tagged with these flags (see `codecov.yml`):

- `dart` — uploaded by **Run Tests & Coverage** (stable matrix entry only, to avoid duplicates)
- `android` — uploaded by **Android Native Tests**
- `ios` — uploaded by **iOS Native Tests**

## Test Counts

| Test Type           | Count | Where                          |
| ------------------- | ----- | ------------------------------ |
| Dart unit tests     | 84    | `Run Tests & Coverage`         |
| Android native      | 6     | `Android Native Tests`         |
| iOS native          | varies | `iOS Native Tests`            |
| Integration tests   | varies | `integration_tests.yml`       |

Counts move with the codebase; treat the table as a snapshot, not a contract.

## When to Run Which Tests

**During development (local):**

```bash
# Quick feedback — Dart only
flutter test

# Full pre-push
flutter test
cd example/android && ./gradlew :nfc_wallet_suppression:testDebugUnitTest
cd ../ios && xcodebuild test ...   # see iOS Native Tests job for the exact invocation
```

**On every PR (automated):** ci.yml runs the relevant subset based on changed paths. All required jobs must pass before merge.

**On main branch (automated):** Same as PR; validates the merge.

## Coverage Collection

| Job                         | Dart Coverage           | Android Coverage    | iOS Coverage         |
| --------------------------- | ----------------------- | ------------------- | -------------------- |
| Run Tests & Coverage (stable) | Uploaded as `dart` flag | —                   | —                    |
| Run Tests & Coverage (3.35.x) | Generated, not uploaded | —                   | —                    |
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
