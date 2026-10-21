package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.content.Context
import android.nfc.NfcAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.mockito.Mockito

/**
 * Unit tests for [NfcWalletSuppressionPlugin].
 *
 * The plugin's NFC access is routed through [WalletSuppressor], so these tests
 * drive a [FakeWalletSuppressor] and use a mock [Activity] as an opaque
 * placeholder — exercising the real suppression/release/lifecycle paths without
 * a device.
 *
 * Run via `./gradlew testDebugUnitTest` in `example/android/`.
 */
internal class NfcWalletSuppressionPluginTest {

  /** Controllable fake of the NFC reader-mode API. */
  private class FakeWalletSuppressor : WalletSuppressor {
    var hasHardware = true
    var nfcEnabled = true
    var startError: Exception? = null
    var stopError: Exception? = null
    var startCount = 0
    var stopCount = 0
    var onNfcEnabled: (() -> Unit)? = null

    override fun hasNfcHardware(context: Context) = hasHardware
    override fun isNfcEnabled(context: Context) = nfcEnabled
    override fun startReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback) {
      startError?.let { throw it }
      startCount++
    }
    override fun stopReaderMode(activity: Activity) {
      stopError?.let { throw it }
      stopCount++
    }
    override fun observeNfcEnabled(context: Context, onEnabled: () -> Unit): AutoCloseable {
      onNfcEnabled = onEnabled
      return AutoCloseable { onNfcEnabled = null }
    }

    fun switchNfcOff() {
      nfcEnabled = false
    }

