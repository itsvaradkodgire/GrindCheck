import SwiftUI
import SwiftData

/// Hosts the NavigationStack for the full-screen quiz flow.
struct QuizNavigator: View {
    @Bindable var viewModel: QuizViewModel
    let allSubjects: [Subject]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var path           = NavigationPath()
    @State private var showMoodCheck  = true
    @State private var currentMood: StudyMood = .ok

    var body: some View {
        if showMoodCheck {
            MoodCheckInView(
                onContinue: { mood in
                    currentMood   = mood
                    showMoodCheck = false
                    viewModel.startQuiz(allSubjects: allSubjects, mood: mood)
                },
                onSkip: {
                    showMoodCheck = false
                    viewModel.startQuiz(allSubjects: allSubjects, mood: .ok)
                }
            )
        } else {
            NavigationStack(path: $path) {
                QuizActiveView(
                    viewModel: viewModel,
                    onComplete: {
                        viewModel.completeQuiz(context: modelContext)
                        path.append("results")
                    },
                    onQuit: {
                        dismiss()
                    }
                )
                .navigationDestination(for: String.self) { destination in
                    if destination == "results" {
                        QuizResultsView(
                            viewModel: viewModel,
                            onDone: { dismiss() },
                            onRetry: {
                                path = NavigationPath()
                                showMoodCheck = true
                            }
                        )
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
