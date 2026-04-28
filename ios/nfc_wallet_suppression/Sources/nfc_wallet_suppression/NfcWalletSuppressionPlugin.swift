import Flutter
import UIKit
import PassKit

public class NfcWalletSuppressionPlugin: NSObject, FlutterPlugin, NfcWalletSuppressionApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let api = NfcWalletSuppressionPlugin()
    NfcWalletSuppressionApiSetup.setUp(binaryMessenger: messenger, api: api)
  }

  private var suppressionToken: PKSuppressionRequestToken?

  func requestSuppression(completion: @escaping (Result<SuppressionResult, Error>) -> Void) {
    // Release any existing token to prevent race conditions and memory leaks
    if let existingToken = suppressionToken {
      #if DEBUG
      NSLog("[NFC Wallet Suppression] Releasing existing token before new request")
      #endif
      PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: existingToken)
      suppressionToken = nil
    }
    
    //https://developer.apple.com/documentation/passkit/pkpasslibrary/requestautomaticpasspresentationsuppression(responsehandler:)
    self.suppressionToken = PKPassLibrary.requestAutomaticPassPresentationSuppression(
      responseHandler: { requestResult in
        let result: SuppressionResult
        //https://developer.apple.com/documentation/passkit/pkautomaticpasspresentationsuppressionresult
        switch requestResult {
        case .success:
          #if DEBUG
          NSLog("[NFC Wallet Suppression] Request success: Pass presentation suppressed")
          #endif
          result = SuppressionResult(
            status: .suppressed,
            message: "Automatic pass presentation is suppressed."
          )
        case .notSupported:
          #if DEBUG
          NSLog("[NFC Wallet Suppression] Request failed: Not supported")
          #endif
          result = SuppressionResult(
            status: .notSupported,
            message: "Device does not support automatic pass presentation suppression."
          )
        case .alreadyPresenting:
          #if DEBUG
          NSLog("[NFC Wallet Suppression] Request failed: Already presenting")
          #endif
          result = SuppressionResult(
            status: .alreadyPresenting,
            message: "Wallet is already presenting a pass."
          )
        case .cancelled:
          #if DEBUG
          NSLog("[NFC Wallet Suppression] Request cancelled")
          #endif
          result = SuppressionResult(
            status: .cancelled,
            message: "Suppression request was cancelled."
          )
        case .denied:
          #if DEBUG
          NSLog("[NFC Wallet Suppression] Request denied")
          #endif
          result = SuppressionResult(
            status: .denied,
            message: "Suppression request was denied by the user or system."
          )
        @unknown default:
          #if DEBUG
          NSLog("[NFC Wallet Suppression] Request failed: Unknown result")
          #endif
          result = SuppressionResult(
            status: .unknown,
            message: "Unknown error occurred during suppression request."
          )
        }
        completion(.success(result))
      }
    )
  }

  //https://developer.apple.com/documentation/passkit/pkpasslibrary/endautomaticpasspresentationsuppression(withrequesttoken:)
  func releaseSuppression(completion: @escaping (Result<SuppressionResult, Error>) -> Void) {
    guard let token = suppressionToken else {
      let result = SuppressionResult(
        status: .unavailable,
        message: "No active suppression to release"
      )
      completion(.success(result))
      return
    }
    
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: token)
    suppressionToken = nil
    
    #if DEBUG
    NSLog("[NFC Wallet Suppression] Automatic pass presentation enabled")
    #endif
    
    let result = SuppressionResult(
      status: .notSuppressed,
      message: "Suppression released"
    )
    completion(.success(result))
  }

  func isSuppressed(completion: @escaping (Result<Bool, Error>) -> Void) {
    let suppressed = PKPassLibrary.isSuppressingAutomaticPassPresentation()
    completion(.success(suppressed))
  }

  func isSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
    // Check iOS version (requires iOS 13.0+) and PassKit library availability
    if #available(iOS 13.0, *) {
      // isPassLibraryAvailable() checks if the device supports PassKit (e.g. has Secure Element)
      // This is a robust check for NFC/Apple Pay capability
      completion(.success(PKPassLibrary.isPassLibraryAvailable()))
    } else {
      completion(.success(false))
    }
  }
}
