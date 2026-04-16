import Foundation

// MARK: - Study Guide JSON Parser

enum StudyGuideParser {

    struct ParsedSection {
        let type: ArticleSectionType
        let title: String
        let content: String
        let confidence: ArticleConfidence
        var parseWarning: String?
    }

    /// Expected JSON format:
    /// [{"type":"summary","title":"...","content":"...","confidence":"high"}]
    /// confidence is optional — defaults to "high" for user-provided content
    static func parseSections(from jsonString: String) -> (sections: [ParsedSection], errors: [String]) {
        guard let data = jsonString.data(using: .utf8) else {
            return ([], ["Could not read file as UTF-8 text."])
        }

        let rawArray: [[String: Any]]
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            rawArray = arr
        } else if let wrapper = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let arr = wrapper["sections"] as? [[String: Any]] {
            rawArray = arr
        } else {
            return ([], ["File is not valid JSON. Expected an array of section objects."
                         + " Download the template to see the correct format."])
        }

        var sections: [ParsedSection] = []
        var errors: [String] = []

        for (i, dict) in rawArray.enumerated() {
            let num = i + 1
            guard let title = dict["title"] as? String, !title.isEmpty else {
                errors.append("Section \(num): missing 'title' — skipped")
                continue
            }
            guard let content = dict["content"] as? String, !content.isEmpty else {
                errors.append("Section \(num): missing 'content' — skipped")
                continue
            }

            let typeStr = (dict["type"] as? String) ?? "explanation"
            let sType   = ArticleSectionType(rawValue: typeStr) ?? .explanation
            var warning: String?
            if ArticleSectionType(rawValue: typeStr) == nil {
                warning = "unknown type '\(typeStr)' — defaulted to explanation"
            }

            // User-provided content is trusted by default — mark as high confidence
            let confStr = (dict["confidence"] as? String) ?? "high"
            let conf    = ArticleConfidence(rawValue: confStr) ?? .high

            sections.append(ParsedSection(
                type:          sType,
                title:         title,
                content:       content,
                confidence:    conf,
                parseWarning:  warning
            ))
        }

        if sections.isEmpty && errors.isEmpty {
            errors.append("No sections found in file.")
        }

        return (sections, errors)
    }

    // MARK: - Template JSON String

    static func studyGuideTemplate(topicName: String) -> String {
        let sections: [[String: String]] = [
            [
                "type":    "summary",
                "title":   "What is \(topicName)?",
                "content": "Write a 2-3 sentence TL;DR summary of \(topicName) here.",
                "confidence": "high"
            ],
            [
                "type":    "concepts",
                "title":   "Key Concepts",
                "content": "- **Concept 1**: One-line explanation\n- **Concept 2**: One-line explanation\n- **Concept 3**: One-line explanation",
                "confidence": "high"
            ],
            [
                "type":    "explanation",
                "title":   "How It Works",
                "content": "Write a detailed explanation here. You can use **bold**, *italic*, and - bullet lists.\n\nBreak into paragraphs using blank lines.",
                "confidence": "high"
            ],
            [
                "type":    "code",
                "title":   "Code Example",
                "content": "```python\n# Replace this with a real code example\nprint('Hello, \(topicName)')\n```",
                "confidence": "high"
            ],
            [
                "type":    "mistakes",
                "title":   "Common Mistakes",
                "content": "- **Mistake 1**: Explanation of why it's wrong\n- **Mistake 2**: Explanation\n- **Mistake 3**: Explanation",
                "confidence": "high"
            ],
            [
                "type":    "reference",
                "title":   "Quick Reference",
                "content": "- **Key term 1**: definition\n- **Key term 2**: definition\n- **Formula/rule**: value",
                "confidence": "high"
            ]
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(sections.map { $0 }),
           let str  = String(data: data, encoding: .utf8) {
            return str
        }

        // Fallback manual format
        return """
        [
          {
            "type": "summary",
            "title": "What is \\(topicName)?",
            "content": "Write a 2-3 sentence TL;DR here.",
            "confidence": "high"
          }
        ]
        """
    }
}

