import Foundation

public enum MessageRole: String, Codable, Sendable, Hashable {
    case user
    case assistant
    case system
}

public struct Message: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public var associatedScreenshotId: UUID?
    public var sources: [String]
    public var screenshotThumbnail: String?
    
    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        associatedScreenshotId: UUID? = nil,
        sources: [String] = [],
        screenshotThumbnail: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.associatedScreenshotId = associatedScreenshotId
        self.sources = sources
        self.screenshotThumbnail = screenshotThumbnail
    }
}
