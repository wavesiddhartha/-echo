import Testing
import Foundation
import AppKit
@testable import Echo

@Suite("Echo Active Conversation & Full Architecture Tests")
struct EchoTests {
    
    @Test("Echo constants and default values integrity")
    func testConstantsAndDefaults() {
        #expect(Constants.appName == "Echo")
        #expect(Constants.Defaults.globalShortcutKey == "Space")
        #expect(Constants.Defaults.globalShortcutModifiers == ["⌥ Option"])
    }
    
    @Test("KeychainManager secure storage save, read, and delete")
    func testKeychainManager() {
        let keychain = KeychainManager.shared
        let testAccount = "test_echo_api_key_\(UUID().uuidString)"
        let testSecret = "sk-test-secret-key-12345"
        
        let saved = keychain.save(key: testSecret, account: testAccount)
        #expect(saved)
        
        let retrieved = keychain.read(account: testAccount)
        #expect(retrieved == testSecret)
        
        keychain.delete(account: testAccount)
        let afterDelete = keychain.read(account: testAccount)
        #expect(afterDelete == nil)
    }
    
    @Test("Global shortcut manager registration lifecycle")
    func testGlobalShortcutManager() {
        let shortcutManager = GlobalShortcutManager()
        var triggered = false
        
        shortcutManager.register(keyCode: UInt32(0x31), modifiers: UInt32(0x0800)) {
            triggered = true
        }
        
        shortcutManager.unregisterShortcut()
        #expect(!triggered)
    }
    
    @Test("DiskSessionRepository persistence CRUD operations")
    func testDiskSessionRepository() async throws {
        let repository = DiskSessionRepository()
        let session = Session(title: "Persistent Disk Session")
        
        try await repository.saveSession(session)
        let fetched = try await repository.fetchSession(byId: session.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Persistent Disk Session")
        
        let all = try await repository.fetchSessions()
        #expect(!all.isEmpty)
        
        try await repository.deleteSession(byId: session.id)
        let afterDelete = try await repository.fetchSession(byId: session.id)
        #expect(afterDelete == nil)
    }
    
    @Test("Echo conversation manager multi-turn dialog flow and persistence")
    func testConversationManager() async throws {
        let repository = InMemorySessionRepository()
        let aiProvider = MockAIProvider()
        let conversationManager = ConversationManager(aiProvider: aiProvider, repository: repository)
        
        let response = try await conversationManager.processUserPrompt("Hello Echo")
        #expect(!response.isEmpty)
        #expect(conversationManager.activeSession.messages.count == 2)
        #expect(conversationManager.activeSession.messages.first?.role == .user)
        #expect(conversationManager.activeSession.messages.last?.role == .assistant)
        
        // Multi-turn continuity
        let followUp = try await conversationManager.processUserPrompt("What should I do next?")
        #expect(!followUp.isEmpty)
        #expect(conversationManager.activeSession.messages.count == 4)
    }
    
    @Test("Echo conversation manager smart auto-titling logic")
    func testSmartAutoTitling() {
        let manager = ConversationManager()
        
        _ = manager.addUserMessage("What is written on my screen right now?")
        #expect(manager.activeSession.title.hasPrefix("Screen:"))
        
        manager.startNewSession()
        _ = manager.addUserMessage("Save this note for my project architecture")
        #expect(manager.activeSession.title.hasPrefix("Note:"))
        
        manager.startNewSession()
        _ = manager.addUserMessage("Create a meeting reminder for tomorrow at 3pm")
        #expect(manager.activeSession.title.hasPrefix("Schedule:"))
        
        manager.startNewSession()
        _ = manager.addUserMessage("What YouTube video should I watch next?")
        #expect(manager.activeSession.title.hasPrefix("YouTube Search:"))
    }
    
    @Test("Echo dictation polish functionality")
    func testDictationPolish() async {
        let conversationManager = ConversationManager()
        let raw = "um hey team like we need to finish the demo today"
        let polished = await conversationManager.polishDictation(rawText: raw)
        #expect(!polished.isEmpty)
    }
    
    @Test("Echo vision manager on-demand screen understanding and shutter snapshot")
    func testVisionAnalysisFlow() async throws {
        let visionManager = VisionManager()
        let analysis = try await visionManager.captureAndAnalyze(request: "What's on screen?", sessionId: UUID())
        #expect(!analysis.summary.isEmpty)
        #expect(visionManager.lastCapturedScreenshot != nil)
    }
    
    @Test("Echo active conversation lifecycle")
    @MainActor
    func testActiveConversationLifecycle() async {
        let appState = AppState()
        #expect(!appState.isActiveConversationActive)
        
        await appState.startActiveConversation(handsFree: true)
        #expect(appState.isActiveConversationActive)
        #expect(appState.isOverlayVisible)
        
        appState.stopActiveConversation()
        #expect(!appState.isActiveConversationActive)
    }
    
    @Test("Echo action planner extracts safe actions")
    func testActionPlanner() async throws {
        let planner = ActionPlanner()
        let actions = try await planner.planActions(userIntent: "Open YouTube", currentContext: "")
        #expect(!actions.isEmpty)
        #expect(actions.first?.type == .openURL)
        #expect(actions.first?.payload == "https://youtube.com")
    }
    
    @Test("Echo overlay HUD window toggle and presentation states")
    @MainActor
    func testOverlayHUDPresentation() async {
        let appState = AppState()
        #expect(appState.isOverlayVisible)
        #expect(appState.overlayState == .idle)
        
        await appState.testSimulatedVoiceFlow(prompt: "Hello Echo")
        if case .responding = appState.overlayState {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .responding overlay state, got \(appState.overlayState)")
        }
        
        appState.toggleOverlay()
        #expect(appState.overlayState == .idle)
    }
    
    @Test("Persistent position configuration in AppSettings")
    func testOverlayPositionPersistence() {
        var settings = AppSettings(customOverlayPositionX: 450.0, customOverlayPositionY: 120.0)
        #expect(settings.customOverlayPositionX == 450.0)
        #expect(settings.customOverlayPositionY == 120.0)
        
        settings.customOverlayPositionX = 520.0
        settings.customOverlayPositionY = 180.0
        #expect(settings.customOverlayPositionX == 520.0)
        #expect(settings.customOverlayPositionY == 180.0)
    }
    
    @Test("Supabase authentication and realtime cloud sync lifecycle")
    func testSupabaseAuthAndSyncLifecycle() async throws {
        let manager = SupabaseManager()
        
        let user = try await manager.signIn(email: "admin@echo.ai", password: "secure-password-123")
        #expect(user.isAdmin)
        #expect(manager.isAuthenticated)
        #expect(manager.currentUser?.email == "admin@echo.ai")
        
        let testSession = Session(title: "Cloud Synced Test")
        try await manager.syncSessionToCloud(testSession)
        #expect(manager.syncState == .idle)
        #expect(manager.lastSyncedAt != nil)
        
        manager.signOut()
        #expect(!manager.isAuthenticated)
        #expect(manager.currentUser == nil)
    }
    
    @Test("OpenAI service configuration, neural voices, and model presets")
    func testOpenAIServiceConfiguration() {
        let service = OpenAIService.shared
        
        service.selectedVoice = .shimmer
        #expect(service.selectedVoice == .shimmer)
        
        service.selectedVoice = .echo
        #expect(service.selectedVoice == .echo)
        
        service.selectedModel = .gpt4o
        #expect(service.selectedModel == .gpt4o)
        
        #expect(OpenAIVoice.allCases.count == 6)
        #expect(OpenAIModel.allCases.count == 2)
    }
}
