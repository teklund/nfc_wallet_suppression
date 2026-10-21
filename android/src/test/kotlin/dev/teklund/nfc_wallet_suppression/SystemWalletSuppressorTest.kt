package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import androidx.core.content.ContextCompat
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertSame
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito

/**
 * Unit tests for [SystemWalletSuppressor], the layer over Android's NFC APIs.
 *
 * Its static entry points (`NfcAdapter.getDefaultAdapter` and
 * `ContextCompat.registerReceiver`) are replaced by mocks for the duration of
 * each call.
 */
internal class SystemWalletSuppressorTest {

  private val activity = Mockito.mock(Activity::class.java)
  private val context = Mockito.mock(Context::class.java)
  private val adapter = Mockito.mock(NfcAdapter::class.java)
  private val callback = NfcAdapter.ReaderCallback { }

  /** Starts observing NFC state and returns the handle and the registered receiver. */
  private fun observe(onEnabled: () -> Unit = {}): Pair<AutoCloseable, BroadcastReceiver> {
    val receiver = ArgumentCaptor.forClass(BroadcastReceiver::class.java)
    Mockito.mockStatic(ContextCompat::class.java).use { compat ->
      val handle = SystemWalletSuppressor().observeNfcEnabled(context, onEnabled)
      compat.verify {
        ContextCompat.registerReceiver(
          eq(context), receiver.capture(), any(IntentFilter::class.java), anyInt())
      }
      return handle to receiver.value
    }
  }

  private fun adapterStateChanged(state: Int): Intent {
    val intent = Mockito.mock(Intent::class.java)
    Mockito.`when`(intent.getIntExtra(eq(NfcAdapter.EXTRA_ADAPTER_STATE), anyInt()))
      .thenReturn(state)
    return intent
  }

  private fun startReaderMode(defaultAdapter: NfcAdapter? = adapter) {
    Mockito.mockStatic(NfcAdapter::class.java).use { nfc ->
      nfc.`when`<NfcAdapter?> { NfcAdapter.getDefaultAdapter(any(Context::class.java)) }
        .thenReturn(defaultAdapter)
      SystemWalletSuppressor().startReaderMode(activity, callback)
    }
  }

  private fun failEnable(error: Exception) {
    Mockito.doThrow(error).`when`(adapter)
      .enableReaderMode(any(Activity::class.java), any(), anyInt(), any())
  }

  @Test
  fun startReaderMode_success_enablesReaderModeWithoutRollingBack() {
    startReaderMode()

    Mockito.verify(adapter).enableReaderMode(eq(activity), eq(callback), anyInt(), isNull())
    Mockito.verify(adapter, Mockito.never()).disableReaderMode(any())
  }

  @Test
  fun startReaderMode_failure_disablesReaderModeAndRethrows() {
    // Android records reader mode for the activity before enableReaderMode can
    // fail, and re-applies it on the next resume unless it is cleared.
    val error = IllegalStateException("Cannot be used when alternative DiscoveryTechnology is set")
    failEnable(error)

    val thrown = assertFailsWith<IllegalStateException> { startReaderMode() }

    assertSame(error, thrown)
    Mockito.verify(adapter).disableReaderMode(activity)
  }

  @Test
  fun startReaderMode_failedRollBack_isAttachedToTheOriginalError() {
    val error = IllegalStateException("enable failed")
    val rollBackError = RuntimeException("disable failed")
    failEnable(error)
    Mockito.doThrow(rollBackError).`when`(adapter).disableReaderMode(any())

    val thrown = assertFailsWith<IllegalStateException> { startReaderMode() }

    assertSame(error, thrown)
    assertContentEquals(arrayOf<Throwable>(rollBackError), thrown.suppressed)
  }

  @Test
  fun startReaderMode_withoutAdapter_throwsWithoutTouchingReaderMode() {
    assertFailsWith<IllegalStateException> { startReaderMode(defaultAdapter = null) }

    Mockito.verifyNoInteractions(adapter)
  }

  @Test
  fun observeNfcEnabled_registersAnExportedReceiverForAdapterStateChanges() {
    val filterActions = mutableListOf<Any?>()
    Mockito.mockConstruction(IntentFilter::class.java) { _, construction ->
      filterActions.addAll(construction.arguments())
    }.use {
      Mockito.mockStatic(ContextCompat::class.java).use { compat ->
        SystemWalletSuppressor().observeNfcEnabled(context) {}

        // The NFC service does not run as the system UID, so a receiver
        // registered with RECEIVER_NOT_EXPORTED never gets its broadcast.
        compat.verify {
          ContextCompat.registerReceiver(
            eq(context), any(), any(IntentFilter::class.java), eq(ContextCompat.RECEIVER_EXPORTED))
        }
      }
    }
    assertEquals(listOf<Any?>(NfcAdapter.ACTION_ADAPTER_STATE_CHANGED), filterActions)
  }

  @Test
  fun observeNfcEnabled_callsBackOnlyOnceNfcIsOn() {
    var calls = 0
    val (_, receiver) = observe { calls++ }

    for (state in listOf(NfcAdapter.STATE_TURNING_ON, NfcAdapter.STATE_TURNING_OFF, NfcAdapter.STATE_OFF)) {
      receiver.onReceive(context, adapterStateChanged(state))
    }
    assertEquals(0, calls, "Reader mode can only be re-armed once NFC is fully on")

    receiver.onReceive(context, adapterStateChanged(NfcAdapter.STATE_ON))
    assertEquals(1, calls)
  }

  @Test
  fun observeNfcEnabled_closingTheHandleUnregistersTheReceiver() {
    val (handle, receiver) = observe()
    Mockito.verify(context, Mockito.never()).unregisterReceiver(any())

    handle.close()

    Mockito.verify(context).unregisterReceiver(receiver)
  }
}
