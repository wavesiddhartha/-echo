import Foundation

public protocol SessionRepositoryProtocol: Sendable {
    func fetchSessions() async throws -> [Session]
    func fetchSession(byId id: UUID) async throws -> Session?
    func saveSession(_ session: Session) async throws
    func deleteSession(byId id: UUID) async throws
    func deleteAllSessions() async throws
}
