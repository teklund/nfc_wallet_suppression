# Security Policy

## Supported versions

Security fixes go into the latest release.

| Version | Supported |
| :--- | :---: |
| 1.x | ✔ |
| < 1.0 | ✘ |

## Reporting a vulnerability

Please don't open a public issue. Report it privately through
[GitHub's private vulnerability reporting](https://github.com/teklund/nfc_wallet_suppression/security/advisories/new),
with the affected version, steps to reproduce and the impact you see.

Responses are best effort. I aim to reply within 7 days, and to fix confirmed
vulnerabilities and publish an advisory within 90 days, agreeing the disclosure
date with you.

## Scope

In scope: this plugin's Dart, Kotlin and Swift code. Issues in Flutter, PassKit
or Android's NFC stack belong to those projects. The plugin sends nothing over
the network and stores no data; see Privacy in the README.
