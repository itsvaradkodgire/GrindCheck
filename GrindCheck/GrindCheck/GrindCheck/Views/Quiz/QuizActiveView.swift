import SwiftUI
import Combine

struct QuizActiveView: View {

    @Bindable var viewModel: QuizViewModel
    let onComplete: () -> Void
    let onQuit: () -> Void

    // MARK: - Local State

    @State private var timeRemaining: Double = 0
    @State private var shuffledOptions: [String] = []
    @State private var flashResult: Bool? = nil   // nil=no flash, true=correct, false=wrong
    @State private var isAdvancing = false
    @State private var showQuitConfirm = false
    @State private var revealedAnswer = false     // for shortAnswer/explainThis/codeOutput

    let timerPublisher = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    // MARK: - Computed

    private var question: Question? { viewModel.currentQuestion }
    private var accentColor: String { question?.topic?.subject?.colorHex ?? AppColors.primary }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            // Result flash overlay
            if let result = flashResult {
                Color(hex: result ? AppColors.success : AppColors.danger)
                    .opacity(0.12)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Header: progress + quit
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Timer bar
                timerBar
                    .frame(height: 4)
                    .padding(.top, 10)

                // Difficulty indicator
                difficultyRow
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Spacer()

                // Question
                if let q = question {
                    questionArea(q)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Options
                if let q = question {
                    optionsArea(q)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onAppear { setupQuestion() }
        .onChange(of: viewModel.currentIndex) { _, _ in setupQuestion() }
        .onReceive(timerPublisher) { _ in tickTimer() }
        .confirmationDialog("Quit quiz?", isPresented: $showQuitConfirm) {
            Button("Quit", role: .destructive) { onQuit() }
            Button("Keep going", role: .cancel) { }
        } message: {
            Text("Your progress will be lost.")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            // Quit
            Button {
                showQuitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: AppColors.neutral))
            }

            Spacer()

            // Progress dots
            HStack(spacing: 5) {
                ForEach(0..<viewModel.totalQuestions, id: \.self) { i in
                    progressDot(index: i)
                }
            }

            Spacer()

            // Question counter
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalQuestions)")
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundStyle(Color(hex: AppColors.muted))
        }
    }

    private func progressDot(index: Int) -> some View {
        let answered = index < viewModel.answers.count
        let correct  = answered ? viewModel.answers[index].isCorrect : false
        let isCurrent = index == viewModel.currentIndex

        return Circle()
            .fill(
                answered ? (correct ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))
                : isCurrent ? Color(hex: AppColors.primary)
                : Color(hex: AppColors.surfaceTertiary)
            )
            .frame(width: isCurrent ? 9 : 7, height: isCurrent ? 9 : 7)
            .animation(.spring(duration: 0.25), value: viewModel.currentIndex)
    }

    // MARK: - Timer Bar

    private var timerBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color(hex: AppColors.surfaceSecondary))
                Rectangle()
                    .fill(timerColor)
                    .frame(width: viewModel.hasAnsweredCurrent
                           ? geo.size.width
                           : geo.size.width * (timeRemaining / viewModel.questionTimerLimit))
                    .animation(viewModel.hasAnsweredCurrent ? nil : .linear(duration: 0.05), value: timeRemaining)
            }
        }
    }

    private var timerColor: Color {
        let fraction = timeRemaining / viewModel.questionTimerLimit
        if fraction > 0.5 { return Color(hex: AppColors.success) }
        if fraction > 0.25 { return Color(hex: AppColors.warning) }
        return Color(hex: AppColors.danger)
    }

    // MARK: - Difficulty Row

    private var difficultyRow: some View {
        HStack {
            // Adaptive difficulty
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= viewModel.currentDifficulty
                              ? Color(hex: AppColors.warning)
                              : Color(hex: AppColors.surfaceTertiary))
                        .frame(width: 14, height: 5)
                }
            }
            Text("Difficulty")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: AppColors.muted))

            Spacer()

            if let subject = question?.topic?.subject {
                Label(subject.name, systemImage: subject.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: subject.colorHex))
            }
        }
    }

    // MARK: - Question Area

    private func questionArea(_ q: Question) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(q.questionType.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: AppColors.muted))
                .tracking(2)

            Text(q.questionText)
                .font(.system(
                    q.questionText.count > 150 ? .body : .title3,
                    design: q.questionType == .codeOutput ? .monospaced : .default,
                    weight: .semibold
                ))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            if q.isNemesis {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.caption2)
                    Text("You've gotten this wrong before")
                        .font(.caption)
                }
                .foregroundStyle(Color(hex: AppColors.danger))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Options Area

    @ViewBuilder
    private func optionsArea(_ q: Question) -> some View {
        if viewModel.hasAnsweredCurrent {
            // Show explanation after answering
            answerExplanation(q)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            switch q.questionType {
            case .mcq:
                mcqOptions(q)
            case .trueFalse:
                tfOptions(q)
            case .shortAnswer, .explainThis, .codeOutput:
                if revealedAnswer {
                    selfEvalButtons(q)
                } else {
                    revealButton(q)
                }
            }
        }
    }

    private func mcqOptions(_ q: Question) -> some View {
        VStack(spacing: 8) {
            ForEach(shuffledOptions, id: \.self) { option in
                QuizOptionButton(
                    text: option,
                    state: .idle,
                    onTap: { handleAnswer(option, question: q) }
                )
            }
        }
    }

    private func tfOptions(_ q: Question) -> some View {
        HStack(spacing: 12) {
            QuizOptionButton(text: "True",  state: .idle, onTap: { handleAnswer("True",  question: q) })
            QuizOptionButton(text: "False", state: .idle, onTap: { handleAnswer("False", question: q) })
        }
    }

    private func revealButton(_ q: Question) -> some View {
        Button { revealedAnswer = true } label: {
            Text("Show Answer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: accentColor))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: accentColor).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(hex: accentColor).opacity(0.35), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func selfEvalButtons(_ q: Question) -> some View {
        VStack(spacing: 10) {
            // Show the answer
            VStack(alignment: .leading, spacing: 6) {
                Text("Answer")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .tracking(2)
                Text(q.correctAnswer)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.success))
                    .fixedSize(horizontal: false, vertical: true)
                if !q.explanation.isEmpty {
                    Text(q.explanation)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: AppColors.surfaceSecondary))
            )

            // Self-evaluation
            HStack(spacing: 10) {
                Button { handleAnswer("__self_wrong__", question: q) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Missed it")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(Color(hex: AppColors.danger))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.danger).opacity(0.12))
                    )
                }
                .buttonStyle(.plain)

                Button { handleAnswer(q.correctAnswer, question: q) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Got it")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(Color(hex: AppColors.success))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.success).opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func answerExplanation(_ q: Question) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Result indicator
            HStack {
                let correct = viewModel.answers.last?.isCorrect ?? false
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(correct ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))
                Text(correct ? "Correct" : "Wrong — Answer: \(q.correctAnswer)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(correct ? Color(hex: AppColors.success) : Color(hex: AppColors.danger))
                    .lineLimit(2)
            }

            if !q.explanation.isEmpty {
                Text(q.explanation)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: AppColors.surfaceSecondary))
                    )
            }
        }
    }

    // MARK: - Logic

    private func setupQuestion() {
        guard !isAdvancing else { return }   // advanceOrComplete already reset state
        timeRemaining   = viewModel.questionTimerLimit
        shuffledOptions = viewModel.currentQuestion?.options.shuffled() ?? []
        flashResult     = nil
        revealedAnswer  = false
    }

    private func handleAnswer(_ answer: String, question: Question) {
        guard !isAdvancing && !viewModel.hasAnsweredCurrent else { return }

        let timeSpent = Int(viewModel.questionTimerLimit - timeRemaining)
        let wasCorrect = viewModel.submitAnswer(answer, timeSpent: timeSpent)

        // Flash
        withAnimation(.easeIn(duration: 0.15)) { flashResult = wasCorrect }

        // Haptics
        if wasCorrect { HapticManager.shared.correctAnswer() }
        else          { HapticManager.shared.wrongAnswer() }

        // Auto-advance after brief delay
        isAdvancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            advanceOrComplete()
        }
    }

    private func advanceOrComplete() {
        withAnimation(.easeOut(duration: 0.15)) { flashResult = nil }
        if viewModel.advance() {
            // Last question answered
            onComplete()
            return
        }
        // Reset timer state synchronously here — before isAdvancing = false —
        // so the ticker can't fire a spurious timeout on the incoming question
        // in the gap before onChange fires setupQuestion() asynchronously.
        timeRemaining   = viewModel.questionTimerLimit
        shuffledOptions = viewModel.currentQuestion?.options.shuffled() ?? []
        revealedAnswer  = false
        isAdvancing     = false
    }

    private func tickTimer() {
        guard !viewModel.hasAnsweredCurrent else { return }
        if timeRemaining > 0 {
            timeRemaining = max(0, timeRemaining - 0.05)
        } else if !isAdvancing {
            // Time up
            viewModel.submitTimeout()
            HapticManager.shared.wrongAnswer()
            withAnimation { flashResult = false }
            isAdvancing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                advanceOrComplete()
            }
        }
    }
}

// MARK: - Quiz Option Button (quiz-specific, slightly different from feed)

struct QuizOptionButton: View {
    let text: String
    let state: QuizCard.OptionState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: AppColors.surfaceSecondary))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(hex: AppColors.surfaceTertiary), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
