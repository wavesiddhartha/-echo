import Foundation
import Speech
import AVFoundation

public actor SpeechRecognizerService {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    public init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    public func startRecognition(
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws -> SFSpeechAudioBufferRecognitionRequest {
        stopRecognition()
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(
                domain: "EchoSpeech",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available on this device."]
            )
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        self.recognitionRequest = request
        
        self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                onError(error)
                return
            }
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                if result.isFinal {
                    onFinalResult(transcription)
                } else {
                    onPartialResult(transcription)
                }
            }
        }
        
        return request
    }
    
    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }
    
    public func finishAudio() {
        recognitionRequest?.endAudio()
    }
    
    public func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
    }
}
