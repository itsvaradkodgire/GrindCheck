import Foundation
import SwiftData

@Model
final class QuizAttempt {
    @Attribute(.unique) var id: UUID
    var topic: Topic?
    var subject: Subject?
    var quizMode: QuizMode
    var answers: [QuizAnswer]
    var totalScore: Int
    var maxScore: Int
    var percentage: Double
    var difficultyLevel: Int
    var brutalFeedback: String
    var proficiencyBefore: Int
    var proficiencyAfter: Int
    var durationSeconds: Int
    var createdAt: Date

    init(
        topic: Topic? = nil,
        subject: Subject? = nil,
        quizMode: QuizMode = .quickFire,
        answers: [QuizAnswer] = [],
        totalScore: Int = 0,
        maxScore: Int = 0,
        difficultyLevel: Int = 3,
        brutalFeedback: String = "",
        proficiencyBefore: Int = 0,
        proficiencyAfter: Int = 0,
        durationSeconds: Int = 0
    ) {
        self.id               = UUID()
        self.topic            = topic
        self.subject          = subject
        self.quizMode         = quizMode
        self.answers          = answers
        self.totalScore       = totalScore
        self.maxScore         = maxScore
        self.percentage       = maxScore > 0 ? Double(totalScore) / Double(maxScore) * 100 : 0
        self.difficultyLevel  = difficultyLevel
        self.brutalFeedback   = brutalFeedback
        self.proficiencyBefore = proficiencyBefore
        self.proficiencyAfter  = proficiencyAfter
        self.durationSeconds  = durationSeconds
        self.createdAt        = Date()
    }

    // MARK: - Computed Properties

    var isPassing: Bool    { percentage >= 60 }
    var isExcellent: Bool  { percentage >= 90 }
    var isPerfect: Bool    { percentage == 100 }

    var proficiencyChange: Int { proficiencyAfter - proficiencyBefore }
    var isImproving: Bool      { proficiencyChange > 0 }

    var correctAnswers: Int { answers.filter { $0.isCorrect }.count }
    var wrongAnswers: Int   { answers.filter { !$0.isCorrect }.count }

    var avgTimePerQuestion: Double {
        guard !answers.isEmpty else { return 0 }
        return Double(durationSeconds) / Double(answers.count)
    }

    var gradeLabel: String {
        switch percentage {
        case 90...100: return "S"
        case 80..<90:  return "A"
        case 70..<80:  return "B"
        case 60..<70:  return "C"
        case 50..<60:  return "D"
        default:       return "F"
        }
    }

    var gradePrimaryColor: String {
        switch percentage {
        case 90...100: return "#00E5FF"
        case 80..<90:  return "#00FF88"
        case 70..<80:  return "#FFCC00"
        case 60..<70:  return "#FF8844"
        default:       return "#FF3366"
        }
    }
}
