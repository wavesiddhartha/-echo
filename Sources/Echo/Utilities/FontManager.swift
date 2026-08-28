import Foundation
import CoreText
import AppKit

public final class FontManager: Sendable {
    public static let shared = FontManager()
    
    public init() {}
    
    public func registerCustomFonts() {
        // Look for fonts in bundle or local resources directory
        let searchPaths = [
            Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/Fonts"),
            URL(fileURLWithPath: "/Users/bysiddhartha/Desktop/demo/Resources/Fonts")
        ].compactMap { $0 }
        
        for dir in searchPaths {
            guard let fontFiles = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
                continue
            }
            
            for file in fontFiles where file.pathExtension.lowercased() == "ttf" || file.pathExtension.lowercased() == "otf" {
                var error: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(file as CFURL, .process, &error)
                if success {
                    EchoLogger.general.info("Successfully registered custom font: \(file.lastPathComponent, privacy: .public)")
                }
            }
        }
    }
}
