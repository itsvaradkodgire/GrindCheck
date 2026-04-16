import Foundation
import SwiftData

@Model
final class AIRoadmap {
    @Attribute(.unique) var id: UUID
    var goal: String
    var subjectName: String      // e.g. "AI Engineering" — the Subject to create
    var rawJSON: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var phases: [RoadmapPhase]

    init(goal: String, subjectName: String = "", rawJSON: String) {
        self.id          = UUID()
        self.goal        = goal
        self.subjectName = subjectName
        self.rawJSON     = rawJSON
        self.phases      = []
        self.createdAt   = Date()
    }

    var completedPhaseCount: Int { phases.filter(\.isCompleted).count }
    var totalPhaseCount: Int     { phases.count }

    var progressFraction: Double {
        guard totalPhaseCount > 0 else { return 0 }
        return Double(completedPhaseCount) / Double(totalPhaseCount)
    }

    var sortedPhases: [RoadmapPhase] {
        phases.sorted { $0.order < $1.order }
    }
}

@Model
final class RoadmapPhase {
    @Attribute(.unique) var id: UUID
    var title: String
    var phaseDescription: String
    var topicNames: [String]
    var estimatedWeeks: Int
    var order: Int
    var isCompleted: Bool
    var roadmap: AIRoadmap?
    var createdAt: Date

    init(
        title: String,
        phaseDescription: String,
        topicNames: [String],
        estimatedWeeks: Int,
        order: Int,
        roadmap: AIRoadmap? = nil
    ) {
        self.id               = UUID()
        self.title            = title
        self.phaseDescription = phaseDescription
        self.topicNames       = topicNames
        self.estimatedWeeks   = estimatedWeeks
        self.order            = order
        self.isCompleted      = false
        self.roadmap          = roadmap
        self.createdAt        = Date()
    }
}
