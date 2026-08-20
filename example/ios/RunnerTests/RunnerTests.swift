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
///
/// Handlers are retained per request number rather than as a single slot, so a
/// test can deliver a *late* handler for request 1 after request 2 has already
/// started — the case that proves a stale response cannot resolve the wrong
/// caller.
final class FakePassLibrary: PassPresentationSuppressing {
  typealias Handler = (PKAutomaticPassPresentationSuppressionResult) -> Void

  var isPassLibraryAvailable = false
  var isSuppressingAutomaticPassPresentation = false

  /// Token returned by `requestSuppression` when `tokensToReturn` is exhausted.
  ///
  /// `0` models PassKit refusing to submit the request. Note that a `0` token
  /// does *not* imply the handler is skipped — Apple documents that PassKit
  /// still calls it — so tests must deliver a result explicitly.
  var tokenToReturn: PKSuppressionRequestToken = 1

  /// Tokens handed out in order, one per request. Needed when a later request
  /// starts *inside* an earlier request's completion, leaving a test no moment
  /// in which to mutate `tokenToReturn`.
  var tokensToReturn: [PKSuppressionRequestToken] = []

  private(set) var requestCount = 0
  private(set) var endedTokens: [PKSuppressionRequestToken] = []
  private var handlers: [Int: Handler] = [:]

  func requestSuppression(responseHandler: @escaping Handler) -> PKSuppressionRequestToken {
    requestCount += 1
    handlers[requestCount] = responseHandler
    if tokensToReturn.isEmpty { return tokenToReturn }
    return tokensToReturn.removeFirst()
  }

  func endSuppression(withRequestToken token: PKSuppressionRequestToken) {
    endedTokens.append(token)
  }

  /// Simulate PassKit answering the most recent undelivered request.
  func deliver(_ result: PKAutomaticPassPresentationSuppressionResult) {
    guard let number = handlers.keys.max() else { return }
    deliver(result, forRequest: number)
  }

  /// Simulate PassKit answering a specific request, identified by its 1-based
  /// order of submission. Used for late and out-of-order deliveries.
  func deliver(_ result: PKAutomaticPassPresentationSuppressionResult, forRequest number: Int) {
    guard let handler = handlers.removeValue(forKey: number) else { return }
    handler(result)
  }
}

/// Deterministic stand-in for the request deadline.
///
/// Lets a test fire the timeout immediately instead of waiting five real
/// seconds, and lets it assert that a deadline was armed and then cancelled.
final class FakeScheduler: DeadlineScheduling {
  private final class Item: DeadlineCancelling {
    var isCancelled = false
    let work: () -> Void
    init(_ work: @escaping () -> Void) { self.work = work }
    func cancel() { isCancelled = true }
  }

  private var items: [Item] = []
  private(set) var scheduledDelays: [TimeInterval] = []

  var pendingCount: Int { items.filter { !$0.isCancelled }.count }

  func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> DeadlineCancelling {
    scheduledDelays.append(seconds)
    let item = Item(work)
    items.append(item)
    return item
  }

  /// Fires the oldest deadline that has not been cancelled.
  func fire() {
    guard let index = items.firstIndex(where: { !$0.isCancelled }) else { return }
    items.remove(at: index).work()
  }
}

class RunnerTests: XCTestCase {

  /// Builds a plugin wired to controllable doubles.
  ///
  /// Every test goes through this: constructing the plugin without a
  /// `FakeScheduler` compiles fine and silently arms a real five-second timer on
  /// the main queue, which would leave timer garbage behind in CI.
  private func makeSUT(
    token: PKSuppressionRequestToken = 1,
    requestTimeout: TimeInterval = NfcWalletSuppressionPlugin.defaultRequestTimeout
  ) -> (NfcWalletSuppressionPlugin, FakePassLibrary, FakeScheduler) {
    let fake = FakePassLibrary()
    fake.tokenToReturn = token
    let clock = FakeScheduler()
    let plugin = NfcWalletSuppressionPlugin(
      library: fake, scheduler: clock, requestTimeout: requestTimeout)
    return (plugin, fake, clock)
  }

