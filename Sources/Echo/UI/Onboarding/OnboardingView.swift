import SwiftUI

public struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep: Int = 0
    public var onComplete: () -> Void
    
    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Step Indicators
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    Capsule()
                        .fill(currentStep >= index ? EchoTheme.accent : EchoTheme.surfaceSecondary)
                        .frame(width: currentStep == index ? 24 : 8, height: 4)
                        .animation(.spring(response: 0.25), value: currentStep)
                }
            }
            .padding(.top, 12)
            
            Spacer()
            
            // Step Content
            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                microphoneStep
            case 2:
                screenRecordingStep
            case 3:
                shortcutStep
            default:
                EmptyView()
            }
            
            Spacer()
            
            // Footer Navigation
            HStack {
                if currentStep > 0 {
                    EchoActionButton(title: "Back") {
                        withAnimation { currentStep -= 1 }
                    }
                }
                
                Spacer()
                
                if currentStep < 3 {
                    EchoActionButton(title: "Continue", isPrimary: true) {
                        withAnimation { currentStep += 1 }
                    }
                } else {
                    EchoActionButton(title: "Get Started with Echo", isPrimary: true) {
                        appState.settings.hasCompletedOnboarding = true
                        onComplete()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .padding(24)
        .frame(width: 520, height: 440)
        .background(EchoTheme.backgroundObsidian)
    }
    
    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: 16) {
            EchoLogoView(size: 64, showBackground: true)
            
            Text("Welcome to Echo")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(EchoTheme.textPrimary)
            
            Text("Your native macOS AI voice & vision overlay assistant. Lives above your apps to explain screens, answer questions, and perform actions seamlessly.")
                .font(.system(size: 13))
                .foregroundColor(EchoTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var microphoneStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(EchoTheme.surfaceSecondary).frame(width: 60, height: 60)
                Image(systemName: "mic.fill").font(.system(size: 26)).foregroundColor(EchoTheme.accent)
            }
            
            Text("Voice Mode Permission")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(EchoTheme.textPrimary)
            
            Text("Echo listens only when you explicitly activate it with your global shortcut. Audio is processed on-device for maximum privacy.")
                .font(.system(size: 12))
                .foregroundColor(EchoTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            EchoActionButton(
                title: appState.permissionManager.microphoneStatus == .authorized ? "Microphone Authorized ✓" : "Allow Microphone Access",
                icon: "mic.badge.plus",
                isPrimary: appState.permissionManager.microphoneStatus != .authorized
            ) {
                Task {
                    _ = await appState.permissionManager.requestMicrophoneAccess()
                }
            }
        }
    }
    
    @ViewBuilder
    private var screenRecordingStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(EchoTheme.surfaceSecondary).frame(width: 60, height: 60)
                Image(systemName: "macwindow.viewfinder").font(.system(size: 26)).foregroundColor(EchoTheme.statusActive)
            }
            
            Text("On-Demand Screen Understanding")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(EchoTheme.textPrimary)
            
            Text("Echo never records or continuously monitors your screen. It takes a single screenshot only when you specifically ask 'What's on my screen?'.")
                .font(.system(size: 12))
                .foregroundColor(EchoTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            EchoActionButton(
                title: appState.permissionManager.screenRecordingStatus == .authorized ? "Screen Capture Authorized ✓" : "Enable Screen Understanding",
                icon: "camera.badge.ellipsis",
                isPrimary: appState.permissionManager.screenRecordingStatus != .authorized
            ) {
                appState.permissionManager.requestScreenRecordingAccess()
            }
        }
    }
    
    @ViewBuilder
    private var shortcutStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(EchoTheme.surfaceSecondary).frame(width: 60, height: 60)
                Image(systemName: "keyboard.fill").font(.system(size: 26)).foregroundColor(EchoTheme.accent)
            }
            
            Text("Activate Anywhere")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(EchoTheme.textPrimary)
            
            Text("Whenever you need assistance in Safari, Chrome, YouTube, PDFs, or VS Code, simply press your activation shortcut:")
                .font(.system(size: 12))
                .foregroundColor(EchoTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            EchoShortcutBadge(key: "Space", modifiers: ["⌥ Option"])
                .scaleEffect(1.2)
                .padding(.vertical, 8)
        }
    }
}
