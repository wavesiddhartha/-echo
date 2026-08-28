import Foundation

public struct MockSpeechToTextProvider: SpeechToTextProvider {
    public init() {}
    public func transcribe(audioData: Data) async throws -> String {
        return "What's happening on my screen?"
    }
}

public struct MockVisionAIProvider: VisionAIProvider {
    public init() {}
    public func analyzeScreenshot(imagePath: String, prompt: String, history: [Message]) async throws -> VisionAnalysis {
        return VisionAnalysis(
            screenshotId: UUID(),
            summary: "I can see your active browser window on Apple Developer documentation.",
            detectedApplication: "Safari",
            detectedWebpage: "https://developer.apple.com",
            visibleUIElements: ["Navigation bar", "Table of contents", "API Reference card"],
            detectedErrors: [],
            suggestedNextSteps: ["Review the documentation guide", "Execute quick sample"]
        )
    }
}

public struct MockChatAIProvider: ChatAIProvider {
    public init() {}
    public func generateResponse(messages: [Message], context: String?) async throws -> String {
        guard let lastMessage = messages.last?.content.lowercased() else {
            return "I am Echo, your macOS voice and vision overlay assistant."
        }
        
        if lastMessage.contains("screen") || lastMessage.contains("looking at") {
            return "I can see your active screen. You are currently viewing the workspace with development documents open."
        } else if lastMessage.contains("hello") || lastMessage.contains("hey") {
            return "Hey! What would you like help with on your Mac?"
        } else if lastMessage.contains("youtube") {
            return "I can open YouTube for you right away."
        } else {
            return "I understood: \"\(messages.last?.content ?? "")\". Ready for next steps."
        }
    }
}

public struct MockActionPlanningProvider: ActionPlanningProvider {
    public init() {}
    public func planActions(userIntent: String, currentContext: String) async throws -> [UserAction] {
        if userIntent.lowercased().contains("youtube") {
            return [
                UserAction(
                    sessionId: UUID(),
                    title: "Open YouTube",
                    type: .openURL,
                    payload: "https://youtube.com",
                    requiresConfirmation: false
                )
            ]
        }
        return []
    }
}

public final class MockAIProvider: AIProvider, @unchecked Sendable {
    public let name: String = "MockAIProvider"
    public let speechToText: SpeechToTextProvider = MockSpeechToTextProvider()
    public let vision: VisionAIProvider = MockVisionAIProvider()
    public let chat: ChatAIProvider = MockChatAIProvider()
    public let actionPlanner: ActionPlanningProvider = MockActionPlanningProvider()
    
    public init() {
        EchoLogger.ai.debug("MockAIProvider initialized")
    }
}
