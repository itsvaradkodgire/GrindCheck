import Foundation
import WidgetKit

/// Pushes at-risk topic data to the shared App Group so the WidgetKit extension can read it.
/// Call this after any quiz completion or when the app enters background.
enum WidgetDataService {

    static let appGroupID = "group.com.grindcheck.app"

    static func update(subjects: [Subject], profile: UserProfile?) {
        let defaults = UserDefaults(suiteName: appGroupID)

        // Streak + freeze tokens
        defaults?.set(profile?.currentStreak ?? 0,  forKey: "currentStreak")
        defaults?.set(profile?.freezeTokens  ?? 0,  forKey: "freezeTokens")

        // At-risk topics (top 5)
        let allTopics = subjects.flatMap(\.topics)
        let allQuestions = allTopics.flatMap(\.questions)

        var atRisk: [AtRiskTopicData] = []

        // FSRS overdue
        let overdueQs = FSRSService.shared.dueQuestions(from: allQuestions)
        for q in overdueQs.prefix(5) {
            guard let topic = q.topic else { continue }
            if !atRisk.contains(where: { $0.topicID == topic.id }) {
                atRisk.append(AtRiskTopicData(
                    topicID:      topic.id,
                    name:         topic.name,
                    subjectName:  topic.subject?.name ?? "",
                    subjectColor: topic.subject?.colorHex ?? "#6C63FF",
                    proficiency:  topic.proficiencyScore,
                    daysOverdue:  q.daysUntilDue,
                    reason:       "Due for review"
                ))
            }
        }

        // Decaying
        for topic in allTopics.filter(\.isDecaying) where !atRisk.contains(where: { $0.topicID == topic.id }) {
            atRisk.append(AtRiskTopicData(
                topicID:      topic.id,
                name:         topic.name,
                subjectName:  topic.subject?.name ?? "",
                subjectColor: topic.subject?.colorHex ?? "#6C63FF",
                proficiency:  topic.proficiencyScore,
                daysOverdue:  -topic.daysSinceLastStudy,
                reason:       "Knowledge decaying"
            ))
        }

        let top5 = Array(atRisk.prefix(5))
        if let data = try? JSONEncoder().encode(top5) {
            defaults?.set(data, forKey: "atRiskTopics")
        }

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// Codable struct for App Group transfer (mirrors AtRiskTopic in widget target)
private struct AtRiskTopicData: Codable {
    let topicID:      UUID
    let name:         String
    let subjectName:  String
    let subjectColor: String
    let proficiency:  Int
    let daysOverdue:  Int
    let reason:       String
}
