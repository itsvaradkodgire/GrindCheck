import Foundation
import SwiftData

// MARK: - Proficiency Engine
// Single source of truth for proficiency calculations.

enum ProficiencyEngine {

    // MARK: - Quiz Result → Proficiency

    /// Updates a topic's proficiency after a quiz. Returns (before, after).
    @discardableResult
    static func applyQuizResult(
        to topic: Topic,
        percentage: Double,
        questionCount: Int
    ) -> (before: Int, after: Int) {
        let before = topic.proficiencyScore

        // Weight increases with question count (more data = more trust)
        let dataWeight = min(0.45, 0.15 + Double(questionCount) / 60.0)
        let raw        = Double(topic.proficiencyScore) * (1.0 - dataWeight) + percentage * dataWeight
        let newScore   = Int(raw.clamped(to: 0...100))

        topic.proficiencyScore  = newScore
        topic.confidenceLevel   = .from(proficiency: newScore)
        topic.lastTestedAt      = Date()

        return (before, newScore)
    }

    // MARK: - Decay

    /// Applies weekly proficiency decay for neglected topics (>30 days since study).
    static func applyDecay(to topics: [Topic]) {
        let now = Date()
        for topic in topics {
            guard topic.isDecaying,
                  let last = topic.lastStudiedAt else { continue }

            let daysSince = Calendar.current.dateComponents([.day], from: last, to: now).day ?? 0
            let weeks     = max(0, (daysSince - 30)) / 7
            if weeks > 0 {
                let decayed = max(0, topic.proficiencyScore - weeks * ProficiencyThreshold.autoDecayPerWeek)
                topic.proficiencyScore = decayed
                topic.confidenceLevel  = .from(proficiency: decayed)
            }
        }
    }

    // MARK: - Reality Score™

    /// Composite score 0–100 representing how much the user actually knows.
    static func calculateRealityScore(subjects: [Subject]) -> Int {
        let allTopics = subjects.flatMap(\.topics)
        guard !allTopics.isEmpty else { return 0 }

        // Base: weighted average of effective proficiency
        let baseScore = allTopics.reduce(0) { $0 + $1.effectiveProficiency } / allTopics.count

        // Penalties
        let decayCount    = allTopics.filter(\.isDecaying).count
        let decayPenalty  = min(25, decayCount * 3)

        let noQsCount     = allTopics.filter { $0.totalQuestions == 0 }.count
        let noQsPenalty   = min(15, noQsCount * 2)

        let weakCount     = allTopics.filter { $0.proficiencyScore < 30 }.count
        let weakPenalty   = min(10, weakCount * 1)

        let raw = baseScore - decayPenalty - noQsPenalty - weakPenalty
        return max(0, min(100, raw))
    }

    // MARK: - Question Pool Selection

