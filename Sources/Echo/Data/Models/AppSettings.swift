import Foundation

public struct AppSettings: Codable, Sendable, Equatable {
    private static let onboardingKey = "echo.hasCompletedOnboarding"
    private static let positionXKey = "echo.overlay.position.x"
    private static let positionYKey = "echo.overlay.position.y"
    
    // General
    public var launchAtStartup: Bool
    public var globalShortcutKey: String
    public var globalShortcutModifiers: [String]
    
    public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey)
        }
    }
    
    // Active Conversation & Multi-Turn
    public var activeConversationModeEnabled: Bool
    public var activeConversationHandsFree: Bool
    public var showScreenshotPreviewBadge: Bool
    
    // Voice
    public var microphoneEnabled: Bool
    public var autoStopListening: Bool
    public var autoStopTimeoutSeconds: Double
    
    // Vision
    public var screenCaptureEnabled: Bool
    public var askBeforeScreenshot: Bool
    public var saveScreenshotsToHistory: Bool
    
    // Privacy
    public var localHistoryOnly: Bool
    public var allowCloudProcessing: Bool
    
    // Automation
    public var allowSafeActions: Bool
    public var requireConfirmationForActions: Bool
    public var autoOpenSuggestedLinks: Bool
    
    // Appearance & Position
    public var trueBlackMode: Bool
    public var overlayOpacity: Double
    public var customOverlayPositionX: Double? {
        didSet {
            if let val = customOverlayPositionX {
                UserDefaults.standard.set(val, forKey: Self.positionXKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.positionXKey)
            }
        }
    }
    public var customOverlayPositionY: Double? {
        didSet {
            if let val = customOverlayPositionY {
                UserDefaults.standard.set(val, forKey: Self.positionYKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.positionYKey)
            }
        }
    }
    
    public init(
        launchAtStartup: Bool = false,
        globalShortcutKey: String = Constants.Defaults.globalShortcutKey,
        globalShortcutModifiers: [String] = Constants.Defaults.globalShortcutModifiers,
        hasCompletedOnboarding: Bool? = nil,
        activeConversationModeEnabled: Bool = false,
        activeConversationHandsFree: Bool = true,
        showScreenshotPreviewBadge: Bool = true,
        microphoneEnabled: Bool = true,
        autoStopListening: Bool = true,
        autoStopTimeoutSeconds: Double = Constants.Defaults.autoStopListeningTimeout,
        screenCaptureEnabled: Bool = true,
        askBeforeScreenshot: Bool = false,
        saveScreenshotsToHistory: Bool = true,
        localHistoryOnly: Bool = true,
        allowCloudProcessing: Bool = true,
        allowSafeActions: Bool = true,
        requireConfirmationForActions: Bool = true,
        autoOpenSuggestedLinks: Bool = false,
        trueBlackMode: Bool = true,
        overlayOpacity: Double = 1.0,
        customOverlayPositionX: Double? = nil,
        customOverlayPositionY: Double? = nil
    ) {
        self.launchAtStartup = launchAtStartup
        self.globalShortcutKey = globalShortcutKey
        self.globalShortcutModifiers = globalShortcutModifiers
        self.hasCompletedOnboarding = hasCompletedOnboarding ?? UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.activeConversationModeEnabled = activeConversationModeEnabled
        self.activeConversationHandsFree = activeConversationHandsFree
        self.showScreenshotPreviewBadge = showScreenshotPreviewBadge
        self.microphoneEnabled = microphoneEnabled
        self.autoStopListening = autoStopListening
        self.autoStopTimeoutSeconds = autoStopTimeoutSeconds
        self.screenCaptureEnabled = screenCaptureEnabled
        self.askBeforeScreenshot = askBeforeScreenshot
        self.saveScreenshotsToHistory = saveScreenshotsToHistory
        self.localHistoryOnly = localHistoryOnly
        self.allowCloudProcessing = allowCloudProcessing
        self.allowSafeActions = allowSafeActions
        self.requireConfirmationForActions = requireConfirmationForActions
        self.autoOpenSuggestedLinks = autoOpenSuggestedLinks
        self.trueBlackMode = trueBlackMode
        self.overlayOpacity = overlayOpacity
        
        let savedX = UserDefaults.standard.object(forKey: Self.positionXKey) as? Double
        let savedY = UserDefaults.standard.object(forKey: Self.positionYKey) as? Double
        self.customOverlayPositionX = customOverlayPositionX ?? savedX
        self.customOverlayPositionY = customOverlayPositionY ?? savedY
    }
}
