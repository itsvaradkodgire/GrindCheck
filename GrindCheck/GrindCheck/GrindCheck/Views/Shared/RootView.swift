import SwiftUI
import SwiftData

/// Entry view. Seeds data on first launch, then hands off to platform navigation.
struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var subjects: [Subject]
    @State private var isSeeding = false

    var body: some View {
        Group {
            if profiles.isEmpty || isSeeding {
                SeedingView()
            } else {
                PlatformAdaptiveLayout()
            }
        }
        .task {
            await seedIfNeeded()
        }
    }

    private func seedIfNeeded() async {
        let seeder = SeedDataManager(modelContext: modelContext)
        if profiles.isEmpty {
            isSeeding = true
            try? await Task.sleep(nanoseconds: 100_000_000)
            seeder.seedAll()
            isSeeding = false
        } else if !subjects.isEmpty {
            // Existing install — seed articles for topics that don't have one yet
            seeder.seedArticlesIfMissing(subjects: subjects)
        }
    }
}

// MARK: - Loading View

private struct SeedingView: View {
    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: AppColors.primary))

                Text("GRINDCHECK")
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.primary))

                Text("Loading your reality...")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.neutral))

                ProgressView()
                    .tint(Color(hex: AppColors.primary))
            }
        }
    }
}
