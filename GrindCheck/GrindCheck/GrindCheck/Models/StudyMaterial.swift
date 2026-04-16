import Foundation
import SwiftData

@Model
final class StudyMaterial {
    @Attribute(.unique) var id: UUID
    var title: String
    var rawText: String
    var sourceFileName: String   // "" if pasted manually, filename if imported
    var topic: Topic?
    var subject: Subject?
    var createdAt: Date

    init(
        title: String,
        rawText: String,
        sourceFileName: String = "",
        topic: Topic? = nil,
        subject: Subject? = nil
    ) {
        self.id             = UUID()
        self.title          = title
        self.rawText        = rawText
        self.sourceFileName = sourceFileName
        self.topic          = topic
        self.subject        = subject ?? topic?.subject
        self.createdAt      = Date()
    }

    var isPDF: Bool     { sourceFileName.lowercased().hasSuffix(".pdf") }
    var preview: String { String(rawText.prefix(200)) }
    var wordCount: Int  { rawText.split(separator: " ").count }
}
