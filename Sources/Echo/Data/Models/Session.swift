import Foundation

public struct Session: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [Message]
    public var screenshots: [Screenshot]
    public var actions: [UserAction]
    
    public init(
        id: UUID = UUID(),
        title: String = "New Interaction",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [Message] = [],
        screenshots: [Screenshot] = [],
        actions: [UserAction] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.screenshots = screenshots
        self.actions = actions
    }
}
