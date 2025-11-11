import Foundation
import PassKit

/// Protocol for abstracting PassKit operations.
/// Allows for dependency injection and easier unit testing.
protocol PassLibraryProtocol {
    /// Request automatic pass presentation suppression
    func requestSuppression(responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void) -> PKSuppressionRequestToken
    
    /// End automatic pass presentation suppression
    func endSuppression(withRequestToken token: PKSuppressionRequestToken)
    
    /// Check if device supports pass presentation suppression
    func isSupported() -> Bool
}

/// Production implementation wrapping the real PKPassLibrary
class RealPassLibrary: PassLibraryProtocol {
    private let passLibrary = PKPassLibrary()
    
    func requestSuppression(responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void) -> PKSuppressionRequestToken {
        return PKPassLibrary.requestAutomaticPassPresentationSuppression(responseHandler: responseHandler)
    }
    
    func endSuppression(withRequestToken token: PKSuppressionRequestToken) {
        PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: token)
    }
    
    func isSupported() -> Bool {
        // PassKit is available on iOS 6+, but suppression requires iOS 9+
        // For now, we'll return true since minimum deployment target handles this
        return true
    }
}

/// Fake implementation for testing.
/// Allows controlling PassKit behavior in unit tests.
class FakePassLibrary: PassLibraryProtocol {
    var supported: Bool = true
    var suppressionResult: PKAutomaticPassPresentationSuppressionResult = .success
    var requestCount: Int = 0
    var endCount: Int = 0
    var lastToken: PKSuppressionRequestToken?
    var methodCalls: [String] = []
    
    // Simulate delay for async response (default: immediate)
    var responseDelay: TimeInterval = 0
    
    func requestSuppression(responseHandler: @escaping (PKAutomaticPassPresentationSuppressionResult) -> Void) -> PKSuppressionRequestToken {
        methodCalls.append("requestSuppression")
        requestCount += 1
        
        // Create a fake token
        let token = PKSuppressionRequestToken()
        lastToken = token
        
        // Call response handler async (simulating real behavior)
        if responseDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + responseDelay) {
                responseHandler(self.suppressionResult)
            }
        } else {
            responseHandler(suppressionResult)
        }
        
        return token
    }
    
    func endSuppression(withRequestToken token: PKSuppressionRequestToken) {
        methodCalls.append("endSuppression")
        endCount += 1
    }
    
    func isSupported() -> Bool {
        methodCalls.append("isSupported")
        return supported
    }
    
    func reset() {
        supported = true
        suppressionResult = .success
        requestCount = 0
        endCount = 0
        lastToken = nil
        methodCalls.removeAll()
        responseDelay = 0
    }
}
