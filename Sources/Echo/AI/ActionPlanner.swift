import Foundation

public struct ActionPlanner: ActionPlanningProvider, Sendable {
    public init() {}
    
    public func planActions(userIntent: String, currentContext: String) async throws -> [UserAction] {
        let lowered = userIntent.lowercased()
        var suggested: [UserAction] = []
        
        if lowered.contains("youtube") {
            suggested.append(
                UserAction(
                    sessionId: UUID(),
                    title: "Open YouTube",
                    type: .openURL,
                    payload: "https://youtube.com",
                    requiresConfirmation: false
                )
            )
        } else if lowered.contains("github") {
            suggested.append(
                UserAction(
                    sessionId: UUID(),
                    title: "Open GitHub",
                    type: .openURL,
                    payload: "https://github.com",
                    requiresConfirmation: false
                )
            )
        } else if lowered.contains("copy") || lowered.contains("clipboard") {
            suggested.append(
                UserAction(
                    sessionId: UUID(),
                    title: "Copy Content",
                    type: .copyText,
                    payload: currentContext,
                    requiresConfirmation: false
                )
            )
        }
        
        return suggested
    }
}
