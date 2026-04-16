import SwiftUI

struct TopicProficiencyBar: View {
    let score: Int   // 0–100
    var showLabel: Bool = true
    var height: CGFloat = 8

    private var confidence: ConfidenceLevel {
        ConfidenceLevel.from(proficiency: score)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabel {
                HStack {
                    Text(confidence.displayName)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color(hex: confidence.colorHex))
                    Spacer()
                    Text("\(score)%")
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundStyle(Color(hex: confidence.colorHex))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color(hex: AppColors.surfaceTertiary))
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color(hex: confidence.colorHex))
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: height)
                        .animation(.spring(duration: 0.5), value: score)
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - Compact Proficiency Badge

struct ProficiencyBadge: View {
    let level: ConfidenceLevel

    var body: some View {
        Text(level.displayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color(hex: level.colorHex))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color(hex: level.colorHex).opacity(0.15))
            )
    }
}
