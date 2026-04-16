import Foundation
import SwiftData

@Model
final class Question {
    @Attribute(.unique) var id: UUID
    var topic: Topic?
    var questionText: String
    var questionType: QuestionType
    var options: [String]       // For MCQ / true-false
    var correctAnswer: String
    var explanation: String
    var difficulty: Int         // 1–5
    var tags: [String]
    var timesAsked: Int
    var timesCorrect: Int
    var timesWrong: Int
    var lastAskedAt: Date?
    var lastShownInFeed: Date?
    var isAIGenerated: Bool
    var isBookmarked: Bool
    var createdAt: Date

    // MARK: - FSRS State (Free Spaced Repetition Scheduler)
    var fsrsStability: Double      // How long (days) before 90% forgetting
    var fsrsDifficulty: Double     // 1–10, higher = harder to remember
    var fsrsDueDate: Date?         // When to next review
    var fsrsReps: Int              // Total successful reviews
    var fsrsLapses: Int            // Times forgotten (Again)
    var fsrsState: Int             // 0=New, 1=Learning, 2=Review, 3=Relearning

    init(
        topic: Topic? = nil,
        questionText: String,
        questionType: QuestionType = .mcq,
        options: [String] = [],
        correctAnswer: String,
        explanation: String = "",
        difficulty: Int = 3,
        tags: [String] = [],
        isAIGenerated: Bool = false
    ) {
        self.id              = UUID()
        self.topic           = topic
        self.questionText    = questionText
        self.questionType    = questionType
        self.options         = options
        self.correctAnswer   = correctAnswer
        self.explanation     = explanation
        self.difficulty      = max(1, min(5, difficulty))
        self.tags            = tags
        self.timesAsked      = 0
        self.timesCorrect    = 0
        self.timesWrong      = 0
        self.lastAskedAt     = nil
        self.lastShownInFeed = nil
        self.isAIGenerated   = isAIGenerated
        self.isBookmarked    = false
        self.createdAt       = Date()
        self.fsrsStability   = 0
        self.fsrsDifficulty  = 0
        self.fsrsDueDate     = nil
        self.fsrsReps        = 0
        self.fsrsLapses      = 0
        self.fsrsState       = 0
    }

    // MARK: - Computed Properties

    var accuracyRate: Double {
        guard timesAsked > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesAsked)
    }

    /// Nemesis: wrong more than right, asked at least 3 times
    var isNemesis: Bool {
        timesAsked >= 3 && timesWrong > timesCorrect
    }

    /// Shown in feed in the last 24 hours
    var shownRecentlyInFeed: Bool {
        guard let last = lastShownInFeed else { return false }
        return Date().timeIntervalSince(last) < 86_400
    }

    var difficultyLabel: String {
        switch difficulty {
        case 1: return "Basics"
        case 2: return "Understanding"
        case 3: return "Application"
        case 4: return "Analysis"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }

    // MARK: - Recording Answers

    func recordAttempt(wasCorrect: Bool) {
        timesAsked   += 1
        lastAskedAt   = Date()
        if wasCorrect { timesCorrect += 1 } else { timesWrong += 1 }
        // Update FSRS state
        let rating: FSRSRating = wasCorrect ? .good : .again
        FSRSService.shared.review(question: self, rating: rating)
    }

    /// Whether FSRS has scheduled this card for review today or earlier
    var isDueForReview: Bool {
        guard let due = fsrsDueDate else { return fsrsState == 0 } // New card
        return due <= Date()
    }

    /// Days until next FSRS review (negative = overdue)
    var daysUntilDue: Int {
        guard let due = fsrsDueDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
    }

    func markShownInFeed() {
        lastShownInFeed = Date()
    }
}
