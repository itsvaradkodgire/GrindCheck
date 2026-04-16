import SwiftUI

/// Routes each FeedCard to the correct card view.
struct FeedCardDispatcher: View {
    let card: FeedCard
    let viewModel: FeedViewModel
    let onCorrect: (Question) -> Void
    let onWrong: (Question) -> Void
    let onBookmark: (Question) -> Void
    let onFlashcardKnew: (Question) -> Void
    let onFlashcardReview: (Question) -> Void
    var onTopicTap: ((String) -> Void)? = nil
    var onStudyGuide: ((Question) -> Void)? = nil   // Feature 6
    var onStartDueReview: (() -> Void)? = nil        // Feature 4

    var body: some View {
        switch card.content {

        case .quiz(let question):
            QuizCard(
                card: card,
                question: question,
                onCorrect: onCorrect,
                onWrong: onWrong,
                onBookmark: onBookmark,
                alreadyAnswered: viewModel.answeredCards[card.id] != nil,
                wasCorrect: viewModel.answeredCards[card.id],
                onStudyGuide: onStudyGuide
            )

        case .flashcard(let question):
            FlashCard(
                card: card,
                question: question,
                onKnew: { onFlashcardKnew(question) },
                onNeedsReview: { onFlashcardReview(question) },
                onBookmark: onBookmark
            )

        case .realityCheck(let message, let topicName, let subjectName):
            FeedRealityCheckCard(
                message: message,
                topicName: topicName,
                subjectName: subjectName,
                onTopicTap: { name in onTopicTap?(name) }
            )

        case .stats(let todayMin, let weekXP, let streak, let level, let levelTitle):
            StatsCard(
                todayMinutes: todayMin,
                weekXP: weekXP,
                streak: streak,
                level: level,
                levelTitle: levelTitle
            )

        case .achievementTease(let name, let desc, let icon, let rarity, let progress, let current, let target):
            AchievementTeaseCard(
                name: name,
                description: desc,
                icon: icon,
                rarity: rarity,
                progress: progress,
                currentValue: current,
                targetValue: target
            )

        case .challenge(let text, let icon, let subtext):
            ChallengeCard(text: text, icon: icon, subtext: subtext)

        case .dueReview(let count, let topicNames):
            DueReviewCard(count: count, topicNames: topicNames) {
                onStartDueReview?()
            }

        case .weeklyDebrief(let xpThis, let xpLast, let mins, let quizzes, let topics, let streak):
            WeeklyDebriefCard(
                xpThisWeek:    xpThis,
                xpLastWeek:    xpLast,
                studyMinutes:  mins,
                quizzesTaken:  quizzes,
                topicsStudied: topics,
                streak:        streak
            )
        }
    }
}
