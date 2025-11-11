package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
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
    //binding.addOnNewIntentListener(this)
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
    return activity != null && suppressionActive
  }

  private fun reestablishSuppression() {
    val activity = activity
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    if (nfcAdapter == null || activity == null || !nfcAdapter.isEnabled()) {
      // NFC not available, clear suppression state
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
    if (nfcAdapter == null || activity == null || !nfcAdapter.isEnabled() ) {
      result.error("UNAVAILABLE", "NFC not available", null)
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
    suppressionActive = true;
    result.success("Suppressed")
  }

  private fun releaseSuppression(result: Result) {
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    if (nfcAdapter == null || activity == null || !nfcAdapter.isEnabled() ) {
      result.error("UNAVAILABLE", "NFC not available", null)
      return
    }
    nfcAdapter.disableForegroundDispatch(activity)
    nfcAdapter.disableReaderMode(activity)
    suppressionActive = false
    result.success("Not suppressed anymore")
  }

  private fun isSupported(): Boolean {
    // Check if device has NFC hardware (requires API 21+)
    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    return nfcAdapter != null
  }
}
