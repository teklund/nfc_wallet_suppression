package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** NfcWalletSuppressionPlugin */
class NfcWalletSuppressionPlugin: FlutterPlugin, ActivityAware,
  NfcAdapter.ReaderCallback, NfcWalletSuppressionApi {

  private var suppressionActive : Boolean = false
  private var activity : Activity? = null
  private var context : Context? = null
  private var isDebug : Boolean = false
  
  companion object {
    private const val TAG = "NfcWalletSuppression"
  }

  // Empty implementation - we only need ReaderCallback for reader mode flags,
  // not for actual tag processing. The goal is to suppress wallet apps, not to read tags.
  override fun onTagDiscovered(tag: Tag?) {}

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    NfcWalletSuppressionApi.setUp(flutterPluginBinding.binaryMessenger, this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NfcWalletSuppressionApi.setUp(binding.binaryMessenger, null)
    if (isDebug) Log.d(TAG, "Detached from engine")
    context = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    // Check if running in debug mode - set automatically by build system (debug vs release)
    // Matches iOS's #if DEBUG behavior - no manual changes needed for production
    isDebug = (activity?.applicationInfo?.flags?.and(android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) ?: 0) != 0
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // Don't clear activity reference during config changes to preserve state
    // Activity will be updated in onReattachedToActivityForConfigChanges
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    
    // Re-establish suppression if it was active before the configuration change
    if (suppressionActive) {
      reestablishSuppression()
    }
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun isSuppressed(callback: (Result<Boolean>) -> Unit) {
    callback(Result.success(isSuppressedInternal()))
  }

  private fun isSuppressedInternal(): Boolean {
    // Return false if no activity
    val activity = activity ?: return false
    
    // Return false if flag not set
    if (!suppressionActive) return false
    
    // Check if NFC is actually available and enabled
    // This matches iOS behavior where isSuppressingAutomaticPassPresentation()
    // returns false if the system can't actually suppress (e.g., NFC disabled)
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    val actuallySupressed = nfcAdapter != null && nfcAdapter.isEnabled
    
    if (isDebug) {
      Log.d(TAG, "isSuppressed check: actuallySuppressed=$actuallySupressed (activity=${activity != null}, " +
              "suppressionActive=$suppressionActive, nfcEnabled=${nfcAdapter?.isEnabled ?: false})")
    }
    
    // If NFC was disabled after we set suppressionActive, clear the flag
    if (!actuallySupressed && suppressionActive) {
      if (isDebug) Log.w(TAG, "NFC was disabled - clearing suppressionActive flag")
      suppressionActive = false
    }
    
    return actuallySupressed
  }

  private fun reestablishSuppression() {
    if (isDebug) Log.d(TAG, "Reestablishing NFC suppression after configuration change")
    val activity = activity
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    if (nfcAdapter == null || activity == null || !nfcAdapter.isEnabled) {
      // NFC not available, clear suppression state
      if (isDebug) Log.w(TAG, "Cannot reestablish suppression: NFC not available")
      suppressionActive = false
      return
    }

    val intent = Intent(activity, activity.javaClass).apply {
      addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
    val pendingIntent: PendingIntent = PendingIntent.getActivity(
      activity,
      0,
      intent,
      PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    nfcAdapter.enableForegroundDispatch(activity, pendingIntent, null, null)

    // Read all techs, skip NDEF to skip P2P
    val flags: Int = NfcAdapter.FLAG_READER_NFC_A or
            NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_NFC_F or
            NfcAdapter.FLAG_READER_NFC_V or
            NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK

    try {
      nfcAdapter.enableReaderMode(activity, this, flags, null)
      if (isDebug) Log.d(TAG, "Reestablished NFC suppression")
    } catch (e: Exception) {
      if (isDebug) Log.e(TAG, "Failed to reestablish suppression", e)
      suppressionActive = false
    }
  }

  override fun requestSuppression(callback: (Result<SuppressionResult>) -> Unit) {
    val activity = activity
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    
    if (activity == null) {
      if (isDebug) Log.e(TAG, "Request suppression failed: Activity is null")
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.UNAVAILABLE,
        message = "Activity not available"
      )))
      return
    }
    
    if (nfcAdapter == null) {
      if (isDebug) Log.e(TAG, "Request suppression failed: No NFC hardware")
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.NOT_SUPPORTED,
        message = "Device does not have NFC hardware"
      )))
      return
    }
    
    if (!nfcAdapter.isEnabled) {
      if (isDebug) Log.w(TAG, "Request suppression failed: NFC is disabled")
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.UNAVAILABLE,
        message = "NFC is disabled. Please enable NFC in device settings"
      )))
      return
    }

    try {
      val intent = Intent(activity, activity.javaClass).apply {
        addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
      }
      val pendingIntent: PendingIntent = PendingIntent.getActivity(
        activity,
        0,
        intent,
        PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
      )

      nfcAdapter.enableForegroundDispatch(activity, pendingIntent, null, null)

      // Read all techs, skip NDEF to skip P2P
      val flags: Int = NfcAdapter.FLAG_READER_NFC_A or
              NfcAdapter.FLAG_READER_NFC_B or
              NfcAdapter.FLAG_READER_NFC_F or
              NfcAdapter.FLAG_READER_NFC_V or
              NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK

      nfcAdapter.enableReaderMode(activity, this, flags, null)
      suppressionActive = true
      if (isDebug) Log.d(TAG, "NFC wallet suppression enabled successfully")
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.SUPPRESSED,
        message = "Suppressed"
      )))
    } catch (e: SecurityException) {
      if (isDebug) Log.e(TAG, "Security exception requesting suppression", e)
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.DENIED,
        message = "Permission denied for NFC operations: ${e.message}"
      )))
    } catch (e: Exception) {
      if (isDebug) Log.e(TAG, "Unexpected error requesting suppression", e)
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.UNKNOWN,
        message = "Failed to request suppression: ${e.message}"
      )))
    }
  }

  override fun releaseSuppression(callback: (Result<SuppressionResult>) -> Unit) {
    val activity = activity
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    
    if (activity == null) {
      if (isDebug) Log.e(TAG, "Release suppression failed: Activity is null")
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.UNAVAILABLE,
        message = "Activity not available"
      )))
      return
    }
    
    if (nfcAdapter == null) {
      if (isDebug) Log.w(TAG, "Release suppression: No NFC adapter (already released or device has no NFC)")
      // Still mark as not suppressed and return success
      suppressionActive = false
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.NOT_SUPPRESSED,
        message = "Suppression released"
      )))
      return
    }
    
    try {
      if (nfcAdapter.isEnabled) {
        nfcAdapter.disableForegroundDispatch(activity)
        nfcAdapter.disableReaderMode(activity)
        if (isDebug) Log.d(TAG, "NFC wallet suppression disabled successfully")
      } else {
        if (isDebug) Log.w(TAG, "NFC is disabled, skipping disable operations")
      }
      suppressionActive = false
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.NOT_SUPPRESSED,
        message = "Suppression released"
      )))
    } catch (e: SecurityException) {
      if (isDebug) Log.e(TAG, "Security exception releasing suppression", e)
      suppressionActive = false  // Mark as not suppressed anyway
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.DENIED,
        message = "Permission denied for NFC operations: ${e.message}"
      )))
    } catch (e: Exception) {
      if (isDebug) Log.e(TAG, "Unexpected error releasing suppression", e)
      suppressionActive = false  // Mark as not suppressed anyway
      callback(Result.success(SuppressionResult(
        status = SuppressionStatusCode.UNKNOWN,
        message = "Failed to release suppression: ${e.message}"
      )))
    }
  }

  override fun isSupported(callback: (Result<Boolean>) -> Unit) {
    // Check if device has NFC hardware (requires API 21+)
    // Use application context so this works even if activity is not attached yet
    val currentContext = context ?: activity
    if (currentContext == null) {
      if (isDebug) Log.w(TAG, "isSupported: No context available")
      callback(Result.success(false))
      return
    }

    val nfcAdapter = NfcAdapter.getDefaultAdapter(currentContext)
    val supported = nfcAdapter != null
    if (isDebug) Log.d(TAG, "isSupported called: $supported (NFC adapter: ${if (nfcAdapter != null) "present" else "null"})")
    callback(Result.success(supported))
  }
}
