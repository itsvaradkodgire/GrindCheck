import Foundation
import Observation
import SwiftData

@Observable
final class FeedViewModel {

    // MARK: - Published State

    private(set) var cards: [FeedCard]       = []
    private(set) var comboStreak: Int         = 0
    private(set) var lastXPEarned: Int        = 0
    private(set) var answeredCards: [UUID: Bool] = [:]  // cardId → wasCorrect
    private(set) var sessionAnswerCount: Int  = 0
    private(set) var sessionCorrectCount: Int = 0

    // MARK: - Card Generation

    func generateCards(
        questions: [Question],
        subjects: [Subject],
        profile: UserProfile?,
        achievements: [Achievement],
        todayLog: DailyLog?,
        logs: [DailyLog] = [],
        count: Int = 25
    ) {
        let eligible = questions.filter { !$0.shownRecentlyInFeed }
        let pool     = eligible.isEmpty ? questions : eligible

        var generated: [FeedCard] = []

        for _ in 0..<count {
            let type = FeedCardType.allCases.weightedRandom(weight: \.weight) ?? .quiz
            if let card = makeCard(
                type: type,
                questions: pool,
                subjects: subjects,
                profile: profile,
                achievements: achievements,
                todayLog: todayLog
            ) {
                generated.append(card)
            }
        }

        // Prepend Due Review card when FSRS-due questions exist
        let dueQuestions = questions.filter { $0.isDueForReview }
        if !dueQuestions.isEmpty {
            let names = Array(Set(dueQuestions.compactMap { $0.topic?.name }))
                .sorted().prefix(4)
            generated.insert(
                FeedCard(content: .dueReview(count: dueQuestions.count, topicNames: Array(names))),
                at: 0
            )
        }

        // Prepend Weekly Debrief on Mondays
        if isMonday, let debrief = makeWeeklyDebrief(logs: logs, profile: profile) {
            let insertAt = dueQuestions.isEmpty ? 0 : 1
            generated.insert(debrief, at: min(insertAt, generated.count))
        }

        cards = generated.isEmpty
            ? [FeedCard(content: .realityCheck(
                message: "Add subjects and questions first. The feed needs material.",
                topicName: nil,
                subjectName: nil))]
            : generated
    }

