import Foundation

public protocol SpeechToTextProvider: Sendable {
    func transcribe(audioData: Data) async throws -> String
}

public protocol VisionAIProvider: Sendable {
    func analyzeScreenshot(imagePath: String, prompt: String, history: [Message]) async throws -> VisionAnalysis
}

public protocol ChatAIProvider: Sendable {
    func generateResponse(messages: [Message], context: String?) async throws -> String
}

public protocol ActionPlanningProvider: Sendable {
    func planActions(userIntent: String, currentContext: String) async throws -> [UserAction]
}

public protocol AIProvider: Sendable {
    var name: String { get }
    var speechToText: SpeechToTextProvider { get }
    var vision: VisionAIProvider { get }
    var chat: ChatAIProvider { get }
    var actionPlanner: ActionPlanningProvider { get }
}
