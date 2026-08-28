import Foundation
import os

public enum EchoLogger {
    private static let subsystem = Constants.bundleIdentifier
    
    public static let general = Logger(subsystem: subsystem, category: "General")
    public static let overlay = Logger(subsystem: subsystem, category: "Overlay")
    public static let voice = Logger(subsystem: subsystem, category: "Voice")
    public static let vision = Logger(subsystem: subsystem, category: "Vision")
    public static let ai = Logger(subsystem: subsystem, category: "AI")
    public static let permissions = Logger(subsystem: subsystem, category: "Permissions")
    public static let actions = Logger(subsystem: subsystem, category: "Actions")
    public static let storage = Logger(subsystem: subsystem, category: "Storage")
}
