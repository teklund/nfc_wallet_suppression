package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.nfc.NfcAdapter

/**
 * Interface for abstracting NFC adapter operations.
 * Allows for dependency injection and easier unit testing.
 */
interface NfcAdapterWrapper {
    /**
     * Check if NFC is available on this device.
     */
    fun isNfcAvailable(): Boolean
    
    /**
     * Check if NFC is currently enabled.
     */
    fun isNfcEnabled(): Boolean
    
    /**
     * Enable reader mode to suppress wallet apps.
     */
    fun enableReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback)
    
    /**
     * Disable reader mode.
     */
    fun disableReaderMode(activity: Activity)
    
    /**
     * Enable foreground dispatch as fallback for reader mode.
     */
    fun enableForegroundDispatch(activity: Activity, intent: android.app.PendingIntent)
    
    /**
     * Disable foreground dispatch.
     */
    fun disableForegroundDispatch(activity: Activity)
}

/**
 * Production implementation wrapping the real NfcAdapter.
 */
class RealNfcAdapterWrapper(private val activity: Activity) : NfcAdapterWrapper {
    private val nfcAdapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(activity)
    
    override fun isNfcAvailable(): Boolean {
        return nfcAdapter != null
    }
    
    override fun isNfcEnabled(): Boolean {
        return nfcAdapter?.isEnabled == true
    }
    
    override fun enableReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback) {
        nfcAdapter?.enableReaderMode(
            activity,
            callback,
            NfcAdapter.FLAG_READER_NFC_A or
            NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_NFC_F or
            NfcAdapter.FLAG_READER_NFC_V or
            NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS,
            null
        )
    }
    
    override fun disableReaderMode(activity: Activity) {
        nfcAdapter?.disableReaderMode(activity)
    }
    
    override fun enableForegroundDispatch(activity: Activity, intent: android.app.PendingIntent) {
        nfcAdapter?.enableForegroundDispatch(activity, intent, null, null)
    }
    
    override fun disableForegroundDispatch(activity: Activity) {
        nfcAdapter?.disableForegroundDispatch(activity)
    }
}

/**
 * Fake implementation for testing.
 * Allows controlling NFC availability and state in unit tests.
 */
class FakeNfcAdapterWrapper : NfcAdapterWrapper {
    var available: Boolean = true
    var enabled: Boolean = true
    var readerModeEnabled: Boolean = false
    var foregroundDispatchEnabled: Boolean = false
    
    val methodCalls = mutableListOf<String>()
    
    override fun isNfcAvailable(): Boolean {
        methodCalls.add("isNfcAvailable")
        return available
    }
    
    override fun isNfcEnabled(): Boolean {
        methodCalls.add("isNfcEnabled")
        return enabled
    }
    
    override fun enableReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback) {
        methodCalls.add("enableReaderMode")
        readerModeEnabled = true
    }
    
    override fun disableReaderMode(activity: Activity) {
        methodCalls.add("disableReaderMode")
        readerModeEnabled = false
    }
    
    override fun enableForegroundDispatch(activity: Activity, intent: android.app.PendingIntent) {
        methodCalls.add("enableForegroundDispatch")
        foregroundDispatchEnabled = true
    }
    
    override fun disableForegroundDispatch(activity: Activity) {
        methodCalls.add("disableForegroundDispatch")
        foregroundDispatchEnabled = false
    }
    
    fun reset() {
        available = true
        enabled = true
        readerModeEnabled = false
        foregroundDispatchEnabled = false
        methodCalls.clear()
    }
}