    /// Selects questions for a quiz mode. Returns ordered array ready to serve.
    static func selectQuestions(
        mode: QuizMode,
        subject: Subject? = nil,
        topic: Topic? = nil,
        allSubjects: [Subject],
        difficulty: Int = 3,
        maxDifficulty: Int = 5,
        countMultiplier: Double = 1.0
    ) -> [Question] {

        // Build the full pool
        let sourceTopics: [Topic]
        if let topic {
            sourceTopics = [topic]
        } else if let subject {
            sourceTopics = subject.topics
        } else {
            sourceTopics = allSubjects.flatMap(\.topics)
        }

        let pool = sourceTopics.flatMap(\.questions)
            .filter { $0.difficulty <= maxDifficulty }

        let adjustedCount = max(5, Int(Double(mode.questionCount) * countMultiplier))

        switch mode {

        case .quickFire:
            return Array(pool.shuffled().prefix(adjustedCount))

        case .deepDive:
            // Single topic, escalating difficulty (sort by difficulty, shuffle within each level)
            let sorted = pool.sorted { $0.difficulty < $1.difficulty }
            return Array(sorted.prefix(adjustedCount))

        case .weakSpotAssault:
            // Only from topics with proficiency < 40
            let weakTopics = sourceTopics.filter { $0.proficiencyScore < 40 }
            let weakPool   = weakTopics.flatMap(\.questions).filter { $0.difficulty <= maxDifficulty }
            let usable     = weakPool.isEmpty ? pool : weakPool
            return Array(usable.shuffled().prefix(adjustedCount))

        case .mixedBag:
            let weak   = pool.filter { ($0.topic?.proficiencyScore ?? 100) < 40 }
            let mid    = pool.filter { let s = $0.topic?.proficiencyScore ?? 100; return s >= 40 && s < 70 }
            let strong = pool.filter { ($0.topic?.proficiencyScore ?? 0) >= 70 }

            let weakCount   = Int(Double(mode.questionCount) * 0.60)
            let midCount    = Int(Double(mode.questionCount) * 0.30)
            let strongCount = mode.questionCount - weakCount - midCount

            var result: [Question] = []
            result += Array(weak.shuffled().prefix(weakCount))
            result += Array(mid.shuffled().prefix(midCount))
            result += Array(strong.shuffled().prefix(strongCount))

            // Fill any gaps if buckets were smaller than needed
            let deficit = mode.questionCount - result.count
            if deficit > 0 {
                let extras = pool.filter { !result.map(\.id).contains($0.id) }
                result    += Array(extras.shuffled().prefix(deficit))
            }

            return result.shuffled()

        case .bossFight:
            // Hardest questions (difficulty 4-5), from everywhere
            let hard = pool.filter { $0.difficulty >= 4 }
            let usable = hard.isEmpty ? pool : hard
            return Array(usable.shuffled().prefix(mode.questionCount))
        }
    }

    // MARK: - Adaptive Difficulty

    static func adjustDifficulty(
        current: Int,
        consecutiveCorrect: Int,
        consecutiveWrong: Int
    ) -> Int {
        if consecutiveCorrect >= QuizConfig.adaptiveCorrectStreak {
            return min(QuizConfig.maxDifficulty, current + 1)
        }
        if consecutiveWrong >= QuizConfig.adaptiveWrongStreak {
            return max(QuizConfig.minDifficulty, current - 1)
        }
        return current
    }

    // MARK: - Result Summary

    struct QuizSummary {
        let percentage: Double
        let grade: String
        let proficiencyChange: Int
        let brutalFeedback: String
        let correctCount: Int
        let wrongCount: Int
        let avgTimePerQuestion: Double
        let peakDifficulty: Int
    }

    static func buildSummary(
        answers: [QuizAnswer],
        questions: [Question],
        topic: Topic?,
        proficiencyBefore: Int,
        proficiencyAfter: Int
    ) -> QuizSummary {
        let correct   = answers.filter(\.isCorrect).count
        let total     = max(1, answers.count)
        let pct       = Double(correct) / Double(total) * 100

        let avgTime   = Double(answers.reduce(0) { $0 + $1.timeSpentSeconds }) / Double(total)
        let peakDiff  = answers.map(\.difficulty).max() ?? 3

        let grade: String
        switch pct {
        case 90...100: grade = "S"
        case 80..<90:  grade = "A"
        case 70..<80:  grade = "B"
        case 60..<70:  grade = "C"
        case 50..<60:  grade = "D"
        default:       grade = "F"
        }

        let feedback = BrutalMessages.quizFeedback(
            percentage: pct,
            topic: topic?.name ?? "your subjects",
            previousScore: nil
        )

        return QuizSummary(
            percentage: pct,
            grade: grade,
            proficiencyChange: proficiencyAfter - proficiencyBefore,
            brutalFeedback: feedback,
            correctCount: correct,
            wrongCount: total - correct,
            avgTimePerQuestion: avgTime,
            peakDifficulty: peakDiff
        )
    }
}
