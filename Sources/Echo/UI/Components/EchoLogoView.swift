import SwiftUI

public struct EchoLogoView: View {
    public var size: CGFloat = 40
    public var showBackground: Bool = true
    
    public init(size: CGFloat = 40, showBackground: Bool = true) {
        self.size = size
        self.showBackground = showBackground
    }
    
    public var body: some View {
        ZStack {
            if showBackground {
                // Obsidian App Icon Container
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(EchoTheme.trueBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                            .strokeBorder(EchoTheme.topHighlightGradient, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: size * 0.15, x: 0, y: size * 0.08)
            }
            
            // Clean Precision Waveform Bars
            HStack(spacing: size * 0.06) {
                bar(heightRatio: 0.35)
                bar(heightRatio: 0.62)
                bar(heightRatio: 0.95)
                bar(heightRatio: 0.62)
                bar(heightRatio: 0.35)
            }
            .frame(width: size * 0.65, height: size * 0.65)
        }
        .frame(width: size, height: size)
    }
    
    private func bar(heightRatio: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(white: 0.88),
                        Color(white: 0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.07, height: size * 0.55 * heightRatio)
    }
}
