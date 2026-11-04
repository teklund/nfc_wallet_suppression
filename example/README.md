# nfc_wallet_suppression_example

Demonstrates how to use the nfc_wallet_suppression plugin. The home screen
calls the API directly, for trying it on a device. The suppression screen shows
the recommended pattern: it requests suppression when it appears and releases
it when it closes, counting open screens so that one closing during a
transition can't end the next one's hold.

On iOS, suppression needs the entitlement described in the plugin's README.
