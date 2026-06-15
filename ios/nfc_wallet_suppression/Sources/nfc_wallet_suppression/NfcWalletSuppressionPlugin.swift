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
/// Implementations MUST invoke the request response handler on the main thread,
/// and asynchronously (after `requestSuppression` has returned) — see
/// `SystemPassLibrary`. The plugin relies on both: state is touched only on the
/// main thread, and the token returned by `requestSuppression` is recorded
/// before the handler runs.
protocol PassPresentationSuppressing {
  var isPassLibraryAvailable: Bool { get }
  var isSuppressingAutomaticPassPresentation: Bool { get }

  /// Requests suppression. Returns the request token, or `0` when the request
  /// could not be submitted (in which case the response handler is not called).
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
    // PassKit does not annotate this API for concurrency and may invoke the
    // response handler on an arbitrary (background) thread. Hop back to the
    // main thread so the plugin's state stays single-threaded and the pigeon
    // reply is delivered on the platform thread.
    // https://developer.apple.com/documentation/passkit/pkpasslibrary/requestautomaticpasspresentationsuppression(responsehandler:)
    PKPassLibrary.requestAutomaticPassPresentationSuppression { result in
      DispatchQueue.main.async { responseHandler(result) }
    }
  }

  func endSuppression(withRequestToken token: PKSuppressionRequestToken) {
    // https://developer.apple.com/documentation/passkit/pkpasslibrary/endautomaticpasspresentationsuppression(withrequesttoken:)
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: token)
  }
}

public class NfcWalletSuppressionPlugin: NSObject, FlutterPlugin, NfcWalletSuppressionApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let api = NfcWalletSuppressionPlugin()
    NfcWalletSuppressionApiSetup.setUp(binaryMessenger: messenger, api: api)
  }

  typealias Completion = (Result<SuppressionResult, Error>) -> Void

  private let library: PassPresentationSuppressing

  // MARK: Lifecycle state
  //
  // Modelled as an enum so illegal combinations are unrepresentable. All access
  // is confined to the main thread: pigeon dispatches the API methods there, and
  // `SystemPassLibrary` delivers the PassKit callback there too, so no locking is
  // required.
  private enum State {
    /// No suppression and no request in flight.
    case idle
    /// A PassKit request is in flight. `waiters` are coalesced request
    /// completions; `release` is a release awaiting the result; `token` is the
    /// issued token (`nil` until known, or if the request could not be submitted).
    case inFlight(waiters: [Completion], release: Completion?, token: PKSuppressionRequestToken?)
    /// Suppression is active, holding `token`.
    case active(PKSuppressionRequestToken)
  }
  private var state: State = .idle

  init(library: PassPresentationSuppressing = SystemPassLibrary()) {
    self.library = library
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

  func requestSuppression(completion: @escaping Completion) {
    switch state {
    case .active(let token):
      // Confirm the OS still agrees before reporting success.
      if library.isSuppressingAutomaticPassPresentation {
        completion(.success(SuppressionResult(status: .suppressed, message: Message.alreadySuppressed)))
      } else {
        // Stale token: suppression was ended outside the plugin. Drop it and
        // issue a fresh request.
        library.endSuppression(withRequestToken: token)
        state = .idle
        startRequest(completion)
      }
    case .inFlight(let waiters, let release, let token):
      // Coalesce onto the in-flight request rather than issuing a second one.
      state = .inFlight(waiters: waiters + [completion], release: release, token: token)
    case .idle:
      startRequest(completion)
    }
  }

  /// Issues a new PassKit request. Precondition: `state == .idle`.
  private func startRequest(_ completion: @escaping Completion) {
    state = .inFlight(waiters: [completion], release: nil, token: nil)
    let token = library.requestSuppression { [weak self] passResult in
      // Delivered on the main thread by `SystemPassLibrary`, after this method
      // has returned and the token has been recorded below.
      self?.resolveInFlight(passResult)
    }
    // Record the issued token in the in-flight state for the handler to use.
    if case .inFlight(let waiters, let release, _) = state {
      state = .inFlight(waiters: waiters, release: release, token: token == 0 ? nil : token)
    }
    if token == 0 {
      // The request could not be submitted; the handler will not fire.
      resolveInFlight(nil)
    }
  }

  /// Resolves the in-flight request. `passResult == nil` means the request could
  /// not be submitted (a `0` token).
  private func resolveInFlight(_ passResult: PKAutomaticPassPresentationSuppressionResult?) {
    guard case .inFlight(let waiters, let release, let token) = state else { return }

    let result: SuppressionResult
    if let passResult = passResult, let token = token {
      result = NfcWalletSuppressionPlugin.suppressionResult(for: passResult)
      if passResult == .success {
        state = .active(token)
      } else {
        // Failed: release the issued token so it cannot leak.
        library.endSuppression(withRequestToken: token)
        state = .idle
      }
    } else {
      // No token: the request could not be submitted (or a token-less result,
      // which is anomalous). Either way nothing is held.
      if let token = token { library.endSuppression(withRequestToken: token) }
      result = SuppressionResult(status: .unknown, message: Message.couldNotSubmit)
      state = .idle
    }

    // State and the captured `release` are settled before firing completions, so
    // the order is correct regardless of what callers do on completion.
    waiters.forEach { $0(.success(result)) }
    if let release = release {
      performRelease(release)
    }
  }

  func releaseSuppression(completion: @escaping Completion) {
    switch state {
    case .inFlight(let waiters, let release, let token):
      if release != nil {
        // A release is already queued behind the in-flight request.
        completion(.success(SuppressionResult(status: .unavailable, message: Message.noActiveToRelease)))
      } else {
        state = .inFlight(waiters: waiters, release: completion, token: token)
      }
    case .active, .idle:
      performRelease(completion)
    }
  }

  private func performRelease(_ completion: @escaping Completion) {
    guard case .active(let token) = state else {
      completion(.success(SuppressionResult(status: .unavailable, message: Message.noActiveToRelease)))
      return
    }
    library.endSuppression(withRequestToken: token)
    state = .idle
    completion(.success(SuppressionResult(status: .notSuppressed, message: Message.released)))
  }

  func isSuppressed(completion: @escaping (Result<Bool, Error>) -> Void) {
    completion(.success(library.isSuppressingAutomaticPassPresentation))
  }

  func isSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
    completion(.success(library.isPassLibraryAvailable))
  }
}
