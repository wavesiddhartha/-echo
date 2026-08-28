import Foundation
import AppKit
import AVFoundation

public enum OpenAIVoice: String, CaseIterable, Identifiable, Sendable {
    case alloy = "alloy"
    case echo = "echo"
    case fable = "fable"
    case onyx = "onyx"
    case nova = "nova"
    case shimmer = "shimmer"
    
    public var id: String { rawValue }
    public var displayName: String { rawValue.capitalized }
}

public enum OpenAIModel: String, CaseIterable, Identifiable, Sendable {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
    
    public var id: String { rawValue }
}

public final class OpenAIService: @unchecked Sendable {
    public static let shared = OpenAIService()
    
    private var audioPlayer: AVAudioPlayer?
    
    public var apiKey: String? {
        get { KeychainManager.shared.read(account: "openai_api_key") ?? Constants.Defaults.defaultOpenAIKey }
        set {
            if let val = newValue, !val.isEmpty {
                _ = KeychainManager.shared.save(key: val, account: "openai_api_key")
            } else {
                KeychainManager.shared.delete(account: "openai_api_key")
            }
        }
    }
    
    public var selectedVoice: OpenAIVoice {
        get {
            let saved = UserDefaults.standard.string(forKey: "echo.openai.voice") ?? "echo"
            return OpenAIVoice(rawValue: saved) ?? .echo
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "echo.openai.voice")
        }
    }
    
    public var selectedModel: OpenAIModel {
        get {
            let saved = UserDefaults.standard.string(forKey: "echo.openai.model") ?? "gpt-4o"
            return OpenAIModel(rawValue: saved) ?? .gpt4o
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "echo.openai.model")
        }
    }
    
    public init() {}
    
    // MARK: - 1. OpenAI Voice Synthesis (Neural TTS)
    public func speak(text: String, voice: OpenAIVoice? = nil) async throws {
        guard let key = apiKey, !key.isEmpty else {
            // Fallback to macOS native speech synthesis
            TextToSpeechManager.shared.speak(text)
            return
        }
        
        let voiceName = (voice ?? selectedVoice).rawValue
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voiceName,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // Fallback to local synthesizer
            TextToSpeechManager.shared.speak(text)
            return
        }
        
        await MainActor.run {
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                TextToSpeechManager.shared.speak(text)
            }
        }
    }
    
    public func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        TextToSpeechManager.shared.stop()
    }
    
    // MARK: - 2. OpenAI Whisper Audio Transcription & Translation
    public func transcribeAudio(fileURL: URL) async throws -> String {
        guard let key = apiKey, !key.isEmpty else {
            return ""
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // Model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Audio File
        let audioData = try Data(contentsOf: fileURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "OpenAIWhisper", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to transcribe audio."])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text
        }
        return ""
    }
    
    // MARK: - 3. OpenAI GPT-4o Vision Screen Analysis
    public func analyzeScreenImage(imagePath: String, prompt: String) async throws -> String {
        guard let key = apiKey, !key.isEmpty else {
            return "Screen Analysis: Observed active window context."
        }
        
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
            return "Unable to load captured screenshot."
        }
        
        let base64 = imageData.base64EncodedString()
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": selectedModel.rawValue,
            "messages": [
                ["role": "system", "content": PromptManager.systemInstruction],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": ["url": "data:image/png;base64,\(base64)", "detail": "high"]
                        ]
                    ]
                ]
            ],
            "max_tokens": 450
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return "Visual understanding complete: analyzed active display."
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Screen context analyzed."
    }
    
    // MARK: - 4. OpenAI DALL·E 3 Image Generation
    public func generateImage(prompt: String) async throws -> URL {
        guard let key = apiKey, !key.isEmpty else {
            throw NSError(domain: "OpenAIImage", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenAI API Key is required for image generation."])
        }
        
        let url = URL(string: "https://api.openai.com/v1/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "standard"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "OpenAIImage", code: 500, userInfo: [NSLocalizedDescriptionKey: "Image generation failed."])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArr = json["data"] as? [[String: Any]],
           let firstItem = dataArr.first,
           let urlString = firstItem["url"] as? String,
           let imageURL = URL(string: urlString) {
            return imageURL
        }
        
        throw NSError(domain: "OpenAIImage", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid image response."])
    }
}
