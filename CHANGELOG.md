# Changelog

All notable changes to this project will be documented in this file.

## 0.1.1

* **DOCS** Clarified that NFC permission is automatically included via plugin manifest (no app-level declaration needed)

* First stable release of the `nfc_wallet_suppression` plugin.
* **DOCS** Updated readme

## 0.0.2-beta

* Enhances error handling within the NFC wallet suppression plugin and refactors the code for better
  clarity.
* **iOS:** Improved error handling for iOS.
* **Android:** Got a working implementation of the NFC wallet suppression plugin.

## 0.0.1-beta

* Initial release of the `nfc_wallet_suppression` plugin.
* **iOS:** Added NFC wallet suppression using PassKit (request, release, check status).
* **Android:** Added NFC wallet suppression using NfcAdapter (request, release, check status).
