import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: String        // "user" or "model" — matches Gemini API field names
    var content: String
    var createdAt: Date

    init(role: String, content: String) {
        self.id        = UUID()
        self.role      = role
        self.content   = content
        self.createdAt = Date()
    }

    var isUser: Bool { role == "user" }
}
