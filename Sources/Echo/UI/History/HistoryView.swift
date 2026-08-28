import SwiftUI

public struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessions: [Session] = []
    @State private var selectedSession: Session?
    @State private var searchQuery: String = ""
    @State private var selectedFilter: HistoryFilter = .all
    @State private var isLoading: Bool = true
    @State private var copiedSessionId: UUID? = nil
    
    public enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case voice = "Voice"
        case vision = "Screen Vision"
        case notes = "Notes & Resources"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var filteredSessions: [Session] {
        sessions.filter { session in
            let matchesSearch = searchQuery.isEmpty ||
                session.title.localizedCaseInsensitiveContains(searchQuery) ||
                session.messages.contains { $0.content.localizedCaseInsensitiveContains(searchQuery) }
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .voice:
                matchesFilter = !session.messages.isEmpty && session.screenshots.isEmpty
            case .vision:
                matchesFilter = !session.screenshots.isEmpty
            case .notes:
                matchesFilter = session.title.localizedCaseInsensitiveContains("Note") ||
                    session.title.localizedCaseInsensitiveContains("Schedule") ||
                    session.title.localizedCaseInsensitiveContains("Post") ||
                    session.title.localizedCaseInsensitiveContains("YouTube")
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left History Master Sidebar List
            VStack(spacing: 12) {
                // High-Contrast Search & Filter Header
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#18181B"))
                            
                            TextField("Search past interactions, code, notes…", text: $searchQuery)
                                .font(.system(size: 12.5, design: .rounded))
                                .textFieldStyle(.plain)
                                .foregroundColor(Color(hex: "#18181B"))
                            
                            if !searchQuery.isEmpty {
                                Button(action: { searchQuery = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "#71717A"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color(hex: "#DDD9CC"), lineWidth: 0.8)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                        
                        Button(action: {
                            Task {
                                try? await appState.repository.deleteAllSessions()
                                ScreenshotStore.shared.clearAllScreenshots()
                                await loadSessions()
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(Color(hex: "#71717A"))
                                .padding(8)
                                .background(Circle().fill(Color(hex: "#EDEAE1")))
                        }
                        .buttonStyle(.plain)
                        .help("Clear All History")
                    }
                    
                    // Filter Chips Bar
                    HStack(spacing: 5) {
                        ForEach(HistoryFilter.allCases) { filter in
                            let isSelected = selectedFilter == filter
                            Button(action: {
                                SoundFeedbackManager.shared.playActivationHaptic()
                                selectedFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? Color.white : Color(hex: "#52525B"))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4.5)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(isSelected ? Color(hex: "#18181B") : Color(hex: "#EDEAE1"))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Divider().background(Color(hex: "#E8E6DF"))
                
                // Session List
                if isLoading {
                    Spacer()
                    ProgressView().controlSize(.small)
                    Spacer()
                } else if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#A1A1AA"))
                        Text("No interactions recorded")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#71717A"))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 5) {
                            ForEach(filteredSessions) { session in
                                sessionRow(session)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 14)
                    }
                }
            }
            .frame(width: 290)
            .background(Color(hex: "#F7F5EE"))
            .overlay(
                Rectangle().fill(Color(hex: "#E8E6DF")).frame(width: 0.75),
                alignment: .trailing
            )
            
            // Right Session Intelligence Dashboard
            VStack(spacing: 0) {
                if let session = selectedSession {
                    sessionDashboardView(session)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 38))
                            .foregroundColor(Color(hex: "#D4D4D8"))
                        
                        Text("Select an interaction to view full intelligence log & resources")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#71717A"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .task {
            await loadSessions()
        }
    }
    
    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        let isSelected = selectedSession?.id == session.id
        Button(action: {
            selectedSession = session
        }) {
            HStack(spacing: 9) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "#18181B") : Color(hex: "#EDEAE1"))
                        .frame(width: 28, height: 28)
                    Image(systemName: iconForSession(session))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color(hex: "#18181B"))
                }
                
                VStack(alignment: .leading, spacing: 2.5) {
                    Text(session.title)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                        .lineLimit(1)
                    
                    HStack {
                        Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10.5))
                            .foregroundColor(Color(hex: "#71717A"))
                        
                        Spacer()
                        
                        if !session.screenshots.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 8))
                                Text("\(session.screenshots.count)")
                                    .font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#059669"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color(hex: "#D1FAE5")))
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color(hex: "#EAE7DF") : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // Right Session Detail Dashboard Canvas
    @ViewBuilder
    private func sessionDashboardView(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dashboard Header Banner
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#18181B"))
                    
                    HStack(spacing: 8) {
                        Text("\(session.messages.count) turns")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Color(hex: "#71717A"))
                        
                        Text("•")
                            .foregroundColor(Color(hex: "#A1A1AA"))
                        
                        Text(session.createdAt.formatted(date: .long, time: .shortened))
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(hex: "#71717A"))
                        
                        Text("•")
                            .foregroundColor(Color(hex: "#A1A1AA"))
                        
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9))
                            Text("OpenAI GPT-4o")
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#D97706"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "#FEF3C7")))
                        
                        HStack(spacing: 3) {
                            Image(systemName: "icloud.fill")
                                .font(.system(size: 9.5))
                            Text("Supabase Cloud")
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#059669"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "#D1FAE5")))
                    }
                }
                
                Spacer()
                
                // Header Action Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            try? await SupabaseManager.shared.syncSessionToCloud(session)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Sync")
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#18181B"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "#EDEAE1"))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        copyTranscript(session)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: copiedSessionId == session.id ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10.5, weight: .bold))
                            Text(copiedSessionId == session.id ? "Copied" : "Copy")
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#18181B"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "#EDEAE1"))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        Task {
                            try? await appState.repository.deleteSession(byId: session.id)
                            selectedSession = nil
                            await loadSessions()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10.5))
                            Text("Delete")
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "#FEE2E2"))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(Color.white)
            
            Divider().background(Color(hex: "#E8E6DF"))
            
            // Conversation & Intelligence Stream
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(session.messages) { message in
                        messageBubble(message)
                    }
                }
                .padding(24)
            }
        }
    }
    
    @ViewBuilder
    private func messageBubble(_ message: Message) -> some View {
        let isUser = message.role == .user
        let extractedLinks = extractURLs(from: message.content)
        
        HStack(alignment: .top) {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 7) {
                // Header badge
                HStack(spacing: 5) {
                    Image(systemName: isUser ? "person.fill" : "sparkles")
                        .font(.system(size: 9.5))
                    Text(isUser ? "You" : "Echo Intelligence (GPT-4o)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(isUser ? Color(hex: "#71717A") : Color(hex: "#D97706"))
                
                // Bubble Content
                VStack(alignment: .leading, spacing: 10) {
                    Text(message.content)
                        .font(.system(size: 13.5, weight: .regular))
                        .foregroundColor(isUser ? .white : Color(hex: "#18181B"))
                        .lineSpacing(3.5)
                    
                    // Extracted Resource Links
                    if !isUser && !extractedLinks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Resources & Links:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#71717A"))
                            
                            ForEach(extractedLinks, id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    Button(action: {
                                        NSWorkspace.shared.open(url)
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "link")
                                                .font(.system(size: 10, weight: .bold))
                                            Text(urlString)
                                                .font(.system(size: 11.5, weight: .semibold))
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                        .foregroundColor(Color(hex: "#2563EB"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(Color(hex: "#EFF6FF"))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isUser ? Color(hex: "#18181B") : Color(hex: "#F4F4F5"))
                        .overlay(
                            isUser ? nil :
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(hex: "#E4E4E7"), lineWidth: 0.75)
                        )
                )
                
                // Timestamp and Actions
                HStack(spacing: 8) {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "#A1A1AA"))
                    
                    if !isUser {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.content, forType: .string)
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9))
                                Text("Copy Text")
                                    .font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#71717A"))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            Task {
                                try? await OpenAIService.shared.speak(text: message.content)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 9))
                                Text("Speak Aloud")
                                    .font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "#71717A"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isUser { Spacer() }
        }
    }
    
    private func extractURLs(from text: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
    
    private func iconForSession(_ session: Session) -> String {
        if !session.screenshots.isEmpty {
            return "camera.viewfinder"
        }
        let lower = session.title.lowercased()
        if lower.contains("note") { return "note.text" }
        if lower.contains("schedule") || lower.contains("meeting") { return "calendar" }
        if lower.contains("post") || lower.contains("dictate") { return "square.and.pencil" }
        if lower.contains("youtube") || lower.contains("search") { return "magnifyingglass" }
        return "waveform"
    }
    
    private func copyTranscript(_ session: Session) {
        let transcript = session.messages.map { "\($0.role == .user ? "User" : "Echo"): \($0.content)" }.joined(separator: "\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcript, forType: .string)
        copiedSessionId = session.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if copiedSessionId == session.id {
                copiedSessionId = nil
            }
        }
    }
    
    private func loadSessions() async {
        isLoading = true
        if let items = try? await appState.repository.fetchSessions() {
            self.sessions = items
            if selectedSession == nil {
                selectedSession = items.first
            }
        }
        isLoading = false
    }
}
