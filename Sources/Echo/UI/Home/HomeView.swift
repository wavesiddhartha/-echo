import SwiftUI

public struct HomeView: View {
    @Environment(AppState.self) private var appState
    
    @State private var selectedTab: SidebarTab = .home
    @State private var showSidebar: Bool = true
    @State private var recentSessions: [Session] = []
    @State private var showOnboardingSheet: Bool = false
    @State private var showAuthModal: Bool = false
    
    public enum SidebarTab: String, CaseIterable, Identifiable {
        case home = "Home"
        case services = "Services"
        case history = "History"
        case settings = "Settings"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .home: return "house.fill"
            case .services: return "sparkles"
            case .history: return "clock.arrow.circlepath"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // 1. Editorial Oat / Linen Sidebar
            if showSidebar {
                editorialSidebar
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // 2. Editorial Dual-Tone White Canvas Main Content
            VStack(spacing: 0) {
                topNavigationBar
                Divider().background(Color(hex: "#E8E6DF"))
                mainTabContent
            }
            .background(Color(hex: "#FFFFFF"))
        }
        .frame(minWidth: 960, minHeight: 660)
        .background(Color(hex: "#F7F5EE"))
        .preferredColorScheme(.light)
        .onAppear {
            loadSessions()
            if !appState.settings.hasCompletedOnboarding {
                showOnboardingSheet = true
            }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView {
                showOnboardingSheet = false
            }
            .environment(appState)
        }
        .sheet(isPresented: $showAuthModal) {
            AuthView()
        }
    }
    
