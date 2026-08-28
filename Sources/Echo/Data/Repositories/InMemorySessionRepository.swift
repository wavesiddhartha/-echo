import Foundation

public actor InMemorySessionRepository: SessionRepositoryProtocol {
    private var storage: [UUID: Session] = [:]
    
    public init() {}
    
    public func fetchSessions() async throws -> [Session] {
        return storage.values.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    public func fetchSession(byId id: UUID) async throws -> Session? {
        return storage[id]
    }
    
    public func saveSession(_ session: Session) async throws {
        storage[session.id] = session
        EchoLogger.storage.info("Saved session \(session.id.uuidString, privacy: .public)")
    }
    
    public func deleteSession(byId id: UUID) async throws {
        storage.removeValue(forKey: id)
        EchoLogger.storage.info("Deleted session \(id.uuidString, privacy: .public)")
    }
    
    public func deleteAllSessions() async throws {
        storage.removeAll()
        EchoLogger.storage.info("Cleared all sessions")
    }
}
