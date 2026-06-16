import Flutter
import UIKit
import PassKit
import XCTest

@testable import nfc_wallet_suppression

/// Controllable fake of the PassKit suppression API.
///
/// Mirrors PassKit's contract: `requestSuppression` returns the token
/// synchronously and the response handler fires later, when the test calls
/// `deliver(_:)`. (In production `SystemPassLibrary` guarantees the handler is
/// delivered asynchronously on the main thread, so synchronous delivery is not
/// modelled here.)
final class FakePassLibrary: PassPresentationSuppressing {
  var isPassLibraryAvailable = false
  var isSuppressingAutomaticPassPresentation = false

  /// Token returned by `requestSuppression`. `0` models a request that could
  /// not be submitted (handler never fires).
  var tokenToReturn: PKSuppressionRequestToken = 1

  private(set) var requestCount = 0
  private(set) var endedTokens: [PKSuppressionRequestToken] = []
  private var pendingHandler: ((PKAutomaticPassPresentationSuppressionResult) -> Void)?

  func requestSuppression(
    responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void
  ) -> PKSuppressionRequestToken {
    requestCount += 1
    pendingHandler = responseHandler
    return tokenToReturn
  }

  func endSuppression(withRequestToken token: PKSuppressionRequestToken) {
    endedTokens.append(token)
  }

  /// Simulate PassKit invoking the response handler.
  func deliver(_ result: PKAutomaticPassPresentationSuppressionResult) {
    let handler = pendingHandler
    pendingHandler = nil
    handler?(result)
  }
}

class RunnerTests: XCTestCase {

  // MARK: - Pure result mapping

  func testMapping_coversEverySuppressionResult() {
    XCTAssertEqual(NfcWalletSuppressionPlugin.suppressionResult(for: .success).status, .suppressed)
    XCTAssertEqual(NfcWalletSuppressionPlugin.suppressionResult(for: .notSupported).status, .notSupported)
    XCTAssertEqual(NfcWalletSuppressionPlugin.suppressionResult(for: .alreadyPresenting).status, .alreadyPresenting)
    XCTAssertEqual(NfcWalletSuppressionPlugin.suppressionResult(for: .cancelled).status, .cancelled)
    XCTAssertEqual(NfcWalletSuppressionPlugin.suppressionResult(for: .denied).status, .denied)
  }

  // MARK: - requestSuppression

  func testRequest_success_becomesActiveAndReportsSuppressed() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 42
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    fake.deliver(.success)

