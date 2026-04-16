import Foundation
import Observation
import SwiftData

@Observable
final class QuizViewModel {

    // MARK: - Configuration

    var selectedMode: QuizMode         = .quickFire
    var selectedSubject: Subject?      = nil
    var selectedTopic: Topic?          = nil

    // MARK: - Active Quiz State

    var questionPool: [Question]       = []   // full pre-loaded pool
    var activeQuestions: [Question]    = []   // queue to answer
    var answers: [QuizAnswer]          = []

    var currentIndex: Int              = 0
    var currentAnswer: String?         = nil
    var hasAnsweredCurrent: Bool       = false
    var isQuizActive: Bool             = false
    var isComplete: Bool               = false

    // MARK: - Adaptive Difficulty

    var currentDifficulty: Int         = 3
    var consecutiveCorrect: Int        = 0
    var consecutiveWrong: Int          = 0
    var maxDifficultyReached: Int      = 3

    // MARK: - Results

    var proficiencyBefore: Int         = 0
    var proficiencyAfter: Int          = 0
    var summary: ProficiencyEngine.QuizSummary?

    // MARK: - Computed

    var currentQuestion: Question? {
        activeQuestions.safeElement(at: currentIndex)
    }

    var progressFraction: Double {
        guard !activeQuestions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(activeQuestions.count)
    }

    var totalQuestions: Int { activeQuestions.count }

    var questionTimerLimit: Double {
        Double(selectedMode.timeLimitPerQuestion)
    }

    var isLastQuestion: Bool {
        currentIndex == activeQuestions.count - 1
    }

    // MARK: - Mood
    var sessionMood: StudyMood = .ok

    // MARK: - Setup

    func startQuiz(allSubjects: [Subject], mood: StudyMood = .ok) {
        sessionMood = mood
        proficiencyBefore  = selectedTopic?.proficiencyScore
                          ?? selectedSubject.map { Int($0.avgProficiency) }
                          ?? 0
        currentDifficulty  = max(1, min(5, proficiencyBefore / 20))
        maxDifficultyReached = currentDifficulty

        // Mood caps the difficulty ceiling
        currentDifficulty = min(currentDifficulty, mood.maxDifficulty)

        activeQuestions = ProficiencyEngine.selectQuestions(
            mode: selectedMode,
            subject: selectedSubject,
            topic: selectedTopic,
            allSubjects: allSubjects,
            difficulty: currentDifficulty,
            maxDifficulty: mood.maxDifficulty,
            countMultiplier: mood.countMultiplier
        )

        // Build the adaptive pool: start with selected, refill from remaining
        questionPool = allSubjects.flatMap(\.topics).flatMap(\.questions)
            .filter { !activeQuestions.map(\.id).contains($0.id) }

        currentIndex    = 0
        answers         = []
        currentAnswer   = nil
        hasAnsweredCurrent = false
        isComplete      = false
        isQuizActive    = true
        summary         = nil
    }

    // MARK: - Answer Submission

    /// Records the answer and returns whether it was correct.
    @discardableResult
    func submitAnswer(_ answer: String, timeSpent: Int = 0) -> Bool {
        guard let q = currentQuestion, !hasAnsweredCurrent else { return false }

        // "__self_wrong__" = user self-marked a reveal question as wrong
        let isCorrect = answer != "__self_wrong__" && answer == q.correctAnswer

        let qa = QuizAnswer(
            questionId:      q.id,
            userAnswer:      answer,
            isCorrect:       isCorrect,
            timeSpentSeconds: timeSpent,
            difficulty:      currentDifficulty
        )
        answers.append(qa)
        currentAnswer      = answer
        hasAnsweredCurrent = true

        // Adaptive difficulty
        if isCorrect {
            consecutiveCorrect += 1
            consecutiveWrong    = 0
        } else {
            consecutiveWrong   += 1
            consecutiveCorrect  = 0
        }

        currentDifficulty = ProficiencyEngine.adjustDifficulty(
            current: currentDifficulty,
            consecutiveCorrect: consecutiveCorrect,
            consecutiveWrong: consecutiveWrong
        )
        maxDifficultyReached = max(maxDifficultyReached, currentDifficulty)

        return isCorrect
    }

