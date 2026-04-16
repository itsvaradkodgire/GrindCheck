import SwiftUI

struct QuizResultsView: View {

    let viewModel: QuizViewModel
    let onDone: () -> Void
    let onRetry: () -> Void

    @Environment(AppState.self) private var appState

    @State private var animateScore = false
    @State private var showBreakdown = false

    // MARK: - Confusion Pattern Detection
    private var confusionPatterns: [ConfusionPattern] {
        let wrong = viewModel.answers.filter { !$0.isCorrect && $0.userAnswer != "__timeout__" }
        var tagCounts: [String: Int] = [:]
        var typeCounts: [QuestionType: Int] = [:]

        for answer in wrong {
            if let q = viewModel.activeQuestions.first(where: { $0.id == answer.questionId }) {
                q.tags.forEach { tagCounts[$0, default: 0] += 1 }
                typeCounts[q.questionType, default: 0] += 1
            }
        }
        var patterns: [ConfusionPattern] = []
        // Tag-based
        for (tag, count) in tagCounts where count >= 2 {
            patterns.append(ConfusionPattern(label: tag, count: count, kind: .tag))
        }
        // Type-based (if > 50% of that type was wrong)
        for (type, wrongCount) in typeCounts {
            let total = viewModel.activeQuestions.filter { $0.questionType == type }.count
            if total > 0 && Double(wrongCount) / Double(total) > 0.5 {
                patterns.append(ConfusionPattern(label: type.displayName, count: wrongCount, kind: .questionType))
            }
        }
        return patterns.sorted { $0.count > $1.count }.prefix(4).map { $0 }
    }