    fun switchNfcOn() {
      nfcEnabled = true
      onNfcEnabled?.invoke()
    }
  }

  private fun engineBinding(): FlutterPlugin.FlutterPluginBinding {
    val binding = Mockito.mock(FlutterPlugin.FlutterPluginBinding::class.java)
    Mockito.`when`(binding.binaryMessenger).thenReturn(Mockito.mock(BinaryMessenger::class.java))
    Mockito.`when`(binding.applicationContext).thenReturn(Mockito.mock(Context::class.java))
    return binding
  }

  private fun activityBinding(activity: Activity): ActivityPluginBinding {
    val binding = Mockito.mock(ActivityPluginBinding::class.java)
    Mockito.`when`(binding.activity).thenReturn(activity)
    return binding
  }

  private fun pluginWithActivity(
    fake: FakeWalletSuppressor,
    activity: Activity = Mockito.mock(Activity::class.java),
  ): NfcWalletSuppressionPlugin {
    val plugin = NfcWalletSuppressionPlugin(fake)
    // Flutter attaches the engine before any activity.
    plugin.onAttachedToEngine(engineBinding())
    plugin.onAttachedToActivity(activityBinding(activity))
    return plugin
  }

  private fun request(plugin: NfcWalletSuppressionPlugin): SuppressionResult {
    var result: SuppressionResult? = null
    plugin.requestSuppression { result = it.getOrNull() }
    return result!!
  }

  private fun requestStatus(plugin: NfcWalletSuppressionPlugin): SuppressionStatusCode =
    request(plugin).status

  private fun releaseStatus(plugin: NfcWalletSuppressionPlugin): SuppressionStatusCode {
    var status: SuppressionStatusCode? = null
    plugin.releaseSuppression { status = it.getOrNull()?.status }
    return status!!
  }

  private fun suppressed(plugin: NfcWalletSuppressionPlugin): Boolean {
    var value = false
    plugin.isSuppressed { value = it.getOrNull()!! }
    return value
  }

  private fun supported(plugin: NfcWalletSuppressionPlugin): Boolean {
    var value = false
    plugin.isSupported { value = it.getOrNull()!! }
    return value
  }

  // requestSuppression

  @Test
  fun request_returnsUnavailableWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin(FakeWalletSuppressor())
    assertEquals(SuppressionStatusCode.UNAVAILABLE, requestStatus(plugin))
  }

  @Test
  fun request_returnsNotSupportedWhenNoNfcHardware() {
    val fake = FakeWalletSuppressor().apply { hasHardware = false }
    assertEquals(SuppressionStatusCode.NOT_SUPPORTED, requestStatus(pluginWithActivity(fake)))
  }

  @Test
  fun request_returnsNfcDisabledWhenNfcSwitchedOff() {
    // Distinct from UNAVAILABLE and NOT_SUPPORTED because it is the one failure
    // the user can fix: an app can deep-link to android.settings.NFC_SETTINGS.
    val fake = FakeWalletSuppressor().apply { nfcEnabled = false }
    assertEquals(SuppressionStatusCode.NFC_DISABLED, requestStatus(pluginWithActivity(fake)))
  }

  @Test
  fun request_success_enablesReaderModeAndReportsSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
    assertEquals(1, fake.startCount)
    assertTrue(suppressed(plugin))
  }

  @Test
  fun request_whenAlreadyActive_returnsSuppressedWithoutReArming() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)
    assertEquals(1, fake.startCount)

    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
    assertEquals(1, fake.startCount, "Must not re-arm reader mode when already active")
  }

  @Test
  fun request_securityException_returnsDenied() {
    val fake = FakeWalletSuppressor().apply { startError = SecurityException("nope") }
    assertEquals(SuppressionStatusCode.DENIED, requestStatus(pluginWithActivity(fake)))
  }

  @Test
  fun request_genericException_returnsUnknown() {
    val fake = FakeWalletSuppressor().apply { startError = IllegalStateException("boom") }
    assertEquals(SuppressionStatusCode.UNKNOWN, requestStatus(pluginWithActivity(fake)))
  }

  // releaseSuppression

  @Test
  fun release_withoutActiveSuppression_isAnIdempotentNoOp() {
    // Releasing when nothing is suppressed is a success: the caller asked for
    // suppression to be off and it is off, so `finally { release() }` needs no
    // special case for a request that failed.
    val plugin = pluginWithActivity(FakeWalletSuppressor())
    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
  }

  @Test
  fun release_whenStopThrowsSecurityException_reportsDeniedAndStaysSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.stopError = SecurityException("denied")
    assertEquals(SuppressionStatusCode.DENIED, releaseStatus(plugin))
    assertTrue(suppressed(plugin), "A failed tear-down must keep suppression active (truthful)")
  }

  @Test
  fun release_whenStopThrowsGenericException_reportsUnknownAndStaysSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.stopError = IllegalStateException("boom")
    assertEquals(SuppressionStatusCode.UNKNOWN, releaseStatus(plugin))
    assertTrue(suppressed(plugin))
  }

  @Test
  fun release_whenActive_disablesReaderModeAndReportsNotSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)
    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
    assertEquals(1, fake.stopCount)
    assertFalse(suppressed(plugin))
  }

  // isSuppressed / isSupported

  @Test
  fun isSuppressed_falseWhenNoActivity() {
    assertFalse(suppressed(NfcWalletSuppressionPlugin(FakeWalletSuppressor())))
  }

  @Test
  fun isSuppressed_falseWhenActiveButNfcDisabled() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)
    fake.nfcEnabled = false  // user turned NFC off after suppressing
    assertFalse(suppressed(plugin))
  }

  @Test
  fun isSupported_reflectsHardwarePresence() {
    assertTrue(supported(pluginWithActivity(FakeWalletSuppressor().apply { hasHardware = true })))
    assertFalse(supported(pluginWithActivity(FakeWalletSuppressor().apply { hasHardware = false })))
  }

  @Test
  fun isSupported_usesApplicationContextWhenNoActivityAttached() {
    val fake = FakeWalletSuppressor().apply { hasHardware = true }
    val plugin = NfcWalletSuppressionPlugin(fake)
    // Attach the engine (sets the application context) but no activity, mirroring
    // a call made before the activity attaches.
    plugin.onAttachedToEngine(engineBinding())

    assertTrue(supported(plugin), "isSupported must work via application context without an activity")
  }

  // lifecycle

  @Test
  fun configurationChange_reArmsReaderModeOnReattach() {
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)
    assertEquals(1, fake.startCount)

    plugin.onDetachedFromActivityForConfigChanges()
    plugin.onReattachedToActivityForConfigChanges(activityBinding(activity))

    assertEquals(2, fake.startCount, "Reader mode must be re-armed against the new activity")
    assertTrue(suppressed(plugin))
  }

  @Test
  fun reattach_whenNfcDisabled_defersReArmUntilNfcIsSwitchedOn() {
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    fake.switchNfcOff()  // while detached
    plugin.onDetachedFromActivityForConfigChanges()
    plugin.onReattachedToActivityForConfigChanges(activityBinding(activity))

    assertEquals(1, fake.startCount, "Must not re-arm when NFC is disabled")
    assertFalse(suppressed(plugin))

    fake.switchNfcOn()
    assertEquals(2, fake.startCount)
    assertTrue(suppressed(plugin))
  }

  @Test
  fun reattach_whenReArmThrows_dropsSuppression() {
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    // Re-arming reader mode fails on reattach (e.g. SecurityException).
    fake.startError = SecurityException("denied")
    plugin.onDetachedFromActivityForConfigChanges()
    plugin.onReattachedToActivityForConfigChanges(activityBinding(activity))

    assertFalse(suppressed(plugin), "A failed re-arm must drop suppression")
    assertNull(fake.onNfcEnabled, "A dropped request must stop observing NFC state")
    assertEquals(
      SuppressionStatusCode.NOT_SUPPRESSED,
      releaseStatus(plugin),
      "suppressionActive must have been cleared on re-arm failure",
    )
  }

  @Test
  fun permanentDetachThenReattach_reArmsReaderMode() {
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    plugin.onDetachedFromActivity()
    assertFalse(suppressed(plugin), "No activity -> not actually suppressed")

    plugin.onAttachedToActivity(activityBinding(activity))
    assertEquals(2, fake.startCount)
    assertTrue(suppressed(plugin))
  }

  // NFC switched off and on

  @Test
  fun nfcSwitchedBackOn_reArmsReaderMode() {
    // Android discards reader mode when NFC is switched off and does not restore
    // it when NFC returns, so the plugin must re-arm it.
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.switchNfcOff()
    assertFalse(suppressed(plugin))

    fake.switchNfcOn()
    assertEquals(2, fake.startCount)
    assertTrue(suppressed(plugin))
  }

  @Test
  fun nfcSwitchedBackOn_whenReArmThrows_dropsSuppression() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.switchNfcOff()
    fake.startError = IllegalStateException("conflicting NFC mode")
    fake.switchNfcOn()

    assertFalse(suppressed(plugin), "A failed re-arm must drop suppression")
    assertNull(fake.onNfcEnabled, "A dropped request must stop observing NFC state")
    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
  }

  @Test
  fun request_whileNfcOff_reportsNfcDisabledAndKeepsTheEarlierRequest() {
    val fake = FakeWalletSuppressor().apply { nfcEnabled = false }
    val plugin = pluginWithActivity(fake)
    val withoutRequest = request(plugin)

    fake.switchNfcOn()
    requestStatus(plugin)
    fake.switchNfcOff()
    val withRequest = request(plugin)

    assertEquals(SuppressionStatusCode.NFC_DISABLED, withRequest.status)
    assertNotEquals(
      withoutRequest.message,
      withRequest.message,
      "The message must tell a held request apart from one that was never made",
    )

    fake.switchNfcOn()
    assertEquals(2, fake.startCount)
    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
  }

  @Test
  fun release_whileNfcOff_preventsReArmWhenNfcReturns() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.switchNfcOff()
    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
    assertEquals(1, fake.stopCount)

    fake.switchNfcOn()
    assertEquals(1, fake.startCount)
    assertFalse(suppressed(plugin))
  }

  @Test
  fun nfcSwitchedOn_withoutActivity_reArmsOnAttach() {
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    plugin.onDetachedFromActivity()
    fake.switchNfcOff()
    fake.switchNfcOn()
    assertEquals(1, fake.startCount, "No activity to arm reader mode against")

    plugin.onAttachedToActivity(activityBinding(activity))
    assertEquals(2, fake.startCount)
    assertTrue(suppressed(plugin))
  }

  // NFC state observation

  @Test
  fun nfcState_isObservedOnlyWhileARequestIsHeld() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    assertNull(fake.onNfcEnabled, "Nothing to re-arm before a request")

    requestStatus(plugin)
    assertNotNull(fake.onNfcEnabled)

    releaseStatus(plugin)
    assertNull(fake.onNfcEnabled)
  }

  @Test
  fun failedRequest_doesNotObserveNfcState() {
    val fake = FakeWalletSuppressor().apply { startError = IllegalStateException("boom") }
    requestStatus(pluginWithActivity(fake))
    assertNull(fake.onNfcEnabled)
  }

  @Test
  fun detachFromEngine_endsTheRequestAndStopsObservingNfcState() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    plugin.onDetachedFromEngine(engineBinding())
    assertNull(fake.onNfcEnabled)
  }
}
