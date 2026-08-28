import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class AppState {
    public var settings: AppSettings
    public var overlayState: OverlayState = .idle
    public var isOverlayVisible: Bool = false
    public var isActiveConversationActive: Bool = false
    public var lastScreenCapturePreview: (appName: String, imagePath: String)? = nil
    
    // Core Subsystems
    public let overlayWindowManager: OverlayWindowManager
    public let voiceManager: VoiceManager
    public let visionManager: VisionManager
    public let conversationManager: ConversationManager
    public let permissionManager: PermissionManager
    public let actionManager: ActionManager
    public let repository: SessionRepositoryProtocol
    
    public init(
        settings: AppSettings? = nil,
        overlayWindowManager: OverlayWindowManager? = nil,
        voiceManager: VoiceManager? = nil,
        visionManager: VisionManager? = nil,
        conversationManager: ConversationManager? = nil,
        permissionManager: PermissionManager? = nil,
        actionManager: ActionManager? = nil,
        repository: SessionRepositoryProtocol? = nil,
        aiProvider: AIProvider? = nil
    ) {
        let repo = repository ?? DiskSessionRepository()
        let provider = aiProvider ?? LiveAIProvider()
        let vm = voiceManager ?? VoiceManager()
        let vism = visionManager ?? VisionManager(aiProvider: provider)
        let conv = conversationManager ?? ConversationManager(aiProvider: provider, repository: repo)
        
        self.settings = settings ?? AppSettings()
        self.overlayWindowManager = overlayWindowManager ?? OverlayWindowManager()
        self.voiceManager = vm
        self.visionManager = vism
        self.conversationManager = conv
        self.permissionManager = permissionManager ?? PermissionManager()
        self.actionManager = actionManager ?? ActionManager()
        self.repository = repo
        
        self.overlayWindowManager.configure(with: self)
        EchoLogger.general.info("Echo AppState initialized with LiveAIProvider & DiskSessionRepository")
    }
    
    public func toggleOverlay() {
        if overlayState != .idle {
            stopActiveConversation()
        } else {
            Task {
                await startActiveConversation(handsFree: true)
            }
        }
    }
    
    // Shortcut Activation: Automatically presents HUD AND starts Voice AI Mode immediately
    public func activateFromShortcut() async {
        if isOverlayVisible && overlayState != .idle && !isActiveConversationActive {
            overlayWindowManager.collapseToIdle()
            return
        }
        await startActiveConversation(handsFree: true)
    }
    
    // Active Conversation Mode (Hands-Free or Push-to-Talk)
    public func startActiveConversation(handsFree: Bool? = nil) async {
        isActiveConversationActive = true
        if let handsFree = handsFree {
            settings.activeConversationHandsFree = handsFree
        }
        conversationManager.startNewSession(title: "Active Dialogue (\(Date().formatted(date: .omitted, time: .shortened)))")
        SoundFeedbackManager.shared.playActivationHaptic()
        await startListeningInteraction()
    }
    
    public func stopActiveConversation() {
        isActiveConversationActive = false
        TextToSpeechManager.shared.stop()
        overlayWindowManager.collapseToIdle()
    }
    
    // 1. Voice AI Mode: Speaks back + Conversational
    public func startListeningInteraction() async {
        isOverlayVisible = true
        overlayWindowManager.showOverlay()
        overlayState = .activating
        TextToSpeechManager.shared.stop()
        
        try? await Task.sleep(nanoseconds: 140_000_000)
        overlayState = .listening(transcript: "")
        
        do {
            try await voiceManager.startListening { [weak self] transcript in
                Task { @MainActor [weak self] in
                    guard let self = self, !transcript.isEmpty else { return }
                    await self.processVoiceQuery(transcript)
                }
            }
        } catch {
            overlayState = .error(message: "Microphone access is unavailable.")
        }
    }
    
    // 2. Post / Dictation Mode: Speech to Text with Direct Insert & Polish
    public func startPostModeInteraction() async {
        isOverlayVisible = true
        overlayWindowManager.showOverlay()
        overlayState = .activating
        TextToSpeechManager.shared.stop()
        
        try? await Task.sleep(nanoseconds: 140_000_000)
        overlayState = .postMode(transcript: "", isPolished: false)
        
        do {
            try await voiceManager.startListening { [weak self] transcript in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.overlayState = .postMode(transcript: transcript, isPolished: false)
                }
            }
        } catch {
            overlayState = .error(message: "Microphone access is unavailable.")
        }
    }
    
    public func polishCurrentPost(text: String) async {
        guard !text.isEmpty else { return }
        overlayState = .processing
        let polished = await conversationManager.polishDictation(rawText: text)
        overlayState = .postMode(transcript: polished, isPolished: true)
    }
    
    public func pasteCurrentPost(text: String) async {
        guard !text.isEmpty else { return }
        overlayWindowManager.collapseToIdle()
        await actionManager.pasteIntoActiveApp(text: text)
    }
    
    public func copyCurrentPost(text: String) {
        guard !text.isEmpty else { return }
        actionManager.copyToClipboard(text: text)
    }
    
    public func processVoiceQuery(_ query: String) async {
        let lower = query.lowercased()
        
        // Stop words for active conversation
        if isActiveConversationActive && (lower.contains("stop") || lower.contains("done") || lower.contains("goodbye") || lower.contains("bye")) {
            stopActiveConversation()
            return
        }
        
        overlayState = .processing
        var visualAnalysis: VisionAnalysis? = nil
        
        // Determine if visual context is needed on demand
        if lower.contains("screen") || lower.contains("looking at") || lower.contains("this") || lower.contains("error") || lower.contains("form") || lower.contains("what") || lower.contains("explain") || lower.contains("screenshot") {
            overlayState = .visionAnalysis(step: "Looking at screen…")
            visualAnalysis = try? await visionManager.captureAndAnalyze(
                request: query,
                sessionId: conversationManager.activeSession.id
            )
            
            if let screenshot = visionManager.lastCapturedScreenshot {
                self.lastScreenCapturePreview = (
                    appName: visualAnalysis?.detectedApplication ?? "Active App",
                    imagePath: screenshot.localPath
                )
            }
        }
        
        do {
            let response = try await conversationManager.processUserPrompt(query, visionAnalysis: visualAnalysis)
            overlayState = .responding(content: response)
            
            // Speak response via native Speech Synthesis
            TextToSpeechManager.shared.speak(response)
            
            // In Active Hands-Free Conversation: Auto re-arm listening after speech completes!
            if isActiveConversationActive && settings.activeConversationHandsFree {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    // Wait for speech to complete or estimated duration
                    let wordCount = response.split(separator: " ").count
                    let estimatedSeconds = max(Double(wordCount) * 0.22, 1.4)
                    try? await Task.sleep(nanoseconds: UInt64(estimatedSeconds * 1_000_000_000))
                    
                    if self.isActiveConversationActive {
                        await self.startListeningInteraction()
                    }
                }
            }
        } catch {
            overlayState = .error(message: "Could not complete request.")
        }
    }
    
    public func triggerDirectVisionAnalysis() async {
        isOverlayVisible = true
        overlayWindowManager.showOverlay()
        overlayState = .visionAnalysis(step: "Capturing current screen…")
        TextToSpeechManager.shared.stop()
        
        do {
            let prompt = "Explain what is happening on my screen right now and what I should do next."
            let analysis = try await visionManager.captureAndAnalyze(
                request: prompt,
                sessionId: conversationManager.activeSession.id
            )
            
            if let screenshot = visionManager.lastCapturedScreenshot {
                self.lastScreenCapturePreview = (
                    appName: analysis.detectedApplication ?? "Active App",
                    imagePath: screenshot.localPath
                )
            }
            
            overlayState = .visionAnalysis(step: "Synthesizing visual explanation…")
            let response = try await conversationManager.processUserPrompt(prompt, visionAnalysis: analysis)
            overlayState = .responding(content: response)
            
            // Speak response aloud
            TextToSpeechManager.shared.speak(response)
        } catch {
            overlayState = .error(message: "Could not analyze screen.")
        }
    }
    
    public func executeAction(_ action: UserAction) async {
        do {
            let success = try await actionManager.execute(action: action)
            if success {
                EchoLogger.actions.info("Executed action: \(action.title, privacy: .public)")
            }
        } catch {
            overlayState = .error(message: "Failed to execute action.")
        }
    }
    
    // Foundation Verification Flow Simulators
    public func testSimulatedVoiceFlow(prompt: String) async {
        isOverlayVisible = true
        overlayWindowManager.showOverlay()
        
        overlayState = .activating
        try? await Task.sleep(nanoseconds: 150_000_000)
        
        overlayState = .listening(transcript: prompt)
        try? await Task.sleep(nanoseconds: 250_000_000)
        
        overlayState = .processing
        try? await Task.sleep(nanoseconds: 250_000_000)
        
        do {
            let response = try await conversationManager.processUserPrompt(prompt)
            overlayState = .responding(content: response)
            TextToSpeechManager.shared.speak(response)
        } catch {
            overlayState = .error(message: "AI Processing failed.")
        }
    }
    
    public func testSimulatedVisionFlow(prompt: String) async {
        isOverlayVisible = true
        overlayWindowManager.showOverlay()
        
        overlayState = .activating
        try? await Task.sleep(nanoseconds: 150_000_000)
        
        overlayState = .listening(transcript: prompt)
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        overlayState = .visionAnalysis(step: "Capturing current screen…")
        try? await Task.sleep(nanoseconds: 250_000_000)
        
        do {
            let analysis = try await visionManager.captureAndAnalyze(
                request: prompt,
                sessionId: conversationManager.activeSession.id
            )
            
            overlayState = .visionAnalysis(step: "Analyzing screen with AI…")
            try? await Task.sleep(nanoseconds: 250_000_000)
            
            let response = try await conversationManager.processUserPrompt(prompt, visionAnalysis: analysis)
            overlayState = .responding(content: response)
            TextToSpeechManager.shared.speak(response)
        } catch {
            overlayState = .error(message: "Screen analysis failed.")
        }
    }
}
