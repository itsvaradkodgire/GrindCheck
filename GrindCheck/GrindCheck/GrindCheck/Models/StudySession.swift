import Foundation
import SwiftData

@Model
final class StudySession {
    @Attribute(.unique) var id: UUID
    var topic: Topic?
    var subject: Subject?
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var sessionType: SessionType
    var focusRating: Int      // 1–5, self-reported
    var notes: String
    var brutalSummary: String
    var wasPomodoro: Bool
    var pomodoroCount: Int    // how many 25-min blocks completed
    var createdAt: Date

    init(
        topic: Topic? = nil,
        subject: Subject? = nil,
        sessionType: SessionType = .study,
        wasPomodoro: Bool = false
    ) {
        self.id             = UUID()
        self.topic          = topic
        self.subject        = subject
        self.startTime      = Date()
        self.endTime        = nil
        self.durationMinutes = 0
        self.sessionType    = sessionType
        self.focusRating    = 3
        self.notes          = ""
        self.brutalSummary  = ""
        self.wasPomodoro    = wasPomodoro
        self.pomodoroCount  = 0
        self.createdAt      = Date()
    }

    // MARK: - Computed

    var isActive: Bool    { endTime == nil }
    var isTooShort: Bool  { durationMinutes < 5 }

    var durationFormatted: String {
        guard durationMinutes > 0 else { return "0m" }
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        return "\(m)m"
    }

    var xpEarned: Int {
        // 10 XP per 25-min block, bonus for focus rating
        let blocks = max(1, durationMinutes / 25)
        let base   = blocks * 10
        let bonus  = (focusRating - 3) * 2   // -4 to +4
        return max(0, base + bonus)
    }

    // MARK: - Lifecycle

    func endSession(focusRating: Int, notes: String = "") {
        endTime          = Date()
        durationMinutes  = Int(Date().timeIntervalSince(startTime) / 60)
        self.focusRating = max(1, min(5, focusRating))
        self.notes       = notes
        pomodoroCount    = durationMinutes / 25
        brutalSummary    = generateBrutalSummary()
    }

    private func generateBrutalSummary() -> String {
        let topicName = topic?.name ?? subject?.name ?? "something"

        if isTooShort {
            return "That wasn't studying. That was opening a book and putting it down."
        }

        switch durationMinutes {
        case 5..<20:
            return "\(durationMinutes) min on \(topicName). Barely warmed up. Sit back down."
        case 20..<45:
            return "\(durationMinutes) min on \(topicName). Not bad, but not enough. You know it."
        case 45..<90:
            return "Solid \(durationMinutes) min on \(topicName). This is what consistency looks like."
        case 90..<120:
            return "\(durationMinutes) min deep on \(topicName). Real work. Don't celebrate yet — review this tomorrow."
        default:
            return "\(durationFormatted) on \(topicName). Impressive. Now sleep, or you'll retain none of it."
        }
    }
}
