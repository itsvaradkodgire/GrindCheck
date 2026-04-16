import Foundation
import SwiftData

@Model
final class Topic {
    @Attribute(.unique) var id: UUID
    var name: String
    var subject: Subject?
    var proficiencyScore: Int        // 0-100
    var confidenceLevel: ConfidenceLevel
    var totalTimeSpentMinutes: Int
    var lastStudiedAt: Date?
    var lastTestedAt: Date?
    var notes: String
    @Relationship(deleteRule: .cascade) var questions: [Question]
    @Relationship(deleteRule: .nullify) var prerequisites: [Topic]   // Topics to master first
    @Relationship(deleteRule: .cascade) var article: TopicArticle?   // Knowledge base article
    var createdAt: Date

    init(
        name: String,
        subject: Subject? = nil,
        notes: String = ""
    ) {
        self.id                   = UUID()
        self.name                 = name
        self.subject              = subject
        self.proficiencyScore     = 0
        self.confidenceLevel      = .unknown
        self.totalTimeSpentMinutes = 0
        self.lastStudiedAt        = nil
        self.lastTestedAt         = nil
        self.notes                = notes
        self.questions            = []
        self.prerequisites        = []
        self.createdAt            = Date()
    }

    // MARK: - Decay

    var daysSinceLastStudy: Int {
        guard let last = lastStudiedAt else { return 9999 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 9999
    }

    var isDecaying: Bool { daysSinceLastStudy > 14 }

    /// 0 = fresh, 1 = fully decayed (after 44 days of neglect)
    var decayFraction: Double {
        let days = daysSinceLastStudy
        guard days > 14 else { return 0 }
        return min(1.0, Double(days - 14) / 30.0)
    }

    /// Proficiency adjusted for decay (auto-decreases 5%/week after 30 days)
    var effectiveProficiency: Int {
        let weeks = max(0, daysSinceLastStudy - 30) / 7
        let decayed = proficiencyScore - (weeks * 5)
        return max(0, decayed)
    }

    // MARK: - Question Stats

    var totalQuestions: Int { questions.count }

    var overallAccuracyRate: Double {
        let asked   = questions.reduce(0) { $0 + $1.timesAsked }
        let correct = questions.reduce(0) { $0 + $1.timesCorrect }
        guard asked > 0 else { return 0 }
        return Double(correct) / Double(asked)
    }

    var nemesisQuestions: [Question] {
        questions.filter { $0.isNemesis }
    }

    var hoursStudied: Double {
        Double(totalTimeSpentMinutes) / 60.0
    }

    /// True if all prerequisites are sufficiently mastered (proficiency >= 60)
    var prerequisitesMet: Bool {
        prerequisites.allSatisfy { $0.proficiencyScore >= 60 }
    }

    var unmetPrerequisites: [Topic] {
        prerequisites.filter { $0.proficiencyScore < 60 }
    }

    // MARK: - Proficiency Update

    func updateProficiency(quizPercentage: Double) {
        // Weighted average: 70% existing, 30% new quiz result
        let newScore = Int(Double(proficiencyScore) * 0.7 + quizPercentage * 0.3)
        proficiencyScore  = max(0, min(100, newScore))
        confidenceLevel   = ConfidenceLevel.from(proficiency: proficiencyScore)
        lastTestedAt      = Date()
    }

    func addStudyTime(minutes: Int) {
        totalTimeSpentMinutes += minutes
        lastStudiedAt          = Date()
        // Small proficiency nudge for showing up
        if proficiencyScore < 100 {
            proficiencyScore = min(100, proficiencyScore + 1)
        }
        confidenceLevel = ConfidenceLevel.from(proficiency: proficiencyScore)
    }
}
