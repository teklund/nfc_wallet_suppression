import Flutter
import UIKit
import XCTest


@testable import nfc_wallet_suppression

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  //TODO Fix tests
  func testIsSuppressed() {
    let plugin = NfcWalletSuppressionPlugin()

    let call = FlutterMethodCall(methodName: "isSuppressed", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
