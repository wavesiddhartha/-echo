import AppKit
import AudioToolbox

public final class SoundFeedbackManager: Sendable {
    public static let shared = SoundFeedbackManager()
    
    public init() {}
    
    public func playActivationHaptic() {
        Task { @MainActor in
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .default
            )
        }
    }
    
    public func playSuccessHaptic() {
        Task { @MainActor in
            NSHapticFeedbackManager.defaultPerformer.perform(
                .generic,
                performanceTime: .default
            )
        }
    }
    
    public func playCameraShutterSound() {
        Task { @MainActor in
            // Play native macOS camera shutter snapshot sound (SystemSound ID 1108)
            AudioServicesPlaySystemSound(1108)
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .default
            )
        }
    }
}