    XCTAssertEqual(status, .suppressed)
    XCTAssertEqual(fake.requestCount, 1)
    XCTAssertTrue(fake.endedTokens.isEmpty, "A successful request must not release its token")
  }

  func testRequest_failure_releasesTokenAndReportsStatus() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 7
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    fake.deliver(.denied)

    XCTAssertEqual(status, .denied)
    XCTAssertEqual(fake.endedTokens, [7], "A failed request must release the issued token")

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .unavailable, "No token should linger after a failed request")
  }

  func testRequest_zeroToken_reportsUnknownWithoutHandler() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 0  // could not be submitted; handler never fires
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var callCount = 0
    var status: SuppressionStatusCode?
    plugin.requestSuppression {
      callCount += 1
      status = (try? $0.get())?.status
    }
    // Deliberately never deliver a handler result.

    XCTAssertEqual(callCount, 1, "completion must fire even if PassKit never calls the handler")
    XCTAssertEqual(status, .unknown)
    XCTAssertTrue(fake.endedTokens.isEmpty, "Must never end a 0 token")
  }

  func testRequest_coalescedRequestAndDeferredReleaseResolveTogether() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 21
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var first: SuppressionStatusCode?
    var second: SuppressionStatusCode?
    var release: SuppressionStatusCode?
    plugin.requestSuppression { first = (try? $0.get())?.status }
    plugin.requestSuppression { second = (try? $0.get())?.status }  // coalesces
    plugin.releaseSuppression { release = (try? $0.get())?.status }  // defers

    XCTAssertEqual(fake.requestCount, 1)
    XCTAssertTrue(fake.endedTokens.isEmpty)

    fake.deliver(.success)

    XCTAssertEqual(first, .suppressed)
    XCTAssertEqual(second, .suppressed)
    XCTAssertEqual(release, .notSuppressed, "Deferred release runs after the coalesced requests resolve")
    XCTAssertEqual(fake.endedTokens, [21])
  }

  func testRequest_concurrentCallsCoalesceOntoOneRequest() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 11
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var first: SuppressionStatusCode?
    var second: SuppressionStatusCode?
    plugin.requestSuppression { first = (try? $0.get())?.status }
    plugin.requestSuppression { second = (try? $0.get())?.status }  // in flight -> coalesces

    XCTAssertEqual(fake.requestCount, 1, "A second in-flight request must not issue another PassKit request")

    fake.deliver(.success)
    XCTAssertEqual(first, .suppressed)
    XCTAssertEqual(second, .suppressed, "Coalesced request shares the in-flight result")
  }

  func testRequest_whenAlreadyActiveAndOsAgrees_returnsSuppressedWithoutNewRequest() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 3
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)
    fake.isSuppressingAutomaticPassPresentation = true  // OS confirms still suppressing

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }

    XCTAssertEqual(status, .suppressed)
    XCTAssertEqual(fake.requestCount, 1, "Must not re-request while genuinely active")
  }

  func testRequest_whenActiveButOsEndedExternally_releasesStaleTokenAndReRequests() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 8
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)  // active, token 8
    fake.isSuppressingAutomaticPassPresentation = false  // OS ended it behind our back
    fake.tokenToReturn = 9

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    XCTAssertEqual(fake.requestCount, 2, "Stale token should trigger a fresh request")
    XCTAssertTrue(fake.endedTokens.contains(8), "Stale token must be released")

    fake.deliver(.success)
    XCTAssertEqual(status, .suppressed)
  }

  func testRequest_whenActiveButOsEnded_reRequestThatFailsGoesIdle() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 8
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)  // active, token 8
    fake.isSuppressingAutomaticPassPresentation = false  // OS ended it externally
    fake.tokenToReturn = 9

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    fake.deliver(.denied)  // the fresh re-request fails

    XCTAssertEqual(status, .denied)
    XCTAssertEqual(fake.endedTokens, [8, 9],
                   "Stale token 8 released before re-request; failed request's token 9 released too")

    // State is idle, so a subsequent release reports unavailable.
    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .unavailable)
  }

  // MARK: - releaseSuppression

  func testRelease_fromIdle_returnsUnavailable() {
    let fake = FakePassLibrary()
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var result: SuppressionResult?
    plugin.releaseSuppression { result = try? $0.get() }

    XCTAssertEqual(result?.status, .unavailable)
    XCTAssertEqual(result?.message, "No active suppression to release")
  }

  func testRelease_fromActive_endsTokenAndReportsNotSuppressed() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 5
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)

    var status: SuppressionStatusCode?
    plugin.releaseSuppression { status = (try? $0.get())?.status }

    XCTAssertEqual(fake.endedTokens, [5])
    XCTAssertEqual(status, .notSuppressed)
  }

  func testRelease_duringInFlightRequest_isDeferredUntilSuccessThenReleases() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 5
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var requestStatus: SuppressionStatusCode?
    var releaseStatus: SuppressionStatusCode?
    plugin.requestSuppression { requestStatus = (try? $0.get())?.status }
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }  // deferred

    XCTAssertTrue(fake.endedTokens.isEmpty, "Release must wait for the in-flight request")

    fake.deliver(.success)
    XCTAssertEqual(requestStatus, .suppressed)
    XCTAssertEqual(releaseStatus, .notSuppressed)
    XCTAssertEqual(fake.endedTokens, [5], "Deferred release ends the now-active token")
  }

  func testRelease_duringInFlightRequest_whenRequestFails_reportsUnavailable() {
    let fake = FakePassLibrary()
    fake.tokenToReturn = 6
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var releaseStatus: SuppressionStatusCode?
    plugin.requestSuppression { _ in }
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }  // deferred

    fake.deliver(.denied)
    XCTAssertEqual(releaseStatus, .unavailable, "Nothing to release after a failed request")
    XCTAssertEqual(fake.endedTokens, [6], "The failed request's token is still released")
  }

  func testSecondRelease_duringInFlightRequest_returnsUnavailable() {
    let fake = FakePassLibrary()
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    plugin.requestSuppression { _ in }
    plugin.releaseSuppression { _ in }  // first deferred

    var secondRelease: SuppressionStatusCode?
    plugin.releaseSuppression { secondRelease = (try? $0.get())?.status }
    XCTAssertEqual(secondRelease, .unavailable)
  }

  // MARK: - isSuppressed / isSupported

  func testIsSuppressed_reflectsLibraryState() {
    let fake = FakePassLibrary()
    fake.isSuppressingAutomaticPassPresentation = true
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var suppressed: Bool?
    plugin.isSuppressed { suppressed = try? $0.get() }
    XCTAssertEqual(suppressed, true)
  }

  func testIsSupported_reflectsPassLibraryAvailability() {
    let fake = FakePassLibrary()
    fake.isPassLibraryAvailable = true
    let plugin = NfcWalletSuppressionPlugin(library: fake)

    var supported: Bool?
    plugin.isSupported { supported = try? $0.get() }
    XCTAssertEqual(supported, true)
  }
}
