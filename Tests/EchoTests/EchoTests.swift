import XCTest
import Foundation
import AppKit
@testable import Echo

final class EchoTests: XCTestCase {
    
    func testConstantsAndDefaults() {
        XCTAssertEqual(Constants.appName, "Echo")
        XCTAssertEqual(Constants.Defaults.globalShortcutKey, "Space")
        XCTAssertEqual(Constants.Defaults.globalShortcutModifiers, ["⌥ Option"])
    }
    
    func testKeychainManager() {
        let keychain = KeychainManager.shared
        let testAccount = "test_echo_api_key_\(UUID().uuidString)"
        let testSecret = "sk-test-secret-key-12345"
        
        let saved = keychain.save(key: testSecret, account: testAccount)
        XCTAssertTrue(saved)
        
        let retrieved = keychain.read(account: testAccount)
        XCTAssertEqual(retrieved, testSecret)
        
        keychain.delete(account: testAccount)
        let afterDelete = keychain.read(account: testAccount)
        XCTAssertNil(afterDelete)
    }
    
    func testGlobalShortcutManager() {
        let shortcutManager = GlobalShortcutManager()
        var triggered = false
        
        shortcutManager.register(keyCode: UInt32(0x31), modifiers: UInt32(0x0800)) {
            triggered = true
        }
        
        shortcutManager.unregisterShortcut()
        XCTAssertFalse(triggered)
    }
    
    func testDiskSessionRepository() async throws {
        let repository = DiskSessionRepository()
        let session = Session(title: "Persistent Disk Session")
        
        try await repository.saveSession(session)
        let fetched = try await repository.fetchSession(byId: session.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Persistent Disk Session")
        
        let all = try await repository.fetchSessions()
        XCTAssertFalse(all.isEmpty)
        
        try await repository.deleteSession(byId: session.id)
        let afterDelete = try await repository.fetchSession(byId: session.id)
        XCTAssertNil(afterDelete)
    }
    
    func testConversationManager() async throws {
        let repository = InMemorySessionRepository()
        let aiProvider = MockAIProvider()
        let conversationManager = ConversationManager(aiProvider: aiProvider, repository: repository)
        
        let response = try await conversationManager.processUserPrompt("Hello Echo")
        XCTAssertFalse(response.isEmpty)
        XCTAssertEqual(conversationManager.activeSession.messages.count, 2)
        XCTAssertEqual(conversationManager.activeSession.messages.first?.role, .user)
        XCTAssertEqual(conversationManager.activeSession.messages.last?.role, .assistant)
        
        // Multi-turn continuity
        let followUp = try await conversationManager.processUserPrompt("What should I do next?")
        XCTAssertFalse(followUp.isEmpty)
        XCTAssertEqual(conversationManager.activeSession.messages.count, 4)
    }
    
    func testSmartAutoTitling() {
        let manager = ConversationManager()
        
        _ = manager.addUserMessage("What is written on my screen right now?")
        XCTAssertTrue(manager.activeSession.title.hasPrefix("Screen:"))
        
        manager.startNewSession()
        _ = manager.addUserMessage("Save this note for my project architecture")
        XCTAssertTrue(manager.activeSession.title.hasPrefix("Note:"))
        
        manager.startNewSession()
        _ = manager.addUserMessage("Create a meeting reminder for tomorrow at 3pm")
        XCTAssertTrue(manager.activeSession.title.hasPrefix("Schedule:"))
        
        manager.startNewSession()
        _ = manager.addUserMessage("What YouTube video should I watch next?")
        XCTAssertTrue(manager.activeSession.title.hasPrefix("YouTube Search:"))
    }
    
    func testDictationPolish() async {
        let conversationManager = ConversationManager()
        let raw = "um hey team like we need to finish the demo today"
        let polished = await conversationManager.polishDictation(rawText: raw)
        XCTAssertFalse(polished.isEmpty)
    }
    
    func testVisionAnalysisFlow() async throws {
        let visionManager = VisionManager()
        let analysis = try await visionManager.captureAndAnalyze(request: "What's on screen?", sessionId: UUID())
        XCTAssertFalse(analysis.summary.isEmpty)
        XCTAssertNotNil(visionManager.lastCapturedScreenshot)
    }
    
    @MainActor
    func testActiveConversationLifecycle() async {
        let appState = AppState()
        XCTAssertFalse(appState.isActiveConversationActive)
        
        await appState.startActiveConversation(handsFree: true)
        XCTAssertTrue(appState.isActiveConversationActive)
        XCTAssertTrue(appState.isOverlayVisible)
        
        appState.stopActiveConversation()
        XCTAssertFalse(appState.isActiveConversationActive)
    }
    
    func testActionPlanner() async throws {
        let planner = ActionPlanner()
        let actions = try await planner.planActions(userIntent: "Open YouTube", currentContext: "")
        XCTAssertFalse(actions.isEmpty)
        XCTAssertEqual(actions.first?.type, .openURL)
        XCTAssertEqual(actions.first?.payload, "https://youtube.com")
    }
    
    @MainActor
    func testOverlayHUDPresentation() async {
        let appState = AppState()
        XCTAssertTrue(appState.isOverlayVisible)
        XCTAssertEqual(appState.overlayState, .idle)
        
        await appState.testSimulatedVoiceFlow(prompt: "Hello Echo")
        if case .responding = appState.overlayState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .responding overlay state, got \(appState.overlayState)")
        }
        
        appState.toggleOverlay()
        XCTAssertEqual(appState.overlayState, .idle)
    }
    
    func testOverlayPositionPersistence() {
        var settings = AppSettings(customOverlayPositionX: 450.0, customOverlayPositionY: 120.0)
        XCTAssertEqual(settings.customOverlayPositionX, 450.0)
        XCTAssertEqual(settings.customOverlayPositionY, 120.0)
        
        settings.customOverlayPositionX = 520.0
        settings.customOverlayPositionY = 180.0
        XCTAssertEqual(settings.customOverlayPositionX, 520.0)
        XCTAssertEqual(settings.customOverlayPositionY, 180.0)
    }
    
    func testSupabaseAuthAndSyncLifecycle() async throws {
        let manager = SupabaseManager()
        
        let user = try await manager.signIn(email: "admin@echo.ai", password: "secure-password-123")
        XCTAssertTrue(user.isAdmin)
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(manager.currentUser?.email, "admin@echo.ai")
        
        let testSession = Session(title: "Cloud Synced Test")
        try await manager.syncSessionToCloud(testSession)
        XCTAssertEqual(manager.syncState, .idle)
        XCTAssertNotNil(manager.lastSyncedAt)
        
        manager.signOut()
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertNil(manager.currentUser)
    }
    
    func testOpenAIServiceConfiguration() {
        let service = OpenAIService.shared
        
        service.selectedVoice = .shimmer
        XCTAssertEqual(service.selectedVoice, .shimmer)
        
        service.selectedVoice = .echo
        XCTAssertEqual(service.selectedVoice, .echo)
        
        service.selectedModel = .gpt4o
        XCTAssertEqual(service.selectedModel, .gpt4o)
        
        XCTAssertEqual(OpenAIVoice.allCases.count, 6)
        XCTAssertEqual(OpenAIModel.allCases.count, 2)
    }
}
