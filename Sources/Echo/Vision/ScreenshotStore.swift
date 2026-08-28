import Foundation
import AppKit

public final class ScreenshotStore: @unchecked Sendable {
    public static let shared = ScreenshotStore()
    
    private let fileManager = FileManager.default
    private let storageDirectory: URL
    
    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.storageDirectory = appSupport.appendingPathComponent("Echo/Screenshots", isDirectory: true)
        
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    public func saveScreenshot(image: CGImage, sessionId: UUID) throws -> Screenshot {
        let screenshotId = UUID()
        let filename = "\(screenshotId.uuidString).png"
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "EchoScreenshotStore", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG screenshot."])
        }
        
        try pngData.write(to: fileURL)
        EchoLogger.vision.info("Saved local screenshot to: \(fileURL.path, privacy: .public)")
        
        return Screenshot(
            id: screenshotId,
            sessionId: sessionId,
            localPath: fileURL.path,
            timestamp: Date(),
            screenIdentifier: "main-display"
        )
    }
    
    public func deleteScreenshot(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? fileManager.removeItem(at: url)
        EchoLogger.vision.info("Deleted screenshot at: \(path, privacy: .public)")
    }
    
    public func clearAllScreenshots() {
        try? fileManager.removeItem(at: storageDirectory)
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        EchoLogger.vision.info("Cleared all local screenshots")
    }
}
