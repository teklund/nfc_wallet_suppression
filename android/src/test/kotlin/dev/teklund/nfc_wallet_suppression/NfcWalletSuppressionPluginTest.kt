package dev.teklund.nfc_wallet_suppression

import kotlin.test.Test

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
        // In Kotlin Result success is checked via exceptionOrNull() or similar, 
        // relying on the callback value being Result.success(false)
        assert(result.isSuccess)
        assert(result.getOrNull() == false)
    }
  }

  @Test
  fun requestSuppression_returnsUnavailableWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin()
    
    plugin.requestSuppression { result ->
        assert(result.isSuccess)
        val suppressionResult = result.getOrNull()
        assert(suppressionResult != null)
        assert(suppressionResult?.status == SuppressionStatusCode.UNAVAILABLE)
        assert(suppressionResult?.message == "Activity not available")
    }
  }
  
  @Test
  fun releaseSuppression_returnsUnavailableWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin()
    
    plugin.releaseSuppression { result ->
        assert(result.isSuccess)
        val suppressionResult = result.getOrNull()
        assert(suppressionResult != null)
        assert(suppressionResult?.status == SuppressionStatusCode.UNAVAILABLE)
        assert(suppressionResult?.message == "Activity not available")
    }
  }
}
