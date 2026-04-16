import SwiftUI

#if os(macOS)

// MARK: - macOS Navigation

struct MacNavigationView: View {

    @State private var selectedItem: SidebarItem? = .dashboard
    @Environment(GeminiService.self) private var geminiService

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selection: $selectedItem)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            switch selectedItem {
            case .dashboard, .none:
                DashboardView()
            case .subjects:
                SubjectsGridView()
            case .feed:
                ScrollFeedView()
            case .quiz:
                QuizModeSelector()
            case .aiCoach:
                AICoachView(geminiService: geminiService)
            case .analytics:
                MacComingSoonView(feature: "Analytics", icon: "chart.line.uptrend.xyaxis", phase: "Phase 5")
            case .achievements:
                MacComingSoonView(feature: "Achievements", icon: "trophy.fill", phase: "Phase 4")
            case .settings:
                MacComingSoonView(feature: "Settings", icon: "gear", phase: "Phase 5")
            }
        }
        .background(Color(hex: AppColors.background))
    }
}

// MARK: - Sidebar Items

enum SidebarItem: String, Identifiable, CaseIterable {
    case dashboard    = "Dashboard"
    case feed         = "Feed"
    case subjects     = "Subjects"
    case quiz         = "Quiz"
    case aiCoach      = "AI Coach"
    case analytics    = "Analytics"
    case achievements = "Achievements"
    case settings     = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:    return "chart.bar.fill"
        case .feed:         return "play.rectangle.fill"
        case .subjects:     return "books.vertical.fill"
        case .quiz:         return "brain.head.profile"
        case .aiCoach:      return "brain"
        case .analytics:    return "chart.line.uptrend.xyaxis"
        case .achievements: return "trophy.fill"
        case .settings:     return "gear"
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("GrindCheck")
        .background(Color(hex: AppColors.surfacePrimary))
    }
}

// MARK: - Mac Coming Soon

private struct MacComingSoonView: View {
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
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Coming in \(phase)")
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#endif
