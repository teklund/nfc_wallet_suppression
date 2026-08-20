import Flutter
import UIKit
import PassKit

/// Abstraction over the PassKit automatic-pass-presentation suppression APIs.
///
/// PassKit exposes these as static functions on `PKPassLibrary`, which makes the
/// suppression logic impossible to unit test. Routing every call through this
/// protocol lets the plugin be driven by a fake in tests while using the real
/// system implementation in production.
///
/// Implementations MUST invoke the response handler on the main thread, and
/// asynchronously (after `requestSuppression` has returned) — see
/// `SystemPassLibrary`. The plugin relies on both: state is touched only on the
/// main thread, and the token returned by `requestSuppression` is recorded
/// before the handler runs.
protocol PassPresentationSuppressing {
  var isPassLibraryAvailable: Bool { get }
  var isSuppressingAutomaticPassPresentation: Bool { get }

  /// Requests suppression. Returns the request token, or `0` when PassKit
  /// refused to submit the request (e.g. the device does not support
  /// suppression).
  ///
  /// A `0` token does *not* mean the handler is skipped. Apple documents that
  /// "this method fails immediately and returns a token value of 0. However,
  /// PassKit still calls the response handler." The token and the handler are
  /// therefore independent facts and must be handled independently.
  func requestSuppression(
    responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void
  ) -> PKSuppressionRequestToken

  func endSuppression(withRequestToken token: PKSuppressionRequestToken)
}

/// Production implementation backed by `PKPassLibrary`.
struct SystemPassLibrary: PassPresentationSuppressing {
  var isPassLibraryAvailable: Bool { PKPassLibrary.isPassLibraryAvailable() }

  var isSuppressingAutomaticPassPresentation: Bool {
    PKPassLibrary.isSuppressingAutomaticPassPresentation()
  }

  func requestSuppression(
    responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void
  ) -> PKSuppressionRequestToken {
    // PassKit calls the response handler "on an arbitrary queue" (Apple's
    // wording). Hop back to the main thread so the plugin's state stays
    // single-threaded and the pigeon reply is delivered on the platform thread.
    // https://developer.apple.com/documentation/passkit/pkpasslibrary/requestautomaticpasspresentationsuppression(responsehandler:)
    PKPassLibrary.requestAutomaticPassPresentationSuppression { result in
      DispatchQueue.main.async { responseHandler(result) }
    }
  }

  func endSuppression(withRequestToken token: PKSuppressionRequestToken) {
    // "If you pass in an invalid request token, the system ignores the end
    // request." Ending a stale, already-ended or unknown token is therefore a
    // documented no-op, which is what lets this plugin release defensively
    // rather than guarding.
    // https://developer.apple.com/documentation/passkit/pkpasslibrary/endautomaticpasspresentationsuppression(withrequesttoken:)
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: token)
  }
}

/// Schedules main-thread work after a delay.
///
/// Injected so tests can drive the request deadline deterministically instead of
/// sleeping for real.
protocol DeadlineScheduling {
  func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> DeadlineCancelling
}

/// A handle to work scheduled by a `DeadlineScheduling`.
protocol DeadlineCancelling {
  func cancel()
}

/// Production scheduler backed by the main dispatch queue.
struct MainQueueScheduler: DeadlineScheduling {
  func schedule(after seconds: TimeInterval, _ work: @escaping () -> Void) -> DeadlineCancelling {
    let item = DispatchWorkItem(block: work)
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    return WorkItemCancellable(item: item)
  }

  private struct WorkItemCancellable: DeadlineCancelling {
    let item: DispatchWorkItem
    func cancel() { item.cancel() }
  }
}

