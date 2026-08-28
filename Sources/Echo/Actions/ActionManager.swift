import Foundation
import AppKit
import Observation
import CoreGraphics

public protocol ActionExecuting: Sendable {
    func execute(action: UserAction) async throws -> Bool
}

@Observable
public final class ActionManager: ActionExecuting, @unchecked Sendable {
    public init() {
        EchoLogger.actions.debug("ActionManager initialized")
    }
    
    public func execute(action: UserAction) async throws -> Bool {
        EchoLogger.actions.info("Executing action: \(action.title, privacy: .public), type: \(action.type.rawValue, privacy: .public)")
        
        switch action.type {
        case .openURL:
            guard let url = URL(string: action.payload) else {
                throw NSError(domain: "EchoAction", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(action.payload)"])
            }
            _ = await MainActor.run {
                NSWorkspace.shared.open(url)
            }
            return true
            
        case .openApplication:
            await MainActor.run {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: action.payload),
                    configuration: NSWorkspace.OpenConfiguration()
                ) { _, _ in }
            }
            return true
            
        case .copyText:
            _ = await MainActor.run {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(action.payload, forType: .string)
            }
            return true
            
        case .runScript, .custom:
            EchoLogger.actions.warning("Custom script execution not enabled in base foundation")
            return false
        }
    }
    
    public func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        EchoLogger.actions.info("Copied transcription to system clipboard")
    }
    
    public func pasteIntoActiveApp(text: String) async {
        copyToClipboard(text: text)
        
        // Wait briefly for active focus
        try? await Task.sleep(nanoseconds: 120_000_000)
        
        // Simulate Command + V keystroke
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 0x09 // 'v' key
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        EchoLogger.actions.info("Simulated direct paste into active macOS application")
    }
}
