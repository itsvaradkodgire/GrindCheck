import Foundation
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String        // SF Symbol name
    var colorHex: String
    @Relationship(deleteRule: .cascade) var topics: [Topic]
    var lastStudiedAt: Date?
    var sortOrder: Int
    var createdAt: Date

    init(
        name: String,
        icon: String = "book.fill",
        colorHex: String = "#00E5FF"
    ) {
        self.id           = UUID()
        self.name         = name
        self.icon         = icon
        self.colorHex     = colorHex
        self.topics       = []
        self.lastStudiedAt = nil
        self.sortOrder    = 0
        self.createdAt    = Date()
    }

    // MARK: - Computed Properties

    var totalTopics: Int { topics.count }

    var masteredTopics: Int {
        topics.filter { $0.confidenceLevel == .mastered }.count
    }

    var avgProficiency: Double {
        guard !topics.isEmpty else { return 0 }
        return Double(topics.reduce(0) { $0 + $1.proficiencyScore }) / Double(topics.count)
    }

    var overallConfidence: ConfidenceLevel {
        ConfidenceLevel.from(proficiency: Int(avgProficiency))
    }

    var weakTopics: [Topic] {
        topics
            .filter { $0.proficiencyScore < 40 }
            .sorted { $0.proficiencyScore < $1.proficiencyScore }
    }

    var decayingTopics: [Topic] {
        topics.filter { $0.isDecaying }
    }

    var totalTimeSpentMinutes: Int {
        topics.reduce(0) { $0 + $1.totalTimeSpentMinutes }
    }

    var totalQuestions: Int {
        topics.reduce(0) { $0 + $1.questions.count }
    }

    var progressDescription: String {
        "\(masteredTopics)/\(totalTopics) topics mastered"
    }
}
