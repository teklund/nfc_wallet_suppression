# Security Policy

## Overview

The `nfc_wallet_suppression` plugin is designed with security and privacy as core principles. This document outlines our security practices, data handling, and vulnerability reporting process.

---

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          | Status |
| ------- | ------------------ | ------ |
| 1.0.x   | :white_check_mark: | Active support |
| 0.1.x   | :x:                | No longer supported |
| < 0.1   | :x:                | No longer supported |

**Recommendation:** Always use the latest stable version to receive security updates.

---

## Security Features

### Data Privacy

This plugin does **NOT**:

- ❌ Collect any user data
- ❌ Send data to external servers
- ❌ Store sensitive information
- ❌ Access contacts, location, or personal information
- ❌ Use tracking or analytics
- ❌ Require network access

This plugin **DOES**:

- ✅ Only interact with system NFC APIs
- ✅ Use local state management only
- ✅ Operate entirely offline
- ✅ Minimize permissions (NFC only)
- ✅ Include iOS privacy manifest (PrivacyInfo.xcprivacy)

### iOS Privacy Manifest

The plugin includes a privacy manifest (`ios/Resources/PrivacyInfo.xcprivacy`) that declares:

```xml
<key>NSPrivacyTrackingDomains</key>
<array/>
<key>NSPrivacyAccessedAPITypes</key>
<array/>
<key>NSPrivacyCollectedDataTypes</key>
<array/>
<key>NSPrivacyTracking</key>
<false/>
```

**What this means:**

- No tracking of users
- No data collection
- No required reason APIs are used
- Complies with Apple's privacy requirements

### Android Permissions

The plugin requires only NFC permission:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

**What this means:**

- No internet access
- No storage access
- No location access
- Only NFC hardware interaction

### Code Security

- ✅ **No external dependencies** (except Flutter SDK and plugin_platform_interface)
- ✅ **Type-safe code** (Dart with null safety)
- ✅ **Memory safe** (automatic garbage collection, proper iOS token cleanup)
- ✅ **Thread-safe** (proper synchronization on platform code)
- ✅ **Error handling** (all operations have proper error handling)
- ✅ **No dynamic code execution** (no eval, no reflection beyond platform channels)

---

## Threat Model

### In Scope

This plugin protects against:

1. **NFC Wallet Popup Interference:** Primary use case - suppressing wallet apps during NFC operations
2. **State Consistency:** Proper cleanup prevents stuck states
3. **Memory Safety:** Proper token management prevents leaks (iOS)
4. **Thread Safety:** Prevents race conditions in multi-threaded scenarios

### Out of Scope

This plugin does NOT protect against:

1. **NFC Tag Content Security:** Plugin doesn't read or validate NFC tag data
2. **App-Level Security:** Host app is responsible for its own security
3. **Physical Access:** Cannot prevent physical device access or tampering
4. **OS-Level Exploits:** Relies on platform security (iOS/Android)

### Assumptions

- Host app uses secure NFC tag reading practices
- Device OS is up to date with security patches
- User has not jailbroken/rooted their device (optional)
- App is distributed through official stores (recommended)

---

## Known Limitations

### iOS

1. **iOS 13.0+ Required:** Plugin minimum (Flutter SDK floor); PassKit suppression API (`requestAutomaticPassPresentationSuppression`) available from iOS 9.0+
2. **User Consent:** User can deny suppression request (by design)
3. **Background Limitations:** Suppression releases when app backgrounds (OS behavior)
4. **PassKit Dependency:** Requires PassKit framework availability

### Android

1. **NFC Hardware Required:** Device must have NFC capability
2. **NFC Enabled:** User must have NFC turned on
3. **Reader Mode:** Uses reader mode which may conflict with other NFC apps
4. **API Level 21+:** Minimum Android 5.0 required

### Both Platforms

1. **No Persistent Suppression:** Suppression is session-based, not persistent across app restarts
2. **Activity Lifecycle:** May need to re-establish suppression after certain lifecycle events
3. **Single App Instance:** Cannot suppress across multiple app instances

---

## Secure Usage Recommendations

### For Plugin Users

```dart
// ✅ Good: Always release suppression
try {
  final plugin = NfcWalletSuppression();
  await plugin.requestSuppression();
  // Your NFC operations
} finally {
  await plugin.releaseSuppression(); // Cleanup
}

// ✅ Good: Check support before use
if (await plugin.isSupported()) {
  await plugin.requestSuppression();
}

// ✅ Good: Handle all error cases
final status = await plugin.requestSuppression();
switch (status) {
  case SuppressionStatus.suppressed:
    // Proceed
  case SuppressionStatus.notSupported:
    // Inform user
  default:
    // Handle error
}

// ❌ Bad: Forgetting to release
await plugin.requestSuppression();
// App exits without cleanup - may leave reader mode active
```

### For NFC Operations

