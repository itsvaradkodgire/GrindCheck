import SwiftUI

// MARK: - iOS Tab Bar

struct AppTabView: View {

    @Environment(AppState.self) private var appState
    @Environment(GeminiService.self) private var geminiService

    var body: some View {
        @Bindable var bindableState = appState
        TabView(selection: $bindableState.selectedTab) {

            // MARK: Feed
            ScrollFeedView()
                .tabItem { Label("Feed", systemImage: "play.rectangle.fill") }
                .tag(AppTab.feed)
                #if os(iOS)
                .toolbarBackground(.hidden, for: .tabBar)
                #endif

            // MARK: Dashboard
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(AppTab.dashboard)

            // MARK: Subjects
            SubjectsGridView()
                .tabItem { Label("Subjects", systemImage: "books.vertical.fill") }
                .tag(AppTab.subjects)

            // MARK: Quiz
            QuizModeSelector()
                .tabItem { Label("Quiz", systemImage: "brain.head.profile") }
                .tag(AppTab.quiz)

            // MARK: AI Coach
            AICoachView(geminiService: geminiService)
                .tabItem { Label("AI Coach", systemImage: "brain") }
                .tag(AppTab.aiCoach)
        }
        .tint(Color(hex: AppColors.primary))
    }
}

// MARK: - Tab Enum

enum AppTab: Hashable {
    case feed, dashboard, subjects, quiz, aiCoach
}

// MARK: - Generic Coming Soon

private struct ComingSoonView: View {
    let feature: String
    let icon: String
    let phase: String

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: AppColors.neutral))
                Text(feature)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Coming in \(phase)")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
    }
}
