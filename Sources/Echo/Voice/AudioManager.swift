import Foundation
import AVFoundation

public final class AudioManager: @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private var isRunning = false
    private let lock = NSLock()
    
    public init() {}
    
    public func startRecording(
        onBuffer: @escaping @Sendable (AVAudioPCMBuffer) -> Void,
        onLevelUpdate: @escaping @Sendable (Float) -> Void
    ) throws {
        lock.lock()
        defer { lock.unlock() }
        
        if isRunning {
            stopRecordingInternal()
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            EchoLogger.voice.warning("Audio input format not ready (sampleRate <= 0). Skipping audio tap installation.")
            return
        }
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            onBuffer(buffer)
            
            // Calculate RMS audio power level (normalized 0.0 to 1.0)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = UInt(buffer.frameLength)
            guard frameLength > 0 else { return }
            var sum: Float = 0.0
            for i in 0..<Int(frameLength) {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(frameLength))
            let normalizedLevel = min(max(rms * 10, 0.0), 1.0)
            onLevelUpdate(normalizedLevel)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRunning = true
        EchoLogger.voice.info("AudioEngine started recording safely")
    }
    
    public func stopRecording() {
        lock.lock()
        defer { lock.unlock() }
        stopRecordingInternal()
    }
    
    private func stopRecordingInternal() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        EchoLogger.voice.info("AudioEngine stopped recording safely")
    }
}
