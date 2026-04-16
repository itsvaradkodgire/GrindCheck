import Foundation
import SwiftData

// MARK: - Gamification Engine
// Central authority for XP awards, achievement unlocks, and level progression.

@MainActor
final class GamificationEngine {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - XP Awards

    /// Awards XP and returns (xpAwarded, didLevelUp)
    @discardableResult
    func awardXP(_ base: Int, comboMultiplier: Int = 1) -> (xp: Int, leveledUp: Bool) {
        let total = base * max(1, comboMultiplier)

        guard let profile = fetchProfile() else { return (total, false) }
        let leveledUp = profile.addXP(total)
        profile.updateStreak()

        updateDailyLog { log in
            log.addXP(total)
        }

        try? context.save()
        return (total, leveledUp)
    }

    // MARK: - Study Session

    func recordStudySession(durationMinutes: Int, topicId: UUID? = nil) {
        let xpBase = max(0, (durationMinutes / 25)) * XPAward.studyBlock25Min
        awardXP(xpBase)

        updateDailyLog { log in
            log.addStudyMinutes(durationMinutes)
        }

        if let topicId {
            let desc = FetchDescriptor<Topic>(predicate: #Predicate { $0.id == topicId })
            if let topic = try? context.fetch(desc).first {
                topic.addStudyTime(minutes: durationMinutes)
            }
        }

        checkStudyAchievements(minutes: durationMinutes)
        try? context.save()
    }

    // MARK: - Quiz Completion

    func recordQuizCompleted(
        topicId: UUID?,
        mode: QuizMode,
        score: Int,
        maxScore: Int,
        proficiencyBefore: Int,
        proficiencyAfter: Int
    ) {
        let percentage = maxScore > 0 ? Double(score) / Double(maxScore) * 100 : 0

        // XP = base + score bonus
        let xpBase  = XPAward.quizBase
        let xpBonus = percentage == 100 ? XPAward.perfectQuiz : Int(percentage / 100 * 20)
        awardXP(xpBase + xpBonus)

        updateDailyLog { log in
            log.recordQuiz(score: percentage)
        }

        // Update topic proficiency
        if let topicId {
            let desc = FetchDescriptor<Topic>(predicate: #Predicate { $0.id == topicId })
            if let topic = try? context.fetch(desc).first {
                topic.updateProficiency(quizPercentage: percentage)
            }
        }

        checkQuizAchievements(mode: mode, percentage: percentage)
        try? context.save()
    }

    // MARK: - Achievement Checks

    func checkAllAchievements() {
        checkStudyTimeAchievements()
        checkStreakAchievements()
        checkQuizCountAchievements()
        checkQuestionCountAchievements()
    }

    private func checkStudyAchievements(minutes: Int) {
        guard let profile = fetchProfile() else { return }
        let totalMinutes = profile.totalStudyMinutes + minutes

        // First hour
        if totalMinutes >= 60 { unlockAchievement("first_hour") }

        // 100 hours
        if totalMinutes >= 6_000 { updateAchievementProgress("hundred_hours", value: Double(totalMinutes)) }

        // 500 hours
        if totalMinutes >= 30_000 { updateAchievementProgress("the_grind", value: Double(totalMinutes)) }

        // Pomodoro
        let blocks = minutes / 25
        if blocks >= 1 { unlockAchievement("pomodoro_first") }
    }

    private func checkQuizAchievements(mode: QuizMode, percentage: Double) {
        // First blood
        unlockAchievement("first_blood")

        // Boss slayer
        if mode == .bossFight && percentage >= 80 { unlockAchievement("boss_slayer") }

        // Perfect storm
        if mode == .bossFight && percentage == 100 { unlockAchievement("perfect_storm") }

        // Perfect quiz
        if percentage == 100 { unlockAchievement("first_perfect") }

        // Increment quiz count
        incrementAchievement("quiz_veteran")
        if percentage >= 90 { incrementAchievement("quiz_champion") }
    }

    private func checkStudyTimeAchievements() {
        guard let profile = fetchProfile() else { return }
        let minutes = profile.totalStudyMinutes

        updateAchievementProgress("first_hour", value: Double(min(minutes, 60)))
        updateAchievementProgress("hundred_hours", value: Double(minutes))
        updateAchievementProgress("the_grind", value: Double(minutes))
        updateAchievementProgress("five_hundred_hours", value: Double(minutes))
    }

    private func checkStreakAchievements() {
        guard let profile = fetchProfile() else { return }
        let streak = profile.currentStreak

        updateAchievementProgress("daily_dose", value: Double(min(streak, 3)))
        updateAchievementProgress("no_days_off", value: Double(min(streak, 7)))
        updateAchievementProgress("streak_lord", value: Double(min(streak, 30)))
        updateAchievementProgress("iron_will", value: Double(min(streak, 100)))
    }

    private func checkQuizCountAchievements() {
        let desc = FetchDescriptor<QuizAttempt>()
        let count = (try? context.fetchCount(desc)) ?? 0
        updateAchievementProgress("quiz_veteran", value: Double(count))
    }

    private func checkQuestionCountAchievements() {
        let desc = FetchDescriptor<Question>()
        let count = (try? context.fetchCount(desc)) ?? 0
        updateAchievementProgress("note_taker", value: 1)
        updateAchievementProgress("question_machine", value: Double(count))
        updateAchievementProgress("knowledge_architect", value: Double(count))
    }

    // MARK: - Achievement Helpers

    private func unlockAchievement(_ id: String) {
        let desc = FetchDescriptor<Achievement>(predicate: #Predicate { $0.id == id })
        if let achievement = try? context.fetch(desc).first, !achievement.isUnlocked {
            achievement.unlock()
        }
    }

    private func updateAchievementProgress(_ id: String, value: Double) {
        let desc = FetchDescriptor<Achievement>(predicate: #Predicate { $0.id == id })
        if let achievement = try? context.fetch(desc).first {
            achievement.updateProgress(value)
        }
    }

    private func incrementAchievement(_ id: String, by amount: Double = 1) {
        let desc = FetchDescriptor<Achievement>(predicate: #Predicate { $0.id == id })
        if let achievement = try? context.fetch(desc).first {
            achievement.incrementProgress(by: amount)
        }
    }

    // MARK: - Daily Log Helper

    private func updateDailyLog(_ update: (DailyLog) -> Void) {
        let today = DailyLog.normalizedDate()
        let desc  = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.date == today })
        if let log = try? context.fetch(desc).first {
            update(log)
        } else {
            let log = DailyLog(date: today)
            context.insert(log)
            update(log)
        }
    }

    // MARK: - Fetch Helpers

    private func fetchProfile() -> UserProfile? {
        let desc = FetchDescriptor<UserProfile>()
        return try? context.fetch(desc).first
    }
}
