import Foundation
import Observation
import AppKit

@Observable
public final class VisionManager: VisionManagerProtocol, @unchecked Sendable {
    public private(set) var state: VisionState = .idle
    public private(set) var lastCapturedScreenshot: Screenshot?
    private let screenCaptureManager: ScreenCaptureProtocol
    private let aiProvider: AIProvider
    
    public init(
        screenCaptureManager: ScreenCaptureProtocol = ScreenCaptureManager(),
        aiProvider: AIProvider = MockAIProvider()
    ) {
        self.screenCaptureManager = screenCaptureManager
        self.aiProvider = aiProvider
        EchoLogger.vision.debug("VisionManager initialized with AI vision pipeline")
    }
    
    public func captureAndAnalyze(request: String, sessionId: UUID) async throws -> VisionAnalysis {
        state = .capturingScreen
        EchoLogger.vision.info("Capturing screen for request: \(request, privacy: .public)")
        
        // Play Camera Shutter Sound and Haptic
        SoundFeedbackManager.shared.playCameraShutterSound()
        
        let screenshot: Screenshot
        do {
            screenshot = try await screenCaptureManager.captureMainScreen()
            self.lastCapturedScreenshot = screenshot
        } catch {
            state = .failed(error.localizedDescription)
            throw error
        }
        
        state = .analyzing
        EchoLogger.vision.info("Analyzing screenshot \(screenshot.id.uuidString, privacy: .public)")
        
        // Detect current frontmost macOS application name
        let activeAppName = await MainActor.run { () -> String in
            NSWorkspace.shared.frontmostApplication?.localizedName ?? "Active Application"
        }
        
        // Process through AI Vision Provider
        var analysis = try await aiProvider.vision.analyzeScreenshot(
            imagePath: screenshot.localPath,
            prompt: request,
            history: []
        )
        
        if analysis.detectedApplication == nil || analysis.detectedApplication == "Safari" {
            analysis.detectedApplication = activeAppName
        }
        
        state = .completed(analysis)
        EchoLogger.vision.info("Screen understanding completed for app: \(activeAppName, privacy: .public)")
        return analysis
    }
}
