package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.content.Context
import android.content.pm.ApplicationInfo
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Abstraction over the Android NFC reader-mode APIs.
 *
 * `NfcAdapter` is obtained through static factory calls, which makes the
 * suppression logic impossible to unit test. Routing every adapter call through
 * this interface lets the plugin be driven by a fake in tests while using the
 * real adapter in production.
 */
internal interface WalletSuppressor {
  fun hasNfcHardware(context: Context): Boolean
  fun isNfcEnabled(context: Context): Boolean

  /**
   * Enables reader mode for [activity]. Reader mode takes over the NFC stack,
   * which suppresses wallet / host-card-emulation apps. Throws if it cannot be
   * enabled (e.g., no adapter, or a security restriction).
   */
  fun startReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback)

  fun stopReaderMode(activity: Activity)
}

/** Production implementation backed by [NfcAdapter]. */
internal class SystemWalletSuppressor : WalletSuppressor {
  override fun hasNfcHardware(context: Context): Boolean =
    NfcAdapter.getDefaultAdapter(context) != null

  override fun isNfcEnabled(context: Context): Boolean =
    NfcAdapter.getDefaultAdapter(context)?.isEnabled == true

  override fun startReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback) {
    val adapter = NfcAdapter.getDefaultAdapter(activity)
      ?: throw IllegalStateException("No NFC adapter available")
    // Reader mode alone suppresses wallet / host-card-emulation apps; foreground
    // dispatch is neither needed nor compatible. We do not read tags, so we skip
    // the NDEF check and suppress the platform discovery sound for our silent
    // reader session.
    val flags = NfcAdapter.FLAG_READER_NFC_A or
      NfcAdapter.FLAG_READER_NFC_B or
      NfcAdapter.FLAG_READER_NFC_F or
      NfcAdapter.FLAG_READER_NFC_V or
      NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or
      NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS
    adapter.enableReaderMode(activity, callback, flags, null)
  }

  override fun stopReaderMode(activity: Activity) {
    NfcAdapter.getDefaultAdapter(activity)?.disableReaderMode(activity)
  }
}

