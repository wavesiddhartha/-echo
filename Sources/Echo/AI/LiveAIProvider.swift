import Foundation

public struct LiveChatProvider: ChatAIProvider, Sendable {
    public let apiKeyProvider: @Sendable () -> String?
    
    public init(apiKeyProvider: @escaping @Sendable () -> String? = {
        KeychainManager.shared.read(account: "openai_api_key") ?? Constants.Defaults.defaultOpenAIKey
    }) {
        self.apiKeyProvider = apiKeyProvider
    }
    
    public func generateResponse(messages: [Message], context: String?) async throws -> String {
        let key = apiKeyProvider() ?? Constants.Defaults.defaultOpenAIKey
        guard !key.isEmpty else {
            return try await MockChatAIProvider().generateResponse(messages: messages, context: context)
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": PromptManager.systemInstruction]
        ]
        
        for msg in messages {
            apiMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }
        
        if let visualContext = context, !visualContext.isEmpty {
            apiMessages.append([
                "role": "system",
                "content": "[Visual Screen Context]: \(visualContext)"
            ])
        }
        
        let model = UserDefaults.standard.string(forKey: "echo.openai.model") ?? "gpt-4o"
        
        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "max_tokens": 800,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return try await MockChatAIProvider().generateResponse(messages: messages, context: context)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "I processed your request."
    }
}

public struct LiveVisionProvider: VisionAIProvider, Sendable {
    public let apiKeyProvider: @Sendable () -> String?
    
    public init(apiKeyProvider: @escaping @Sendable () -> String? = {
        KeychainManager.shared.read(account: "openai_api_key") ?? Constants.Defaults.defaultOpenAIKey
    }) {
        self.apiKeyProvider = apiKeyProvider
    }
    
    public func analyzeScreenshot(imagePath: String, prompt: String, history: [Message]) async throws -> VisionAnalysis {
        let key = apiKeyProvider() ?? Constants.Defaults.defaultOpenAIKey
        guard !key.isEmpty, let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
            return try await MockVisionAIProvider().analyzeScreenshot(imagePath: imagePath, prompt: prompt, history: history)
        }
        
        let base64Image = imageData.base64EncodedString()
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let promptText = "Analyze this screen screenshot with deep precision for the user request: '\(prompt)'. What application is visible, what code, video, or documents are present, what errors or buttons exist, and what is the recommended next action or answer? Respond with clear markdown."
        let model = UserDefaults.standard.string(forKey: "echo.openai.model") ?? "gpt-4o"
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": PromptManager.systemInstruction],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": promptText],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 600
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return try await MockVisionAIProvider().analyzeScreenshot(imagePath: imagePath, prompt: prompt, history: history)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return VisionAnalysis(
                screenshotId: UUID(),
                summary: content,
                detectedApplication: "Active Screen",
                detectedWebpage: nil,
                visibleUIElements: [],
                detectedErrors: [],
                suggestedNextSteps: ["Review assistant recommendations"]
            )
        }
        
        return try await MockVisionAIProvider().analyzeScreenshot(imagePath: imagePath, prompt: prompt, history: history)
    }
}

public final class LiveAIProvider: AIProvider, @unchecked Sendable {
    public let name: String = "LiveAIProvider (GPT-4o)"
    public let speechToText: SpeechToTextProvider = MockSpeechToTextProvider()
    public let vision: VisionAIProvider = LiveVisionProvider()
    public let chat: ChatAIProvider = LiveChatProvider()
    public let actionPlanner: ActionPlanningProvider = ActionPlanner()
    
    public init() {
        EchoLogger.ai.debug("LiveAIProvider initialized with default GPT-4o pipeline")
    }
}
