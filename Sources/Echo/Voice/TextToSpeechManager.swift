import Foundation
import AVFoundation
import Observation

@Observable
public final class TextToSpeechManager: NSObject, @unchecked Sendable {
    public static let shared = TextToSpeechManager()
    
    public private(set) var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    
    public override init() {
        super.init()
    }
    
    public func speak(_ text: String, rate: Float = 1.0) {
        stop()
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isSpeaking = true
        EchoLogger.ai.info("OpenAI Voice Assistant speaking: \(trimmed.prefix(40), privacy: .public)…")
        
        Task {
            do {
                let key = OpenAIService.shared.apiKey ?? Constants.Defaults.defaultOpenAIKey
                let voiceName = OpenAIService.shared.selectedVoice.rawValue
                
                let url = URL(string: "https://api.openai.com/v1/audio/speech")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "model": "tts-1",
                    "input": trimmed,
                    "voice": voiceName,
                    "response_format": "mp3",
                    "speed": 1.0
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    await MainActor.run { self.isSpeaking = false }
                    return
                }
                
                await MainActor.run {
                    do {
                        self.audioPlayer = try AVAudioPlayer(data: data)
                        self.audioPlayer?.prepareToPlay()
                        self.audioPlayer?.play()
                        
                        // Estimated duration auto-reset
                        let duration = self.audioPlayer?.duration ?? max(Double(trimmed.split(separator: " ").count) * 0.35, 1.5)
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            if self.isSpeaking {
                                self.isSpeaking = false
                            }
                        }
                    } catch {
                        self.isSpeaking = false
                    }
                }
            } catch {
                await MainActor.run { self.isSpeaking = false }
            }
        }
    }
    
    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }
}
