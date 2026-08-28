import Foundation

public struct Screenshot: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let localPath: String
    public let timestamp: Date
    public let screenIdentifier: String
    public var analysis: VisionAnalysis?
    
    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        localPath: String,
        timestamp: Date = Date(),
        screenIdentifier: String = "main",
        analysis: VisionAnalysis? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.localPath = localPath
        self.timestamp = timestamp
        self.screenIdentifier = screenIdentifier
        self.analysis = analysis
    }
}
