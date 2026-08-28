import Foundation

public enum VisionState: Equatable, Sendable {
    case idle
    case capturingScreen
    case analyzing
    case completed(VisionAnalysis)
    case failed(String)
}

public protocol ScreenCaptureProtocol: Sendable {
    func captureMainScreen() async throws -> Screenshot
}

public protocol VisionManagerProtocol: AnyObject, Sendable {
    var state: VisionState { get }
    func captureAndAnalyze(request: String, sessionId: UUID) async throws -> VisionAnalysis
}
