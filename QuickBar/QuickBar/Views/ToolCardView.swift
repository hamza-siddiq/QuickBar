import SwiftUI

struct ToolCardButtonStyle: ButtonStyle {
    let tool: QuickBarTool
    let isHovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovering ? 1.03 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ToolBlockView: View {
    let tool: QuickBarTool
    let state: QuickBarState
    let action: () -> Void

    @State private var isHovering = false

    private var badgeText: String? {
        if tool == .noSleep && state.isNoSleepEnabled { return "ON" }
        if tool == .toggleDarkMode && state.isDarkMode { return "ON" }
        if tool == .scheduledShutdown && state.isShutdownScheduled { return "SCHEDULED" }
        return nil
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(tool.accentColor.opacity(isHovering ? 0.18 : 0.10))
                        .frame(width: 32, height: 32)

                    Image(systemName: tool.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(tool.accentColor)
                }

                Text(tool.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(tool.accentColor.opacity(0.85))
                        .clipShape(Capsule())
                } else {
                    Text(tool.description)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHovering ? tool.accentColor.opacity(0.4) : .white.opacity(0.08),
                        lineWidth: isHovering ? 1.0 : 0.5
                    )
            )
            .shadow(color: isHovering ? tool.accentColor.opacity(0.15) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(ToolCardButtonStyle(tool: tool, isHovering: isHovering))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
