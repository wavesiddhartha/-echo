import SwiftUI
import AppKit

public struct OverlayView: View {
    @Environment(AppState.self) private var appState
    @State private var isHovered: Bool = false
    @State private var hoveredMode: ModeItem = .voice
    @State private var thinkingPhase: CGFloat = 0.0
    
    public enum ModeItem: String {
        case voice = "Voice fn"
        case post = "Dictate & Post"
        case vision = "Screen Vision"
    }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .center, spacing: isCompact && isHovered ? 6 : (isCompact ? 0 : 8)) {
            // Floating Tooltip Bubble when Hovering Idle Pill
            if isCompact && isHovered {
                floatingTooltipBubble
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Main Overlay Container
            mainOverlayContainer
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.82), value: isHovered)
        .animation(.spring(response: 0.20, dampingFraction: 0.80), value: hoveredMode)
        .animation(.spring(response: 0.25, dampingFraction: 0.84), value: appState.overlayState)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                SoundFeedbackManager.shared.playActivationHaptic()
            }
        }
    }
    
    private var isCompact: Bool {
        if case .idle = appState.overlayState { return true }
        return false
    }
    
    private var targetWidth: CGFloat {
        switch appState.overlayState {
        case .idle:
            return isHovered ? 148 : 72
        case .activating, .listening:
            return 288
        case .processing, .visionAnalysis, .responding, .postMode, .actionSuggestions, .error:
            return Constants.Layout.overlayExpandedWidth
        }
    }
    
    // Floating Tooltip Pill
    @ViewBuilder
    private var floatingTooltipBubble: some View {
        HStack(spacing: 0) {
            Text(tooltipText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4.5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.6)
                )
        )
        .shadow(color: Color.black.opacity(0.40), radius: 8, x: 0, y: 3)
    }
    
    private var tooltipText: String {
        switch hoveredMode {
        case .voice: return "Voice fn"
        case .post: return "Dictate & Post"
        case .vision: return "Screen Vision"
        }
    }
    
    // Main Overlay Container
    @ViewBuilder
    private var mainOverlayContainer: some View {
        VStack(alignment: .leading, spacing: isCompact ? 0 : 10) {
            headerBar
            if !isCompact {
                stateBody
            }
        }
        .padding(.horizontal, isCompact ? (isHovered ? 6 : 8) : 14)
        .padding(.vertical, isCompact ? (isHovered ? 4 : 2) : 12)
        .frame(width: targetWidth)
        .frame(minHeight: isCompact ? 26 : nil)
        .background {
            if isCompact && !isHovered {
                Capsule(style: .continuous)
                    .fill(Color.black)
            } else {
                RoundedRectangle(cornerRadius: isCompact ? 14 : Constants.Layout.overlayCornerRadius, style: .continuous)
                    .fill(Color(hex: "#080808").opacity(0.98))
            }
        }
        .clipShape(
            isCompact && !isHovered
                ? AnyShape(Capsule(style: .continuous))
                : AnyShape(RoundedRectangle(cornerRadius: isCompact ? 14 : Constants.Layout.overlayCornerRadius, style: .continuous))
        )
        .overlay {
            if isCompact && !isHovered {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
            } else {
                RoundedRectangle(cornerRadius: isCompact ? 14 : Constants.Layout.overlayCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)
            }
        }
        .shadow(color: Color.black.opacity(0.40), radius: 14, x: 0, y: 6)
    }
    
    @ViewBuilder
    private var headerBar: some View {
        HStack(spacing: 6) {
            if isCompact {
                if isHovered {
                    hoverModeIconsBar
                } else {
                    figmaAguafinaCapsule
                }
            } else {
                activeHeaderBar
            }
        }
    }
    
    // Resting Pill: Aguafina Script Wordmark
    @ViewBuilder
    private var figmaAguafinaCapsule: some View {
        HStack(spacing: 0) {
            Text("echo")
                .font(.custom("AguafinaScript-Regular", size: 19))
                .foregroundColor(.white)
                .baselineOffset(-1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // Hover Controls: Separate Pills with Green Dot
    @ViewBuilder
    private var hoverModeIconsBar: some View {
        HStack(spacing: 6) {
            Button(action: {
                SoundFeedbackManager.shared.playSuccessHaptic()
                Task { await appState.startListeningInteraction() }
            }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 26)
                    .background(
                        Capsule(style: .continuous)
                            .fill(hoveredMode == .voice ? Color.white.opacity(0.22) : Color(hex: "#222222"))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                    )
            }
            .buttonStyle(.plain)
            .onHover { h in if h { hoveredMode = .voice } }
            
            Button(action: {
                SoundFeedbackManager.shared.playSuccessHaptic()
                Task { await appState.startPostModeInteraction() }
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 26)
                    .background(
                        Capsule(style: .continuous)
                            .fill(hoveredMode == .post ? Color.white.opacity(0.22) : Color(hex: "#222222"))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                    )
            }
            .buttonStyle(.plain)
            .onHover { h in if h { hoveredMode = .post } }
            
            Button(action: {
                SoundFeedbackManager.shared.playSuccessHaptic()
                Task { await appState.triggerDirectVisionAnalysis() }
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "circle.circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(hoveredMode == .vision ? Color.white.opacity(0.22) : Color(hex: "#222222"))
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                        )
                    
                    Circle()
                        .fill(Color(hex: "#5FD2B5"))
                        .frame(width: 4.5, height: 4.5)
                        .offset(x: 1, y: -1)
                }
            }
            .buttonStyle(.plain)
            .onHover { h in if h { hoveredMode = .vision } }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // Active Header Bar for Recording / Responding
    @ViewBuilder
    private var activeHeaderBar: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 20, height: 20)
                
                Image(systemName: iconForState(appState.overlayState))
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(statusTitle)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if appState.isActiveConversationActive {
                HStack(spacing: 3.5) {
                    Circle()
                        .fill(EchoTheme.statusActive)
                        .frame(width: 4, height: 4)
                    Text("Active")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(EchoTheme.statusActive)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(EchoTheme.statusActive.opacity(0.16)))
            }
            
            Spacer()
            
            if case .listening = appState.overlayState {
                EchoWaveformView(isListening: true)
            }
            
            Button(action: {
                SoundFeedbackManager.shared.playActivationHaptic()
                appState.overlayWindowManager.collapseToIdle()
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.75))
                    .padding(4.5)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Collapse to idle pill")
        }
    }
    
    @ViewBuilder
    private var stateBody: some View {
        switch appState.overlayState {
        case .idle:
            EmptyView()
            
        case .activating:
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                Text("Listening for speech…")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.white.opacity(0.85))
            }
            .padding(.top, 1)
            
        case .listening(let transcript):
            VStack(alignment: .leading, spacing: 4) {
                if !transcript.isEmpty {
                    Text(transcript)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white)
                        .padding(.top, 1)
                } else {
                    Text("Speak naturally or ask about your screen…")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            
        case .postMode(let transcript, let isPolished):
            postModeView(transcript: transcript, isPolished: isPolished)
            
        case .processing:
            thinkingAnimationView
            
        case .visionAnalysis(let step):
            visionAnalysisAnimationView(step: step)
            
        case .responding(let content):
            respondingView(content: content)
            
        case .actionSuggestions(let actions):
            actionSuggestionsView(actions: actions)
            
        case .error(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9.5))
                    .foregroundColor(EchoTheme.statusError)
                Text(message)
                    .font(.system(size: 11.5))
                    .foregroundColor(EchoTheme.statusError)
            }
        }
    }
    
    @ViewBuilder
    private var thinkingAnimationView: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 13, height: 13)
                
                Circle()
                    .trim(from: 0, to: 0.65)
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: 13, height: 13)
                    .rotationEffect(.degrees(thinkingPhase * 360))
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    thinkingPhase = 1.0
                }
            }
            
            Text("Thinking & synthesizing response…")
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.9))
            
            Spacer()
        }
        .padding(.vertical, 1)
    }
    
    @ViewBuilder
    private func visionAnalysisAnimationView(step: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(EchoTheme.statusActive)
                
                Text(step.isEmpty ? "Analyzing screen context…" : step)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white)
                
                Spacer()
                
                ProgressView()
                    .controlSize(.mini)
                    .colorInvert()
            }
            
            if let preview = appState.lastScreenCapturePreview {
                screenshotPreviewBadge(preview: preview)
            }
        }
        .padding(.vertical, 1)
    }
    
    @ViewBuilder
    private func screenshotPreviewBadge(preview: (appName: String, imagePath: String)) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "camera.fill")
                .font(.system(size: 8.5))
                .foregroundColor(Color(hex: "#5FD2B5"))
            
            Text(preview.appName)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.9))
        }
        .padding(.horizontal, 7.5)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        )
    }
    
    // Redesigned Post Mode Card (No Double-Boxes, Clean Unified Actions)
    @ViewBuilder
    private func postModeView(transcript: String, isPolished: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if transcript.isEmpty {
                HStack(spacing: 8) {
                    EchoWaveformView(isListening: true)
                    Text("Dictating speech for active application…")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .padding(.vertical, 4)
            } else {
                Text(transcript)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Refined Bottom Action Controls Row
                HStack(spacing: 6) {
                    // [ 📥 Insert into App ]
                    refinedGlassButton(title: "Insert into App", icon: "arrow.down.doc.fill", isPrimary: true) {
                        Task { await appState.pasteCurrentPost(text: transcript) }
                    }
                    
                    // [ ✨ Polish ]
                    if !isPolished {
                        refinedGlassButton(title: "Polish", icon: "sparkles") {
                            Task { await appState.polishCurrentPost(text: transcript) }
                        }
                    }
                    
                    // [ 📋 Copy ]
                    refinedGlassButton(title: "Copy", icon: "doc.on.doc") {
                        appState.copyCurrentPost(text: transcript)
                    }
                    
                    Spacer()
                    
                    // Dictate More Button
                    Button(action: {
                        Task { await appState.startPostModeInteraction() }
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.10))
                                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Dictate More")
                }
                .padding(.top, 2)
            }
        }
    }
    
    // Redesigned Vision / Responding Card
    @ViewBuilder
    private func respondingView(content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let preview = appState.lastScreenCapturePreview {
                screenshotPreviewBadge(preview: preview)
            }
            
            Text(content)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                if TextToSpeechManager.shared.isSpeaking {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 8.5))
                            .foregroundColor(Color(hex: "#5FD2B5"))
                        Text("Speaking")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                }
                
                Spacer()
                
                if appState.isActiveConversationActive {
                    refinedGlassButton(title: "End Session", icon: "stop.circle.fill") {
                        appState.stopActiveConversation()
                    }
                } else {
                    refinedGlassButton(title: "Follow up", icon: "mic.fill", isPrimary: true) {
                        Task { await appState.startListeningInteraction() }
                    }
                }
            }
            .padding(.top, 2)
        }
    }
    
    private func refinedGlassButton(
        title: String,
        icon: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            SoundFeedbackManager.shared.playSuccessHaptic()
            action()
        }) {
            HStack(spacing: 4.5) {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(isPrimary ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(isPrimary ? 0.25 : 0.12), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func actionSuggestionsView(actions: [UserAction]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(actions) { action in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(action.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white)
                        Text(action.payload)
                            .font(.system(size: 9))
                            .foregroundColor(Color.white.opacity(0.60))
                            .lineLimit(1)
                    }
                    Spacer()
                    EchoActionButton(title: "Run", icon: "arrow.up.right", isPrimary: true) {
                        Task {
                            await appState.executeAction(action)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5.5)
                .background(
                    RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                        )
                )
            }
        }
    }
    
    private var statusTitle: String {
        switch appState.overlayState {
        case .idle: return "Echo"
        case .activating: return "Waking up…"
        case .listening: return "Listening"
        case .postMode: return "Post Mode"
        case .processing: return "Thinking"
        case .visionAnalysis: return "Looking at Screen"
        case .responding: return "Echo"
        case .actionSuggestions: return "Suggested Action"
        case .error: return "Notice"
        }
    }
    
    private func iconForState(_ state: OverlayState) -> String {
        switch state {
        case .idle: return "sparkle"
        case .activating: return "waveform"
        case .listening: return "waveform.badge.mic"
        case .postMode: return "square.and.pencil"
        case .processing: return "brain"
        case .visionAnalysis: return "macwindow.viewfinder"
        case .responding: return "bubble.left.fill"
        case .actionSuggestions: return "bolt.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}