    // 1. Editorial Oat / Linen Sidebar (Consistent Warm Linen Highlight Across All Tabs)
    @ViewBuilder
    private var editorialSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Brand Header with Pure Aguafina Script Wordmark (No extra logo icon)
            HStack(spacing: 6) {
                Text("echo")
                    .font(.custom("AguafinaScript-Regular", size: 30))
                    .foregroundColor(Color(hex: "#18181B"))
                    .baselineOffset(-2)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        showSidebar.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#666666"))
                        .padding(5.5)
                        .background(Circle().fill(Color(hex: "#EAE7DF")))
                }
                .buttonStyle(.plain)
                .help("Toggle Sidebar")
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            
            // Creator Profile Card (Opens Supabase Auth Modal)
            Button(action: {
                SoundFeedbackManager.shared.playActivationHaptic()
                showAuthModal = true
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#18181B"))
                            .frame(width: 28, height: 28)
                        
                        Text(SupabaseManager.shared.currentUser?.fullName?.prefix(1) ?? "S")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(SupabaseManager.shared.currentUser?.fullName ?? "Siddhartha")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#18181B"))
                            
                            if SupabaseManager.shared.currentUser?.isAdmin == true {
                                Text("Admin")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(hex: "#D97706"))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1.5)
                                    .background(Capsule().fill(Color(hex: "#FEF3C7")))
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: "#10B981")).frame(width: 5, height: 5)
                            Text(SupabaseManager.shared.isAuthenticated ? "Supabase Synced ☁️" : "Offline Studio")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#EDEAE1"))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            
            // 4 Clean Navigation Items (Unified Warm Linen Highlight Across All Tabs)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(SidebarTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        SoundFeedbackManager.shared.playActivationHaptic()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 20)
                                .foregroundColor(isSelected ? Color(hex: "#18181B") : Color(hex: "#71717A"))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 13.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? Color(hex: "#18181B") : Color(hex: "#3F3F46"))
                            
                            Spacer()
                            
                            if tab == .services {
                                Text("4")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#18181B"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "#E5E1D5")))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8.5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? Color(hex: "#EAE7DF") : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // Floating Overlay Launch Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#18181B"))
                    
                    Text("Always-On Companion")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                }
                
                Text("Summon Echo anywhere with Option + Space or fn key.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .lineSpacing(2)
                
                Button(action: {
                    appState.overlayWindowManager.showOverlay()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Open Overlay")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 7.5)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(hex: "#18181B"))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#EFECE3"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(hex: "#DDD9CC"), lineWidth: 0.75)
                    )
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
        .frame(width: 220)
        .background(Color(hex: "#F7F5EE"))
        .overlay(
            Rectangle()
                .fill(Color(hex: "#E8E6DF"))
                .frame(width: 0.75),
            alignment: .trailing
        )
    }
    
    // Top Navigation Bar
    @ViewBuilder
    private var topNavigationBar: some View {
        HStack {
            if !showSidebar {
                Button(action: {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        showSidebar.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#18181B"))
                        .padding(6)
                        .background(Circle().fill(Color(hex: "#EAE7DF")))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            
            Text(selectedTab.rawValue)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#18181B"))
            
            Spacer()
            
            // Reown-Style Colorful Dock Pills in Header
            HStack(spacing: 6) {
                dockPill(title: "Voice", icon: "mic.fill", color: Color(hex: "#F59E0B")) {
                    Task { await appState.startListeningInteraction() }
                }
                
                dockPill(title: "Vision", icon: "camera.viewfinder", color: Color(hex: "#F97316")) {
                    Task { await appState.triggerDirectVisionAnalysis() }
                }
                
                dockPill(title: "Dictate", icon: "square.and.pencil", color: Color(hex: "#10B981")) {
                    Task { await appState.startPostModeInteraction() }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
    }
    
    private func dockPill(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundFeedbackManager.shared.playSuccessHaptic()
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color))
            .shadow(color: color.opacity(0.30), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // Main Content Router
    @ViewBuilder
    private var mainTabContent: some View {
        switch selectedTab {
        case .home:
            editorialHomeCanvas
        case .services:
            servicesPipelineHub
        case .history:
            HistoryView().environment(appState)
        case .settings:
            SettingsView().environment(appState)
        }
    }
    
    // TAB 1: Colorful Editorial Home Canvas
    @ViewBuilder
    private var editorialHomeCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Editorial Hero Banner (Mailchimp + Pure Maison style)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("ECHO INTELLIGENCE")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#D97706"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: "#FEF3C7")))
                    }
                    
                    Text("Create, dictate & see with natural clarity.")
                        .font(.system(size: 32, weight: .heavy, design: .serif))
                        .foregroundColor(Color(hex: "#18181B"))
                        .lineSpacing(2)
                    
                    Text("Effortlessly speak in Hindi or English, analyze active screens (YouTube, VS Code, Safari), and automatically copy and paste into your frontmost application.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "#52525B"))
                        .lineSpacing(3)
                }
                .padding(26)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E8F0E6"), Color(hex: "#F7F5EE"), Color(hex: "#FFFFFF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                
                // Pallet Ross Fanned Masterpiece Feature Cards Grid
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Core Capabilities")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#18181B"))
                        
                        Spacer()
                        
                        Text("Instant Hardware Accelerated")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Color(hex: "#71717A"))
                    }
                    
                    HStack(spacing: 16) {
                        // 1. Voice Realtime Card (Warm Marigold)
                        colorfulFeatureCard(
                            title: "Voice Dialogue",
                            badge: "Continuous",
                            description: "Hands-free conversational loop with speech-to-speech translation.",
                            gradient: [Color(hex: "#FEF3C7"), Color(hex: "#FDE68A")],
                            badgeBg: Color(hex: "#F59E0B"),
                            buttonBg: Color(hex: "#D97706"),
                            icon: "waveform.badge.mic",
                            actionTitle: "Launch Voice"
                        ) {
                            Task { await appState.startActiveConversation() }
                        }
                        
                        // 2. Screen Vision Card (Coral Orange)
                        colorfulFeatureCard(
                            title: "Screen Vision",
                            badge: "Shutter OCR",
                            description: "Instant context analysis of YouTube, VS Code, Safari, and active windows.",
                            gradient: [Color(hex: "#FFEDD5"), Color(hex: "#FED7AA")],
                            badgeBg: Color(hex: "#F97316"),
                            buttonBg: Color(hex: "#EA580C"),
                            icon: "camera.viewfinder",
                            actionTitle: "Capture Screen"
                        ) {
                            Task { await appState.triggerDirectVisionAnalysis() }
                        }
                        
                        // 3. Smart Dictate Card (Mint Emerald)
                        colorfulFeatureCard(
                            title: "Smart Dictation",
                            badge: "Direct Paste",
                            description: "Multilingual translation & AI polish with instant paste into active app.",
                            gradient: [Color(hex: "#D1FAE5"), Color(hex: "#A7F3D0")],
                            badgeBg: Color(hex: "#10B981"),
                            buttonBg: Color(hex: "#059669"),
                            icon: "square.and.pencil",
                            actionTitle: "Start Dictating"
                        ) {
                            Task { await appState.startPostModeInteraction() }
                        }
                    }
                }
                
                // Activity History Feed
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Activity History")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#18181B"))
                        
                        Spacer()
                        
                        Button(action: {
                            selectedTab = .history
                        }) {
                            Text("See all history →")
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#18181B"))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if recentSessions.isEmpty {
                        Text("No interactions yet. Press Option + Space to begin speaking.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#71717A"))
                            .padding(.vertical, 10)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentSessions.prefix(3)) { session in
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "#F4F4F5"))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "bubble.left.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#18181B"))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.title)
                                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(hex: "#18181B"))
                                        
                                        Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#71717A"))
                                    }
                                    
                                    Spacer()
                                    
                                    if !session.screenshots.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 9))
                                            Text("\(session.screenshots.count) snapshot")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundColor(Color(hex: "#10B981"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color(hex: "#ECFDF5")))
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(hex: "#FAFAFA"))
                                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#E4E4E7"), lineWidth: 0.75))
                                )
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
    }
    
    private func colorfulFeatureCard(
        title: String,
        badge: String,
        description: String,
        gradient: [Color],
        badgeBg: Color,
        buttonBg: Color,
        icon: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#18181B"))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(badge)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(badgeBg))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#18181B"))
                
                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(hex: "#52525B"))
                    .lineSpacing(2)
                    .lineLimit(2)
            }
            
            Spacer()
            
            
            Button(action: {
                SoundFeedbackManager.shared.playSuccessHaptic()
                action()
            }) {
                HStack {
                    Spacer()
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 7.5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(buttonBg)
                )
                .shadow(color: buttonBg.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(height: 175)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
    
    // TAB 2: Services Pipeline Hub
    @ViewBuilder
    private var servicesPipelineHub: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Services & Model Pipelines")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                    
                    Text("Select and trigger specialized AI subsystems on demand.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#71717A"))
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    serviceTile(
                        title: "Echo-Realtime Voice",
                        badge: "Voice Loop",
                        badgeColor: Color(hex: "#F59E0B"),
                        buttonBg: Color(hex: "#D97706"),
                        description: "Continuous hands-free speech conversation with automatic follow-up and native macOS synthesis.",
                        icon: "waveform.badge.mic",
                        buttonText: "Launch Pipeline"
                    ) {
                        Task { await appState.startActiveConversation() }
                    }
                    
                    serviceTile(
                        title: "Echo-Omni Vision",
                        badge: "OCR & Vision",
                        badgeColor: Color(hex: "#F97316"),
                        buttonBg: Color(hex: "#EA580C"),
                        description: "Shutter snapshot analysis understanding active Xcode, VS Code, Safari, YouTube, and Terminal windows.",
                        icon: "camera.viewfinder",
                        buttonText: "Analyze Screen"
                    ) {
                        Task { await appState.triggerDirectVisionAnalysis() }
                    }
                    
                    serviceTile(
                        title: "Echo-Smart Post",
                        badge: "Speech to Text",
                        badgeColor: Color(hex: "#10B981"),
                        buttonBg: Color(hex: "#059669"),
                        description: "Direct speech transcription with AI polish, translation, and instant paste into frontmost applications.",
                        icon: "square.and.pencil",
                        buttonText: "Start Dictating"
                    ) {
                        Task { await appState.startPostModeInteraction() }
                    }
                    
                    serviceTile(
                        title: "Safe Action Planner",
                        badge: "Automation",
                        badgeColor: Color(hex: "#6366F1"),
                        buttonBg: Color(hex: "#4F46E5"),
                        description: "Proposes and runs safe terminal and browser automation actions with explicit user approval.",
                        icon: "bolt.fill",
                        buttonText: "Test Planner"
                    ) {
                        Task { await appState.processVoiceQuery("Open Safari and check docs") }
                    }
                }
            }
            .padding(32)
        }
    }
    
    private func serviceTile(
        title: String,
        badge: String,
        badgeColor: Color,
        buttonBg: Color,
        description: String,
        icon: String,
        buttonText: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#18181B"))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(badge)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(badgeColor))
            }
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#18181B"))
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#52525B"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button(action: {
                SoundFeedbackManager.shared.playSuccessHaptic()
                action()
            }) {
                HStack {
                    Spacer()
                    Text(buttonText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(buttonBg)
                )
                .shadow(color: buttonBg.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(height: 195)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "#FAFAFA"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(hex: "#E4E4E7"), lineWidth: 0.75)
                )
        )
    }
    
    private func loadSessions() {
        Task {
            if let items = try? await appState.repository.fetchSessions() {
                self.recentSessions = items
            }
        }
    }
}
