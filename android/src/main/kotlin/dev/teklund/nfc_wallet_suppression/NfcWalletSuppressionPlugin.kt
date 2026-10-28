package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Abstraction over the Android NFC APIs the plugin uses.
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
   * enabled (e.g., no adapter, or a security restriction), and then leaves
   * reader mode disabled for [activity].
   *
   * Returns normally while NFC is off: Android keeps reader mode for [activity]
   * and re-sends it on resume, but NfcService drops it until NFC is on, so it
   * must be armed again then.
   */
  fun startReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback)

  fun stopReaderMode(activity: Activity)

  /**
   * Calls [onEnabled] each time NFC is switched on, until the returned handle
   * is closed.
   */
  fun observeNfcEnabled(context: Context, onEnabled: () -> Unit): AutoCloseable
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
    try {
      adapter.enableReaderMode(activity, callback, flags, null)
    } catch (e: Exception) {
      // Android records reader mode before this can fail, and re-applies it on
      // resume. Clear it: release only undoes a request that succeeded.
      runCatching { adapter.disableReaderMode(activity) }.onFailure(e::addSuppressed)
      throw e
    }
  }

  override fun stopReaderMode(activity: Activity) {
    NfcAdapter.getDefaultAdapter(activity)?.disableReaderMode(activity)
  }

  override fun observeNfcEnabled(context: Context, onEnabled: () -> Unit): AutoCloseable {
    val receiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
        val state = intent.getIntExtra(NfcAdapter.EXTRA_ADAPTER_STATE, NfcAdapter.STATE_OFF)
        if (state == NfcAdapter.STATE_ON) onEnabled()
      }
    }
    val filter = IntentFilter(NfcAdapter.ACTION_ADAPTER_STATE_CHANGED)
    // The NFC service sends this from its own UID, not the system UID, so
    // RECEIVER_NOT_EXPORTED never gets it. Exporting is safe: it is a protected
    // broadcast only the platform can send.
    ContextCompat.registerReceiver(context, receiver, filter, ContextCompat.RECEIVER_EXPORTED)
    return AutoCloseable { context.unregisterReceiver(receiver) }
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

  /**
   * Whether the app holds a suppression request. Android arms reader mode while
   * this is set, an activity is attached and resumed, and NFC is on, unless
   * another app or plugin takes reader mode over.
   *
   * NFC state is observed only while this is set, to re-arm reader mode when NFC
   * is switched on (as from quick settings): Android drops reader mode set while
   * NFC is off, and from Android 13 switching NFC off clears it, in both cases
   * until the next resume.
   */
  private var suppressionActive: Boolean = false
    set(active) {
      if (active == field) return
      if (active) {
        // Observe first, so a failure to observe leaves nothing held.
        nfcEnabledObserver = context?.let { suppressor.observeNfcEnabled(it) { reestablish() } }
      } else {
        nfcEnabledObserver?.close()
        nfcEnabledObserver = null
      }
      field = active
    }

  private var nfcEnabledObserver: AutoCloseable? = null

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
    // Without an engine nothing can hold the request; this also stops observing NFC state.
    suppressionActive = false
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
    // Reader mode belongs to the activity, which can outlive Flutter (a removed
    // FlutterFragment). A destroyed one has already lost it and rejects the call.
    val activity = activity
    if (suppressionActive && activity != null && !activity.isDestroyed) {
      runCatching { suppressor.stopReaderMode(activity) }
    }
    this.activity = null
  }

  /** Re-arms reader mode against the current activity. Precondition: suppressionActive. */
  private fun reestablish() {
    val activity = activity ?: return
    try {
      // Armed even while NFC is off, as in hold(): Android keeps it for the
      // activity and re-sends it on resume, and the observer re-arms on NFC-on.
      suppressor.startReaderMode(activity, this)
      if (isDebug) {
        Log.d(TAG, if (suppressor.isNfcEnabled(activity)) {
          "Re-established NFC suppression"
        } else {
          "Re-armed NFC suppression; it starts when NFC is enabled"
        })
      }
    } catch (e: Exception) {
      // Drop the request, so isSuppressed stops reporting it and the next
      // request arms reader mode again instead of reporting the failed hold.
      if (isDebug) Log.e(TAG, "Failed to re-establish suppression", e)
      suppressionActive = false
    }
  }

  /** Holds the request and arms reader mode, or leaves neither in place. */
  private fun hold(activity: Activity) {
    // Hold first, so NFC state is observed before arming: NfcService drops the
    // arming if NFC is still off, and the observer then re-arms once it is on.
    suppressionActive = true
    try {
      suppressor.startReaderMode(activity, this)
    } catch (e: Exception) {
      runCatching { suppressionActive = false }.onFailure(e::addSuppressed)
      throw e
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
    // Already held: reader mode is re-armed on every resume, attach and NFC-on,
    // and Android has no API to query it, so keep the hold. Arming again would
    // risk a failure that clears the reader mode already in effect.
    val alreadyHeld = suppressionActive
    if (!alreadyHeld) {
      try {
        hold(activity)
      } catch (e: SecurityException) {
        callback(Result.success(SuppressionResult(
          SuppressionStatusCode.DENIED, "Permission denied for NFC operations: ${e.message}")))
        return
      } catch (e: Exception) {
        callback(Result.success(SuppressionResult(
          SuppressionStatusCode.UNKNOWN, "Failed to request suppression: ${e.message}")))
        return
      }
    }
    if (!suppressor.isNfcEnabled(activity)) {
      // Held, but nothing is suppressed while NFC is off; reader mode is armed
      // when it is switched on.
      if (isDebug) Log.d(TAG, "NFC wallet suppression held; it starts when NFC is enabled")
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.NFC_DISABLED, "NFC is disabled. Suppression starts when NFC is enabled")))
      return
    }
    if (isDebug && !alreadyHeld) Log.d(TAG, "NFC wallet suppression enabled")
    val message = if (alreadyHeld) "Suppression already active" else "Suppressed"
    callback(Result.success(SuppressionResult(SuppressionStatusCode.SUPPRESSED, message)))
  }

  override fun releaseSuppression(callback: (Result<SuppressionResult>) -> Unit) {
    // Intent-based release (matches iOS): we report on the suppression we were
    // holding, not on live device state. We deliberately do NOT reconcile against
    // live state here (unlike isSuppressed) so request/release stays a clean pair
    // and both platforms behave identically; isSuppressed is the API for live
    // state.
    //
    // Releasing when nothing was suppressed is NOT_SUPPRESSED, not an error: the
    // caller asked for suppression to be off and it is off. That makes release
    // idempotent, so a `finally { release() }` block never has to special-case
    // whether the matching request succeeded. The message still distinguishes the
    // two paths for anyone reading logs.
    if (!suppressionActive) {
      callback(Result.success(SuppressionResult(
        SuppressionStatusCode.NOT_SUPPRESSED, "No active suppression to release")))
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

  override fun isSuppressed(): Boolean {
    if (!suppressionActive) return false
    val activity = activity ?: return false
    // Reconcile intent with reality: Android arms reader mode only while the
    // activity is resumed and NFC is on. An activity without a lifecycle (a rare
    // add-to-app host) is taken as resumed.
    val resumed = (activity as? LifecycleOwner)?.lifecycle?.currentState
      ?.isAtLeast(Lifecycle.State.RESUMED) ?: true
    return resumed && suppressor.isNfcEnabled(activity)
  }

  override fun isSupported(): Boolean {
    val context = context
    return context != null && suppressor.hasNfcHardware(context)
  }
}
