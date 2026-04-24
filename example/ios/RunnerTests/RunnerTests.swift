import Flutter
import UIKit
import XCTest


@testable import nfc_wallet_suppression

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {
    
    var plugin: NfcWalletSuppressionPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = NfcWalletSuppressionPlugin()
    }
    
    override func tearDown() {
        plugin = nil
        super.tearDown()
    }
    
    /// Test default isSuppressed state
    func testIsSuppressed_defaultsToFalse() {
        let expectation = self.expectation(description: "isSuppressed completes")
        
        plugin.isSuppressed { result in
            switch result {
            case .success(let suppressed):
                XCTAssertFalse(suppressed, "Default suppression state should be false")
            case .failure(let error):
                XCTFail("isSuppressed failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    /// Test that releaseSuppression returns notSuppressed when no token exists (idempotent)
    func testReleaseSuppression_withoutRequest_returnsUnavailable() {
        let expectation = self.expectation(description: "releaseSuppression completes")
        
        plugin.releaseSuppression { result in
            switch result {
            case .success(let suppressionResult):
                // Based on implementation, releasing without token returns UNAVAILABLE
                XCTAssertEqual(suppressionResult.status, .unavailable)
                XCTAssertEqual(suppressionResult.message, "No active suppression to release")
            case .failure(let error):
                XCTFail("releaseSuppression failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    /// Test isSupported (will likely return false on Simulator)
    func testIsSupported_returnsResult() {
        let expectation = self.expectation(description: "isSupported completes")
        
        plugin.isSupported { result in
            switch result {
            case .success:
                // Just verifying it returns a success result, boolean depends on simulator environment
                XCTAssertTrue(true)
            case .failure(let error):
                XCTFail("isSupported failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
}
