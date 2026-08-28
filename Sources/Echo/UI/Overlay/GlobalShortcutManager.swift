import Foundation
import AppKit
import Carbon

public final class GlobalShortcutManager: @unchecked Sendable {
    public static let shared = GlobalShortcutManager()
    
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var actionHandler: (@MainActor () -> Void)?
    private var localMonitor: Any?
    private var flagsMonitor: Any?
    private var lastFnPressTime: Date = Date.distantPast
    
    public init() {}
    
    deinit {
        unregisterShortcut()
    }
    
    public func register(
        keyCode: UInt32 = UInt32(kVK_Space),
        modifiers: UInt32 = UInt32(optionKey),
        action: @escaping @MainActor () -> Void
    ) {
        unregisterShortcut()
        self.actionHandler = action
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(32984) // Unique signature
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamName(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr && hotKeyID.id == 1 {
                    DispatchQueue.main.async {
                        manager.actionHandler?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
        
        if status == noErr {
            let regStatus = RegisterEventHotKey(
                keyCode,
                modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            if regStatus == noErr {
                EchoLogger.overlay.info("Registered global shortcut (Option + Space)")
            } else {
                EchoLogger.overlay.error("Failed to register hot key: \(regStatus)")
            }
        }
        
        // Listen for Function (Fn) key presses
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            if event.modifierFlags.contains(.function) {
                let now = Date()
                if now.timeIntervalSince(self.lastFnPressTime) < 0.45 {
                    // Double-tap Fn detected or single Fn tap
                    DispatchQueue.main.async {
                        self.actionHandler?()
                    }
                    self.lastFnPressTime = Date.distantPast
                } else {
                    self.lastFnPressTime = now
                }
            }
        }
        
        // Local monitor for ESC key
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                DispatchQueue.main.async {
                    self?.actionHandler?()
                }
                return nil
            }
            return event
        }
    }
    
    public func unregisterShortcut() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let flagsMonitor = flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
    }
}
