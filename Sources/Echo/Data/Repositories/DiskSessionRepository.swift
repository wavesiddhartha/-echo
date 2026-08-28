import Foundation

public actor DiskSessionRepository: SessionRepositoryProtocol {
    private let fileManager = FileManager.default
    private let storageDirectory: URL
    
    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.storageDirectory = appSupport.appendingPathComponent("Echo/Sessions", isDirectory: true)
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    public func fetchSessions() async throws -> [Session] {
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        var sessions: [Session] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for url in fileURLs where url.pathExtension == "json" {
            if let data = try? Data(contentsOf: url),
               let session = try? decoder.decode(Session.self, from: data) {
                sessions.append(session)
            }
        }
        
        return sessions.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    public func fetchSession(byId id: UUID) async throws -> Session? {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Session.self, from: data)
    }
    
    public func saveSession(_ session: Session) async throws {
        let fileURL = storageDirectory.appendingPathComponent("\(session.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(session)
        try data.write(to: fileURL)
        EchoLogger.storage.info("Persisted session \(session.id.uuidString, privacy: .public) to disk")
    }
    
    public func deleteSession(byId id: UUID) async throws {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: fileURL)
        EchoLogger.storage.info("Deleted session \(id.uuidString, privacy: .public) from disk")
    }
    
    public func deleteAllSessions() async throws {
        try? fileManager.removeItem(at: storageDirectory)
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        EchoLogger.storage.info("Cleared all sessions from disk")
    }
}
