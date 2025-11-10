# CI/CD Pipeline Improvement Plan

## Overview

This document outlines improvements needed for the GitHub Actions workflows to fix issues, optimize performance, and follow best practices.

---

## Critical Issues (Must Fix)

### 1. Dart SDK Version Compatibility ✅ COMPLETED

**Problem**: `pubspec.yaml` required Dart `^3.7.0`, but this was more restrictive than ecosystem standards and incompatible with older Flutter versions.

**Impact**: Workflows failed with older Flutter versions, limiting adoption and compatibility

**Solution Implemented**: Updated to Dart `^3.2.0` and Flutter `>=3.16.0` to match the actual Dart version shipped with Flutter 3.16.0

**Files Updated**:

- `pubspec.yaml` - Changed from `sdk: ^3.7.0` to `sdk: ^3.2.0`, Flutter from `>=3.22.0` to `>=3.16.0`, `flutter_lints` from `^5.0.0` to `^4.0.0`
- `example/pubspec.yaml` - Changed from `sdk: ^3.7.0` to `sdk: ^3.2.0`, added `flutter: '>=3.16.0'`, `flutter_lints` from `^5.0.0` to `^4.0.0`
- `example/ios/Podfile` - Set minimum iOS platform to `13.0` (required by modern Flutter)
- `example/ios/Runner.xcodeproj/project.pbxproj` - Updated `IPHONEOS_DEPLOYMENT_TARGET` from `12.0` to `13.0`
- `android/src/main/AndroidManifest.xml` - Added `flutterEmbedding` v2 declaration
- `.github/workflows/pull_request.yml` - Changed test matrix from 3.27.0 to 3.22.x and stable

---

## High Priority Issues

### 2. Broken Test Result Extraction ✅ COMPLETED

**Problem**: The "Extract and display test results" step in `pull_request.yml` re-ran tests instead of parsing actual output. The conditional logic never found the files it was looking for.

**Solution Implemented**: Removed the wasteful step entirely since:

- Test results are already shown via `--reporter=github`
- Re-running tests was wasteful and didn't capture original results
- Coverage is already uploaded separately

**Files Updated**:

- `.github/workflows/pull_request.yml` (removed lines 116-127)

---

### 3. Pana Score Regex Not Cross-Platform ✅ COMPLETED

**Problem**: `grep -oP` uses Perl regex, which isn't available on macOS or BSD systems by default.

**Solution Implemented**: Changed to POSIX-compliant grep:

```bash
SCORE=$(grep -o 'Score: [0-9]*' pana-output.txt | grep -o '[0-9]*' | tail -1 || echo "0")
```

**Files Updated**:

- `.github/workflows/pull_request.yml` (line 210)

---

## Medium Priority Optimizations

### 4. Optimize Job Dependencies ✅ COMPLETED

**Problem**: `publish-dry-run` and `pana` both waited for `analyze` to complete, but could run in parallel with `test`.

**Solution Implemented**: Changed both jobs to depend on `format` instead of `analyze`, allowing them to run in parallel with both `analyze` and `test`.

**New Flow**:

```
format → analyze (parallel with below)
    ↓ → test
    ↓ → publish-dry-run
    ↓ → pana
```

**Benefits**:

- Reduces overall workflow time by ~5-10 minutes
- Provides faster feedback on package quality issues

**Files Updated**:

- `.github/workflows/pull_request.yml` (changed `needs: analyze` to `needs: format` for both jobs)

---

### 5. Run Package Validation Only on PRs ✅ COMPLETED

**Problem**: `publish-dry-run` and `pana` ran on every push to main/master, which was redundant since they already ran in the PR.

**Solution Implemented**: Added condition to only run on pull requests:

```yaml
publish-dry-run:
  name: Publish Dry Run
  if: github.event_name == 'pull_request'
  ...

pana:
  name: Pub Score Check
  if: github.event_name == 'pull_request'
  ...
```

**Benefits**:

- Saves CI minutes
- Faster main branch builds

**Files Updated**:

- `.github/workflows/pull_request.yml` (added `if: github.event_name == 'pull_request'` to both jobs)

---

### 6. Consolidate Environment Info Printing ✅ COMPLETED

**Problem**: Every job printed similar environment info, creating noise in logs.

**Solution Implemented**: Removed duplicate environment info printing from secondary jobs, keeping only in the first job of each workflow.

