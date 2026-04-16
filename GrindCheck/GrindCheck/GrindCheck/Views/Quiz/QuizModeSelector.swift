import SwiftUI
import SwiftData

struct QuizModeSelector: View {

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel       = QuizViewModel()
    @State private var isShowingQuiz   = false
    @State private var noQuestionsAlert = false

    private var canStart: Bool {
        let pool = ProficiencyEngine.selectQuestions(
            mode: viewModel.selectedMode,
            subject: viewModel.selectedSubject,
            topic: viewModel.selectedTopic,
            allSubjects: subjects
        )
        return !pool.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Mode grid
                    modePicker
                        .padding(.top, 8)

                    // Target selector
                    if viewModel.selectedMode != .bossFight && viewModel.selectedMode != .mixedBag {
                        targetPicker
                    }

                    // Mode description card
                    modeInfoCard

                    // Start button
                    startButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
            }
            .background(Color(hex: AppColors.background))
            .navigationTitle("Quiz")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isShowingQuiz, onDismiss: { viewModel.reset() }) {
            QuizNavigator(viewModel: viewModel, allSubjects: subjects)
        }
        #else
        .sheet(isPresented: $isShowingQuiz, onDismiss: { viewModel.reset() }) {
            QuizNavigator(viewModel: viewModel, allSubjects: subjects)
                .frame(minWidth: 600, minHeight: 700)
        }
        #endif
        .alert("Not enough questions", isPresented: $noQuestionsAlert) {
            Button("OK") { }
        } message: {
            Text("Add questions to this subject/topic first. The quiz engine needs material to work with.")
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "gamecontroller.fill", iconColor: AppColors.primary,
                          title: "Mode", subtitle: "")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(QuizMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: viewModel.selectedMode == mode,
                        onTap: {
                            viewModel.selectedMode = mode
                            HapticManager.shared.selectionChanged()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Target Picker

    private var targetPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "target", iconColor: AppColors.secondary,
                          title: "Focus", subtitle: "optional")

            // All subjects option
            HStack {
                Button {
                    viewModel.selectedSubject = nil
                    viewModel.selectedTopic   = nil
                    HapticManager.shared.selectionChanged()
                } label: {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(Color(hex: AppColors.primary))
                        Text("All Subjects")
                            .foregroundStyle(.white)
                        Spacer()
                        if viewModel.selectedSubject == nil && viewModel.selectedTopic == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: AppColors.primary))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }

            // Subject list
            ForEach(subjects) { subject in
                SubjectTargetRow(
                    subject: subject,
                    selectedSubject: $viewModel.selectedSubject,
                    selectedTopic: $viewModel.selectedTopic
                )
            }
        }
    }

    // MARK: - Mode Info

    private var modeInfoCard: some View {
        let mode = viewModel.selectedMode
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: mode.sfSymbol)
                    .foregroundStyle(Color(hex: AppColors.primary))
                Text(mode.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            Text(mode.description)
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))

            HStack(spacing: 16) {
                Label("\(mode.questionCount) questions", systemImage: "number.circle.fill")
                Label("\(mode.timeLimitPerQuestion)s per question", systemImage: "timer")
            }
            .font(.caption)
            .foregroundStyle(Color(hex: AppColors.muted))
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            if canStart {
                viewModel.startQuiz(allSubjects: subjects)
                isShowingQuiz = true
            } else {
                noQuestionsAlert = true
            }
        } label: {
            HStack {
                Image(systemName: viewModel.selectedMode.sfSymbol)
                    .font(.headline)
                Text("Start \(viewModel.selectedMode.displayName)")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(Color(hex: AppColors.background))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: AppColors.primary))
                    .primaryGlow()
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Card

private struct ModeCard: View {
    let mode: QuizMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color(hex: AppColors.primary) : Color(hex: AppColors.neutral))

                Text(mode.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Color(hex: AppColors.neutral))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: AppColors.surfacePrimary))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? Color(hex: AppColors.primary) : Color(hex: AppColors.surfaceTertiary),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .if(isSelected) { $0.primaryGlow() }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Subject Target Row

private struct SubjectTargetRow: View {
    let subject: Subject
    @Binding var selectedSubject: Subject?
    @Binding var selectedTopic: Topic?

    @State private var isExpanded = false

    private var isSubjectSelected: Bool {
        selectedSubject?.id == subject.id && selectedTopic == nil
    }

    var body: some View {
        VStack(spacing: 6) {
            // Subject header
            Button {
                if isSubjectSelected {
                    selectedSubject = nil
                } else {
                    selectedSubject = subject
                    selectedTopic   = nil
                }
                HapticManager.shared.selectionChanged()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: subject.icon)
                        .foregroundStyle(Color(hex: subject.colorHex))
                        .frame(width: 20)

                    Text(subject.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    if isSubjectSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: AppColors.primary))
                    }

                    Button {
                        isExpanded.toggle()
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: AppColors.surfacePrimary))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isSubjectSelected
                                    ? Color(hex: subject.colorHex).opacity(0.5)
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)

            // Topics (expanded)
            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(subject.topics.sorted { $0.proficiencyScore < $1.proficiencyScore }) { topic in
                        TopicTargetRow(
                            topic: topic,
                            isSelected: selectedTopic?.id == topic.id,
                            onTap: {
                                selectedTopic   = topic
                                selectedSubject = subject
                                HapticManager.shared.selectionChanged()
                            }
                        )
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

private struct TopicTargetRow: View {
    let topic: Topic
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(Color(hex: topic.confidenceLevel.colorHex))
                    .frame(width: 7, height: 7)

                Text(topic.name)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : Color(hex: AppColors.neutral))

                Spacer()

                Text("\(topic.proficiencyScore)%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(hex: topic.confidenceLevel.colorHex))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.primary))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? Color(hex: AppColors.primary).opacity(0.08)
                          : Color(hex: AppColors.surfacePrimary).opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}
