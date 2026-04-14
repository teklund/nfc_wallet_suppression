package dev.teklund.nfc_wallet_suppression

import kotlin.test.Test
import kotlin.test.assertTrue
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertEquals

/*
 * Unit tests for NfcWalletSuppressionPlugin focusing on state persistence
 * across activity lifecycle events (Task 3 validation).
 *
 * Run these tests from the command line: `./gradlew testDebugUnitTest` in `example/android/`
 * or directly from Android Studio.
 */

internal class NfcWalletSuppressionPluginTest {

  @Test
  fun isSuppressed_returnsFalseWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin()
    // No activity attached, so isSuppressed should be false
    
    plugin.isSuppressed { result ->
        assertTrue(result.isSuccess)
        assertFalse(result.getOrNull()!!)
    }
  }

  @Test
  fun requestSuppression_returnsUnavailableWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin()
    
    plugin.requestSuppression { result ->
        assertTrue(result.isSuccess)
        val suppressionResult = result.getOrNull()
        assertNotNull(suppressionResult)
        assertEquals(SuppressionStatusCode.UNAVAILABLE, suppressionResult.status)
        assertEquals("Activity not available", suppressionResult.message)
    }
  }
  
  @Test
  fun releaseSuppression_returnsNotSuppressedWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin()

    plugin.releaseSuppression { result ->
        assertTrue(result.isSuccess)
        val suppressionResult = result.getOrNull()
        assertNotNull(suppressionResult)
        assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, suppressionResult.status)
        assertEquals("Suppression released", suppressionResult.message)
    }
  }

  @Test
  fun isSupported_returnsFalseWhenNoContext() {
    val plugin = NfcWalletSuppressionPlugin()
    plugin.isSupported { result ->
      assertTrue(result.isSuccess)
      assertFalse(result.getOrNull()!!)
    }
  }

  @Test
  fun requestSuppression_returnsNotSupportedWhenNoNfcDevice() {
    val plugin = NfcWalletSuppressionPlugin()
    val binding = org.mockito.Mockito.mock(io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding::class.java)
    val activity = org.mockito.Mockito.mock(android.app.Activity::class.java)
    org.mockito.Mockito.`when`(binding.activity).thenReturn(activity)
    
    plugin.onAttachedToActivity(binding)
    // When no NFC is available on the device, NfcAdapter.getDefaultAdapter returns null
    plugin.requestSuppression { result ->
        assertTrue(result.isSuccess)
        val suppressionResult = result.getOrNull()
        assertNotNull(suppressionResult)
        assertEquals(SuppressionStatusCode.NOT_SUPPORTED, suppressionResult.status)
        assertEquals("Device does not have NFC hardware", suppressionResult.message)
    }
  }

  @Test
  fun releaseSuppression_returnsNotSuppressedWhenNoNfcDevice() {
    val plugin = NfcWalletSuppressionPlugin()
    val binding = org.mockito.Mockito.mock(io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding::class.java)
    val activity = org.mockito.Mockito.mock(android.app.Activity::class.java)
    org.mockito.Mockito.`when`(binding.activity).thenReturn(activity)
    
    plugin.onAttachedToActivity(binding)
    
    plugin.releaseSuppression { result ->
        assertTrue(result.isSuccess)
        val suppressionResult = result.getOrNull()
        assertNotNull(suppressionResult)
        assertEquals(SuppressionStatusCode.NOT_SUPPRESSED, suppressionResult.status)
        assertEquals("Suppression released", suppressionResult.message)
    }
  }
}

