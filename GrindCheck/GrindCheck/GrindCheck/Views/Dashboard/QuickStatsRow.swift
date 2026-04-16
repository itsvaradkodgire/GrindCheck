import SwiftUI

struct QuickStatsRow: View {
    let todayMinutes: Int
    let todayXP: Int
    let weeklyAvgScore: Double
    let decayingCount: Int

    var body: some View {
        HStack(spacing: 10) {
            StatCell(
                icon: "clock.fill",
                iconColor: AppColors.primary,
                value: todayMinutes.studyTimeFormatted,
                label: "Today"
            )
            StatCell(
                icon: "bolt.fill",
                iconColor: AppColors.secondary,
                value: "\(todayXP) XP",
                label: "Earned"
            )
            StatCell(
                icon: "chart.bar.fill",
                iconColor: AppColors.warning,
                value: weeklyAvgScore > 0 ? weeklyAvgScore.percentFormatted : "--",
                label: "Avg Score"
            )
            StatCell(
                icon: "arrow.down.heart.fill",
                iconColor: decayingCount > 0 ? AppColors.danger : AppColors.muted,
                value: "\(decayingCount)",
                label: "Decaying"
            )
        }
    }
}

// MARK: - Stat Cell

private struct StatCell: View {
    let icon: String
    let iconColor: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: iconColor))

            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: AppColors.neutral))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
    }
}
