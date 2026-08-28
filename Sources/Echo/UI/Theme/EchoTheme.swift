import SwiftUI

public enum EchoTheme {
    // True Black & Apple Glass Obsidian
    public static let trueBlack = Color(hex: "#000000")
    public static let backgroundObsidian = Color(hex: "#000000")
    public static let surfacePrimary = Color(hex: "#080808")
    public static let surfaceSecondary = Color.white.opacity(0.12)
    public static let surfaceTertiary = Color.white.opacity(0.06)
    public static let surfaceElevated = Color.white.opacity(0.18)
    
    // Pure Crisp White Apple Typography & Icons
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.86)
    public static let textTertiary = Color.white.opacity(0.60)
    public static let textQuaternary = Color.white.opacity(0.38)
    
    // Apple Monochrome & Ambient Accents
    public static let accent = Color.white
    public static let accentMuted = Color.white.opacity(0.75)
    public static let visionAccent = Color.white
    
    // Gradients
    public static let accentGradient = LinearGradient(
        colors: [Color.white, Color.white.opacity(0.80)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let topHighlightGradient = LinearGradient(
        colors: [Color.white.opacity(0.32), Color.white.opacity(0.06)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Status (Apple System Colors)
    public static let statusActive = Color(hex: "#34C759") // Apple Emerald
    public static let statusWarning = Color(hex: "#FF9F0A")
    public static let statusError = Color(hex: "#FF453A")
    
    // Apple Dynamic Island Specular Rim Gradient
    public static let subtleBorderGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.32), location: 0.0),
            .init(color: Color.white.opacity(0.14), location: 0.35),
            .init(color: Color.white.opacity(0.05), location: 0.70),
            .init(color: Color.white.opacity(0.02), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public struct EchoOverlayBackground: ViewModifier {
    public var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = Constants.Layout.overlayCornerRadius) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Deep OLED Obsidian Base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(hex: "#040404").opacity(0.96))
                    
                    // Apple VisionOS Ultra-Thin Material Frosted Glass
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.40))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(EchoTheme.subtleBorderGradient, lineWidth: 0.8)
            }
            // Multi-Layered Natural Apple Ambient Shadow
            .shadow(color: Color.black.opacity(0.48), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.24), radius: 6, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
    }
}

public struct EchoCardBackground: ViewModifier {
    public var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = Constants.Layout.cardCornerRadius) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(hex: "#0C0C0C").opacity(0.96))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.75)
            }
    }
}

public extension View {
    func echoOverlayBackground(cornerRadius: CGFloat = Constants.Layout.overlayCornerRadius) -> some View {
        modifier(EchoOverlayBackground(cornerRadius: cornerRadius))
    }
    
    func echoCardBackground(cornerRadius: CGFloat = Constants.Layout.cardCornerRadius) -> some View {
        modifier(EchoCardBackground(cornerRadius: cornerRadius))
    }
}