    private var isMonday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 2
    }

    private func makeWeeklyDebrief(logs: [DailyLog], profile: UserProfile?) -> FeedCard? {
        let calendar    = Calendar.current
        let sevenAgo    = calendar.date(byAdding: .day, value: -7,  to: Date())!
        let fourteenAgo = calendar.date(byAdding: .day, value: -14, to: Date())!

        let thisWeek = logs.filter { $0.date >= sevenAgo }
        let lastWeek = logs.filter { $0.date >= fourteenAgo && $0.date < sevenAgo }

        let xpThis  = thisWeek.map(\.xpEarned).reduce(0, +)
        let xpLast  = lastWeek.map(\.xpEarned).reduce(0, +)
        let minutes = thisWeek.map(\.totalStudyMinutes).reduce(0, +)
        let quizzes = thisWeek.map(\.quizzesTaken).reduce(0, +)
        let topics  = thisWeek.map(\.topicsStudiedCount).reduce(0, +)

        guard xpThis > 0 || minutes > 0 else { return nil }

        return FeedCard(content: .weeklyDebrief(
            xpThisWeek:   xpThis,
            xpLastWeek:   xpLast,
            studyMinutes: minutes,
            quizzesTaken: quizzes,
            topicsStudied: topics,
            streak:       profile?.currentStreak ?? 0
        ))
    }

    func appendMoreCards(
        questions: [Question],
        subjects: [Subject],
        profile: UserProfile?,
        achievements: [Achievement],
        todayLog: DailyLog?
    ) {
        generateCards(questions: questions, subjects: subjects,
                      profile: profile, achievements: achievements,
                      todayLog: todayLog, count: 15)
        // Append rather than replace when loading more
    }

    func loadMoreIfNeeded(currentIndex: Int, questions: [Question], subjects: [Subject],
                          profile: UserProfile?, achievements: [Achievement], todayLog: DailyLog?) {
        guard currentIndex >= cards.count - 5 else { return }
        let extra = makeExtraCards(questions: questions, subjects: subjects,
                                   profile: profile, achievements: achievements,
                                   todayLog: todayLog)
        cards.append(contentsOf: extra)
    }

    // MARK: - Card Factory

    private func makeCard(
        type: FeedCardType,
        questions: [Question],
        subjects: [Subject],
        profile: UserProfile?,
        achievements: [Achievement],
        todayLog: DailyLog?
    ) -> FeedCard? {

        switch type {

        case .quiz:
            // 60% weak topics, 30% mid, 10% strong
            let weak = questions.filter { ($0.topic?.proficiencyScore ?? 100) < 40 }
            let mid  = questions.filter { let s = $0.topic?.proficiencyScore ?? 100; return s >= 40 && s < 70 }
            let strong = questions.filter { ($0.topic?.proficiencyScore ?? 0) >= 70 }
            let pool: [Question]
            let r = Int.random(in: 0..<10)
            if r < 6, let q = weak.randomElement()   { pool = [q] }
            else if r < 9, let q = mid.randomElement() { pool = [q] }
            else if let q = strong.randomElement()    { pool = [q] }
            else { pool = [] }
            guard let question = pool.first ?? questions.randomElement() else { return nil }
            return FeedCard(content: .quiz(question))

        case .flashcard:
            guard let question = questions.randomElement() else { return nil }
            return FeedCard(content: .flashcard(question))

        case .realityCheck:
            let decaying = subjects.flatMap(\.topics).filter(\.isDecaying)
            if let topic = decaying.randomElement() {
                return FeedCard(content: .realityCheck(
                    message: BrutalMessages.stagnationMessage(
                        topic: topic.name, daysSince: topic.daysSinceLastStudy),
                    topicName: topic.name,
                    subjectName: topic.subject?.name
                ))
            }
            return FeedCard(content: .realityCheck(
                message: BrutalMessages.dailyCheck(
                    studyMinutes: todayLog?.totalStudyMinutes ?? 0,
                    goalMinutes: profile?.dailyGoalMinutes ?? 60,
                    streak: profile?.currentStreak ?? 0
                ),
                topicName: nil, subjectName: nil
            ))

        case .stats:
            guard let p = profile else { return nil }
            return FeedCard(content: .stats(
                todayMinutes: todayLog?.totalStudyMinutes ?? 0,
                weekXP: todayLog?.xpEarned ?? 0,
                streak: p.currentStreak,
                level: p.level,
                levelTitle: p.levelTitle
            ))

        case .achievementTease:
            let close = achievements.filter(\.isAlmostUnlocked)
            guard let ach = close.randomElement() else { return nil }
            return FeedCard(content: .achievementTease(
                name: ach.name,
                description: ach.descriptionText,
                icon: ach.icon,
                rarity: ach.rarity,
                progress: ach.progressFraction,
                currentValue: ach.currentValue,
                targetValue: ach.targetValue
            ))

        case .challenge:
            guard let ch = DailyChallenge.allChallenges.randomElement() else { return nil }
            return FeedCard(content: .challenge(text: ch.text, icon: ch.icon, subtext: ch.subtext))
        }
    }

    private func makeExtraCards(
        questions: [Question], subjects: [Subject],
        profile: UserProfile?, achievements: [Achievement], todayLog: DailyLog?
    ) -> [FeedCard] {
        var extra: [FeedCard] = []
        for _ in 0..<10 {
            let type = FeedCardType.allCases.weightedRandom(weight: \.weight) ?? .quiz
            if let c = makeCard(type: type, questions: questions, subjects: subjects,
                                profile: profile, achievements: achievements, todayLog: todayLog) {
                extra.append(c)
            }
        }
        return extra
    }

    // MARK: - Answer Recording

    /// Returns XP earned (includes combo multiplier).
    @discardableResult
    func recordCorrectAnswer(cardId: UUID, question: Question, context: ModelContext) -> Int {
        comboStreak += 1
        sessionAnswerCount  += 1
        sessionCorrectCount += 1
        answeredCards[cardId] = true

        let multiplier = ComboMultiplier.multiplier(forStreak: comboStreak)
        let xp         = XPAward.feedCorrect * multiplier
        lastXPEarned   = xp

        question.recordAttempt(wasCorrect: true)
        question.markShownInFeed()

        awardXP(xp, context: context)

        if [ComboMultiplier.tier1Streak, ComboMultiplier.tier2Streak,
            ComboMultiplier.tier3Streak, ComboMultiplier.tier4Streak].contains(comboStreak) {
            HapticManager.shared.comboMilestone()
        }

        return xp
    }

    func recordWrongAnswer(cardId: UUID, question: Question, context: ModelContext) {
        comboStreak = 0
        sessionAnswerCount += 1
        answeredCards[cardId] = false

        question.recordAttempt(wasCorrect: false)
        question.markShownInFeed()

        try? context.save()
    }

    func recordFlashcardKnew(cardId: UUID) {
        answeredCards[cardId] = true
        comboStreak += 1
        sessionAnswerCount += 1
        sessionCorrectCount += 1
    }

    func recordFlashcardNeedsReview(cardId: UUID, topic: Topic?, context: ModelContext) {
        answeredCards[cardId] = false
        comboStreak = 0
        sessionAnswerCount += 1
        // Flag the topic for review
        topic?.lastStudiedAt = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        try? context.save()
    }

    // MARK: - Helpers

    private func awardXP(_ xp: Int, context: ModelContext) {
        let desc = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(desc).first {
            let didLevelUp = profile.addXP(xp)
            if didLevelUp { HapticManager.shared.levelUp() }
        }

        let today     = DailyLog.normalizedDate()
        let logDesc   = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.date == today })
        if let log    = try? context.fetch(logDesc).first {
            log.addXP(xp)
        }

        try? context.save()
    }

    var isCardAnswered: (UUID) -> Bool {
        { [weak self] id in self?.answeredCards[id] != nil }
    }

    var sessionAccuracy: Double {
        guard sessionAnswerCount > 0 else { return 0 }
        return Double(sessionCorrectCount) / Double(sessionAnswerCount)
    }
}
