import Foundation

public struct VisionAnalysis: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let screenshotId: UUID
    public var summary: String
    public var detectedApplication: String?
    public var detectedWebpage: String?
    public var visibleUIElements: [String]
    public var detectedErrors: [String]
    public var suggestedNextSteps: [String]
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        screenshotId: UUID,
        summary: String,
        detectedApplication: String? = nil,
        detectedWebpage: String? = nil,
        visibleUIElements: [String] = [],
        detectedErrors: [String] = [],
        suggestedNextSteps: [String] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.screenshotId = screenshotId
        self.summary = summary
        self.detectedApplication = detectedApplication
        self.detectedWebpage = detectedWebpage
        self.visibleUIElements = visibleUIElements
        self.detectedErrors = detectedErrors
        self.suggestedNextSteps = suggestedNextSteps
        self.timestamp = timestamp
    }
}
