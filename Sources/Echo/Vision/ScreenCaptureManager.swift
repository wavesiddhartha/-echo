import Foundation
import CoreGraphics
import AppKit

public final class ScreenCaptureManager: ScreenCaptureProtocol, @unchecked Sendable {
    private let screenshotStore: ScreenshotStore
    
    public init(screenshotStore: ScreenshotStore = ScreenshotStore.shared) {
        self.screenshotStore = screenshotStore
        EchoLogger.vision.debug("ScreenCaptureManager initialized with native CoreGraphics capture")
    }
    
    public func captureMainScreen() async throws -> Screenshot {
        EchoLogger.vision.info("Triggered on-demand single screen capture")
        
        let mainDisplayID = CGMainDisplayID()
        guard let image = CGDisplayCreateImage(mainDisplayID) else {
            throw NSError(
                domain: "EchoScreenCapture",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Screen Recording permission required to capture display."]
            )
        }
        
        return try screenshotStore.saveScreenshot(image: image, sessionId: UUID())
    }
}
