import Foundation
import Observation
import AVFoundation

public enum PermissionStatus: String, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@Observable
public final class PermissionManager: @unchecked Sendable {
    public private(set) var microphoneStatus: PermissionStatus = .notDetermined
    public private(set) var screenRecordingStatus: PermissionStatus = .notDetermined
    public private(set) var accessibilityStatus: PermissionStatus = .notDetermined
    
    public init() {
        checkAllPermissions()
    }
    
    public func checkAllPermissions() {
        checkMicrophonePermission()
        checkScreenRecordingPermission()
        checkAccessibilityPermission()
    }
    
    public func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .restricted:
            microphoneStatus = .restricted
        case .notDetermined:
            microphoneStatus = .notDetermined
        @unknown default:
            microphoneStatus = .notDetermined
        }
    }
    
    public func checkScreenRecordingPermission() {
        if #available(macOS 14.0, *) {
            let hasAccess = CGPreflightScreenCaptureAccess()
            screenRecordingStatus = hasAccess ? .authorized : .notDetermined
        } else {
            screenRecordingStatus = .authorized
        }
    }
    
    public func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        accessibilityStatus = isTrusted ? .authorized : .notDetermined
    }
    
    public func requestMicrophoneAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = granted ? .authorized : .denied
        EchoLogger.permissions.info("Microphone access request completed: \(granted)")
        return granted
    }
    
    public func requestScreenRecordingAccess() {
        if #available(macOS 14.0, *) {
            let granted = CGRequestScreenCaptureAccess()
            screenRecordingStatus = granted ? .authorized : .denied
            EchoLogger.permissions.info("Screen recording access request: \(granted)")
        }
    }
}
