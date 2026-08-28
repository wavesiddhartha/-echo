import Foundation

public enum Constants {
    public static let appName = "Echo"
    public static let appTagline = "Native macOS AI Voice + Vision Overlay"
    public static let appVersion = "0.1.0"
    public static let bundleIdentifier = "com.antigravity.echo"
    
    public enum Layout {
        public static let overlayCompactWidth: CGFloat = 80
        public static let overlayCompactHeight: CGFloat = 30
        public static let overlayHoverWidth: CGFloat = 252
        public static let overlayListeningWidth: CGFloat = 296
        public static let overlayExpandedWidth: CGFloat = 356
        public static let overlayExpandedMaxHeight: CGFloat = 370
        public static let overlayCornerRadius: CGFloat = 14
        public static let cardCornerRadius: CGFloat = 10
        public static let buttonCornerRadius: CGFloat = 7
        public static let defaultPadding: CGFloat = 10
    }
    
    public enum Defaults {
        public static let globalShortcutKey = "Space"
        public static let globalShortcutModifiers = ["⌥ Option"]
        public static let autoStopListeningTimeout: TimeInterval = 1.1
        public static let maxHistorySessions = 100
        public static let defaultOpenAIKey = ""
    }
}
