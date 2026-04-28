# Publishing Checklist

This document provides a comprehensive checklist for publishing new versions of the `nfc_wallet_suppression` plugin to pub.dev.

---

## Pre-Release Checklist

### 📝 Documentation

- [ ] Update `CHANGELOG.md` with all changes following [Keep a Changelog](https://keepachangelog.com/) format
- [ ] Update version number in `pubspec.yaml`
- [ ] Update version number in `ios/nfc_wallet_suppression.podspec`
- [ ] Update README.md if API has changed
- [ ] Review and update API documentation in code
- [ ] Review all documentation for accuracy and completeness

### 🧪 Testing

- [ ] Run all Dart tests: `flutter test`
- [ ] Verify test coverage: `flutter test --coverage`
- [ ] Run iOS native tests: `cd ios && xcodebuild test -workspace ...`
- [ ] Run Android native tests: `cd android && ./gradlew test`
- [ ] Run integration tests on iOS simulator: `cd example && flutter test integration_test/`
- [ ] Run integration tests on Android emulator: `cd example && flutter test integration_test/`
- [ ] Test on real iOS device (if available)
- [ ] Test on real Android device (if available)
- [ ] Test example app functionality on both platforms
- [ ] Verify no test failures or warnings

### 🔍 Code Quality

- [ ] Run analyzer: `flutter analyze` (zero issues)
- [ ] Check formatting: `dart format --set-exit-if-checked .`
- [ ] Review code for TODOs or FIXMEs
- [ ] Check for unused imports: `dart analyze --fatal-infos`
- [ ] Review all public API documentation
- [ ] Verify no debug code left in production paths
- [ ] Check for proper error handling in all methods

### 📦 Package Validation

- [ ] Run pub.dev dry-run: `dart pub publish --dry-run`
- [ ] Verify package score will be 140+
- [ ] Check package size is reasonable
- [ ] Verify all required files are included:
  - [ ] README.md
  - [ ] CHANGELOG.md
  - [ ] LICENSE
  - [ ] pubspec.yaml
  - [ ] All source files
  - [ ] Example app
- [ ] Verify `.pubignore` or `.gitignore` excludes unnecessary files:
  - [ ] `.git/`
  - [ ] `.idea/`
  - [ ] `.vscode/`
  - [ ] `build/`
  - [ ] `.dart_tool/`
  - [ ] `*.iml`
  - [ ] Coverage reports

### 🛡️ Security & Privacy

- [ ] Review SECURITY.md is up to date
- [ ] Verify iOS privacy manifest (`PrivacyInfo.xcprivacy`) is correct
- [ ] Check no sensitive data in code or comments
- [ ] Verify no API keys or credentials
- [ ] Review dependency versions for known vulnerabilities
- [ ] Check permissions are properly documented

### 🔧 Platform Specific

#### iOS

- [ ] Verify podspec is valid: `pod lib lint ios/nfc_wallet_suppression.podspec`
- [ ] Check minimum iOS version in podspec matches pubspec
- [ ] Verify Swift version compatibility
- [ ] Test on latest iOS version
- [ ] Test on minimum supported iOS version (13.0)
- [ ] Privacy manifest is included

#### Android

- [ ] Verify Gradle builds successfully: `cd android && ./gradlew build`
- [ ] Check minimum SDK version in build.gradle
- [ ] Test on latest Android version
- [ ] Test on minimum supported Android version (API 21)
- [ ] Verify ProGuard rules if applicable
- [ ] Check Kotlin version compatibility

### 🚀 CI/CD

- [ ] All GitHub Actions workflows passing
- [ ] CI tests passing on all platforms
- [ ] No failing checks in pull request
- [ ] Branch is up to date with main/master

### 📱 Example App

- [ ] Example app runs on iOS without errors
- [ ] Example app runs on Android without errors
- [ ] Example code demonstrates all features
- [ ] Example app has clear UI and instructions
- [ ] Screenshots are up to date (if applicable)

---

## Release Process

### 1. Version Bump

Update version numbers following [Semantic Versioning](https://semver.org/):

**pubspec.yaml:**

```yaml
version: 1.0.0
```

**ios/nfc_wallet_suppression.podspec:**

```ruby
s.version = '1.0.0'
```

### 2. Update CHANGELOG

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [1.0.0] - 2026-01-20

### Added
- New `isSupported()` method for platform capability check
- Comprehensive integration tests
- iOS native XCTest suite
- Android native JUnit tests

### Changed
- Improved iOS token management (prevents race conditions)
- Enhanced Android state persistence across config changes
- Better error handling with detailed status codes

### Fixed
- Memory leaks in iOS token management
- State loss during Android activity recreation

### Security
- Added iOS privacy manifest
- Security review completed
```

### 3. Commit and Tag

```bash
# Commit version changes
git add .
git commit -m "chore: bump version to 1.0.0"

# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push commits and tags
git push origin main
git push origin v1.0.0
```

### 4. Publish to pub.dev (automated)

Pushing the tag triggers the [publish workflow](.github/workflows/publish.yml) automatically:

1. **Verify job** runs: format, analyze, tests, pana score check, and a dry-run publish
2. **Publish job** waits for manual approval in the `pub.dev` GitHub Actions environment, then publishes via OIDC (no stored credentials)
3. **Release job** creates the GitHub Release with auto-generated notes

To approve the publish, go to the Actions tab, open the workflow run, and approve the pending deployment.

> To set up the `pub.dev` environment: go to **Settings → Environments → New environment**, name it `pub.dev`, and add required reviewers.

### 5. Verify Publication

- [ ] Package appears on [pub.dev](https://pub.dev/packages/nfc_wallet_suppression)
- [ ] Package score is displayed (wait ~10 minutes)
- [ ] Documentation is generated correctly
- [ ] Example tab works on pub.dev
- [ ] All platforms show as supported
- [ ] Try installing in a fresh project: `flutter pub add nfc_wallet_suppression`

---

## Post-Release

### Monitoring

- [ ] Monitor pub.dev package health score
- [ ] Watch for initial bug reports on GitHub
- [ ] Check community feedback
- [ ] Monitor download statistics

### Communication

- [ ] Announce release on GitHub Discussions (if applicable)
- [ ] Update any related documentation sites
- [ ] Notify stakeholders
- [ ] Share on social media (optional)

### Immediate Fixes

If critical issues are found immediately after release:

1. Create hotfix branch
2. Fix the issue
3. Bump patch version (e.g., 1.0.0 → 1.0.1)
4. Follow rapid release process
5. Document in CHANGELOG as patch release

---

## Version Numbering Guidelines

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
  - API changes that break backward compatibility
  - Removal of deprecated features
  - Major architectural changes

- **MINOR** (1.0.0 → 1.1.0): New features (backward compatible)
  - New methods or functionality
  - Enhancements to existing features
  - Deprecations (with migration path)

- **PATCH** (1.0.0 → 1.0.1): Bug fixes (backward compatible)
  - Bug fixes
  - Documentation updates
  - Performance improvements
  - Security patches

### Pre-release Versions

For testing before stable release:

- **Alpha:** `1.0.0-alpha.1` (early testing, unstable)
- **Beta:** `1.0.0-beta.1` (feature complete, testing)
- **RC:** `1.0.0-rc.1` (release candidate, final testing)

---

## Rollback Procedure

If a critical issue is discovered after publishing:

### Option 1: Quick Patch Release

1. Create hotfix branch
2. Fix the issue
3. Release patch version (e.g., 1.0.1)
4. Document issue and fix in CHANGELOG

### Option 2: Retract Version (Last Resort)

```bash
# Retract broken version from pub.dev
dart pub global activate pubspec_cli
pub retract <version> --reason "Critical bug: [description]"
```

**Note:** Retraction should be rare. Prefer patch releases.

---

## Common Issues

### Issue: Dry-run shows warnings

**Solution:** Review and address all warnings before publishing. Common fixes:

- Add missing documentation
- Update pubspec.yaml metadata
- Fix formatting issues
- Remove debug code

### Issue: Package score is low

**Solution:**

- Add comprehensive documentation
- Include example code
- Support multiple platforms
- Maintain dependencies
- Add tests with good coverage

### Issue: Platform not detected

**Solution:**

- Verify `plugin` section in pubspec.yaml
- Check native platform files are included
- Validate podspec and Gradle configuration

---

## Resources

- [Pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Flutter Plugin Development](https://docs.flutter.dev/packages-and-plugins/developing-packages)

---

## Checklist Summary

Before running `dart pub publish`:

- ✅ All tests pass
- ✅ Code quality checks pass
- ✅ Documentation is complete
- ✅ Version numbers updated
- ✅ CHANGELOG updated
- ✅ Dry-run succeeds
- ✅ Changes committed and tagged
- ✅ CI/CD pipeline green

**Ready to publish!** 🚀

---

**Last Updated:** January 21, 2026
