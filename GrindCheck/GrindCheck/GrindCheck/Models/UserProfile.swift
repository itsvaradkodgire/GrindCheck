import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var totalXP: Int
    var level: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var dailyGoalMinutes: Int
    var difficultyPreference: DifficultyLevel
    var realityScore: Int
    var totalStudyMinutes: Int
    var soundEffectsEnabled: Bool
    var hapticsEnabled: Bool
    var createdAt: Date

    // MARK: - Freeze Tokens
    var freezeTokens: Int          // Earned by studying extra; each protects one missed day
    var lastFreezeUsedDate: Date?  // Prevents using multiple freezes consecutively

    // MARK: - Mood / Pre-session
    var lastMoodRating: Int        // 1=Stressed, 2=Tired, 3=OK, 4=Focused, 5=Energized
    var lastMoodDate: Date?

    // MARK: - Exam Scheduler
    var examDate: Date?
    var examSubjectName: String

    init(
        name: String = "Grinder",
        dailyGoalMinutes: Int = 60,
        difficultyPreference: DifficultyLevel = .normal
    ) {
        self.id = UUID()
        self.name = name
        self.totalXP = 0
        self.level = 1
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.dailyGoalMinutes = dailyGoalMinutes
        self.difficultyPreference = difficultyPreference
        self.realityScore = 0
        self.totalStudyMinutes = 0
        self.soundEffectsEnabled = true
        self.hapticsEnabled = true
        self.createdAt = Date()
        self.freezeTokens = 0
        self.lastFreezeUsedDate = nil
        self.lastMoodRating = 3
        self.lastMoodDate = nil
        self.examDate = nil
        self.examSubjectName = ""
    }

    // MARK: - Level System

    var levelTitle: String {
        switch level {
        case 1...4:   return "Clueless Beginner"
        case 5...9:   return "Page Turner"
        case 10...14: return "Getting Somewhere"
        case 15...24: return "Not Totally Lost"
        case 25...34: return "Actual Student"
        case 35...49: return "Knowledge Seeker"
        case 50...64: return "Half Dangerous"
        case 65...74: return "Grind Master"
        case 75...84: return "Almost Dangerous"
        case 85...94: return "Knowledge Warrior"
        case 95...99: return "Near Enlightenment"
        case 100:     return "Walking Encyclopedia"
        default:      return "Legend Beyond Level"
        }
    }

    var xpForCurrentLevel: Int { xpRequired(forLevel: level) }
    var xpForNextLevel: Int    { xpRequired(forLevel: level + 1) }

    var levelProgress: Double {
        let current = xpRequired(forLevel: level)
        let next    = xpRequired(forLevel: level + 1)
        guard next > current else { return 1.0 }
        let progress = Double(totalXP - current) / Double(next - current)
        return max(0, min(1, progress))
    }

    var xpIntoCurrentLevel: Int { totalXP - xpRequired(forLevel: level) }
    var xpNeededForNextLevel: Int { xpRequired(forLevel: level + 1) - xpRequired(forLevel: level) }

    private func xpRequired(forLevel lvl: Int) -> Int {
        guard lvl > 1 else { return 0 }
        // Base 50 XP per level, scaling ~15% per level
        var total = 0
        var base  = 50
        for _ in 2...lvl {
            total += base
            base   = Int(Double(base) * 1.15)
        }
        return total
    }

    var totalStudyHours: Double { Double(totalStudyMinutes) / 60.0 }

    // MARK: - XP & Level Management

    /// Awards XP and returns true if a level-up occurred
    @discardableResult
    func addXP(_ amount: Int) -> Bool {
        totalXP += amount
        let newLevel = computeLevel(forXP: totalXP)
        let didLevelUp = newLevel > level
        level = newLevel
        return didLevelUp
    }

    private func computeLevel(forXP xp: Int) -> Int {
        var lvl = 1
        while xpRequired(forLevel: lvl + 1) <= xp && lvl < 100 {
            lvl += 1
        }
        return lvl
    }

    // MARK: - Streak

    func updateStreak(for date: Date = Date()) {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: date)

        if let last = lastActiveDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff    = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            switch diff {
            case 0:  break                          // same day, no change
            case 1:  currentStreak += 1             // consecutive day
            case 2:  // missed exactly 1 day — try to use a freeze token
                let frozeRecently = lastFreezeUsedDate.map {
                    calendar.dateComponents([.day], from: $0, to: today).day ?? 0 < 2
                } ?? false
                if freezeTokens > 0 && !frozeRecently {
                    freezeTokens       -= 1
                    currentStreak      += 1          // streak preserved!
                    lastFreezeUsedDate  = today
                } else {
                    currentStreak = 1               // streak broken
                }
            default: currentStreak = 1              // streak broken (2+ days gap)
            }
        } else {
            currentStreak = 1
        }

        longestStreak  = max(longestStreak, currentStreak)
        lastActiveDate = date
    }

    /// Award a freeze token for an especially productive session (e.g. > 2× daily goal).
    /// Maximum 5 tokens banked at once.
    func tryEarnFreezeToken(studyMinutes: Int) {
        let threshold = dailyGoalMinutes * 2
        if studyMinutes >= threshold && freezeTokens < 5 {
            freezeTokens += 1
        }
    }

    /// Whether a freeze token was used today (show indicator in UI).
    var usedFreezeToday: Bool {
        guard let d = lastFreezeUsedDate else { return false }
        return Calendar.current.isDateInToday(d)
    }
}
