import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var date: Date  // Stored as start-of-day
    var totalStudyMinutes: Int
    var topicsStudiedCount: Int
    var quizzesTaken: Int
    var avgQuizScore: Double
    var xpEarned: Int
    var streakDay: Int
    var realityCheckMessage: String
    var goalHit: Bool
    var quizScoreTotal: Double  // sum for avg calculation

    init(date: Date = Date()) {
        self.date                = Calendar.current.startOfDay(for: date)
        self.totalStudyMinutes   = 0
        self.topicsStudiedCount  = 0
        self.quizzesTaken        = 0
        self.avgQuizScore        = 0
        self.xpEarned            = 0
        self.streakDay           = 0
        self.realityCheckMessage = ""
        self.goalHit             = false
        self.quizScoreTotal      = 0
    }

    // MARK: - Computed

    var studyHours: Double { Double(totalStudyMinutes) / 60.0 }

    /// 0–4 intensity level for heatmap (GitHub-style)
    var intensityLevel: Int {
        switch totalStudyMinutes {
        case 0:      return 0
        case 1..<30: return 1
        case 30..<60: return 2
        case 60..<120: return 3
        default:     return 4
        }
    }

    var studyTimeFormatted: String {
        guard totalStudyMinutes > 0 else { return "0m" }
        let h = totalStudyMinutes / 60
        let m = totalStudyMinutes % 60
        return h > 0 ? (m > 0 ? "\(h)h \(m)m" : "\(h)h") : "\(m)m"
    }

    // MARK: - Mutations

    func addStudyMinutes(_ minutes: Int) {
        totalStudyMinutes += minutes
    }

    func recordQuiz(score: Double) {
        quizzesTaken    += 1
        quizScoreTotal  += score
        avgQuizScore     = quizScoreTotal / Double(quizzesTaken)
    }

    func addXP(_ xp: Int) {
        xpEarned += xp
    }

    // MARK: - Static Helpers

    static func normalizedDate(_ date: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
