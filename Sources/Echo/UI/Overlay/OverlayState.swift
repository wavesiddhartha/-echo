import Foundation

public enum OverlayState: Equatable, Sendable, Hashable {
    case idle
    case activating
    case listening(transcript: String)
    case processing
    case visionAnalysis(step: String)
    case responding(content: String)
    case postMode(transcript: String, isPolished: Bool)
    case actionSuggestions(actions: [UserAction])
    case error(message: String)
    
    public var statusDescription: String {
        switch self {
        case .idle:
            return "Echo Ready"
        case .activating:
            return "Waking up…"
        case .listening(let transcript):
            return transcript.isEmpty ? "Listening…" : transcript
        case .processing:
            return "Synthesizing…"
        case .visionAnalysis(let step):
            return step.isEmpty ? "Reading Screen…" : step
        case .responding:
            return "Echo Response"
        case .postMode(let transcript, let isPolished):
            if transcript.isEmpty {
                return "Dictating…"
            }
            return isPolished ? "Polished Post Ready" : "Post Transcription"
        case .actionSuggestions:
            return "Suggested Actions"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
