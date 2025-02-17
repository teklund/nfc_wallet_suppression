package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NfcWalletSuppressionPlugin */
class NfcWalletSuppressionPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var supperessionActive : Boolean = false
  private var activity : Activity? = null

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
        val success = requestSuppression()
        result.success(success)
      }
      "releaseSuppression" -> {
        val success = releaseSuppression()
        result.success(success)
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
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  private fun isSuppressed(): Boolean {
    return activity != null && supperessionActive
  }

  private fun requestSuppression(): Boolean {
    var activity = activity
    var nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    if (nfcAdapter == null || activity == null) {
      print("NFC not available")
      return false
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

    val intentFiltersArray = arrayOf(IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED))
    nfcAdapter.enableForegroundDispatch(activity, pendingIntent, intentFiltersArray, null)
    supperessionActive = true;
    print("Suppressed")
    return true
  }

  private fun releaseSuppression(): Boolean {
    var activity = activity
    var nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    if (nfcAdapter == null || activity == null) {
      print("NFC not available")
      return false
    }
    nfcAdapter.disableForegroundDispatch(activity)
    print("Not suppressed anymore")
    supperessionActive = false;
    return true
  }
}
