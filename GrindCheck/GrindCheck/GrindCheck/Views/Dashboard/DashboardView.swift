import SwiftUI
import SwiftData

struct DashboardView: View {

    @Query private var profiles: [UserProfile]
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @Query(sort: \AIRoadmap.createdAt, order: .reverse) private var roadmaps: [AIRoadmap]
    @Environment(GeminiService.self) private var geminiService

    @State private var showingProfile = false

    private var latestRoadmap: AIRoadmap? { roadmaps.first }

    private var profile: UserProfile?  { profiles.first }
    private var todayLog: DailyLog?    { logs.first { DailyLog.isToday($0.date) } }

    private var decayingTopics: [Topic] {
        subjects.flatMap(\.topics)
            .filter(\.isDecaying)
            .sorted { $0.daysSinceLastStudy > $1.daysSinceLastStudy }
            .prefix(5)
            .map { $0 }
    }

    private var allTopics: [Topic] { subjects.flatMap(\.topics) }
    private var weakTopics: [Topic] {
        allTopics.filter { $0.proficiencyScore < 40 }
            .sorted { $0.proficiencyScore < $1.proficiencyScore }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Reality check card
                    RealityCheckCard(
                        profile: profile,
                        todayMinutes: todayLog?.totalStudyMinutes ?? 0,
                        dailyGoalMinutes: profile?.dailyGoalMinutes ?? 60,
                        currentStreak: profile?.currentStreak ?? 0
                    )

                    // Stats row
                    QuickStatsRow(
                        todayMinutes: todayLog?.totalStudyMinutes ?? 0,
                        todayXP: todayLog?.xpEarned ?? 0,
                        weeklyAvgScore: weeklyAvgScore,
                        decayingCount: decayingTopics.count
                    )

                    // Streak + Freeze tokens
                    if let profile {
                        StreakFreezeCard(profile: profile)
                    }

                    // Level / XP progress
                    if let profile {
                        LevelProgressCard(profile: profile)
                    }

                    // Study heatmap
                    StudyHeatmapView(logs: Array(logs))

                    // AI Roadmap progress
                    if let roadmap = latestRoadmap {
                        RoadmapProgressCard(roadmap: roadmap)
                    }

                    // Weekly gap report
                    WeeklyGapReportCard(
                        geminiService: geminiService,
                        subjects: Array(subjects),
                        logs: Array(logs)
                    )

                    // Decaying topics
                    if !decayingTopics.isEmpty {
                        DecayingTopicsSection(topics: decayingTopics)
                    }

                    // Subjects overview
                    if subjects.isEmpty {
                        EmptyStateView(
                            icon: "books.vertical.fill",
                            title: "No subjects yet",
                            message: "Tap Subjects to add what you're studying."
                        )
                    } else {
                        SubjectsOverviewSection(subjects: Array(subjects))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(hex: AppColors.background))
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingProfile = true
                    } label: {
                        profileButtonLabel
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                if let profile {
                    ProfileSettingsView(profile: profile)
                        .environment(geminiService)
                }
            }
        }
    }

    @ViewBuilder
    private var profileButtonLabel: some View {
        if let profile {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                Text(initials(for: profile.name))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
            }
        } else {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(Color(hex: AppColors.primary))
        }
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ").map(String.init)
        return words.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private var weeklyAvgScore: Double {
        let recentLogs = logs.prefix(7).filter { $0.quizzesTaken > 0 }
        guard !recentLogs.isEmpty else { return 0 }
        return recentLogs.reduce(0) { $0 + $1.avgQuizScore } / Double(recentLogs.count)
    }
}

// MARK: - Roadmap Progress Card

private struct RoadmapProgressCard: View {
    let roadmap: AIRoadmap
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("AI Roadmap", systemImage: "map.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.primary))
                Spacer()
                Button {
                    appState.selectedTab = .aiCoach
                } label: {
                    Text("View")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.primary))
                }
                .buttonStyle(.plain)
            }

            Text(roadmap.goal)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: AppColors.surfaceSecondary))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: AppColors.success))
                            .frame(width: geo.size.width * roadmap.progressFraction)
                    }
                }
                .frame(height: 6)

                Text("\(roadmap.completedPhaseCount)/\(roadmap.totalPhaseCount)")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.success))
                    .fixedSize()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: AppColors.primary).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Level Progress Card

private struct LevelProgressCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Level \(profile.level)")
                    .font(.system(.headline, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.primary))

                Text("· \(profile.levelTitle)")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))

                Spacer()

                Text("\(profile.totalXP.xpFormatted) XP")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.secondary))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: AppColors.surfaceTertiary))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * profile.levelProgress, height: 8)
                        .animation(.spring(duration: 0.6), value: profile.levelProgress)
                }
            }
            .frame(height: 8)

            Text("\(profile.xpIntoCurrentLevel.xpFormatted) / \(profile.xpNeededForNextLevel.xpFormatted) XP to Level \(profile.level + 1)")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .padding(16)
        .cardStyle()
    }
}
