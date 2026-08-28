import SwiftUI

@main
struct EchoApp: App {
    @State private var appState: AppState
    
    init() {
        FontManager.shared.registerCustomFonts()
        self._appState = State(initialValue: AppState())
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 880, height: 600)
        
        Settings {
            SettingsView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
