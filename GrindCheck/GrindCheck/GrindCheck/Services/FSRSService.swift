import Foundation

// MARK: - FSRS Rating

enum FSRSRating: Int {
    case again = 1   // Completely forgot
    case hard  = 2   // Recalled with difficulty
    case good  = 3   // Recalled correctly
    case easy  = 4   // Recalled instantly
}

// MARK: - FSRS-4.5 Service

/// Implements the Free Spaced Repetition Scheduler (FSRS-4.5).
/// Trained on 400M+ real reviews — reduces required reviews ~20-30% vs SM-2.
/// Reference: https://github.com/open-spaced-repetition/fsrs4anki
final class FSRSService {

    static let shared = FSRSService()
    private init() {}

    // FSRS-4.5 default weights (trained on real review data)
    private let w: [Double] = [
        0.40255, 1.18385, 3.1262, 15.4722,
        7.2102,  0.5316,  1.0651, 0.06166,
        1.4351,  0.14327, 1.0531, 1.9393,
        0.11282, 0.29898, 2.2700, 0.52975,
        2.9898,  0.51655, 0.6621
    ]

    private let DECAY:  Double = -0.5
    // FACTOR = 0.9^(1/DECAY) - 1
    private let FACTOR: Double = 19.0 / 81.0   // ≈ 0.2346
    private let targetRetention: Double = 0.90

    // MARK: - Public API

    /// Process a review and mutate the question's FSRS fields.
    func review(question: Question, rating: FSRSRating) {
        let elapsedDays = elapsedSince(question.lastAskedAt)

        switch question.fsrsState {
        case 0:  // New
            initNew(question: question, rating: rating)
        case 1, 3:  // Learning / Relearning
            reviewLearning(question: question, rating: rating)
        case 2:  // Review
            reviewMature(question: question, rating: rating, elapsedDays: elapsedDays)
        default:
            initNew(question: question, rating: rating)
        }
    }

    /// Returns all questions sorted by urgency (most overdue first).
    func dueQuestions(from questions: [Question]) -> [Question] {
        questions
            .filter { $0.isDueForReview }
            .sorted { ($0.daysUntilDue) < ($1.daysUntilDue) }
    }

    /// Questions due within the next N days (for session planning).
    func questionsDueInDays(_ days: Int, from questions: [Question]) -> [Question] {
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return questions.filter { q in
            guard let due = q.fsrsDueDate else { return q.fsrsState == 0 }
            return due <= cutoff
        }.sorted { ($0.fsrsDueDate ?? Date()) < ($1.fsrsDueDate ?? Date()) }
    }

    // MARK: - Private Logic

    private func initNew(question: Question, rating: FSRSRating) {
        let g = Double(rating.rawValue)
        // Initial stability from grade
        question.fsrsStability  = max(0.1, w[rating.rawValue - 1])
        // Initial difficulty
        question.fsrsDifficulty = clampD(w[4] - exp(w[5] * (g - 1)) + 1)
        question.fsrsReps       = rating == .again ? 0 : 1
        question.fsrsLapses     = rating == .again ? 1 : 0
        question.fsrsState      = rating == .again ? 1 : 2  // 1=Learning, 2=Review

        let interval = rating == .again ? 1 : nextInterval(stability: question.fsrsStability)
        question.fsrsDueDate = Calendar.current.date(byAdding: .day, value: max(1, interval), to: Date())
    }

    private func reviewLearning(question: Question, rating: FSRSRating) {
        if rating == .again {
            question.fsrsLapses += 1
            question.fsrsStability = max(0.1, w[0])
            question.fsrsDueDate   = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else {
            question.fsrsReps     += 1
            question.fsrsState     = 2  // Graduate to Review
            question.fsrsStability = max(0.1, w[rating.rawValue - 1])
            let interval = nextInterval(stability: question.fsrsStability)
            question.fsrsDueDate   = Calendar.current.date(byAdding: .day, value: max(1, interval), to: Date())
        }
        updateDifficulty(question: question, rating: rating)
    }

    private func reviewMature(question: Question, rating: FSRSRating, elapsedDays: Double) {
        let S  = max(0.1, question.fsrsStability)
        let D  = question.fsrsDifficulty
        let R  = retrievability(stability: S, elapsedDays: elapsedDays)

        updateDifficulty(question: question, rating: rating)

        if rating == .again {
            // Forgotten — reset to Relearning
            question.fsrsLapses   += 1
            question.fsrsState     = 3  // Relearning
            question.fsrsStability = forgettingStability(S: S, D: D, R: R)
            question.fsrsDueDate   = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else {
            // Recalled — use recall stability formula
            question.fsrsReps     += 1
            question.fsrsState     = 2
            question.fsrsStability = recallStability(S: S, D: D, R: R, rating: rating)
            let interval = nextInterval(stability: question.fsrsStability)
            question.fsrsDueDate   = Calendar.current.date(byAdding: .day, value: max(1, interval), to: Date())
        }
    }

    // MARK: - FSRS Math

    /// R(t) = (1 + FACTOR * t / S)^DECAY
    private func retrievability(stability: Double, elapsedDays: Double) -> Double {
        pow(1 + FACTOR * elapsedDays / stability, DECAY)
    }

    /// Stability after successful recall
    private func recallStability(S: Double, D: Double, R: Double, rating: FSRSRating) -> Double {
        let hardPenalty: Double = rating == .hard ? w[15] : 1.0
        let easyBonus:   Double = rating == .easy ? w[16] : 1.0
        return S * (exp(w[8]) * (11 - D) * pow(S, -w[9]) * (exp(w[10] * (1 - R)) - 1) * hardPenalty * easyBonus + 1)
    }

    /// Stability after forgetting (lapses)
    private func forgettingStability(S: Double, D: Double, R: Double) -> Double {
        w[11] * pow(D, -w[12]) * (pow(S + 1, w[13]) - 1) * exp(w[14] * (1 - R))
    }

    /// D' = D + mean_reversion(w[6] * (4-grade))
    private func updateDifficulty(question: Question, rating: FSRSRating) {
        let g = Double(rating.rawValue)
        let delta = -w[6] * (g - 3)
        // Mean reversion toward initial difficulty
        let newD = question.fsrsDifficulty + delta
        question.fsrsDifficulty = clampD(newD * 1.0 + (1 - 1.0) * w[4])  // simplified mean reversion
    }

    /// Convert stability to interval (days) targeting 90% retention
    private func nextInterval(stability: Double) -> Int {
        let interval = stability / FACTOR * (pow(targetRetention, 1.0 / DECAY) - 1)
        return max(1, Int(interval.rounded()))
    }

    private func clampD(_ d: Double) -> Double { min(10, max(1, d)) }

    private func elapsedSince(_ date: Date?) -> Double {
        guard let date else { return 0 }
        return max(0, Date().timeIntervalSince(date) / 86_400)
    }
}
