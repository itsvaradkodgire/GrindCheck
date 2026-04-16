import Foundation

// MARK: - Feed Card Value Types

struct FeedCard: Identifiable {
    let id = UUID()
    let content: FeedCardContent
}

enum FeedCardContent {
    case quiz(Question)
    case flashcard(Question)
    case realityCheck(message: String, topicName: String?, subjectName: String?)
    case stats(todayMinutes: Int, weekXP: Int, streak: Int, level: Int, levelTitle: String)
    case achievementTease(
        name: String,
        description: String,
        icon: String,
        rarity: AchievementRarity,
        progress: Double,
        currentValue: Double,
        targetValue: Double
    )
    case challenge(text: String, icon: String, subtext: String)
    case dueReview(count: Int, topicNames: [String])
    case weeklyDebrief(xpThisWeek: Int, xpLastWeek: Int, studyMinutes: Int,
                       quizzesTaken: Int, topicsStudied: Int, streak: Int)
}

// MARK: - Daily Challenge Definitions

struct DailyChallenge {
    let text: String
    let icon: String
    let subtext: String

    static let allChallenges: [DailyChallenge] = [
        .init(text: "Study 3 different subjects",
              icon: "3.circle.fill",
              subtext: "Breadth beats depth sometimes"),
        .init(text: "Score 80%+ on any quiz",
              icon: "checkmark.seal.fill",
              subtext: "No excuses. You know this material."),
        .init(text: "Add 5 new questions to your bank",
              icon: "plus.circle.fill",
              subtext: "Writing good questions is studying"),
        .init(text: "Answer 20 feed questions",
              icon: "play.rectangle.fill",
              subtext: "This is what the feed is for"),
        .init(text: "Review your weakest topic",
              icon: "arrow.up.heart.fill",
              subtext: "You know which one. Stop avoiding it."),
        .init(text: "Survive a Boss Fight",
              icon: "flame.fill",
              subtext: "If you can't, you weren't ready"),
        .init(text: "Study for 45 uninterrupted minutes",
              icon: "timer",
              subtext: "No phone. No alt-tab. Just you and the material."),
        .init(text: "Hit 80% accuracy in the feed",
              icon: "target",
              subtext: "Random guessing won't get you there"),
        .init(text: "Fix a decaying topic",
              icon: "arrow.clockwise.circle.fill",
              subtext: "One review is better than none"),
        .init(text: "Get a 10-answer correct streak",
              icon: "bolt.circle.fill",
              subtext: "Ten in a row without slipping"),
    ]
}
