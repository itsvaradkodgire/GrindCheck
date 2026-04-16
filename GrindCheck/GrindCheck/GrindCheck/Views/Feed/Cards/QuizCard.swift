import SwiftUI
import Combine

struct QuizCard: View {
    let card: FeedCard
    let question: Question
    let onCorrect: (Question) -> Void
    let onWrong: (Question) -> Void
    let onBookmark: (Question) -> Void
    let alreadyAnswered: Bool
    let wasCorrect: Bool?
    var onStudyGuide: ((Question) -> Void)? = nil

    // MARK: - State

    @State private var selectedAnswer: String?  = nil
    @State private var hasAnswered: Bool         = false
    @State private var showExplanation: Bool     = false
    @State private var timeRemaining: Double     = 30.0
    @State private var shuffledOptions: [String] = []
    @State private var isBookmarked: Bool        = false
    @State private var isActive: Bool            = false

    @Environment(AppState.self) private var appState

    // Timer
    let timerPublisher = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    // MARK: - Computed

    private var timeFraction: Double { timeRemaining / 30.0 }

    private var timerColor: Color {
        switch timeRemaining {
        case 20...: return Color(hex: AppColors.success)
        case 10...: return Color(hex: AppColors.warning)
        default:    return Color(hex: AppColors.danger)
        }
    }

