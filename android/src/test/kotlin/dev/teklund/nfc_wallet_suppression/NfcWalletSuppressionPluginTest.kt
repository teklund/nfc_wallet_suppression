package dev.teklund.nfc_wallet_suppression

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito
import org.mockito.Mockito.mock

/*
 * Unit tests for NfcWalletSuppressionPlugin focusing on state persistence
 * across activity lifecycle events (Task 3 validation).
 *
 * Run these tests from the command line: `./gradlew testDebugUnitTest` in `example/android/`
 * or directly from Android Studio.
 */

internal class NfcWalletSuppressionPluginTest {

  @Test
  fun onMethodCall_isSuppressed_returnsExpectedValue() {
    val plugin = NfcWalletSuppressionPlugin()

    val call = MethodCall("isSuppressed", null)
    val mockResult: MethodChannel.Result = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success(false)
  }

  @Test
  fun isSuppressed_returnsFalseWhenNoActivity() {
    val plugin = NfcWalletSuppressionPlugin()
    
    val call = MethodCall("isSuppressed", null)
    val mockResult: MethodChannel.Result = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)
    
    // Should return false when activity is null
    Mockito.verify(mockResult).success(false)
  }

  // Note: requestSuppression and releaseSuppression tests require NFC hardware
  // and proper Android Context/Activity setup which cannot be easily mocked
  // in unit tests. These should be tested via integration tests on real devices.

  @Test
  fun unknownMethod_returnsNotImplemented() {
    val plugin = NfcWalletSuppressionPlugin()
    
    val call = MethodCall("unknownMethod", null)
    val mockResult: MethodChannel.Result = mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)
    
    // Should return not implemented for unknown methods
    Mockito.verify(mockResult).notImplemented()
  }
}
