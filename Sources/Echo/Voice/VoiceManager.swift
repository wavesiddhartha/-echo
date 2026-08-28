import Foundation
import Observation
import AVFoundation

@Observable
public final class VoiceManager: @unchecked Sendable {
    public private(set) var state: VoiceState = .inactive
    public private(set) var currentTranscript: String = ""
    public private(set) var audioLevel: Float = 0.0
    
    private let audioManager = AudioManager()
    private let speechRecognizer = SpeechRecognizerService()
    private var silenceTimer: Timer?
    private var onSpeechCompleted: (@Sendable (String) -> Void)?
    
    public init() {
        EchoLogger.voice.debug("VoiceManager initialized with native STT & audio pipeline")
    }
    
    public func startListening(onCompletion: (@Sendable (String) -> Void)? = nil) async throws {
        state = .listening
        currentTranscript = ""
        audioLevel = 0.0
        self.onSpeechCompleted = onCompletion
        
        do {
            _ = try await speechRecognizer.startRecognition(
                onPartialResult: { [weak self] partial in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.currentTranscript = partial
                        self.resetSilenceTimer()
                    }
                },
                onFinalResult: { [weak self] finalTranscript in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.currentTranscript = finalTranscript
                        self.finishListening()
                    }
                },
                onError: { error in
                    Task { @MainActor in
                        EchoLogger.voice.error("Speech recognition error: \(error.localizedDescription)")
                    }
                }
            )
            
            try audioManager.startRecording(
                onBuffer: { [weak self] buffer in
                    Task { [weak self] in
                        await self?.speechRecognizer.appendAudioBuffer(buffer)
                    }
                },
                onLevelUpdate: { [weak self] level in
                    Task { @MainActor [weak self] in
                        self?.audioLevel = level
                    }
                }
            )
            
            EchoLogger.voice.info("VoiceManager actively listening to microphone")
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }
    
    public func stopListening() async -> String {
        state = .processing
        audioManager.stopRecording()
        await speechRecognizer.finishAudio()
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        let result = currentTranscript
        EchoLogger.voice.info("VoiceManager finished with transcript: \(result, privacy: .public)")
        state = .inactive
        return result
    }
    
    public func cancelListening() async {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioManager.stopRecording()
        await speechRecognizer.stopRecognition()
        state = .inactive
        currentTranscript = ""
        audioLevel = 0.0
        EchoLogger.voice.info("VoiceManager cancelled listening")
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: Constants.Defaults.autoStopListeningTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, case .listening = self.state, !self.currentTranscript.isEmpty else { return }
                self.finishListening()
            }
        }
    }
    
    private func finishListening() {
        Task {
            let transcript = await self.stopListening()
            self.onSpeechCompleted?(transcript)
        }
    }
}
