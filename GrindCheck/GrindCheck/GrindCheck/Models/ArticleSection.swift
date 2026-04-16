import Foundation
import SwiftData

// MARK: - ArticleSection

@Model
final class ArticleSection {

    @Attribute(.unique) var id: UUID = UUID()
    var order: Int           = 0
    var typeRaw: String      = ArticleSectionType.explanation.rawValue
    var title: String        = ""
    var content: String      = ""
    var confidenceRaw: String = ArticleConfidence.high.rawValue
    var isVerified: Bool     = false
    var isFlagged: Bool      = false
    var flagNote: String     = ""

    var article: TopicArticle?

    init(
        order:      Int,
        type:       ArticleSectionType,
        title:      String,
        content:    String,
        confidence: ArticleConfidence
    ) {
        self.order         = order
        self.typeRaw       = type.rawValue
        self.title         = title
        self.content       = content
        self.confidenceRaw = confidence.rawValue
    }

    var type: ArticleSectionType {
        ArticleSectionType(rawValue: typeRaw) ?? .explanation
    }

    var confidence: ArticleConfidence {
        ArticleConfidence(rawValue: confidenceRaw) ?? .medium
    }
}

// MARK: - ArticleSectionType

enum ArticleSectionType: String, CaseIterable {
    case summary     = "summary"
    case concepts    = "concepts"
    case explanation = "explanation"
    case code        = "code"
    case mistakes    = "mistakes"
    case reference   = "reference"

    var icon: String {
        switch self {
        case .summary:     return "text.alignleft"
        case .concepts:    return "list.bullet.circle"
        case .explanation: return "doc.text"
        case .code:        return "chevron.left.forwardslash.chevron.right"
        case .mistakes:    return "exclamationmark.triangle.fill"
        case .reference:   return "bolt.fill"
        }
    }

    var label: String {
        switch self {
        case .summary:     return "Summary"
        case .concepts:    return "Key Concepts"
        case .explanation: return "How It Works"
        case .code:        return "Code Example"
        case .mistakes:    return "Common Mistakes"
        case .reference:   return "Quick Reference"
        }
    }

    var accentColor: String {
        switch self {
        case .summary:     return "#6C63FF"
        case .concepts:    return "#00E5FF"
        case .explanation: return "#A855F7"
        case .code:        return "#00E5A0"
        case .mistakes:    return "#FF6B6B"
        case .reference:   return "#FF9F43"
        }
    }
}

// MARK: - ArticleConfidence

enum ArticleConfidence: String {
    case high   = "high"
    case medium = "medium"
    case low    = "low"

    var colorHex: String {
        switch self {
        case .high:   return "#00E5A0"
        case .medium: return "#FF9F43"
        case .low:    return "#FF6B6B"
        }
    }

    var label: String {
        switch self {
        case .high:   return "High confidence"
        case .medium: return "Verify this section"
        case .low:    return "Low confidence — double-check"
        }
    }

    var icon: String {
        switch self {
        case .high:   return "checkmark.seal.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low:    return "xmark.octagon.fill"
        }
    }
}
