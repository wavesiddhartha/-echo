import SwiftUI

public struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var activeSettingsTab: SettingsTab = .general
    @State private var openAIApiKey: String = ""
    @State private var isKeySaved: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showAuthModal: Bool = false
    @State private var supabaseUrl: String = SupabaseManager.shared.projectURL
    @State private var supabaseAnonKey: String = SupabaseManager.shared.anonKey
    @State private var isSyncing: Bool = false
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case ai = "AI & Security"
        case cloud = "Cloud & Sync"
        case voice = "Voice"
        case vision = "Vision"
        case privacy = "Privacy"
        case automation = "Automation"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .ai: return "key.fill"
            case .cloud: return "cloud.fill"
            case .voice: return "waveform"
            case .vision: return "camera.viewfinder"
            case .privacy: return "hand.raised.fill"
            case .automation: return "bolt.fill"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        @Bindable var state = appState
        
        VStack(alignment: .leading, spacing: 0) {
            // Segmented Header Tabs
            HStack(spacing: 5) {
                ForEach(SettingsTab.allCases) { tab in
                    let isSelected = activeSettingsTab == tab
                    Button(action: {
                        SoundFeedbackManager.shared.playActivationHaptic()
                        activeSettingsTab = tab
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10.5, weight: .bold))
                            Text(tab.rawValue)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? Color.white : Color(hex: "#52525B"))
                        .padding(.horizontal, 9.5)
                        .padding(.vertical, 5.5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? Color(hex: "#18181B") : Color(hex: "#EDEAE1"))
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 14)
            
            Divider().background(Color(hex: "#E8E6DF"))
            
            // Tab Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch activeSettingsTab {
                    case .general:
                        generalSection(state: state)
                    case .ai:
                        aiSection(state: state)
                    case .cloud:
                        cloudSection(state: state)
                    case .voice:
                        voiceSection(state: state)
                    case .vision:
                        visionSection(state: state)
                    case .privacy:
                        privacySection(state: state)
                    case .automation:
                        automationSection(state: state)
                    }
                }
                .padding(24)
            }
        }
        .background(Color(hex: "#FFFFFF"))
        .preferredColorScheme(.light)
        .onAppear {
            if let key = KeychainManager.shared.read(account: "openai_api_key") {
                openAIApiKey = key
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
            }
            .environment(appState)
        }
        .sheet(isPresented: $showAuthModal) {
            AuthView()
        }
    }
    
    // 1. General Section
    @ViewBuilder
    private func generalSection(state: AppState) -> some View {
        settingsCard(title: "Activation & Overlay Controls") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Summon Shortcut")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#18181B"))
                        Text("Press Option + Space or fn anywhere to summon the AI assistant.")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(hex: "#71717A"))
                    }
                    Spacer()
                    EchoShortcutBadge(key: state.settings.globalShortcutKey, modifiers: state.settings.globalShortcutModifiers)
                }
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Launch Echo automatically at startup",
                    subtitle: "Starts Echo in the menu bar and background overlay on login.",
                    isOn: Binding(
                        get: { state.settings.launchAtStartup },
                        set: { state.settings.launchAtStartup = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "True Black OLED Overlay Mode",
                    subtitle: "Uses pure deep black specular glass styling for the floating pill.",
                    isOn: Binding(
                        get: { state.settings.trueBlackMode },
                        set: { state.settings.trueBlackMode = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                HStack(spacing: 12) {
                    Button(action: {
                        state.overlayWindowManager.resetToDefaultBottomPosition()
                    }) {
                        Text("Reset Overlay Position to Bottom")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#18181B"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6.5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: "#EDEAE1"))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Text("Replay Welcome Onboarding")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#18181B"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6.5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: "#EDEAE1"))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // 2. AI Section
    @ViewBuilder
    private func aiSection(state: AppState) -> some View {
        settingsCard(title: "AI Provider & Keychain Credentials") {
            VStack(alignment: .leading, spacing: 14) {
                Text("OpenAI API Key (Encrypted in macOS Keychain)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#18181B"))
                
                SecureField("sk-proj-...", text: $openAIApiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                
                HStack {
                    Button(action: {
                        if !openAIApiKey.isEmpty {
                            _ = KeychainManager.shared.save(key: openAIApiKey, account: "openai_api_key")
                            isKeySaved = true
                        }
                    }) {
                        Text("Save Key to Keychain")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: "#18181B"))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    if isKeySaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#10B981"))
                            Text("Saved securely in Keychain")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#10B981"))
                        }
                        .padding(.leading, 8)
                    }
                    
                    Spacer()
                }
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                // OpenAI Neural Voice Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("OpenAI Neural Voice")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#18181B"))
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                try? await OpenAIService.shared.speak(text: "Hello! I am Echo, your conversational AI desktop companion.")
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 10))
                                Text("Test Voice")
                                    .font(.system(size: 11.5, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#18181B"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: "#EDEAE1"))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 6) {
                        ForEach(OpenAIVoice.allCases) { voice in
                            let isSelected = OpenAIService.shared.selectedVoice == voice
                            Button(action: {
                                SoundFeedbackManager.shared.playActivationHaptic()
                                OpenAIService.shared.selectedVoice = voice
                            }) {
                                Text(voice.displayName)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? Color.white : Color(hex: "#52525B"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(isSelected ? Color(hex: "#18181B") : Color(hex: "#EDEAE1"))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                // OpenAI Intelligence Model Selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenAI Vision & Reasoning Model")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#18181B"))
                    
                    HStack(spacing: 8) {
                        ForEach(OpenAIModel.allCases) { model in
                            let isSelected = OpenAIService.shared.selectedModel == model
                            Button(action: {
                                SoundFeedbackManager.shared.playActivationHaptic()
                                OpenAIService.shared.selectedModel = model
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "cpu.fill")
                                        .font(.system(size: 10))
                                    Text(model.rawValue)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                                }
                                .foregroundColor(isSelected ? Color.white : Color(hex: "#52525B"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isSelected ? Color(hex: "#18181B") : Color(hex: "#EDEAE1"))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    // 3. Cloud & Supabase Section
    @ViewBuilder
    private func cloudSection(state: AppState) -> some View {
        settingsCard(title: "Supabase Realtime Cloud Sync & Database") {
            VStack(alignment: .leading, spacing: 14) {
                // User Status Card
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#18181B"))
                            .frame(width: 38, height: 38)
                        Text(SupabaseManager.shared.currentUser?.fullName?.prefix(1) ?? "S")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(SupabaseManager.shared.currentUser?.fullName ?? "Siddhartha")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#18181B"))
                            
                            if SupabaseManager.shared.currentUser?.isAdmin == true {
                                Text("Admin")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#D97706"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "#FEF3C7")))
                            }
                        }
                        
                        Text(SupabaseManager.shared.currentUser?.email ?? "Not logged in")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#71717A"))
                    }
                    
                    Spacer()
                    
                    Button(action: { showAuthModal = true }) {
                        Text(SupabaseManager.shared.isAuthenticated ? "Account Details" : "Sign In")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#18181B"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: "#EDEAE1"))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#F4F4F2"))
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                // Supabase Project Configuration
                VStack(alignment: .leading, spacing: 6) {
                    Text("Supabase Project URL")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                    TextField("https://your-project.supabase.co", text: $supabaseUrl)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12.5, design: .monospaced))
                        .onChange(of: supabaseUrl) { _, val in
                            SupabaseManager.shared.projectURL = val
                        }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Supabase Publishable Anon Key")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                    SecureField("eyJhbGciOiJIUzI1NiIsIn...", text: $supabaseAnonKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12.5, design: .monospaced))
                        .onChange(of: supabaseAnonKey) { _, val in
                            SupabaseManager.shared.anonKey = val
                        }
                }
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                // Realtime Sync Action
                HStack {
                    Button(action: {
                        isSyncing = true
                        Task {
                            try? await SupabaseManager.shared.forceSyncAll(repository: state.repository)
                            isSyncing = false
                        }
                    }) {
                        HStack(spacing: 5) {
                            if isSyncing {
                                ProgressView().controlSize(.small).colorInvert()
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(isSyncing ? "Syncing to Cloud…" : "Force Realtime Cloud Sync")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "#18181B"))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSyncing)
                    
                    if let lastSync = SupabaseManager.shared.lastSyncedAt {
                        Text("Last synced: \(lastSync.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(hex: "#71717A"))
                            .padding(.leading, 8)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // 4. Voice Section
    @ViewBuilder
    private func voiceSection(state: AppState) -> some View {
        settingsCard(title: "Voice Processing & Translation Loop") {
            VStack(alignment: .leading, spacing: 14) {
                settingsToggle(
                    title: "Hands-Free Continuous Dialogue Loop",
                    subtitle: "Keeps listening and responding across multi-turn questions automatically.",
                    isOn: Binding(
                        get: { state.settings.activeConversationHandsFree },
                        set: { state.settings.activeConversationHandsFree = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Microphone Input Enabled",
                    subtitle: "Allows high-fidelity voice dictation and agent commands.",
                    isOn: Binding(
                        get: { state.settings.microphoneEnabled },
                        set: { state.settings.microphoneEnabled = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Auto-Stop Listening on Silence",
                    subtitle: "Automatically processes query when speech pauses for 2 seconds.",
                    isOn: Binding(
                        get: { state.settings.autoStopListening },
                        set: { state.settings.autoStopListening = $0 }
                    )
                )
            }
        }
    }
    
    // 5. Vision Section
    @ViewBuilder
    private func visionSection(state: AppState) -> some View {
        settingsCard(title: "Screen Context & Vision Intelligence") {
            VStack(alignment: .leading, spacing: 14) {
                settingsToggle(
                    title: "Enable On-Demand Screen Understanding",
                    subtitle: "Takes camera shutter snapshots of the active screen (YouTube, VS Code, Safari) when asked.",
                    isOn: Binding(
                        get: { state.settings.screenCaptureEnabled },
                        set: { state.settings.screenCaptureEnabled = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Save analyzed screenshots to History",
                    subtitle: "Attaches screen context thumbnails to your session transcripts for easy review.",
                    isOn: Binding(
                        get: { state.settings.saveScreenshotsToHistory },
                        set: { state.settings.saveScreenshotsToHistory = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 11))
                        Text("Open macOS Screen Recording Permissions")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "#18181B"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(hex: "#EDEAE1"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // 6. Privacy Section
    @ViewBuilder
    private func privacySection(state: AppState) -> some View {
        settingsCard(title: "Privacy & Local Device Storage") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Echo processes all speech waveforms and visual snapshot buffers locally in memory. Keys are protected with Apple Keychain encryption.")
                    .font(.system(size: 12.5))
                    .foregroundColor(Color(hex: "#52525B"))
                    .lineSpacing(2)
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Store History Locally Only",
                    subtitle: "Never syncs conversation history or screen snapshots to external servers.",
                    isOn: Binding(
                        get: { state.settings.localHistoryOnly },
                        set: { state.settings.localHistoryOnly = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                Button(action: {
                    Task {
                        try? await state.repository.deleteAllSessions()
                        ScreenshotStore.shared.clearAllScreenshots()
                    }
                }) {
                    Text("Clear All Local Historical Sessions")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "#FEE2E2"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // 7. Automation Section
    @ViewBuilder
    private func automationSection(state: AppState) -> some View {
        settingsCard(title: "Action Automation & Active Window Insertion") {
            VStack(alignment: .leading, spacing: 14) {
                settingsToggle(
                    title: "Allow Safe Proposed System Actions",
                    subtitle: "Extracts actionable shortcuts, URLs, and commands from responses.",
                    isOn: Binding(
                        get: { state.settings.allowSafeActions },
                        set: { state.settings.allowSafeActions = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Require User Confirmation Before Executing Actions",
                    subtitle: "Presents explicit Run button before opening links or running scripts.",
                    isOn: Binding(
                        get: { state.settings.requireConfirmationForActions },
                        set: { state.settings.requireConfirmationForActions = $0 }
                    )
                )
                
                Divider().background(Color(hex: "#F0F0EE"))
                
                settingsToggle(
                    title: "Automatically Open Suggested URLs (YouTube, Web)",
                    subtitle: "Instantly navigates to best matching links found by the vision agent.",
                    isOn: Binding(
                        get: { state.settings.autoOpenSuggestedLinks },
                        set: { state.settings.autoOpenSuggestedLinks = $0 }
                    )
                )
            }
        }
    }
    
    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2.5) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#18181B"))
                
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(hex: "#71717A"))
            }
            
            Spacer()
            
            EchoToggleSwitch(isOn: isOn)
        }
    }
    
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#18181B"))
            
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "#FAFAFA"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(hex: "#E8E6DF"), lineWidth: 0.75)
                )
        )
    }
}
