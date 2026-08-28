import AppKit
import SwiftUI

@MainActor
public final class OverlayWindowManager: NSObject, NSWindowDelegate {
    private var overlayPanel: NSPanel?
    private var appState: AppState?
    private var clickOutsideMonitor: Any?
    
    private let positionXKey = "echo.overlay.position.x"
    private let positionYKey = "echo.overlay.position.y"
    
    public override init() {
        super.init()
    }
    
    deinit {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    public func configure(with appState: AppState) {
        self.appState = appState
        setupGlobalShortcut()
        showOverlay()
    }
    
    public func showOverlay() {
        guard let appState = self.appState else { return }
        appState.isOverlayVisible = true
        
        if overlayPanel == nil {
            createPanel(appState: appState)
        }
        
        guard let panel = overlayPanel else { return }
        
        if !panel.isVisible {
            positionPanel(panel)
            panel.alphaValue = 0.0
            panel.makeKeyAndOrderFront(nil)
            
            // Smooth entrance fade
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1.0
            }
            
            startClickOutsideMonitoring()
            EchoLogger.overlay.info("Echo permanent overlay active on screen")
        }
    }
    
    public func collapseToIdle() {
        guard let appState = self.appState else { return }
        appState.overlayState = .idle
        TextToSpeechManager.shared.stop()
    }
    
    public func hideOverlay() {
        // Overlay only quits when the app itself terminates or requested explicitly
        collapseToIdle()
    }
    
    public func toggleOverlay() {
        guard let appState = self.appState else { return }
        if appState.overlayState != .idle {
            collapseToIdle()
        } else {
            Task {
                await appState.startListeningInteraction()
            }
        }
    }
    
    // NSWindowDelegate: Track and persist user manual repositioning
    public func windowDidMove(_ notification: Notification) {
        guard let panel = overlayPanel else { return }
        let origin = panel.frame.origin
        UserDefaults.standard.set(Double(origin.x), forKey: positionXKey)
        UserDefaults.standard.set(Double(origin.y), forKey: positionYKey)
        appState?.settings.customOverlayPositionX = Double(origin.x)
        appState?.settings.customOverlayPositionY = Double(origin.y)
        EchoLogger.overlay.debug("Saved custom overlay position: (\(origin.x), \(origin.y))")
        
    }
    
    public func resetToDefaultBottomPosition() {
        UserDefaults.standard.removeObject(forKey: positionXKey)
        UserDefaults.standard.removeObject(forKey: positionYKey)
        appState?.settings.customOverlayPositionX = nil
        appState?.settings.customOverlayPositionY = nil
        if let panel = overlayPanel {
            positionPanel(panel)
        }
    }
    
    private func setupGlobalShortcut() {
        GlobalShortcutManager.shared.register { [weak self] in
            guard let self = self, let appState = self.appState else { return }
            Task { @MainActor in
                await appState.activateFromShortcut()
            }
        }
    }
    
    private func positionPanel(_ panel: NSPanel) {
        // 1. Check if the user previously dragged and moved the overlay
        if let savedX = UserDefaults.standard.object(forKey: positionXKey) as? Double,
           let savedY = UserDefaults.standard.object(forKey: positionYKey) as? Double {
            let savedPoint = NSPoint(x: savedX, y: savedY)
            let isVisibleOnAnyScreen = NSScreen.screens.contains { screen in
                NSPointInRect(savedPoint, screen.frame)
            }
            if isVisibleOnAnyScreen {
                panel.setFrameOrigin(savedPoint)
                return
            }
        }
        
        // 2. Default position: Bottom-center of the active display
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        
        if let screen = targetScreen {
            let screenRect = screen.visibleFrame
            let x = (screenRect.width - (Constants.Layout.overlayExpandedWidth + 40)) / 2 + screenRect.minX
            // Position at bottom center (above Dock / bottom edge)
            let y = screenRect.minY + 44
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    private func createPanel(appState: AppState) {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Constants.Layout.overlayExpandedWidth + 40,
                height: Constants.Layout.overlayExpandedMaxHeight
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        
        let hostingView = NSHostingView(
            rootView: ZStack {
                Color.clear
                OverlayView()
                    .environment(appState)
            }
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false
        panel.contentView = hostingView
        
        self.overlayPanel = panel
    }
    
    private func startClickOutsideMonitoring() {
        stopClickOutsideMonitoring()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.overlayPanel, panel.isVisible, let appState = self.appState else { return }
            let clickLocation = NSEvent.mouseLocation
            if !NSPointInRect(clickLocation, panel.frame) {
                DispatchQueue.main.async {
                    // Clicking outside collapses active responses back to the minimal idle pill permanently
                    if appState.overlayState != .idle {
                        self.collapseToIdle()
                    }
                }
            }
        }
    }
    
    private func stopClickOutsideMonitoring() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            self.clickOutsideMonitor = nil
        }
    }
}