public class NfcWalletSuppressionPlugin: NSObject, FlutterPlugin, NfcWalletSuppressionApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let api = NfcWalletSuppressionPlugin()
    NfcWalletSuppressionApiSetup.setUp(binaryMessenger: messenger, api: api)
  }

  typealias Completion = (Result<SuppressionResult, Error>) -> Void

  /// Default deadline for a PassKit suppression request.
  ///
  /// Apple DTS puts the request → callback gap at 50–300 ms and explicitly calls
  /// it non-deterministic, so 5 s is roughly 16× that ceiling and should never
  /// fire in steady state.
  ///
  /// This deadline is DEFENSIVE, not evidence-driven: there are no reported
  /// cases of PassKit failing to invoke the handler. It exists because Apple
  /// documents no delivery guarantee (the only promise is that the handler is
  /// still called on the unsupported-device path), and because the effect of the
  /// first-run "Apple Pay is unavailable" alert on callback timing is unknown.
  /// Without it, a handler that never arrives wedges the plugin for the lifetime
  /// of the process: every later request coalesces onto the dead one and every
  /// release parks behind it forever.
  static let defaultRequestTimeout: TimeInterval = 5.0

  /// Upper bound on retained timed-out tokens. In practice this is always empty;
  /// it only grows if PassKit stops answering entirely.
  private static let maxOrphanedTokens = 8

  // MARK: State
  //
  // Ordering was previously encoded as *roles* on a single enum
  // (`inFlight(waiters:release:token:)`), which cannot express "these operations
  // happened in this order" and produced two distinct ordering bugs. It is now
  // split into three independent concerns:
  //
  //   - `tokenState` — what we own. No notion of order.
  //   - `queue`      — the order operations were submitted in. Order lives here,
  //                    and only here.
  //   - `inFlight`   — bookkeeping for the single outstanding PassKit request.
  //
  // All access is confined to the main thread: pigeon dispatches the API methods
  // there, and `SystemPassLibrary` delivers the PassKit callback there too, so no
  // locking is required.

  /// The suppression token the plugin owns, if any.
  private enum TokenState: Equatable {
    /// Nothing held.
    case none
    /// PassKit answered `.success` for this token.
    case held(PKSuppressionRequestToken)
    /// The token was issued but PassKit did not answer before the deadline.
    ///
    /// Retained, never discarded: PassKit may still grant it, and ending an
    /// invalid token is a documented no-op, so holding costs nothing while
    /// dropping it could strand suppression that we could then never turn off.
    case unconfirmed(token: PKSuppressionRequestToken, requestID: UInt64)

    var token: PKSuppressionRequestToken? {
      switch self {
      case .none: return nil
      case .held(let token): return token
      case .unconfirmed(let token, _): return token
      }
    }
  }

  /// A set of `requestSuppression` callers sharing one PassKit request.
  ///
  /// A reference type so callers can join a group that is already queued or
  /// already running.
  private final class RequestGroup {
    private var completions: [Completion]
    private(set) var isDelivered = false

    init(_ completion: @escaping Completion) { completions = [completion] }

    func join(_ completion: @escaping Completion) {
      assert(!isDelivered, "cannot join a group that has already answered")
      completions.append(completion)
    }

    /// Answers every caller in the group, exactly once.
    ///
    /// Deliver-once matters because the deadline path and a late handler can
    /// both reach the same group; only the first may answer.
    func deliver(_ result: SuppressionResult) {
      guard !isDelivered else { return }
      isDelivered = true
      let pending = completions
      completions = []
      pending.forEach { $0(.success(result)) }
    }
  }

  private enum QueuedOperation {
    case request(RequestGroup)
    case release(Completion)
  }

  /// The single outstanding PassKit request, if any.
  private final class InFlight {
    let id: UInt64
    let group: RequestGroup
    /// `nil` when PassKit returned a `0` token — there is then nothing to end.
    var token: PKSuppressionRequestToken?
    var deadline: DeadlineCancelling?

    init(id: UInt64, group: RequestGroup) {
      self.id = id
      self.group = group
    }
  }

  private var tokenState: TokenState = .none
  private var queue: [QueuedOperation] = []
  private var inFlight: InFlight?
  private var isDraining = false
  private var nextRequestID: UInt64 = 1

  /// Tokens from requests that hit the deadline, oldest first.
  ///
  /// Kept so that a handler arriving after we gave up can still end the token —
  /// including when the caller has already released in the meantime, which is the
  /// only way to turn off suppression PassKit granted after the deadline.
  private var orphanedTokens: [(id: UInt64, token: PKSuppressionRequestToken)] = []

  private let library: PassPresentationSuppressing
  private let scheduler: DeadlineScheduling
  private let requestTimeout: TimeInterval

  init(
    library: PassPresentationSuppressing = SystemPassLibrary(),
    scheduler: DeadlineScheduling = MainQueueScheduler(),
    requestTimeout: TimeInterval = NfcWalletSuppressionPlugin.defaultRequestTimeout
  ) {
    self.library = library
    self.scheduler = scheduler
    self.requestTimeout = requestTimeout
    super.init()
  }

  private enum Message {
    static let suppressed = "Automatic pass presentation is suppressed."
    static let alreadySuppressed = "Automatic pass presentation is already suppressed."
    static let notSupported = "Device does not support automatic pass presentation suppression."
    static let alreadyPresenting = "Wallet is already presenting a pass."
    static let cancelled = "Suppression request was cancelled."
    static let denied = "Suppression request was denied by the user or system."
    static let unknown = "Unknown error occurred during suppression request."
    static let couldNotSubmit = "Suppression request could not be submitted."
    static let released = "Suppression released"
    static let noActiveToRelease = "No active suppression to release"

    static func timedOut(after seconds: TimeInterval) -> String {
      // `%g` drops the trailing zeros on a whole number of seconds ("5s") without
      // truncating a sub-second timeout to "0s", which `Int(seconds)` would. The
      // timeout is injectable, so fractional values reach here in tests.
      "PassKit did not answer the suppression request within "
        + String(format: "%g", seconds) + "s."
    }
  }

  /// Maps a PassKit suppression result to the cross-platform pigeon result.
  ///
  /// Pure and side-effect free so the mapping can be unit tested directly.
  /// https://developer.apple.com/documentation/passkit/pkautomaticpasspresentationsuppressionresult
  static func suppressionResult(
    for result: PKAutomaticPassPresentationSuppressionResult
  ) -> SuppressionResult {
    switch result {
    case .success:
      return SuppressionResult(status: .suppressed, message: Message.suppressed)
    case .notSupported:
      return SuppressionResult(status: .notSupported, message: Message.notSupported)
    case .alreadyPresenting:
      return SuppressionResult(status: .alreadyPresenting, message: Message.alreadyPresenting)
    case .cancelled:
      return SuppressionResult(status: .cancelled, message: Message.cancelled)
    case .denied:
      return SuppressionResult(status: .denied, message: Message.denied)
    @unknown default:
      return SuppressionResult(status: .unknown, message: Message.unknown)
    }
  }

  // MARK: - API

  func requestSuppression(completion: @escaping Completion) {
    assertMainThread()
    // Coalesce only onto the TAIL of the pipeline. Joining anything earlier would
    // let a release submitted before this request overtake it, so the caller
    // would be told `.suppressed` by a request that a later-running release then
    // undoes — an answer that is already false by the time it is delivered.
    if let group = coalescingTarget() {
      group.join(completion)
      return
    }
    queue.append(.request(RequestGroup(completion)))
    drain()
  }

  func releaseSuppression(completion: @escaping Completion) {
    assertMainThread()
    queue.append(.release(completion))
    drain()
  }

  func isSuppressed(completion: @escaping (Result<Bool, Error>) -> Void) {
    completion(.success(library.isSuppressingAutomaticPassPresentation))
  }

  /// Reports whether the Wallet pass library is available, which is a *necessary*
  /// condition for suppression (e.g. it is false on iPad). It is not a guarantee
  /// that a suppression request will succeed — PassKit exposes no API to query
  /// suppression capability or the required entitlement up front. The definitive
  /// answer comes from `requestSuppression`'s result (`.notSupported` / `.denied`).
  func isSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
    completion(.success(library.isPassLibraryAvailable))
  }

  // MARK: - Scheduling

  /// The request group a new caller may join: the last queued request if the
  /// queue ends with one, otherwise the running request if nothing is queued
  /// behind it. Returns `nil` whenever a release sits between the caller and the
  /// running request.
  private func coalescingTarget() -> RequestGroup? {
    if case .request(let group)? = queue.last { return group }
    if queue.isEmpty, let inFlight = inFlight { return inFlight.group }
    return nil
  }

  /// Runs queued operations in FIFO order until the queue empties or a PassKit
  /// request goes in flight. Releases resolve synchronously, so one drain can
  /// execute several operations.
  private func drain() {
    // Completions run inside this loop and may re-enter the plugin. A nested
    // drain can safely be dropped: the `while` re-reads `queue` and `inFlight`
    // every iteration, so anything enqueued from a completion is picked up
    // before the outer loop exits.
    guard !isDraining else { return }
    isDraining = true
    defer { isDraining = false }

    while inFlight == nil, !queue.isEmpty {
      switch queue.removeFirst() {
      case .release(let completion):
        performRelease(completion)
      case .request(let group):
        startOrShortCircuit(group)
      }
    }
  }

  private func startOrShortCircuit(_ group: RequestGroup) {
    if let token = tokenState.token {
      // Reconcile intent against the OS before reporting success. This also
      // covers a token retained past its deadline: if PassKit granted it late,
      // the OS says so and we adopt it rather than issuing a second request.
      if library.isSuppressingAutomaticPassPresentation {
        promoteToHeld(token)
        group.deliver(SuppressionResult(status: .suppressed, message: Message.alreadySuppressed))
        return
      }
      // Stale: suppression was ended outside the plugin, or was never granted.
      library.endSuppression(withRequestToken: token)
      tokenState = .none
    }
    startRequest(group)
  }

  /// Adopts a token as confirmed-held.
  ///
  /// Clearing the orphan entry is load-bearing: without it a late handler for the
  /// same request would later take the "not ours any more" branch of
  /// `reconcileLate` and end a token we are actively holding.
  private func promoteToHeld(_ token: PKSuppressionRequestToken) {
    if case .unconfirmed(_, let requestID) = tokenState {
      orphanedTokens.removeAll { $0.id == requestID }
    }
    tokenState = .held(token)
  }

  /// Issues a new PassKit request. Precondition: nothing held, nothing in flight.
  private func startRequest(_ group: RequestGroup) {
    assert(tokenState == .none && inFlight == nil)
    let id = nextRequestID
    nextRequestID += 1

    let flight = InFlight(id: id, group: group)
    inFlight = flight

    // Armed before the PassKit call so there is no window in which a flight
    // exists without a deadline to bound it.
    flight.deadline = scheduler.schedule(after: requestTimeout) { [weak self] in
      self?.handleDeadline(id: id)
    }

    let token = library.requestSuppression { [weak self] passResult in
      // Main thread, asynchronous, per the protocol contract.
      self?.handleResponse(id: id, passResult: passResult)
    }

    // `flight.token` is recorded only *after* `requestSuppression` returns, so a
    // handler invoked synchronously would settle this flight while its token is
    // still unrecorded: the caller would be told `.unknown` for a request that
    // actually succeeded, and the granted token would be referenced by nothing,
    // stranding suppression on for the lifetime of the process.
    // `PassPresentationSuppressing` requires asynchronous delivery precisely for
    // this reason, and `SystemPassLibrary` guarantees it with a main-queue hop.
    // Assert it so a refactor that drops that hop fails loudly in tests rather
    // than silently in the field.
    assert(inFlight === flight, "response handler must not be invoked synchronously")

    // A `0` token means PassKit refused to submit, so there is nothing we could
    // ever end. We still wait for the handler: Apple documents that PassKit calls
    // it anyway, and it carries the real reason (typically `.notSupported`),
    // which beats a synthesised one. The deadline bounds that wait.
    flight.token = (token == 0) ? nil : token
  }

  // MARK: - Settling

  private func handleResponse(
    id: UInt64,
    passResult: PKAutomaticPassPresentationSuppressionResult
  ) {
    assertMainThread()
    guard let flight = inFlight, flight.id == id else {
      // Late: the deadline already answered this caller, or this handler belongs
      // to a superseded request. Never answer twice — but do reconcile the token
      // we deliberately kept. Keying on `id` is what stops a stale handler from
      // resolving whichever request happens to be running now.
      reconcileLate(id: id, passResult: passResult)
      return
    }
    flight.deadline?.cancel()
    inFlight = nil

    let result: SuppressionResult
    switch (passResult, flight.token) {
    case (.success, .some(let token)):
      tokenState = .held(token)
      result = Self.suppressionResult(for: .success)
    case (.success, .none):
      // Anomalous: PassKit refused to submit (`0` token) and then reported
      // success. We hold nothing we could ever end, so we do not claim
      // suppression.
      result = SuppressionResult(status: .unknown, message: Message.couldNotSubmit)
    case (let passResult, let token):
      if let token = token { library.endSuppression(withRequestToken: token) }
      result = Self.suppressionResult(for: passResult)
    }

    // State is settled before completions fire, so a re-entrant caller sees the
    // post-operation world.
    flight.group.deliver(result)
    drain()
  }

  private func handleDeadline(id: UInt64) {
    assertMainThread()
    guard let flight = inFlight, flight.id == id else { return }
    flight.deadline = nil
    inFlight = nil

    if let token = flight.token {
      tokenState = .unconfirmed(token: token, requestID: id)
      orphanedTokens.append((id: id, token: token))
      if orphanedTokens.count > Self.maxOrphanedTokens {
        // Dropping the record alone would strand the token: `reconcileLate` finds
        // nothing for that id, so nothing could ever end it. End it as we evict.
        // Free if PassKit never granted it — invalid tokens are a documented
        // no-op — and the only way to turn it off if it did.
        library.endSuppression(withRequestToken: orphanedTokens.removeFirst().token)
      }
    }
    flight.group.deliver(
      SuppressionResult(status: .unknown, message: Message.timedOut(after: requestTimeout)))
    drain()
  }

  /// Handles a response whose request was already answered.
  ///
  /// The caller is never notified twice, but the token still has to be
  /// reconciled so suppression cannot be stranded in the on state.
  private func reconcileLate(
    id: UInt64,
    passResult: PKAutomaticPassPresentationSuppressionResult
  ) {
    guard let index = orphanedTokens.firstIndex(where: { $0.id == id }) else { return }
    let token = orphanedTokens.remove(at: index).token

    var isStillOurs = false
    if case .unconfirmed(_, let requestID) = tokenState, requestID == id { isStillOurs = true }

    if isStillOurs {
      if passResult == .success {
        // It really did turn on, late. Adopt it so a later release can end it.
        tokenState = .held(token)
      } else {
        // PassKit refused after we had already given up. End the token we were
        // holding on spec and go idle.
        library.endSuppression(withRequestToken: token)
        tokenState = .none
      }
      return
    }

    // The caller released this token in the meantime, or a later request
    // superseded it. End it defensively: the API ignores invalid and
    // already-ended tokens, so a second end costs nothing, and it is the only
    // way to turn off suppression that PassKit granted after we gave up on it.
    //
    // The one token we must NOT end here is the one we currently hold. Apple
    // documents the token as identifying a request but never promises the
    // numeric value is unique for the lifetime of the process, so a reissued
    // value would otherwise let this late reconcile switch off *live*
    // suppression while `tokenState` still claims to hold it.
    guard tokenState.token != token else { return }
    library.endSuppression(withRequestToken: token)
  }

  private func performRelease(_ completion: @escaping Completion) {
    // Intent-based release (matches Android): if we hold a token we end it and
    // report `.notSuppressed`; otherwise `.unavailable`. We deliberately do not
    // reconcile against `isSuppressingAutomaticPassPresentation` here so the
    // request/release pair stays clean and both platforms behave identically;
    // `isSuppressed` reports live state.
    switch tokenState {
    case .none:
      completion(
        .success(SuppressionResult(status: .unavailable, message: Message.noActiveToRelease)))
    case .held(let token), .unconfirmed(let token, _):
      library.endSuppression(withRequestToken: token)
      tokenState = .none
      completion(.success(SuppressionResult(status: .notSuppressed, message: Message.released)))
    }
  }

  private func assertMainThread() {
    assert(Thread.isMainThread, "plugin state must only be touched on the main thread")
  }
}
