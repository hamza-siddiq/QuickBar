import SwiftUI

struct SystemBarView: View {
    let label: String
    let used: Double
    let total: Double
    let extra: String?
    let percent: Double

    init(label: String, used: Double, total: Double, percent: Double, extra: String? = nil) {
        self.label = label
        self.used = used
        self.total = total
        self.percent = percent
        self.extra = extra
    }

    private var barColors: [Color] {
        if percent < 60 {
            return [.green, .green.opacity(0.8)]
        } else if percent < 80 {
            return [.yellow, .orange]
        } else {
            return [.orange, .red]
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))

                Spacer()

                Text("\(used, specifier: "%.1f") / \(total, specifier: "%.0f") GB")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)

                if let extra {
                    Text(extra)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.10))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: barColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * CGFloat(min(percent, 100) / 100)))
                }
            }
            .frame(height: 4)
        }
    }
}
