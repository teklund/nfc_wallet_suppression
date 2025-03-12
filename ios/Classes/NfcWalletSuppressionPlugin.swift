import Flutter
import UIKit
import PassKit

public class NfcWalletSuppressionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nfc_wallet_suppression", binaryMessenger: registrar.messenger())
    let instance = NfcWalletSuppressionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let passLibrary = PKPassLibrary()
  private var suppressionToken: PKSuppressionRequestToken?

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestSuppression":
      requestSuppression(result: result)
    case "releaseSuppression":
      releaseSuppression(result: result)
    case "isSuppressed":
      isSuppressed(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestSuppression(result: @escaping FlutterResult) {
    //https://developer.apple.com/documentation/passkit/pkpasslibrary/requestautomaticpasspresentationsuppression(responsehandler:)
    self.suppressionToken = PKPassLibrary.requestAutomaticPassPresentationSuppression(responseHandler: { requestResult in
      //https://developer.apple.com/documentation/passkit/pkautomaticpasspresentationsuppressionresult
      switch requestResult {
        case .success:
          print("Pass presentation suppressed successfully.")
            result("Suppressed")
        case .notSupported:
            result(FlutterError(code: "NOT_SUPPORTED",
                message: "The device doesn’t support the suppression of automatic pass presentation.",
                details: nil))
        case .alreadyPresenting:
            result(FlutterError(code: "ALREADY_PRESENTING",
                message: "The device is already presenting passes.",
                details: nil))
        case .cancelled:
            result(FlutterError(code: "CANCELLED",
                message: "Suppression cancelled",
                details: nil))
        case .denied:
            result(FlutterError(code: "DENIED",
                message: "The user prevented the suppression, or an internal error occurred.",
                details: nil))
        @unknown default:
          result(FlutterError(code: "UNKNOWN",
                message: "Unknown suppression result.",
                details: nil))
        }
    })
  }

  //https://developer.apple.com/documentation/passkit/pkpasslibrary/endautomaticpasspresentationsuppression(withrequesttoken:)
  private func releaseSuppression(result: @escaping FlutterResult) {
    guard let token = suppressionToken else {
      result(FlutterError(code: "UNAVAILABLE",
                          message: "NFC not available",
                          details: nil))
      return
    }
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: token)
    print("Automatic Pass Presentation enabled")
    suppressionToken = nil
    result("Not suppressed anymore")
  }

  private func isSuppressed(result: @escaping FlutterResult) {
    let suppressed = PKPassLibrary.isSuppressingAutomaticPassPresentation()
    result(suppressed)
  }
}