**Benefits**:

- Cleaner logs
- Faster job execution (~5-10s saved per job)

**Files Updated**:

- `.github/workflows/pull_request.yml` - Removed from analyze, test, publish-dry-run, and pana jobs
- `.github/workflows/integration_tests.yml` - Removed from iOS job
- `.github/workflows/platform_builds.yml` - Removed from iOS job

---

## Low Priority Improvements

### 7. Add Pub Cache Sharing

**Problem**: Each job downloads dependencies separately, wasting time and bandwidth.

**Solution**: Add pub cache to Flutter action or use separate caching:

```yaml
- name: Cache Pub Dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      **/.dart_tool
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-
```

**Benefits**:

- Faster `flutter pub get` (from ~30s to ~5s)
- Reduced network usage

**Files to Update**: All workflow files with Flutter setup

---

### 8. Remove Redundant `continue-on-error: false` ✅ COMPLETED

**Problem**: `sdk_compatibility.yml` explicitly set `continue-on-error: false`, which is already the default.

**Solution Implemented**: Removed all three redundant instances from formatting, analysis, and test steps.

**Files Updated**:

- `.github/workflows/sdk_compatibility.yml` (lines 50, 54, 58)

---

### 9. Improve Test Summary Display

**Problem**: "Print test environment" step runs after tests complete but doesn't show actual test results.

**Current Code** (lines 129-134):

```yaml
- name: Print test environment
  run: |
    echo "## 🧪 Test Environment" >> $GITHUB_STEP_SUMMARY
    echo "**Flutter:** $(flutter --version | head -n 1)" >> $GITHUB_STEP_SUMMARY
```

**Solution**: Either:

- Remove this step (redundant with earlier env info)
- Replace with actual test metrics if available

**Files to Update**:

- `.github/workflows/pull_request.yml`

---

### 10. Add Workflow Status Badges

**Problem**: No visibility into CI status from README.

**Solution**: Add status badges to `README.md`:

```markdown
[![Pull Request](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/pull_request.yml/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/pull_request.yml)
[![Platform Builds](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/platform_builds.yml/badge.svg)](https://github.com/teklund/nfc_wallet_suppression/actions/workflows/platform_builds.yml)
[![codecov](https://codecov.io/gh/teklund/nfc_wallet_suppression/branch/main/graph/badge.svg)](https://codecov.io/gh/teklund/nfc_wallet_suppression)
```

**Files to Update**:

- `README.md`

---

## Implementation Priority

### Phase 1: Critical Fixes (Do First)

1. ✅ Fix Dart SDK version compatibility
2. ✅ Remove broken test result extraction
3. ✅ Fix pana regex for cross-platform

### Phase 2: Performance Optimizations (Next)

4. ✅ Optimize job dependencies (parallel execution)
5. ✅ Run package validation only on PRs
6. ✅ Consolidate environment info printing

### Phase 3: Nice-to-Have Improvements (Optional)

7. ⬜ Add pub cache sharing
8. ✅ Remove redundant continue-on-error
9. ⬜ Improve test summary display
10. ⬜ Add workflow status badges

---

## Estimated Impact

| Improvement | Time Saved | Complexity | Priority |
|-------------|------------|------------|----------|
| SDK Version Fix | N/A (fixes failures) | Low | Critical |
| Remove Broken Test Step | ~30s per run | Low | High |
| Fix Pana Regex | N/A (fixes potential failure) | Low | High |
| Parallel Job Execution | ~5-10 min per PR | Low | Medium |
| Skip Jobs on Main | ~3-5 min per push | Low | Medium |
| Consolidate Env Info | ~10-20s per run | Low | Medium |
| Pub Cache Sharing | ~20-30s per job | Medium | Low |
| Status Badges | Visibility only | Low | Low |

**Total Estimated Savings**: ~8-15 minutes per PR, plus fixing current failures

---

## Testing Plan

After implementing changes:

1. **Test on a branch**: Create a test PR to verify all workflows pass
2. **Verify parallel execution**: Check that jobs run in parallel as expected
3. **Test failure scenarios**: Ensure failures are still reported correctly
4. **Check summaries**: Verify GitHub step summaries display correctly
5. **Monitor CI minutes**: Track reduction in CI time usage

---

## Notes

- All changes are backward compatible
- No secrets or configuration changes required
- Can be implemented incrementally
- Consider creating separate PRs for each phase