    /// Auto-submit timeout as wrong answer
    func submitTimeout() {
        guard currentQuestion != nil, !hasAnsweredCurrent else { return }
        submitAnswer("__timeout__", timeSpent: selectedMode.timeLimitPerQuestion)
    }

    // MARK: - Advance

    /// Move to next question. Returns true if quiz should complete.
    @discardableResult
    func advance() -> Bool {
        if isLastQuestion {
            return true  // caller should complete
        }
        currentIndex      += 1
        currentAnswer      = nil
        hasAnsweredCurrent = false

        // Inject adaptive question if needed (swap in a question matching current difficulty)
        if currentIndex < activeQuestions.count {
            let nextQ = activeQuestions[currentIndex]
            if nextQ.difficulty != currentDifficulty {
                let candidates = questionPool.filter {
                    $0.difficulty == currentDifficulty
                    && !answers.map(\.questionId).contains($0.id)
                }
                if let swap = candidates.randomElement() {
                    // Move swapped question into pool, swap next in
                    questionPool.removeAll { $0.id == swap.id }
                    questionPool.append(activeQuestions[currentIndex])
                    activeQuestions[currentIndex] = swap
                }
            }
        }
        return false
    }

    // MARK: - Complete

    func completeQuiz(context: ModelContext) {
        guard !isComplete else { return }
        isComplete = true

        // Update question stats
        for qa in answers {
            if let q = (activeQuestions + questionPool).first(where: { $0.id == qa.questionId }) {
                q.recordAttempt(wasCorrect: qa.isCorrect)
            }
        }

        // Update proficiency
        let pct = Double(answers.filter(\.isCorrect).count) / Double(max(1, answers.count)) * 100
        if let topic = selectedTopic {
            let (before, after) = ProficiencyEngine.applyQuizResult(
                to: topic, percentage: pct, questionCount: answers.count)
            proficiencyBefore = before
            proficiencyAfter  = after
        } else {
            proficiencyAfter = proficiencyBefore + Int((pct - Double(proficiencyBefore)) * 0.1)
        }

        summary = ProficiencyEngine.buildSummary(
            answers: answers,
            questions: activeQuestions,
            topic: selectedTopic,
            proficiencyBefore: proficiencyBefore,
            proficiencyAfter: proficiencyAfter
        )

        // Save QuizAttempt to SwiftData
        let attempt = QuizAttempt(
            topic: selectedTopic,
            subject: selectedSubject ?? selectedTopic?.subject,
            quizMode: selectedMode,
            answers: answers,
            totalScore: answers.filter(\.isCorrect).count,
            maxScore: answers.count,
            difficultyLevel: maxDifficultyReached,
            brutalFeedback: summary?.brutalFeedback ?? "",
            proficiencyBefore: proficiencyBefore,
            proficiencyAfter: proficiencyAfter,
            durationSeconds: answers.reduce(0) { $0 + $1.timeSpentSeconds }
        )
        context.insert(attempt)

        // Award XP
        let engine = GamificationEngine(context: context)
        engine.recordQuizCompleted(
            topicId: selectedTopic?.id,
            mode: selectedMode,
            score: attempt.totalScore,
            maxScore: attempt.maxScore,
            proficiencyBefore: proficiencyBefore,
            proficiencyAfter: proficiencyAfter
        )

        try? context.save()
    }

    // MARK: - Reset

    func reset() {
        isQuizActive       = false
        isComplete         = false
        currentIndex       = 0
        answers            = []
        currentAnswer      = nil
        hasAnsweredCurrent = false
        activeQuestions    = []
        questionPool       = []
        summary            = nil
        consecutiveCorrect = 0
        consecutiveWrong   = 0
    }
}
