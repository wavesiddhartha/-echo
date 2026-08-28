import Foundation

public enum ActionType: String, Codable, Sendable, Hashable {
    case openURL
    case openApplication
    case copyText
    case runScript
    case custom
}

public enum ActionStatus: String, Codable, Sendable, Hashable {
    case suggested
    case pendingConfirmation
    case executing
    case completed
    case cancelled
    case failed
}

public struct UserAction: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let title: String
    public let type: ActionType
    public let payload: String
    public var status: ActionStatus
    public let requiresConfirmation: Bool
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        title: String,
        type: ActionType,
        payload: String,
        status: ActionStatus = .suggested,
        requiresConfirmation: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.title = title
        self.type = type
        self.payload = payload
        self.status = status
        self.requiresConfirmation = requiresConfirmation
        self.timestamp = timestamp
    }
}
