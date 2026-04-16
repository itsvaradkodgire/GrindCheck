import SwiftUI

struct RealityCheckCard: View {
    let profile: UserProfile?
    let todayMinutes: Int
    let dailyGoalMinutes: Int
    let currentStreak: Int

    private var message: String {
        BrutalMessages.dailyCheck(
            studyMinutes: todayMinutes,
            goalMinutes: dailyGoalMinutes,
            streak: currentStreak
        )
    }

    private var realityScore: Int { profile?.realityScore ?? 0 }

    private var goalFraction: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(1.0, Double(todayMinutes) / Double(dailyGoalMinutes))
    }

    private var streakIcon: String {
        currentStreak > 0 ? "flame.fill" : "xmark.circle.fill"
    }

    private var streakColor: String {
        currentStreak > 0 ? "#FF6B35" : AppColors.muted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundStyle(Color(hex: AppColors.danger))
                Text("Reality Check")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.danger))
                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: streakIcon)
                        .foregroundStyle(Color(hex: streakColor))
                    Text("\(currentStreak)")
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundStyle(Color(hex: streakColor))
                }
            }

            // Message
            Text(message)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Today's progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                    Spacer()
                    Text("\(todayMinutes.studyTimeFormatted) / \(dailyGoalMinutes.studyTimeFormatted)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(goalFraction >= 1 ? Color(hex: AppColors.success) : Color(hex: AppColors.neutral))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: AppColors.surfaceTertiary))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(goalFraction >= 1
                                  ? LinearGradient(
                                      colors: [Color(hex: AppColors.success), Color(hex: AppColors.success)],
                                      startPoint: .leading, endPoint: .trailing
                                  )
                                  : LinearGradient(
                                      colors: [Color(hex: AppColors.danger), Color(hex: AppColors.warning)],
                                      startPoint: .leading, endPoint: .trailing
                                  )
                            )
                            .frame(width: geo.size.width * goalFraction, height: 6)
                            .animation(.spring(duration: 0.5), value: goalFraction)
                    }
                }
                .frame(height: 6)
            }

            // Reality Score
            HStack {
                Text("Reality Score™")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                Spacer()
                Text("\(realityScore)/100")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: realityScoreColor))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(hex: AppColors.danger).opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var realityScoreColor: String {
        switch realityScore {
        case 0..<30: return AppColors.danger
        case 30..<60: return AppColors.warning
        case 60..<80: return AppColors.secondary
        default:      return AppColors.primary
        }
    }
}