/** NfcWalletSuppressionPlugin */
class NfcWalletSuppressionPlugin internal constructor(
  private val suppressor: WalletSuppressor
) : FlutterPlugin, ActivityAware, NfcAdapter.ReaderCallback, NfcWalletSuppressionApi {

  constructor() : this(SystemWalletSuppressor())

  private var activity: Activity? = null
  private var context: Context? = null
  private var isDebug: Boolean = false

  /** Whether suppression is intended to be active (reader mode held). */
  private var suppressionActive: Boolean = false

  companion object {
    private const val TAG = "NfcWalletSuppression"
  }

  // Reader mode requires a callback, but we only occupy the NFC stack to
  // suppress wallet apps; we do not process tags.
  override fun onTagDiscovered(tag: Tag?) {}

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    NfcWalletSuppressionApi.setUp(flutterPluginBinding.binaryMessenger, this)
    context = flutterPluginBinding.applicationContext
    // Set automatically by the build system (debug vs. release); mirrors iOS's #if DEBUG.
    isDebug = ((context?.applicationInfo?.flags ?: 0) and ApplicationInfo.FLAG_DEBUGGABLE) != 0
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NfcWalletSuppressionApi.setUp(binding.binaryMessenger, null)
    if (isDebug) Log.d(TAG, "Detached from engine")
    context = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    // Re-establish reader mode if suppression was active before this activity
    // attached (configuration change or activity recreation). Reader mode is
    // bound to an activity, so it must be re-armed against the new one.
    if (suppressionActive) reestablish()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // Reader mode is torn down with the activity; it is re-armed on reattach.
    activity = null
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  /** Re-arms reader mode against the current activity. Precondition: suppressionActive. */
  private fun reestablish() {
    val activity = activity ?: return
    if (!suppressor.isNfcEnabled(activity)) {
      // NFC was turned off while detached; suppression can no longer be held.
      if (isDebug) Log.w(TAG, "Cannot re-establish suppression: NFC not enabled")
      suppressionActive = false
      return
    }
    try {
      suppressor.startReaderMode(activity, this)
      if (isDebug) Log.d(TAG, "Re-established NFC suppression")
    } catch (e: Exception) {
      if (isDebug) Log.e(TAG, "Failed to re-establish suppression", e)
      suppressionActive = false
    }
  }

  override fun requestSuppression(callback: (Result<SuppressionResult>) -> Unit) {
    val activity = activity
    if (activity == null) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.UNAVAILABLE, "Activity not available")))
      return
    }
    if (!suppressor.hasNfcHardware(activity)) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.NOT_SUPPORTED, "Device does not have NFC hardware")))
      return
    }
    if (!suppressor.isNfcEnabled(activity)) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.UNAVAILABLE, "NFC is disabled. Please enable NFC in device settings")))
      return
    }
    // Already active (and NFC enabled): return idempotent success without
    // re-arming, so a re-arm that failed could never leave the active flag
    // inconsistent. Mirrors iOS.
    if (suppressionActive) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.SUPPRESSED, "Suppression already active")))
      return
    }
    try {
      suppressor.startReaderMode(activity, this)
      suppressionActive = true
      if (isDebug) Log.d(TAG, "NFC wallet suppression enabled")
      callback(Result.success(SuppressionResult(SuppressionStatusCode.SUPPRESSED, "Suppressed")))
    } catch (e: SecurityException) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.DENIED, "Permission denied for NFC operations: ${e.message}")))
    } catch (e: Exception) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.UNKNOWN, "Failed to request suppression: ${e.message}")))
    }
  }

  override fun releaseSuppression(callback: (Result<SuppressionResult>) -> Unit) {
    // Intent-based release (matches iOS): NOT_SUPPRESSED when we release a
    // suppression that was requested, UNAVAILABLE when there was none to release.
    // We deliberately do NOT reconcile against live state here (unlike
    // isSuppressed) so request/release stays a clean pair and both platforms
    // behave identically; isSuppressed is the API for live state.
    if (!suppressionActive) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.UNAVAILABLE, "No active suppression to release")))
      return
    }
    val activity = activity
    if (activity != null) {
      try {
        suppressor.stopReaderMode(activity)
      } catch (e: SecurityException) {
        // Tear-down failed, so suppression is likely still active. Keep the flag
        // truthful (do not clear it) and surface the failure, mirroring how
        // requestSuppression maps exceptions.
        if (isDebug) Log.e(TAG, "Security exception releasing suppression", e)
        callback(Result.success(SuppressionResult(
          SuppressionStatusCode.DENIED, "Permission denied for NFC operations: ${e.message}")))
        return
      } catch (e: Exception) {
        if (isDebug) Log.e(TAG, "Unexpected error releasing suppression", e)
        callback(Result.success(SuppressionResult(
          SuppressionStatusCode.UNKNOWN, "Failed to release suppression: ${e.message}")))
        return
      }
    }
    suppressionActive = false
    callback(Result.success(SuppressionResult(
      SuppressionStatusCode.NOT_SUPPRESSED, "Suppression released")))
  }

  override fun isSuppressed(callback: (Result<Boolean>) -> Unit) {
    val activity = activity
    // Reconcile intent with reality: reader mode is only held while an activity is
    // attached and NFC is still enabled.
    val active = suppressionActive && activity != null && suppressor.isNfcEnabled(activity)
    callback(Result.success(active))
  }

  override fun isSupported(callback: (Result<Boolean>) -> Unit) {
    val ctx = context ?: activity
    if (ctx == null) {
      callback(Result.success(false))
      return
    }
    callback(Result.success(suppressor.hasNfcHardware(ctx)))
  }
}
