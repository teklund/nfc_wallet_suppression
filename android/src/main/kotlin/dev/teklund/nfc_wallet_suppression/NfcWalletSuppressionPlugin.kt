package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NfcWalletSuppressionPlugin */
class NfcWalletSuppressionPlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
  NfcAdapter.ReaderCallback {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var suppressionActive : Boolean = false
  private var activity : Activity? = null
  private var isDebug : Boolean = false
  
  companion object {
    private const val TAG = "NfcWalletSuppression"
  }

  // Empty implementation - we only need ReaderCallback for reader mode flags,
  // not for actual tag processing. The goal is to suppress wallet apps, not to read tags.
  override fun onTagDiscovered(tag: Tag?) {}

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nfc_wallet_suppression")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {

    when (call.method) {
      "isSuppressed" -> {
        result.success(isSuppressed())
      }
      "requestSuppression" -> {
        requestSuppression(result)
      }
      "releaseSuppression" -> {
        releaseSuppression(result)
      }
      "isSupported" -> {
        result.success(isSupported())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
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

  private fun isSuppressed(): Boolean {
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
      Log.d(TAG, "isSuppressed called: $actuallySupressed (activity: true, " +
              "suppressionActive: $suppressionActive, nfcEnabled: ${nfcAdapter?.isEnabled ?: false})")
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

    nfcAdapter.enableReaderMode(activity, this, flags, null)
  }

  private fun requestSuppression(result: Result) {
    val activity = activity
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    
    if (activity == null) {
      if (isDebug) Log.e(TAG, "Request suppression failed: Activity is null")
      result.error("UNAVAILABLE", "Activity not available", null)
      return
    }
    
    if (nfcAdapter == null) {
      if (isDebug) Log.e(TAG, "Request suppression failed: No NFC hardware")
      result.error("NOT_SUPPORTED", "Device does not have NFC hardware", null)
      return
    }
    
    if (!nfcAdapter.isEnabled) {
      if (isDebug) Log.w(TAG, "Request suppression failed: NFC is disabled")
      result.error("UNAVAILABLE", "NFC is disabled. Please enable NFC in device settings", null)
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
      result.success("Suppressed")
    } catch (e: SecurityException) {
      if (isDebug) Log.e(TAG, "Security exception requesting suppression", e)
      result.error("DENIED", "Permission denied for NFC operations", e.message)
    } catch (e: Exception) {
      if (isDebug) Log.e(TAG, "Unexpected error requesting suppression", e)
      result.error("UNKNOWN", "Failed to request suppression: ${e.message}", null)
    }
  }

  private fun releaseSuppression(result: Result) {
    val activity = activity
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    
    if (activity == null) {
      if (isDebug) Log.e(TAG, "Release suppression failed: Activity is null")
      result.error("UNAVAILABLE", "Activity not available", null)
      return
    }
    
    if (nfcAdapter == null) {
      if (isDebug) Log.w(TAG, "Release suppression: No NFC adapter (already released or device has no NFC)")
      // Still mark as not suppressed and return success
      suppressionActive = false
      result.success("Not suppressed anymore")
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
      result.success("Not suppressed anymore")
    } catch (e: SecurityException) {
      if (isDebug) Log.e(TAG, "Security exception releasing suppression", e)
      suppressionActive = false  // Mark as not suppressed anyway
      result.error("DENIED", "Permission denied for NFC operations", e.message)
    } catch (e: Exception) {
      if (isDebug) Log.e(TAG, "Unexpected error releasing suppression", e)
      suppressionActive = false  // Mark as not suppressed anyway
      result.error("UNKNOWN", "Failed to release suppression: ${e.message}", null)
    }
  }

  private fun isSupported(): Boolean {
    // Check if device has NFC hardware (requires API 21+)
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    val supported = nfcAdapter != null
    if (isDebug) Log.d(TAG, "isSupported called: $supported (NFC adapter: ${if (nfcAdapter != null) "present" else "null"})")
    return supported
  }
}
