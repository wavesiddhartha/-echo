import Foundation

public enum VoiceState: Equatable, Sendable {
    case inactive
    case requested
    case listening
    case processing
    case error(String)
}

public protocol VoiceManagerProtocol: AnyObject, Sendable {
    var state: VoiceState { get }
    func startListening() async throws
    func stopListening() async -> String
    func cancelListening() async
}
