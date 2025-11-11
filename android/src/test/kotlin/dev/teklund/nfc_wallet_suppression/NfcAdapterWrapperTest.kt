package dev.teklund.nfc_wallet_suppression

import android.app.Activity
import kotlin.test.Test
import kotlin.test.assertTrue
import kotlin.test.assertFalse
import kotlin.test.assertEquals
import org.mockito.Mockito

/**
 * Unit tests for NfcAdapterWrapper implementations.
 * Demonstrates how dependency injection enables better unit testing.
 */
class NfcAdapterWrapperTest {
    
    @Test
    fun fakeNfcAdapter_defaultState() {
        val fake = FakeNfcAdapterWrapper()
        
        assertTrue(fake.isNfcAvailable())
        assertTrue(fake.isNfcEnabled())
        assertFalse(fake.readerModeEnabled)
        assertFalse(fake.foregroundDispatchEnabled)
    }
    
    @Test
    fun fakeNfcAdapter_canConfigureAvailability() {
        val fake = FakeNfcAdapterWrapper()
        
        fake.available = false
        assertFalse(fake.isNfcAvailable())
        
        fake.available = true
        assertTrue(fake.isNfcAvailable())
    }
    
    @Test
    fun fakeNfcAdapter_canConfigureEnabled() {
        val fake = FakeNfcAdapterWrapper()
        
        fake.enabled = false
        assertFalse(fake.isNfcEnabled())
        
        fake.enabled = true
        assertTrue(fake.isNfcEnabled())
    }
    
    @Test
    fun fakeNfcAdapter_tracksMethodCalls() {
        val fake = FakeNfcAdapterWrapper()
        
        fake.isNfcAvailable()
        fake.isNfcEnabled()
        
        assertEquals(2, fake.methodCalls.size)
        assertEquals("isNfcAvailable", fake.methodCalls[0])
        assertEquals("isNfcEnabled", fake.methodCalls[1])
    }
    
    @Test
    fun fakeNfcAdapter_reset() {
        val fake = FakeNfcAdapterWrapper()
        
        // Modify state
        fake.available = false
        fake.enabled = false
        fake.isNfcAvailable() // Add to method calls
        
        // Reset
        fake.reset()
        
        // Verify reset state
        assertTrue(fake.isNfcAvailable())
        assertTrue(fake.isNfcEnabled())
        assertFalse(fake.readerModeEnabled)
        assertFalse(fake.foregroundDispatchEnabled)
        // Method calls should be empty after reset, but the assertions above added 2 calls
        assertEquals(2, fake.methodCalls.size) // isNfcAvailable and isNfcEnabled from assertions
    }
}
