import SwiftUI

struct ToolBlockView: View {
    let tool: QuickMacTool
    let state: QuickMacState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(tool.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if tool == .noSleep && state.isNoSleepEnabled {
                    Text("ON")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(nsColor: .separatorColor).opacity(0.4))
                        .clipShape(Capsule())
                }

                if tool == .scheduledShutdown && state.isShutdownScheduled {
                    Text("SCHEDULED")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(nsColor: .separatorColor).opacity(0.4))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
        )
    }
}
