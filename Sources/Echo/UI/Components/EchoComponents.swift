import SwiftUI
import AppKit

public struct EchoStatusBadge: View {
    public let title: String
    public let color: Color
    
    public init(title: String, color: Color) {
        self.title = title
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .shadow(color: color.opacity(0.6), radius: 2)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#18181B"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "#EDEAE1"))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color(hex: "#DDD9CC"), lineWidth: 0.75)
                )
        )
    }
}

// High-Contrast Shortcut Badge (Light & Dark Theme Safe)
public struct EchoShortcutBadge: View {
    public let key: String
    public let modifiers: [String]
    
    public init(key: String, modifiers: [String]) {
        self.key = key
        self.modifiers = modifiers
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            ForEach(modifiers, id: \.self) { mod in
                keyCap(mod)
            }
            keyCap(key)
        }
    }
    
    private func keyCap(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Color(hex: "#18181B"))
            .padding(.horizontal, 6.5)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(hex: "#EDEAE1"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color(hex: "#D4D0C5"), lineWidth: 0.8)
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
    }
}

// Custom High-Visibility Tactile Toggle Switch
public struct EchoToggleSwitch: View {
    @Binding public var isOn: Bool
    
    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    public var body: some View {
        Button(action: {
            SoundFeedbackManager.shared.playActivationHaptic()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn ? Color(hex: "#18181B") : Color(hex: "#E4E4E7"))
                    .frame(width: 44, height: 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isOn ? Color.clear : Color(hex: "#D4D4D8"), lineWidth: 0.8)
                    )
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1.5)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct EchoActionButton: View {
    public let title: String
    public var icon: String? = nil
    public var isPrimary: Bool = false
    public var action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    public init(title: String, icon: String? = nil, isPrimary: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isPrimary = isPrimary
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            SoundFeedbackManager.shared.playSuccessHaptic()
            action()
        }) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isPrimary ? Color.black : Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5.5)
            .background(
                RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius, style: .continuous)
                    .fill(isPrimary ? AnyShapeStyle(Color.white) : (isHovered ? AnyShapeStyle(Color.white.opacity(0.18)) : AnyShapeStyle(Color.white.opacity(0.10))))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius, style: .continuous)
                            .strokeBorder(isPrimary ? AnyShapeStyle(Color.clear) : AnyShapeStyle(Color.white.opacity(0.16)), lineWidth: 0.6)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
            .animation(.spring(response: 0.16, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Apple-Grade Fluid Sinusoidal Waveform Animation
public struct EchoWaveformView: View {
    public var isListening: Bool
    
    @State private var phase: Double = 0.0
    
    public init(isListening: Bool) {
        self.isListening = isListening
    }
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5) {
                ForEach(0..<7) { index in
                    let barHeight = computeHeight(index: index, time: time)
                    
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.4), location: 0.0),
                                    .init(color: Color.white, location: 0.5),
                                    .init(color: Color.white.opacity(0.4), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.2, height: barHeight)
                        .shadow(color: Color.white.opacity(isListening ? 0.35 : 0.0), radius: 2)
                }
            }
        }
        .frame(height: 16)
    }
    
    private func computeHeight(index: Int, time: Double) -> CGFloat {
        guard isListening else { return 3.5 }
        
        let speed = 4.2
        let offset = Double(index) * 0.75
        let sine = sin(time * speed + offset)
        let normalized = (sine + 1.0) / 2.0
        
        let centerDist = abs(Double(index) - 3.0) / 3.0
        let envelope = 1.0 - (centerDist * 0.45)
        
        let minHeight: CGFloat = 4.0
        let maxHeight: CGFloat = 15.0
        return minHeight + CGFloat(normalized * envelope) * (maxHeight - minHeight)
    }
}
