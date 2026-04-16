import Foundation
import SwiftData

// MARK: - TopicArticle (one per topic, AI-generated study guide)

@Model
final class TopicArticle {

    @Attribute(.unique) var id: UUID = UUID()
    var createdAt: Date              = Date()
    var updatedAt: Date              = Date()
    var isAIGenerated: Bool          = true

    // Owning topic (set by caller after insert)
    var topic: Topic?

    @Relationship(deleteRule: .cascade) var sections: [ArticleSection] = []

    init() {}

    // MARK: - Computed

    var sortedSections: [ArticleSection] {
        sections.sorted { $0.order < $1.order }
    }

    var verifiedCount: Int  { sections.filter(\.isVerified).count }
    var flaggedCount: Int   { sections.filter(\.isFlagged).count }
    var totalSections: Int  { sections.count }

    var isFullyVerified: Bool {
        totalSections > 0 && verifiedCount == totalSections
    }

    var verificationProgress: Double {
        totalSections > 0 ? Double(verifiedCount) / Double(totalSections) : 0
    }

    var overallConfidence: ArticleConfidence {
        let lowCount = sections.filter { $0.confidence == .low }.count
        let medCount = sections.filter { $0.confidence == .medium }.count
        if lowCount > 0 { return .low }
        if medCount > 1 { return .medium }
        return .high
    }
}