```dart
// ✅ Validate NFC tag data in your app
final tagData = await readNfcTag();
if (!isValidTag(tagData)) {
  throw SecurityException('Invalid tag');
}

// ✅ Use HTTPS for any network operations related to NFC data
final response = await https.post('https://api.example.com/verify', body: tagData);

// ✅ Sanitize data from NFC tags
final sanitized = sanitizeInput(tagData);
```

---

## Vulnerability Reporting

### How to Report

If you discover a security vulnerability, please report it responsibly:

**DO NOT** open a public GitHub issue for security vulnerabilities.

**Instead:**

1. **Email:** Send details to the repository owner via GitHub (create a security advisory)
2. **GitHub Security Advisory:** Use GitHub's [private vulnerability reporting](https://github.com/teklund/nfc_wallet_suppression/security/advisories/new)
3. **Include:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
   - Your contact information

### Response Timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Depends on severity (critical issues prioritized)
- **Public Disclosure:** After fix is released and users have time to update

### Severity Levels

| Severity | Response Time | Examples |
|----------|---------------|----------|
| **Critical** | 24-48 hours | Remote code execution, data exfiltration |
| **High** | 1 week | Memory leaks, privilege escalation |
| **Medium** | 2-4 weeks | Denial of service, state corruption |
| **Low** | Next release | Minor information disclosure |

---

## Security Updates

### Notification

Security updates are announced via:

1. **GitHub Security Advisories:** [Security Tab](https://github.com/teklund/nfc_wallet_suppression/security)
2. **GitHub Releases:** [Releases Page](https://github.com/teklund/nfc_wallet_suppression/releases)
3. **CHANGELOG.md:** Under `[Security]` section
4. **pub.dev:** Package updates

### Applying Updates

```bash
# Update to latest version
flutter pub upgrade nfc_wallet_suppression

# Or specify version
flutter pub add nfc_wallet_suppression:^1.0.0
```

---

## Security Best Practices

### For Developers Using This Plugin

1. **Keep Updated:** Use the latest stable version
2. **Review Changes:** Read CHANGELOG.md before updating
3. **Test Thoroughly:** Test security-critical flows after updates
4. **Monitor Dependencies:** Check for security advisories
5. **Secure NFC Data:** Validate and sanitize all NFC tag data
6. **Use HTTPS:** For any network communication related to NFC
7. **Implement Timeouts:** Don't leave suppression active indefinitely
8. **Handle Errors:** Properly handle all error states
9. **User Privacy:** Be transparent about NFC usage in your privacy policy

### For Plugin Contributors

1. **Code Review:** All changes require review
2. **Static Analysis:** All code must pass `flutter analyze`
3. **Testing:** Maintain test coverage
4. **Documentation:** Document security implications
5. **Dependencies:** Minimize and vet all dependencies
6. **Principle of Least Privilege:** Request minimum necessary permissions
7. **Input Validation:** Validate all inputs from platform channels
8. **Error Handling:** Never expose sensitive information in errors

---

## Dependency Security

### Current Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

All dependencies are:

- ✅ Official Flutter/Dart packages
- ✅ Actively maintained
- ✅ Widely used (high confidence)
- ✅ Regular security updates

### Monitoring

We monitor dependencies using:

- GitHub Dependabot
- `dart pub outdated`
- Security advisories for Flutter/Dart ecosystem

---

## Compliance

### GDPR Compliance

- ✅ **No data collection:** Plugin doesn't collect personal data
- ✅ **No data processing:** No user data is processed
- ✅ **No data sharing:** No data shared with third parties
- ✅ **No cookies/tracking:** No tracking mechanisms

### Apple App Store Privacy Requirements

- ✅ Privacy manifest included (`PrivacyInfo.xcprivacy`)
- ✅ No tracking declaration
- ✅ No data collection
- ✅ API usage declared (UserDefaults for state)

### Google Play Security Requirements

- ✅ Minimal permissions (NFC only)
- ✅ No dangerous permissions
- ✅ No background access
- ✅ No data collection

---

## Auditing

### Security Review History

| Date | Version | Reviewer | Status |
|------|---------|----------|--------|
| 2026-01-20 | 1.0.0 | Internal | ✅ Approved |

### Future Audits

We plan to:

- Conduct internal security reviews for each major release
- Welcome community security researchers
- Consider third-party audits for 2.0.0+

---

## Contact

For security concerns:

- **Security Issues:** Use [GitHub Security Advisories](https://github.com/teklund/nfc_wallet_suppression/security/advisories/new)
- **General Issues:** [GitHub Issues](https://github.com/teklund/nfc_wallet_suppression/issues)

---

## Acknowledgments

We appreciate responsible disclosure from security researchers. Contributors who report valid security issues will be acknowledged in release notes (with permission).

---

**Last Updated:** January 21, 2026

**Note:** This security policy is subject to updates. Check the latest version in the repository.
