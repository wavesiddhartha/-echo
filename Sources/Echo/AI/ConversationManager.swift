import Foundation
import Observation

@Observable
public final class ConversationManager: @unchecked Sendable {
    public private(set) var activeSession: Session
    private let aiProvider: AIProvider
    private let repository: SessionRepositoryProtocol
    
    public init(
        aiProvider: AIProvider = MockAIProvider(),
        repository: SessionRepositoryProtocol = InMemorySessionRepository()
    ) {
        self.aiProvider = aiProvider
        self.repository = repository
        self.activeSession = Session()
        EchoLogger.ai.debug("ConversationManager initialized")
    }
    
    public func startNewSession(title: String = "New Interaction") {
        activeSession = Session(title: title)
        EchoLogger.ai.info("Started new conversation session: \(self.activeSession.id.uuidString, privacy: .public)")
    }
    
    public func addUserMessage(_ content: String, screenshotId: UUID? = nil) -> Message {
        let message = Message(
            sessionId: activeSession.id,
            role: .user,
            content: content,
            associatedScreenshotId: screenshotId
        )
        activeSession.messages.append(message)
        activeSession.updatedAt = Date()
        
        // Auto-generate a meaningful title from the first prompt
        if activeSession.title == "New Interaction" || activeSession.title.isEmpty {
            activeSession.title = generateSmartTitle(from: content)
        }
        
        return message
    }
    
    public func addAssistantMessage(_ content: String) -> Message {
        let message = Message(
            sessionId: activeSession.id,
            role: .assistant,
            content: content
        )
        activeSession.messages.append(message)
        activeSession.updatedAt = Date()
        return message
    }
    
    public func processUserPrompt(_ prompt: String, visionAnalysis: VisionAnalysis? = nil) async throws -> String {
        _ = addUserMessage(prompt, screenshotId: visionAnalysis?.screenshotId)
        
        var contextInfo: String? = nil
        if let vision = visionAnalysis {
            contextInfo = "Visual Context: \(vision.summary). Active App: \(vision.detectedApplication ?? "Unknown")."
            if let app = vision.detectedApplication, activeSession.title.hasPrefix("Interaction") {
                activeSession.title = "\(app) Analysis: \(prompt.prefix(25))"
            }
        }
        
        let response = try await aiProvider.chat.generateResponse(
            messages: activeSession.messages,
            context: contextInfo
        )
        
        _ = addAssistantMessage(response)
        
        // Save session state to local storage
        try? await repository.saveSession(activeSession)
        
        // Automatically sync to Supabase Cloud in real-time
        Task {
            try? await SupabaseManager.shared.syncSessionToCloud(activeSession)
        }
        
        return response
    }
    
    public func polishDictation(rawText: String) async -> String {
        let polishPrompt = [
            Message(
                sessionId: activeSession.id,
                role: .system,
                content: "You are an expert editor. Clean up this raw speech dictation into a polished, crisp, well-punctuated message or post without changing the original meaning. If spoken in Hindi/Hinglish, translate or refine cleanly into fluent English. Do not add conversational filler."
            ),
            Message(
                sessionId: activeSession.id,
                role: .user,
                content: rawText
            )
        ]
        
        if let polished = try? await aiProvider.chat.generateResponse(messages: polishPrompt, context: nil), !polished.isEmpty {
            return polished.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Local formatting fallback
        var formatted = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !formatted.isEmpty {
            formatted = formatted.prefix(1).uppercased() + formatted.dropFirst()
            if !formatted.hasSuffix(".") && !formatted.hasSuffix("!") && !formatted.hasSuffix("?") {
                formatted += "."
            }
        }
        return formatted
    }
    
    private func generateSmartTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Voice Interaction" }
        
        let lower = trimmed.lowercased()
        if lower.contains("screen") || lower.contains("written") || lower.contains("looking") {
            return "Screen: " + trimmed.prefix(32)
        } else if lower.contains("note") || lower.contains("save") || lower.contains("remember") {
            return "Note: " + trimmed.prefix(32)
        } else if lower.contains("meeting") || lower.contains("calendar") || lower.contains("reminder") {
            return "Schedule: " + trimmed.prefix(32)
        } else if lower.contains("youtube") || lower.contains("video") {
            return "YouTube Search: " + trimmed.prefix(28)
        }
        
        if trimmed.count > 36 {
            return String(trimmed.prefix(36)) + "…"
        }
        return trimmed
    }
}
