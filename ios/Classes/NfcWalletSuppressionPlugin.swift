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
//    if suppressionToken != nil {
//              print("Pass presentation is already suppressed.")
//              result(false)
//              return
//          }
    //https://developer.apple.com/documentation/passkit/pkpasslibrary/requestautomaticpasspresentationsuppression(responsehandler:)
    suppressionToken = PKPassLibrary.requestAutomaticPassPresentationSuppression(responseHandler: { result in
      //https://developer.apple.com/documentation/passkit/pkautomaticpasspresentationsuppressionresult
      switch result {
        case .success:
          print("Pass presentation suppressed successfully.")
//        case .alreadySuppressed:
//          print("Pass presentation was already suppressed.")
        case .denied:
          print("Pass presentation suppression denied.")
//        case .failed:
//          print("Pass presentation suppression failed.")
        @unknown default:
          print("Unknown suppression result.")
        }
    })
    print("Automatic Pass Presentation Suppressed")
//    guard let suppressionToken = token else {
//      result(false)
//      return
//    }
    result(true)
  }

  //https://developer.apple.com/documentation/passkit/pkpasslibrary/endautomaticpasspresentationsuppression(withrequesttoken:)
  private func releaseSuppression(result: @escaping FlutterResult) {
    guard let token = suppressionToken else {
      result(false)
      return
    }
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: token)
    print("Automatic Pass Presentation enabled")
    suppressionToken = nil
    result(true)
  }

  private func isSuppressed(result: @escaping FlutterResult) {
    let suppressed = PKPassLibrary.isSuppressingAutomaticPassPresentation()
    result(suppressed)
  }
}