    private var summary: ProficiencyEngine.QuizSummary? { viewModel.summary }
    private var correctCount: Int { viewModel.answers.filter(\.isCorrect).count }
    private var totalCount: Int  { viewModel.answers.count }
    private var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount) * 100
    }

    private var gradeColor: Color {
        switch percentage {
        case 90...: return Color(hex: AppColors.success)
        case 70...: return Color(hex: AppColors.primary)
        case 50...: return Color(hex: AppColors.warning)
        default:    return Color(hex: AppColors.danger)
        }
    }

    private var gradeLetter: String {
        switch percentage {
        case 95...: return "S"
        case 85...: return "A"
        case 70...: return "B"
        case 55...: return "C"
        case 40...: return "D"
        default:    return "F"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Grade hero
                    gradeHero
                        .padding(.top, 32)

                    // Brutal feedback
                    if let fb = summary?.brutalFeedback {
                        brutalFeedbackCard(fb)
                    }

                    // Stats row
                    statsRow

                    // Proficiency change
                    proficiencyCard

                    // Confusion patterns
                    if !confusionPatterns.isEmpty {
                        confusionPatternCard
                    }

                    // Per-question breakdown toggle
                    breakdownSection

                    // Actions
                    actionButtons
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onAppear {
            withAnimation(.spring(duration: 0.6).delay(0.2)) {
                animateScore = true
            }
        }
    }

    // MARK: - Grade Hero

    private var gradeHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.1))
                    .frame(width: 130, height: 130)
                Circle()
                    .strokeBorder(gradeColor.opacity(0.35), lineWidth: 2)
                    .frame(width: 130, height: 130)

                Text(gradeLetter)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(gradeColor)
                    .scaleEffect(animateScore ? 1 : 0.3)
            }

            Text("\(correctCount) / \(totalCount) correct")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(.white)

            Text(String(format: "%.0f%%", percentage))
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(gradeColor)

            Text(viewModel.selectedMode.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.muted))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(hex: AppColors.surfaceSecondary))
                )
        }
    }

    // MARK: - Brutal Feedback

    private func brutalFeedbackCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundStyle(Color(hex: AppColors.danger))

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: AppColors.danger).opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Confusion Pattern Card

    private var confusionPatternCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Where You're Getting Stuck", systemImage: "brain.head.profile")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.warning))

            Text("Patterns detected in your wrong answers:")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))

            VStack(spacing: 6) {
                ForEach(confusionPatterns) { pattern in
                    HStack(spacing: 10) {
                        Image(systemName: pattern.kind == .tag ? "tag.fill" : "questionmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: AppColors.warning))
                            .frame(width: 20)
                        Text(pattern.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(pattern.count)×")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(Color(hex: AppColors.warning))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: AppColors.surfaceSecondary)))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(hex: AppColors.warning).opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                icon: "bolt.fill",
                label: "Max Difficulty",
                value: "\(viewModel.maxDifficultyReached)/5",
                color: AppColors.warning
            )
            statTile(
                icon: "clock.fill",
                label: "Avg Time",
                value: avgTimeString,
                color: AppColors.primary
            )
            statTile(
                icon: "flame.fill",
                label: "Nemeses",
                value: "\(nemesisCount)",
                color: AppColors.danger
            )
        }
    }

    private func statTile(icon: String, label: String, value: String, color: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: AppColors.muted))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    private var avgTimeString: String {
        guard !viewModel.answers.isEmpty else { return "—" }
        let avg = viewModel.answers.map(\.timeSpentSeconds).reduce(0, +) / viewModel.answers.count
        return "\(avg)s"
    }

    private var nemesisCount: Int {
        viewModel.activeQuestions.filter(\.isNemesis).count
    }

    // MARK: - Proficiency Card

    private var proficiencyCard: some View {
        let before = viewModel.proficiencyBefore
        let after  = viewModel.proficiencyAfter
        let delta  = after - before
        let isUp   = delta >= 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Proficiency")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if delta != 0 {
                    Label(
                        "\(isUp ? "+" : "")\(delta)%",
                        systemImage: isUp ? "arrow.up.right" : "arrow.down.right"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isUp ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))
                }
            }

            if let topic = viewModel.selectedTopic {
                Text(topic.name)
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }

            HStack(spacing: 8) {
                proficiencyBar(label: "Before", value: before, color: AppColors.muted)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                proficiencyBar(label: "After", value: after, color: isUp ? AppColors.success : AppColors.danger)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    private func proficiencyBar(label: String, value: Int, color: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: AppColors.muted))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: AppColors.surfaceSecondary))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: color))
                        .frame(width: animateScore
                               ? geo.size.width * CGFloat(value) / 100
                               : 0)
                        .animation(.spring(duration: 0.8).delay(0.4), value: animateScore)
                }
            }
            .frame(height: 6)
            Text("\(value)%")
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundStyle(Color(hex: color))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Breakdown

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) { showBreakdown.toggle() }
            } label: {
                HStack {
                    Text("Question Breakdown")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: AppColors.surfacePrimary))
                )
            }
            .buttonStyle(.plain)

            if showBreakdown {
                VStack(spacing: 6) {
                    ForEach(Array(viewModel.answers.enumerated()), id: \.offset) { idx, answer in
                        if let q = viewModel.activeQuestions.first(where: { $0.id == answer.questionId }) {
                            breakdownRow(index: idx + 1, question: q, answer: answer)
                        }
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func breakdownRow(index: Int, question: Question, answer: QuizAnswer) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Number + result icon
            ZStack {
                Circle()
                    .fill(answer.isCorrect
                          ? Color(hex: AppColors.success).opacity(0.15)
                          : Color(hex: AppColors.danger).opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: answer.isCorrect ? "checkmark" : "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(answer.isCorrect ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(question.questionText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !answer.isCorrect && answer.userAnswer == "__self_wrong__" {
                    Text("Self-marked wrong — Answer: \(question.correctAnswer)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: AppColors.warning))
                } else if !answer.isCorrect && answer.userAnswer != "__timeout__" {
                    HStack(spacing: 4) {
                        Text("You:")
                            .foregroundStyle(Color(hex: AppColors.muted))
                        Text(answer.userAnswer)
                            .foregroundStyle(Color(hex: AppColors.danger))
                        Text("→")
                            .foregroundStyle(Color(hex: AppColors.muted))
                        Text(question.correctAnswer)
                            .foregroundStyle(Color(hex: AppColors.success))
                    }
                    .font(.system(size: 10))
                } else if answer.userAnswer == "__timeout__" {
                    Text("Timed out — \(question.correctAnswer)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: AppColors.warning))
                }
            }

            Spacer()

            Text("\(answer.timeSpentSeconds)s")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
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

            // Ask AI Coach — shown when score is below 70%
            if percentage < 70 {
                Button {
                    askAICoach()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "brain")
                        Text("Ask AI Coach Why I Failed")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: AppColors.primary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.primary).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color(hex: AppColors.primary).opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Button(action: onDone) {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.surfaceSecondary))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func askAICoach() {
        let topicName = viewModel.selectedTopic?.name ?? viewModel.selectedMode.displayName
        let wrongQuestions = viewModel.answers
            .filter { !$0.isCorrect }
            .compactMap { answer in
                viewModel.activeQuestions.first(where: { $0.id == answer.questionId })?.questionText
            }
            .prefix(3)
            .joined(separator: "; ")

        let message = "I just scored \(Int(percentage))% on \(topicName). " +
            (wrongQuestions.isEmpty ? "" : "I struggled with: \(wrongQuestions). ") +
            "What should I focus on to improve?"

        appState.pendingAIMessage = message
        appState.selectedTab = .aiCoach
        onDone()
    }
}

// MARK: - Confusion Pattern Model

struct ConfusionPattern: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    enum Kind { case tag, questionType }
    let kind: Kind
}
