package dev.teklund.nfc_wallet_suppression

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class NfcWalletSuppressionPluginTest {

  //TODO Fix tests
  @Test
  fun onMethodCall_isSuppressed_returnsExpectedValue() {
    val plugin = NfcWalletSuppressionPlugin()

    val call = MethodCall("isSuppressed", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success(false)
  }
}
