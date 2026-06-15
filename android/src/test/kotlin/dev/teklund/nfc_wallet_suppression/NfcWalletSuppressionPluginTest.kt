package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.content.Context
import android.nfc.NfcAdapter
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.mockito.Mockito

/**
 * Unit tests for [NfcWalletSuppressionPlugin].
 *
 * The plugin's NFC access is routed through [WalletSuppressor], so these tests
 * drive a [FakeWalletSuppressor] and use a mock [Activity] as an opaque token —
 * exercising the real suppression/release/lifecycle paths without a device.
 *
 * Run via `./gradlew testDebugUnitTest` in `example/android/`.
 */
internal class NfcWalletSuppressionPluginTest {

  /** Controllable fake of the NFC reader-mode API. */
  private class FakeWalletSuppressor : WalletSuppressor {
    var hasHardware = true
    var nfcEnabled = true
    var startError: Exception? = null
    var startCount = 0
    var stopCount = 0

    override fun hasNfcHardware(context: Context) = hasHardware
    override fun isNfcEnabled(context: Context) = nfcEnabled
    override fun startReaderMode(activity: Activity, callback: NfcAdapter.ReaderCallback) {
      startError?.let { throw it }
      startCount++
    }
    override fun stopReaderMode(activity: Activity) {
      stopCount++
    }
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
    plugin.onAttachedToActivity(activityBinding(activity))
    return plugin
  }

  private fun requestStatus(plugin: NfcWalletSuppressionPlugin): SuppressionStatusCode {
    var status: SuppressionStatusCode? = null
    plugin.requestSuppression { status = it.getOrNull()?.status }
    return status!!
  }

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
  fun request_returnsUnavailableWhenNfcDisabled() {
    val fake = FakeWalletSuppressor().apply { nfcEnabled = false }
    assertEquals(SuppressionStatusCode.UNAVAILABLE, requestStatus(pluginWithActivity(fake)))
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
  fun release_withoutActiveSuppression_returnsUnavailable() {
    val plugin = pluginWithActivity(FakeWalletSuppressor())
    assertEquals(SuppressionStatusCode.UNAVAILABLE, releaseStatus(plugin))
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
  fun reattach_whenNfcDisabled_dropsSuppression() {
    val fake = FakeWalletSuppressor()
    val activity = Mockito.mock(Activity::class.java)
    val plugin = pluginWithActivity(fake, activity)
    requestStatus(plugin)

    fake.nfcEnabled = false  // NFC turned off while detached
    plugin.onDetachedFromActivityForConfigChanges()
    plugin.onReattachedToActivityForConfigChanges(activityBinding(activity))

    assertEquals(1, fake.startCount, "Must not re-arm when NFC is disabled")
    assertFalse(suppressed(plugin))
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
}