  private func status(_ result: Result<SuppressionResult, Error>?) -> SuppressionStatusCode? {
    guard let result = result else { return nil }
    return (try? result.get())?.status
  }

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
    let (plugin, fake, _) = makeSUT(token: 42)

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    fake.deliver(.success)

    XCTAssertEqual(status, .suppressed)
    XCTAssertEqual(fake.requestCount, 1)
    XCTAssertTrue(fake.endedTokens.isEmpty, "A successful request must not release its token")
  }

  func testRequest_failure_releasesTokenAndReportsStatus() {
    let (plugin, fake, _) = makeSUT(token: 7)

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    fake.deliver(.denied)

    XCTAssertEqual(status, .denied)
    XCTAssertEqual(fake.endedTokens, [7], "A failed request must release the issued token")

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .unavailable, "No token should linger after a failed request")
  }

  func testRequest_zeroToken_waitsForHandlerAndReportsItsReason() {
    // Apple: "this method fails immediately and returns a token value of 0.
    // However, PassKit still calls the response handler." So we wait for it —
    // the handler carries the real reason, which beats a synthesised one.
    let (plugin, fake, _) = makeSUT(token: 0)

    var callCount = 0
    var status: SuppressionStatusCode?
    plugin.requestSuppression {
      callCount += 1
      status = (try? $0.get())?.status
    }

    XCTAssertEqual(callCount, 0, "Must not synthesise an answer while the handler is still coming")

    fake.deliver(.notSupported)

    XCTAssertEqual(callCount, 1)
    XCTAssertEqual(status, .notSupported, "The caller learns the real reason, not a generic error")
    XCTAssertTrue(fake.endedTokens.isEmpty, "Must never end a 0 token")
  }

  func testRequest_zeroToken_handlerNeverFires_timesOutWithoutEndingZeroToken() {
    let (plugin, fake, clock) = makeSUT(token: 0)

    var callCount = 0
    var status: SuppressionStatusCode?
    plugin.requestSuppression {
      callCount += 1
      status = (try? $0.get())?.status
    }
    clock.fire()

    XCTAssertEqual(callCount, 1, "The deadline must answer a caller PassKit abandoned")
    XCTAssertEqual(status, .unknown)
    XCTAssertTrue(fake.endedTokens.isEmpty, "Must never end a 0 token")

    // No phantom token was retained, so a following release has nothing to end.
    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .unavailable)
  }

  func testRequest_timeoutMessage_statesTheTimeoutWithoutTruncatingIt() {
    // The timeout is injectable, so the message must survive a fractional value.
    // Formatting it as an `Int` would report a 0.5 s timeout as "0s".
    let (halfSecond, _, halfClock) = makeSUT(requestTimeout: 0.5)
    var message: String?
    halfSecond.requestSuppression { message = (try? $0.get())?.message }
    halfClock.fire()
    XCTAssertEqual(
      message, "PassKit did not answer the suppression request within 0.5s.")

    // A whole number of seconds still reads "5s", not "5.0s".
    let (whole, _, wholeClock) = makeSUT(requestTimeout: 5)
    whole.requestSuppression { message = (try? $0.get())?.message }
    wholeClock.fire()
    XCTAssertEqual(
      message, "PassKit did not answer the suppression request within 5s.")
  }

  func testRequest_zeroToken_anomalousSuccess_reportsUnknownAndClaimsNothing() {
    let (plugin, fake, _) = makeSUT(token: 0)

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }
    fake.deliver(.success)  // refused to submit, yet reported success

    XCTAssertEqual(status, .unknown, "We hold nothing we could ever end, so we claim nothing")
    XCTAssertTrue(fake.endedTokens.isEmpty)

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .unavailable)
  }

  func testRequest_coalescedRequestAndDeferredReleaseResolveTogether() {
    let (plugin, fake, _) = makeSUT(token: 21)

    var first: SuppressionStatusCode?
    var second: SuppressionStatusCode?
    var release: SuppressionStatusCode?
    plugin.requestSuppression { first = (try? $0.get())?.status }
    plugin.requestSuppression { second = (try? $0.get())?.status }  // coalesces
    plugin.releaseSuppression { release = (try? $0.get())?.status }  // queued behind

    XCTAssertEqual(fake.requestCount, 1)
    XCTAssertTrue(fake.endedTokens.isEmpty)

    fake.deliver(.success)

    XCTAssertEqual(first, .suppressed)
    XCTAssertEqual(second, .suppressed)
    XCTAssertEqual(release, .notSuppressed, "The queued release runs after the coalesced requests")
    XCTAssertEqual(fake.endedTokens, [21])
  }

  func testRequest_concurrentCallsCoalesceOntoOneRequest() {
    let (plugin, fake, _) = makeSUT(token: 11)

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
    let (plugin, fake, _) = makeSUT(token: 3)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)
    fake.isSuppressingAutomaticPassPresentation = true  // OS confirms still suppressing

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }

    XCTAssertEqual(status, .suppressed)
    XCTAssertEqual(fake.requestCount, 1, "Must not re-request while genuinely active")
  }

  func testRequest_whenActiveButOsEndedExternally_releasesStaleTokenAndReRequests() {
    let (plugin, fake, _) = makeSUT(token: 8)

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
    let (plugin, fake, _) = makeSUT(token: 8)

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

  // MARK: - Ordering

  /// The reported bug: `request → release → request` used to answer the second
  /// request `.suppressed` and then immediately release, so the caller held a
  /// status that was already false, and the process ended unsuppressed despite
  /// the last intent being to suppress.
  func testInterleave_requestReleaseRequest_endsSuppressedAndAnswersEachCallerTruthfully() {
    let (plugin, fake, _) = makeSUT()
    fake.tokensToReturn = [42, 43]

    var first: SuppressionStatusCode?
    var release: SuppressionStatusCode?
    var second: SuppressionStatusCode?
    plugin.requestSuppression { first = (try? $0.get())?.status }
    plugin.releaseSuppression { release = (try? $0.get())?.status }
    plugin.requestSuppression { second = (try? $0.get())?.status }

    fake.deliver(.success)  // resolves request 1, then drains release, then starts request 2
    XCTAssertEqual(first, .suppressed)
    XCTAssertEqual(release, .notSuppressed)
    XCTAssertNil(second, "The second request must wait for its own PassKit answer")
    XCTAssertEqual(fake.endedTokens, [42])
    XCTAssertEqual(fake.requestCount, 2, "The second request must not coalesce past the release")

    fake.deliver(.success)  // resolves request 2
    XCTAssertEqual(second, .suppressed)

    // The end state matches the last intent, and the second token is the live one.
    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .notSuppressed)
    XCTAssertEqual(fake.endedTokens, [42, 43], "Suppression was genuinely held by token 43")
  }

  func testRequest_afterQueuedRelease_doesNotCoalesceOntoTheInFlightRequest() {
    let (plugin, fake, _) = makeSUT()
    fake.tokensToReturn = [1, 2]

    plugin.requestSuppression { _ in }
    plugin.releaseSuppression { _ in }
    plugin.requestSuppression { _ in }

    XCTAssertEqual(fake.requestCount, 1, "Nothing starts while the first request is in flight")
    fake.deliver(.success)
    XCTAssertEqual(fake.requestCount, 2, "A request behind a release needs its own PassKit request")
  }

  func testRequest_coalescingStillAppliesToTheQueuedTailRequest() {
    let (plugin, fake, _) = makeSUT()
    fake.tokensToReturn = [1, 2]

    var second: SuppressionStatusCode?
    var third: SuppressionStatusCode?
    plugin.requestSuppression { _ in }
    plugin.releaseSuppression { _ in }
    plugin.requestSuppression { second = (try? $0.get())?.status }
    plugin.requestSuppression { third = (try? $0.get())?.status }  // joins the queued tail

    fake.deliver(.success)
    fake.deliver(.success)

    XCTAssertEqual(fake.requestCount, 2, "The tail request absorbs the fourth call")
    XCTAssertEqual(second, .suppressed)
    XCTAssertEqual(third, .suppressed)
  }

  func testQueue_runsOperationsInFifoOrder() {
    let (plugin, fake, _) = makeSUT()
    fake.tokensToReturn = [1, 2]

    var statuses: [SuppressionStatusCode?] = []
    plugin.requestSuppression { statuses.append((try? $0.get())?.status) }
    plugin.releaseSuppression { statuses.append((try? $0.get())?.status) }
    plugin.requestSuppression { statuses.append((try? $0.get())?.status) }
    plugin.releaseSuppression { statuses.append((try? $0.get())?.status) }

    fake.deliver(.success)
    fake.deliver(.success)

    XCTAssertEqual(statuses, [.suppressed, .notSuppressed, .suppressed, .notSuppressed])
    XCTAssertEqual(fake.endedTokens, [1, 2])
  }

  func testCompletionReentrancy_callingReleaseFromARequestCompletionDoesNotStallTheQueue() {
    let (plugin, fake, _) = makeSUT(token: 30)

    var releaseStatus: SuppressionStatusCode?
    plugin.requestSuppression { _ in
      plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    }
    fake.deliver(.success)

    XCTAssertEqual(releaseStatus, .notSuppressed, "A release enqueued from a completion must still run")
    XCTAssertEqual(fake.endedTokens, [30])
  }

  // MARK: - Request deadline

  func testRequest_deadlineArmedOnStartAndCancelledOnResponse() {
    let (plugin, fake, clock) = makeSUT(token: 4)

    var callCount = 0
    plugin.requestSuppression { _ in callCount += 1 }
    XCTAssertEqual(clock.scheduledDelays, [NfcWalletSuppressionPlugin.defaultRequestTimeout])

    fake.deliver(.success)
    XCTAssertEqual(callCount, 1)
    XCTAssertEqual(clock.pendingCount, 0, "An answered request must not leave a deadline armed")

    clock.fire()  // no-op: nothing live
    XCTAssertEqual(callCount, 1, "A cancelled deadline must never answer")
  }

  func testRequest_timeout_answersCallerAsUnknownAndDoesNotWedgeThePlugin() {
    let (plugin, fake, clock) = makeSUT()
    fake.tokensToReturn = [42, 43]

    var first: SuppressionStatusCode?
    plugin.requestSuppression { first = (try? $0.get())?.status }
    clock.fire()

    XCTAssertEqual(first, .unknown)

    // The plugin is still usable: a later request is served rather than
    // coalescing onto the abandoned one forever.
    fake.isSuppressingAutomaticPassPresentation = false
    var second: SuppressionStatusCode?
    plugin.requestSuppression { second = (try? $0.get())?.status }
    fake.deliver(.success)
    XCTAssertEqual(second, .suppressed)
  }

  func testRequest_timeout_retainsTokenSoALaterReleaseEndsIt() {
    let (plugin, _, clock) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    clock.fire()

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }

    XCTAssertEqual(releaseStatus, .notSuppressed)
  }

  func testRequest_timeout_releaseEndsTheRetainedToken() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    clock.fire()
    plugin.releaseSuppression { _ in }

    XCTAssertEqual(fake.endedTokens, [42], "The token must never be discarded on timeout")
  }

  func testRequest_lateSuccessAfterTimeout_promotesTokenAndDoesNotAnswerTwice() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    var callCount = 0
    plugin.requestSuppression { _ in callCount += 1 }
    clock.fire()
    XCTAssertEqual(callCount, 1)

    fake.deliver(.success, forRequest: 1)  // PassKit answers late
    XCTAssertEqual(callCount, 1, "A late handler must not answer an already-answered caller")

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .notSuppressed)
    XCTAssertEqual(fake.endedTokens, [42], "The late-granted suppression is still releasable")
  }

  func testRequest_lateFailureAfterTimeout_endsRetainedToken() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    clock.fire()
    fake.deliver(.denied, forRequest: 1)

    XCTAssertEqual(fake.endedTokens, [42])

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .unavailable, "Nothing is held once the late failure is reconciled")
  }

  func testRequest_lateSuccessAfterTimeoutAndRelease_endsTokenDefensivelyASecondTime() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    clock.fire()
    plugin.releaseSuppression { _ in }
    XCTAssertEqual(fake.endedTokens, [42])

    // PassKit grants the suppression after we gave up AND after the caller
    // released. Ending an already-ended token is a documented no-op, and it is
    // the only way to turn off suppression that arrived this late.
    fake.deliver(.success, forRequest: 1)
    XCTAssertEqual(fake.endedTokens, [42, 42])
  }

  func testRequest_afterTimeout_whenOsConfirmsSuppression_promotesWithoutANewPassKitRequest() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    clock.fire()
    fake.isSuppressingAutomaticPassPresentation = true  // it was granted after all

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }

    XCTAssertEqual(status, .suppressed)
    XCTAssertEqual(fake.requestCount, 1, "Adopt the live token rather than requesting again")
    XCTAssertTrue(fake.endedTokens.isEmpty)
  }

  func testRequest_afterTimeoutAndPromotion_lateHandlerDoesNotEndTheHeldToken() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    clock.fire()
    fake.isSuppressingAutomaticPassPresentation = true
    plugin.requestSuppression { _ in }  // promotes token 42 to held

    fake.deliver(.success, forRequest: 1)  // the original handler finally arrives
    XCTAssertTrue(fake.endedTokens.isEmpty, "A late handler must not end a token we now hold")

    var releaseStatus: SuppressionStatusCode?
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }
    XCTAssertEqual(releaseStatus, .notSuppressed)
    XCTAssertEqual(fake.endedTokens, [42])
  }

  func testRequest_afterTimeout_whenOsDeniesSuppression_endsRetainedTokenAndReRequests() {
    let (plugin, fake, clock) = makeSUT()
    fake.tokensToReturn = [42, 43]

    plugin.requestSuppression { _ in }
    clock.fire()
    fake.isSuppressingAutomaticPassPresentation = false

    var status: SuppressionStatusCode?
    plugin.requestSuppression { status = (try? $0.get())?.status }

    XCTAssertEqual(fake.requestCount, 2)
    XCTAssertTrue(fake.endedTokens.contains(42), "The unconfirmed token is released before re-requesting")

    fake.deliver(.success)
    XCTAssertEqual(status, .suppressed)
  }

  func testRequest_coalescedGroupSharesTheTimeoutResult() {
    let (plugin, _, clock) = makeSUT(token: 42)

    var firstCount = 0
    var secondCount = 0
    var first: SuppressionStatusCode?
    var second: SuppressionStatusCode?
    plugin.requestSuppression {
      firstCount += 1
      first = (try? $0.get())?.status
    }
    plugin.requestSuppression {
      secondCount += 1
      second = (try? $0.get())?.status
    }
    clock.fire()

    XCTAssertEqual(first, .unknown)
    XCTAssertEqual(second, .unknown)
    XCTAssertEqual(firstCount, 1)
    XCTAssertEqual(secondCount, 1, "Every coalesced caller is answered exactly once")
  }

  func testRequest_lateHandlerFromASupersededRequestCannotResolveTheCurrentOne() {
    let (plugin, fake, clock) = makeSUT()
    fake.tokensToReturn = [42, 43]

    plugin.requestSuppression { _ in }
    clock.fire()  // request 1 abandoned

    var second: SuppressionStatusCode?
    plugin.requestSuppression { second = (try? $0.get())?.status }
    XCTAssertEqual(fake.requestCount, 2)

    fake.deliver(.denied, forRequest: 1)  // request 1's stale handler arrives
    XCTAssertNil(second, "A stale handler must not resolve a different request")

    fake.deliver(.success, forRequest: 2)
    XCTAssertEqual(second, .suppressed)
  }

  func testRequest_timeout_withAQueuedRelease_releasesTheRetainedTokenWhenTheQueueDrains() {
    let (plugin, fake, clock) = makeSUT(token: 42)

    var request: SuppressionStatusCode?
    var release: SuppressionStatusCode?
    plugin.requestSuppression { request = (try? $0.get())?.status }
    plugin.releaseSuppression { release = (try? $0.get())?.status }

    XCTAssertNil(release, "The release waits behind the in-flight request")

    clock.fire()

    XCTAssertEqual(request, .unknown)
    XCTAssertEqual(
      release, .notSuppressed,
      "The timeout's drain must run the queued release against the retained token")
    XCTAssertEqual(fake.endedTokens, [42])
  }

  func testRequest_multipleOrphans_lateHandlerReconcilesItsOwnTokenByRequestId() {
    let (plugin, fake, clock) = makeSUT()
    fake.tokensToReturn = [101, 102, 103]

    plugin.requestSuppression { _ in }
    clock.fire()  // orphan (request 1, token 101)
    plugin.requestSuppression { _ in }  // stale path ends 101, starts request 2
    clock.fire()  // orphan (request 2, token 102)

    XCTAssertEqual(fake.endedTokens, [101])

    // Two orphans are now live. Request 1's handler must reconcile *its* token
    // and leave request 2's alone — `reconcileLate` looks the entry up by id.
    fake.deliver(.denied, forRequest: 1)
    XCTAssertEqual(fake.endedTokens, [101, 101], "The late handler ends its own token")

    fake.deliver(.denied, forRequest: 2)
    XCTAssertEqual(fake.endedTokens, [101, 101, 102])
  }

  func testRequest_lateHandlerForAReusedTokenValue_doesNotEndLiveSuppression() {
    let (plugin, fake, clock) = makeSUT()
    // PassKit hands out the same numeric value twice. Apple documents the token
    // as identifying a request but never promises the value is unique for the
    // lifetime of the process, so the plugin must not assume it is.
    fake.tokensToReturn = [42, 42]

    plugin.requestSuppression { _ in }
    clock.fire()  // orphan (request 1, token 42)
    fake.isSuppressingAutomaticPassPresentation = false

    var second: SuppressionStatusCode?
    plugin.requestSuppression { second = (try? $0.get())?.status }
    XCTAssertEqual(fake.requestCount, 2)
    XCTAssertEqual(fake.endedTokens, [42], "The unconfirmed token is ended before re-requesting")

    fake.deliver(.success, forRequest: 2)
    XCTAssertEqual(second, .suppressed)  // token 42 is now genuinely held

    fake.deliver(.success, forRequest: 1)  // request 1's handler finally arrives
    XCTAssertEqual(
      fake.endedTokens, [42],
      "A late handler must not end a token whose value matches the one we now hold")
  }

  func testRequest_orphanEviction_endsTheEvictedTokenRatherThanStrandingIt() {
    let (plugin, fake, clock) = makeSUT()
    let tokens: [PKSuppressionRequestToken] = Array(101...109)
    fake.tokensToReturn = tokens

    // Eight requests PassKit never answers fills the orphan list to its cap.
    // Each new request first ends the previous unconfirmed token via the
    // stale-token path, so most of these tokens are already in `endedTokens`.
    for _ in 0..<8 {
      plugin.requestSuppression { _ in }
      clock.fire()
    }
    let endedBeforeOverflow = fake.endedTokens.count

    // The ninth timeout pushes the list past the cap and evicts orphan 101.
    plugin.requestSuppression { _ in }
    clock.fire()

    let newlyEnded = fake.endedTokens.dropFirst(endedBeforeOverflow)
    XCTAssertTrue(
      newlyEnded.contains(101),
      "An evicted orphan must be ended as it is dropped — once its record is gone, "
        + "no later handler can ever end it")
  }

  // MARK: - Completion re-entrancy

  func testCompletionReentrancy_requestFromAShortCircuitedCompletionIsNotDropped() {
    let (plugin, fake, _) = makeSUT(token: 42)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)
    fake.isSuppressingAutomaticPassPresentation = true

    // This request short-circuits to `.alreadySuppressed`, so its completion runs
    // *inside* the drain loop. That is the only path where the re-entrancy guard
    // actually drops a nested drain, leaving the outer loop responsible for the
    // work enqueued here.
    var release: SuppressionStatusCode?
    plugin.requestSuppression { _ in
      plugin.releaseSuppression { release = (try? $0.get())?.status }
    }

    XCTAssertEqual(
      release, .notSuppressed, "Work enqueued from inside the drain loop must still run")
    XCTAssertEqual(fake.endedTokens, [42])
  }

  func testCompletionReentrancy_requestFromATimeoutCompletionStartsAFreshRequest() {
    let (plugin, fake, clock) = makeSUT()
    fake.tokensToReturn = [42, 43]

    var second: SuppressionStatusCode?
    plugin.requestSuppression { _ in
      // A caller retrying on timeout. The retained token is visible at this
      // point, so the retry must reconcile it rather than stack a second
      // suppression on top of it.
      plugin.requestSuppression { second = (try? $0.get())?.status }
    }
    clock.fire()

    XCTAssertEqual(fake.requestCount, 2)
    XCTAssertEqual(fake.endedTokens, [42], "The unconfirmed token is ended before re-requesting")

    fake.deliver(.success, forRequest: 2)
    XCTAssertEqual(second, .suppressed)
  }

  // MARK: - releaseSuppression

  func testRelease_fromIdle_returnsUnavailable() {
    let (plugin, _, _) = makeSUT()

    var result: SuppressionResult?
    plugin.releaseSuppression { result = try? $0.get() }

    XCTAssertEqual(result?.status, .unavailable)
    XCTAssertEqual(result?.message, "No active suppression to release")
  }

  func testRelease_fromActive_endsTokenAndReportsNotSuppressed() {
    let (plugin, fake, _) = makeSUT(token: 5)

    plugin.requestSuppression { _ in }
    fake.deliver(.success)

    var status: SuppressionStatusCode?
    plugin.releaseSuppression { status = (try? $0.get())?.status }

    XCTAssertEqual(fake.endedTokens, [5])
    XCTAssertEqual(status, .notSuppressed)
  }

  func testRelease_duringInFlightRequest_isDeferredUntilSuccessThenReleases() {
    let (plugin, fake, _) = makeSUT(token: 5)

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
    let (plugin, fake, _) = makeSUT(token: 6)

    var releaseStatus: SuppressionStatusCode?
    plugin.requestSuppression { _ in }
    plugin.releaseSuppression { releaseStatus = (try? $0.get())?.status }  // deferred

    fake.deliver(.denied)
    XCTAssertEqual(releaseStatus, .unavailable, "Nothing to release after a failed request")
    XCTAssertEqual(fake.endedTokens, [6], "The failed request's token is still released")
  }

  func testSecondRelease_duringInFlightRequest_runsAfterTheFirstAndReportsUnavailable() {
    let (plugin, fake, _) = makeSUT(token: 12)

    var firstRelease: SuppressionStatusCode?
    var secondRelease: SuppressionStatusCode?
    plugin.requestSuppression { _ in }
    plugin.releaseSuppression { firstRelease = (try? $0.get())?.status }
    plugin.releaseSuppression { secondRelease = (try? $0.get())?.status }

    XCTAssertNil(firstRelease, "Both releases wait behind the in-flight request")
    XCTAssertNil(secondRelease)
    XCTAssertTrue(fake.endedTokens.isEmpty)

    fake.deliver(.success)

    XCTAssertEqual(firstRelease, .notSuppressed, "The first release ends the suppression")
    XCTAssertEqual(secondRelease, .unavailable, "The second finds nothing left to release")
    XCTAssertEqual(fake.endedTokens, [12])
  }

  // MARK: - isSuppressed / isSupported

  func testIsSuppressed_reflectsLibraryState() {
    let (plugin, fake, _) = makeSUT()
    fake.isSuppressingAutomaticPassPresentation = true

    var suppressed: Bool?
    plugin.isSuppressed { suppressed = try? $0.get() }
    XCTAssertEqual(suppressed, true)
  }

  func testIsSupported_reflectsPassLibraryAvailability() {
    let (plugin, fake, _) = makeSUT()
    fake.isPassLibraryAvailable = true

    var supported: Bool?
    plugin.isSupported { supported = try? $0.get() }
    XCTAssertEqual(supported, true)
  }
}
