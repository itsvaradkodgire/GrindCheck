import SwiftUI
import SwiftData

// MARK: - Study Heatmap (GitHub-style, last 16 weeks)

struct StudyHeatmapView: View {

    let logs: [DailyLog]
    let weeks: Int = 16

    private var logByDate: [Date: DailyLog] {
        Dictionary(uniqueKeysWithValues: logs.map {
            (Calendar.current.startOfDay(for: $0.date), $0)
        })
    }

    private var cells: [[Date]] {
        // Build 16 weeks × 7 days grid, ending today
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Pad to start on Sunday
        let weekday = cal.component(.weekday, from: today) - 1  // 0=Sun
        let totalDays = weeks * 7
        let startDate = cal.date(byAdding: .day, value: -(totalDays - 1 + weekday), to: today)!

        var grid: [[Date]] = Array(repeating: [], count: weeks)
        for w in 0..<weeks {
            for d in 0..<7 {
                let day = cal.date(byAdding: .day, value: w * 7 + d, to: startDate)!
                grid[w].append(day)
            }
        }
        return grid
    }

    private var totalMinutesLast16Weeks: Int {
        cells.flatMap { $0 }.compactMap { logByDate[$0]?.totalStudyMinutes }.reduce(0, +)
    }

    private var activeDaysLast16Weeks: Int {
        cells.flatMap { $0 }.filter { (logByDate[$0]?.totalStudyMinutes ?? 0) > 0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Study Activity", systemImage: "calendar.badge.checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.primary))
                Spacer()
                Text("\(activeDaysLast16Weeks) active days")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.muted))
            }

            // Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    // Day labels
                    VStack(spacing: 3) {
                        ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                            Text(d)
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: AppColors.muted))
                                .frame(width: 10, height: 10)
                        }
                    }
                    // Week columns
                    ForEach(0..<weeks, id: \.self) { w in
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { d in
                                let date = cells[w][d]
                                let intensity = logByDate[date]?.intensityLevel ?? 0
                                let isFuture = date > Date()
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isFuture
                                          ? Color(hex: AppColors.surfaceSecondary)
                                          : heatColor(intensity))
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: AppColors.muted))
                ForEach(0...4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(i))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: AppColors.muted))
                Spacer()
                Text(totalMinutesLast16Weeks.studyTimeFormatted + " studied")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func heatColor(_ intensity: Int) -> Color {
        switch intensity {
        case 0:  return Color(hex: AppColors.surfacePrimary)
        case 1:  return Color(hex: AppColors.primary).opacity(0.25)
        case 2:  return Color(hex: AppColors.primary).opacity(0.50)
        case 3:  return Color(hex: AppColors.primary).opacity(0.75)
        default: return Color(hex: AppColors.primary)
        }
    }
}

// MARK: - Streak Card with Freeze Tokens

struct StreakFreezeCard: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 0) {
            // Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(profile.currentStreak)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(streakColor)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(streakColor)
                }
                Text("day streak")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: AppColors.muted))
                if profile.longestStreak > 0 {
                    Text("Best: \(profile.longestStreak)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .background(Color(hex: AppColors.surfaceTertiary))
                .frame(height: 50)

            // Freeze tokens
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < profile.freezeTokens ? "snowflake" : "snowflake")
                            .font(.system(size: 14))
                            .foregroundStyle(i < profile.freezeTokens
                                             ? Color(hex: "64D8F0")
                                             : Color(hex: AppColors.surfaceTertiary))
                    }
                }
                Text("\(profile.freezeTokens) freeze\(profile.freezeTokens == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: AppColors.muted))
                Text("Study 2× goal to earn")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .cardStyle()
    }

    private var streakColor: Color {
        switch profile.currentStreak {
        case 0:     return Color(hex: AppColors.muted)
        case 1...6: return Color(hex: AppColors.warning)
        case 7...29: return Color(hex: AppColors.secondary)
        default:    return Color(hex: "FF4500")  // deep orange for 30+ days
        }
    }
}
