import SwiftUI

struct WeeklyDebriefCard: View {
    let xpThisWeek:   Int
    let xpLastWeek:   Int
    let studyMinutes: Int
    let quizzesTaken: Int
    let topicsStudied: Int
    let streak:       Int

    private var xpDelta: Int { xpThisWeek - xpLastWeek }
    private var deltaColor: String { xpDelta >= 0 ? AppColors.success : AppColors.danger }
    private var deltaIcon: String  { xpDelta >= 0 ? "arrow.up.right" : "arrow.down.right" }

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: AppColors.primary).opacity(0.08), .clear],
                startPoint: .top, endPoint: .center
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Text("WEEKLY DEBRIEF")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: AppColors.muted))
                            .tracking(3)

                        Text("Last 7 Days")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                    }

                    // XP highlight
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(xpThisWeek)")
                                .font(.system(size: 52, weight: .black, design: .monospaced))
                                .foregroundStyle(Color(hex: AppColors.primary))

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 3) {
                                    Image(systemName: deltaIcon)
                                        .font(.system(size: 11, weight: .bold))
                                    Text("\(abs(xpDelta)) vs last week")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(Color(hex: deltaColor))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: deltaColor).opacity(0.15)))

                                Text("XP earned")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: AppColors.muted))
                            }
                            .padding(.bottom, 8)
                        }
                    }

                    // Stats grid
                    HStack(spacing: 12) {
                        weekStatCell(
                            value: studyMinutes.studyTimeFormatted,
                            label: "Studied",
                            icon: "clock.fill",
                            color: AppColors.secondary
                        )
                        weekStatCell(
                            value: "\(quizzesTaken)",
                            label: "Quizzes",
                            icon: "checkmark.circle.fill",
                            color: AppColors.success
                        )
                        weekStatCell(
                            value: "\(topicsStudied)",
                            label: "Topics",
                            icon: "tag.fill",
                            color: AppColors.warning
                        )
                        weekStatCell(
                            value: "\(streak)🔥",
                            label: "Streak",
                            icon: "flame.fill",
                            color: AppColors.danger
                        )
                    }

                    // Motivational line
                    Text(motivationalLine)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Swipe up for the feed →")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(.bottom, 100)
            }
        }
    }

    private func weekStatCell(value: String, label: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    private var motivationalLine: String {
        if xpThisWeek == 0 { return "Radio silence this week. That's a choice." }
        if xpDelta > 200   { return "You leveled up the grind. Keep that energy." }
        if xpDelta > 0     { return "Up from last week. Compounding." }
        if xpDelta == 0    { return "Same as last week. Consistent — but push harder." }
        return "Down from last week. Identify what broke the rhythm."
    }
}