    private var accentColor: String {
        question.topic?.subject?.colorHex ?? AppColors.primary
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            cardBackground

            // Center: question + options
            VStack(spacing: 0) {
                // Smaller top spacer pushes content downward
                Spacer().frame(minHeight: 110)

                questionContent
                    .padding(.horizontal, 20)

                Spacer()

                if hasAnswered {
                    answerRevealBlock
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    optionsBlock
                        .padding(.horizontal, 20)
                }

                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    // Clear the tab bar (≈83pt on modern iPhones)
                    .padding(.bottom, 100)
            }

            // Top overlay: timer bar + meta row (below safe area)
            VStack(spacing: 0) {
                timerBar
                    .frame(height: 3)

                metadataRow
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    .padding(.bottom, 8)

                Spacer()
            }
        }
        .onAppear { setup(); isActive = true }
        .onDisappear { isActive = false }
        .onReceive(timerPublisher) { _ in tickTimer() }
        .animation(.spring(duration: 0.3), value: hasAnswered)
    }

    // MARK: - Subviews

    private var cardBackground: some View {
        ZStack {
            Color(hex: AppColors.background)
            // Subtle subject color gradient
            LinearGradient(
                colors: [Color(hex: accentColor).opacity(0.08), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var timerBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color(hex: AppColors.surfaceSecondary))
                Rectangle()
                    .fill(timerColor)
                    .frame(width: hasAnswered ? geo.size.width : geo.size.width * timeFraction)
                    .animation(hasAnswered ? .none : .linear(duration: 0.05), value: timeRemaining)
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            // Subject + Topic
            if let subject = question.topic?.subject {
                Label(subject.name, systemImage: subject.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: subject.colorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: subject.colorHex).opacity(0.12)))
            }

            // Question type badge
            Text(question.questionType.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: AppColors.muted))

            Spacer()

            // Difficulty dots
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= question.difficulty
                              ? Color(hex: AppColors.warning)
                              : Color(hex: AppColors.muted).opacity(0.4))
                        .frame(width: 5, height: 5)
                }
            }

            // Bookmark
            Button {
                isBookmarked.toggle()
                onBookmark(question)
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14))
                    .foregroundStyle(isBookmarked ? Color(hex: AppColors.warning) : Color(hex: AppColors.muted))
            }
        }
    }

    private var questionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.questionText)
                .font(.system(
                    question.questionText.count > 120 ? .body : .title3,
                    design: question.questionType == .codeOutput ? .monospaced : .default,
                    weight: .semibold
                ))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            if question.isNemesis {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: AppColors.danger))
                    Text("Nemesis question — you've gotten this wrong before")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.danger))
                }
            }
        }
    }

    private var optionsBlock: some View {
        Group {
            switch question.questionType {
            case .mcq:
                mcqOptions
            case .trueFalse:
                trueFalseOptions
            case .shortAnswer, .explainThis, .codeOutput:
                tapToRevealButton
            }
        }
    }

    private var mcqOptions: some View {
        VStack(spacing: 10) {
            ForEach(shuffledOptions, id: \.self) { option in
                OptionButton(
                    text: option,
                    state: optionState(for: option),
                    onTap: { submitAnswer(option) }
                )
            }
        }
    }

    private var trueFalseOptions: some View {
        HStack(spacing: 12) {
            OptionButton(
                text: "True",
                state: optionState(for: "True"),
                onTap: { submitAnswer("True") }
            )
            OptionButton(
                text: "False",
                state: optionState(for: "False"),
                onTap: { submitAnswer("False") }
            )
        }
    }

    private var tapToRevealButton: some View {
        Button {
            submitAnswer("__revealed__")
        } label: {
            Text("Tap to reveal answer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: accentColor))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: accentColor).opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(hex: accentColor).opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var answerRevealBlock: some View {
        VStack(spacing: 12) {
            // Result badge
            HStack {
                Image(systemName: isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(isAnswerCorrect ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))

                Text(isAnswerCorrect ? "Correct" : "Wrong")
                    .font(.headline)
                    .foregroundStyle(isAnswerCorrect ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))

                Spacer()

                if !isAnswerCorrect {
                    Text("Answer: \(question.correctAnswer)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color(hex: AppColors.success))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }

            // Explanation
            if !question.explanation.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why:")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: AppColors.muted))
                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: AppColors.surfaceSecondary))
                )
            }

            // Feature 6: Study guide deep-link on wrong answer
            if !isAnswerCorrect, question.topic?.article != nil {
                Button {
                    HapticManager.shared.lightTap()
                    onStudyGuide?(question)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 13))
                        Text("Read the concept →")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: AppColors.primary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: AppColors.primary).opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(hex: AppColors.primary).opacity(0.3), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            // Accuracy for this question
            if question.timesAsked > 0 {
                Label("\(Int(question.accuracyRate * 100))% historical", systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
            Spacer()
            if hasAnswered {
                Text("Swipe up →")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
    }

    // MARK: - Option State

    enum OptionState { case idle, selected, correct, wrong, dimmed }

    private func optionState(for option: String) -> OptionState {
        guard hasAnswered else { return .idle }
        let isCorrect = option == question.correctAnswer
        let isSelected = option == selectedAnswer
        if isCorrect { return .correct }
        if isSelected { return .wrong }
        return .dimmed
    }

    private var isAnswerCorrect: Bool {
        selectedAnswer == question.correctAnswer || selectedAnswer == "__revealed__"
    }

    // MARK: - Logic

    private func setup() {
        isBookmarked  = question.isBookmarked
        shuffledOptions = question.options.shuffled()
        if alreadyAnswered {
            hasAnswered      = true
            selectedAnswer   = wasCorrect == true ? question.correctAnswer : ""
            timeRemaining    = 0
        }
    }

    private func submitAnswer(_ answer: String) {
        guard !hasAnswered else { return }
        selectedAnswer = answer
        hasAnswered    = true
        isActive = false
        withAnimation(.spring(duration: 0.3)) { showExplanation = true }

        let correct = answer == question.correctAnswer || answer == "__revealed__"
        if correct {
            HapticManager.shared.correctAnswer()
            onCorrect(question)
        } else {
            HapticManager.shared.wrongAnswer()
            onWrong(question)
        }
    }

    private func tickTimer() {
        // Don't tick if this card is off-screen or the feed tab isn't selected
        guard isActive, appState.selectedTab == .feed, !hasAnswered else { return }
        if timeRemaining > 0 {
            timeRemaining = max(0, timeRemaining - 0.05)
        } else {
            selectedAnswer = "__timeout__"
            hasAnswered    = true
            HapticManager.shared.wrongAnswer()
            onWrong(question)
        }
    }
}

// MARK: - Option Button

private struct OptionButton: View {
    let text: String
    let state: QuizCard.OptionState
    let onTap: () -> Void

    private var bg: Color {
        switch state {
        case .idle:     return Color(hex: AppColors.surfaceSecondary)
        case .selected: return Color(hex: AppColors.danger).opacity(0.2)
        case .correct:  return Color(hex: AppColors.success).opacity(0.2)
        case .wrong:    return Color(hex: AppColors.danger).opacity(0.2)
        case .dimmed:   return Color(hex: AppColors.surfacePrimary).opacity(0.4)
        }
    }

    private var border: Color {
        switch state {
        case .idle:     return Color(hex: AppColors.surfaceTertiary)
        case .selected: return Color(hex: AppColors.danger)
        case .correct:  return Color(hex: AppColors.success)
        case .wrong:    return Color(hex: AppColors.danger)
        case .dimmed:   return Color.clear
        }
    }

    private var textColor: Color {
        switch state {
        case .idle:     return .white
        case .selected: return Color(hex: AppColors.danger)
        case .correct:  return Color(hex: AppColors.success)
        case .wrong:    return Color(hex: AppColors.danger)
        case .dimmed:   return Color(hex: AppColors.muted)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: AppColors.success))
                } else if state == .wrong || state == .selected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(hex: AppColors.danger))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(border, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
        .animation(.spring(duration: 0.25), value: state)
    }
}
