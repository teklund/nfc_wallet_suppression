import XCTest
import PassKit
@testable import nfc_wallet_suppression

/// Unit tests for PassLibraryProtocol implementations.
/// Demonstrates how dependency injection enables better unit testing.
class PassLibraryProtocolTests: XCTestCase {
    
    var fake: FakePassLibrary!
    
    override func setUp() {
        super.setUp()
        fake = FakePassLibrary()
    }
    
    override func tearDown() {
        fake = nil
        super.tearDown()
    }
    
    // MARK: - Default State Tests
    
    func testDefaultState() {
        XCTAssertTrue(fake.isSupported(), "Default supported should be true")
        XCTAssertEqual(fake.requestCount, 0, "Default request count should be 0")
        XCTAssertEqual(fake.endCount, 0, "Default end count should be 0")
        XCTAssertNil(fake.lastToken, "Default last token should be nil")
    }
    
    // MARK: - Configuration Tests
    
    func testCanConfigureSupported() {
        fake.supported = false
        XCTAssertFalse(fake.isSupported(), "Should report not supported")
        XCTAssertTrue(fake.methodCalls.contains("isSupported"), "Should track isSupported call")
        
        fake.supported = true
        XCTAssertTrue(fake.isSupported(), "Should report supported")
    }
    
    func testCanConfigureResult() {
        fake.suppressionResult = .denied
        
        let expectation = self.expectation(description: "response")
        _ = fake.requestSuppression { result in
            XCTAssertEqual(result, .denied, "Should return configured result")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Request Suppression Tests
    
    func testRequestSuppressionTracking() {
        let expectation = self.expectation(description: "response")
        
        let token = fake.requestSuppression { result in
            XCTAssertEqual(result, .success, "Should return success by default")
            expectation.fulfill()
        }
        
        XCTAssertNotNil(token, "Should return a token")
        XCTAssertEqual(fake.requestCount, 1, "Should increment request count")
        XCTAssertEqual(fake.lastToken, token, "Should store last token")
        XCTAssertTrue(fake.methodCalls.contains("requestSuppression"), "Should track method call")
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testMultipleRequestSuppression() {
        let expectation1 = self.expectation(description: "response1")
        let expectation2 = self.expectation(description: "response2")
        
        _ = fake.requestSuppression { _ in expectation1.fulfill() }
        _ = fake.requestSuppression { _ in expectation2.fulfill() }
        
        XCTAssertEqual(fake.requestCount, 2, "Should track multiple requests")
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testRequestSuppressionWithDifferentResults() {
        let results: [PKAutomaticPassPresentationSuppressionResult] = [
            .success, .denied, .cancelled, .notSupported, .alreadyPresenting
        ]
        
        for expectedResult in results {
            fake.reset()
            fake.suppressionResult = expectedResult
            
            let expectation = self.expectation(description: "response_\(expectedResult)")
            _ = fake.requestSuppression { result in
                XCTAssertEqual(result, expectedResult, "Should return \(expectedResult)")
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0)
        }
    }
    
    // MARK: - End Suppression Tests
    
    func testEndSuppressionTracking() {
        // First request suppression to get a token
        let token = fake.requestSuppression { _ in }
        
        // Then end it
        fake.endSuppression(withRequestToken: token)
        
        XCTAssertEqual(fake.endCount, 1, "Should increment end count")
        XCTAssertTrue(fake.methodCalls.contains("endSuppression"), "Should track method call")
    }
    
    func testMultipleEndSuppression() {
        let token1 = fake.requestSuppression { _ in }
        let token2 = fake.requestSuppression { _ in }
        
        fake.endSuppression(withRequestToken: token1)
        fake.endSuppression(withRequestToken: token2)
        
        XCTAssertEqual(fake.endCount, 2, "Should track multiple end calls")
    }
    
    // MARK: - Method Call Tracking Tests
    
    func testTracksAllMethodCalls() {
        _ = fake.isSupported()
        _ = fake.requestSuppression { _ in }
        let token = fake.requestSuppression { _ in }
        fake.endSuppression(withRequestToken: token)
        
        XCTAssertEqual(fake.methodCalls.count, 4, "Should track all 4 method calls")
        XCTAssertEqual(fake.methodCalls[0], "isSupported")
        XCTAssertEqual(fake.methodCalls[1], "requestSuppression")
        XCTAssertEqual(fake.methodCalls[2], "requestSuppression")
        XCTAssertEqual(fake.methodCalls[3], "endSuppression")
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        // Modify state
        fake.supported = false
        fake.suppressionResult = .denied
        _ = fake.requestSuppression { _ in }
        fake.endSuppression(withRequestToken: PKSuppressionRequestToken())
        
        // Reset
        fake.reset()
        
        // Verify reset state
        XCTAssertTrue(fake.supported, "Should reset supported to true")
        XCTAssertEqual(fake.suppressionResult, .success, "Should reset result to success")
        XCTAssertEqual(fake.requestCount, 0, "Should reset request count")
        XCTAssertEqual(fake.endCount, 0, "Should reset end count")
        XCTAssertNil(fake.lastToken, "Should reset last token")
        XCTAssertTrue(fake.methodCalls.isEmpty, "Should clear method calls")
    }
    
    // MARK: - Async Behavior Tests
    
    func testAsyncResponseWithDelay() {
        fake.responseDelay = 0.1
        
        let expectation = self.expectation(description: "delayed response")
        let startTime = Date()
        
        _ = fake.requestSuppression { result in
            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsed, 0.1, "Should delay response")
            XCTAssertEqual(result, .success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
}
