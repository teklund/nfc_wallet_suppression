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
    var observeError: Exception? = null
    var startCount = 0
    var stopCount = 0
    var onNfcEnabled: (() -> Unit)? = null
    var whileArming: (() -> Unit)? = null

    override fun hasNfcHardware(context: Context) = hasHardware
    override fun isNfcEnabled(context: Context) = nfcEnabled
    override fun startReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback) {
      whileArming?.invoke()
      startError?.let { throw it }
      startCount++
    }
    override fun stopReaderMode(activity: Activity) {
      stopError?.let { throw it }
      stopCount++
    }
    override fun observeNfcEnabled(context: Context, onEnabled: () -> Unit): AutoCloseable {
      observeError?.let { throw it }
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
  fun request_whileNfcOff_returnsNfcDisabledAndArmsWhenNfcIsSwitchedOn() {
    val fake = FakeWalletSuppressor().apply { nfcEnabled = false }
    val plugin = pluginWithActivity(fake)
    assertEquals(SuppressionStatusCode.NFC_DISABLED, requestStatus(plugin))
    assertFalse(plugin.isSuppressed())

    fake.switchNfcOn()
    assertEquals(2, fake.startCount, "Reader mode must be re-armed once NFC is on")
    assertTrue(plugin.isSuppressed())
    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
  }

  @Test
  fun request_whenNfcComesOnWhileArming_reArms() {
    // NfcService drops the arming while NFC is still off. The NFC-on broadcast
    // goes only to receivers registered when it is sent, and arrives after the
    // request returns.
    val fake = FakeWalletSuppressor().apply { nfcEnabled = false }
    var broadcast: (() -> Unit)? = null
    fake.whileArming = {
      fake.whileArming = null
      fake.nfcEnabled = true
      broadcast = fake.onNfcEnabled
    }
    val plugin = pluginWithActivity(fake)

    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
    broadcast?.invoke()
    assertEquals(2, fake.startCount, "The NFC-on broadcast must re-arm reader mode")
  }

  @Test
  fun request_success_enablesReaderModeAndReportsSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
    assertEquals(1, fake.startCount)
    assertTrue(plugin.isSuppressed())
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
    assertTrue(plugin.isSuppressed(), "A failed tear-down must keep suppression active (truthful)")
  }

  @Test
  fun release_whenStopThrowsGenericException_reportsUnknownAndStaysSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.stopError = IllegalStateException("boom")
    assertEquals(SuppressionStatusCode.UNKNOWN, releaseStatus(plugin))
    assertTrue(plugin.isSuppressed())
  }

  @Test
  fun release_whenActive_disablesReaderModeAndReportsNotSuppressed() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)
    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
    assertEquals(1, fake.stopCount)
    assertFalse(plugin.isSuppressed())
  }

  // isSuppressed / isSupported

  @Test
  fun isSuppressed_falseWhenNoActivity() {
    assertFalse(NfcWalletSuppressionPlugin(FakeWalletSuppressor()).isSuppressed())
  }

  @Test
  fun isSuppressed_falseWhenActiveButNfcDisabled() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)
    fake.nfcEnabled = false  // user turned NFC off after suppressing
    assertFalse(plugin.isSuppressed())
  }

  @Test
  fun isSupported_reflectsHardwarePresence() {
    assertTrue(
        pluginWithActivity(FakeWalletSuppressor().apply { hasHardware = true }).isSupported())
    assertFalse(
        pluginWithActivity(FakeWalletSuppressor().apply { hasHardware = false }).isSupported())
  }

  @Test
  fun isSupported_usesApplicationContextWhenNoActivityAttached() {
    val fake = FakeWalletSuppressor().apply { hasHardware = true }
    val plugin = NfcWalletSuppressionPlugin(fake)
    // Attach the engine (sets the application context) but no activity, mirroring
    // a call made before the activity attaches.
    plugin.onAttachedToEngine(engineBinding())

    assertTrue(
        plugin.isSupported(), "isSupported must work via application context without an activity")
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
    assertTrue(plugin.isSuppressed())
  }

  @Test
  fun reattach_whenNfcDisabled_armsTheNewActivity() {
    // Android keeps reader mode for the new activity and re-sends it on resume,
    // a second path besides the NFC-on observer.
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    fake.switchNfcOff()  // while detached
    plugin.onDetachedFromActivityForConfigChanges()
    plugin.onReattachedToActivityForConfigChanges(activityBinding(activity))

    assertEquals(2, fake.startCount, "The new activity must be armed while NFC is off")
    assertFalse(plugin.isSuppressed())

    fake.switchNfcOn()
    assertEquals(3, fake.startCount)
    assertTrue(plugin.isSuppressed())
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

    assertFalse(plugin.isSuppressed(), "A failed re-arm must drop suppression")
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
    assertEquals(1, fake.stopCount, "An activity that lives on must not keep reader mode")
    assertFalse(plugin.isSuppressed(), "No activity -> not actually suppressed")

    plugin.onAttachedToActivity(activityBinding(activity))
    assertEquals(2, fake.startCount)
    assertTrue(plugin.isSuppressed())
  }

  @Test
  fun permanentDetach_fromDestroyedActivity_leavesReaderModeToAndroid() {
    // Android has already discarded a destroyed activity's reader mode and
    // throws if asked to change it.
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    Mockito.`when`(activity.isDestroyed).thenReturn(true)
    plugin.onDetachedFromActivity()

    assertEquals(0, fake.stopCount)
  }

  @Test
  fun permanentDetach_withoutRequest_leavesReaderModeAlone() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)

    plugin.onDetachedFromActivity()

    assertEquals(0, fake.stopCount)
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
    assertFalse(plugin.isSuppressed())

    fake.switchNfcOn()
    assertEquals(2, fake.startCount)
    assertTrue(plugin.isSuppressed())
  }

  @Test
  fun nfcSwitchedBackOn_whenReArmThrows_dropsSuppression() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.switchNfcOff()
    fake.startError = IllegalStateException("conflicting NFC mode")
    fake.switchNfcOn()

    assertFalse(plugin.isSuppressed(), "A failed re-arm must drop suppression")
    assertNull(fake.onNfcEnabled, "A dropped request must stop observing NFC state")

    fake.startError = null
    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
    assertEquals(2, fake.startCount, "The next request must arm reader mode again")
    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
  }

  @Test
  fun request_whileNfcOff_keepsTheEarlierRequest() {
    val fake = FakeWalletSuppressor()
    val plugin = pluginWithActivity(fake)
    requestStatus(plugin)

    fake.switchNfcOff()
    assertEquals(SuppressionStatusCode.NFC_DISABLED, requestStatus(plugin))
    assertEquals(1, fake.startCount, "Must not re-arm reader mode when already held")

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
    assertFalse(plugin.isSuppressed())
  }

  @Test
  fun release_afterRequestWhileNfcOff_endsTheHold() {
    val fake = FakeWalletSuppressor().apply { nfcEnabled = false }
    val plugin = pluginWithActivity(fake)
    assertEquals(SuppressionStatusCode.NFC_DISABLED, requestStatus(plugin))

    assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, releaseStatus(plugin))
    assertEquals(1, fake.stopCount)
    assertNull(fake.onNfcEnabled, "Release must stop observing NFC state")

    fake.switchNfcOn()
    assertEquals(1, fake.startCount, "Nothing may arm once released")
    assertFalse(plugin.isSuppressed())
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
    assertTrue(plugin.isSuppressed())
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
  fun request_whenObservingNfcStateFails_holdsNothing() {
    // For example when the app already has the maximum number of receivers.
    val fake = FakeWalletSuppressor().apply {
      observeError = IllegalStateException("Too many receivers")
    }
    val plugin = pluginWithActivity(fake)

    assertEquals(SuppressionStatusCode.UNKNOWN, requestStatus(plugin))
    assertEquals(0, fake.startCount, "Reader mode must not be armed")
    assertFalse(plugin.isSuppressed())

    fake.observeError = null
    assertEquals(SuppressionStatusCode.SUPPRESSED, requestStatus(plugin))
    assertEquals(1, fake.startCount, "A retry must arm, not report the failed request as held")
    assertNotNull(fake.onNfcEnabled)
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
