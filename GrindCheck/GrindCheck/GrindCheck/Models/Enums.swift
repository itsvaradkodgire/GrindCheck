import Foundation

// MARK: - Confidence Level

enum ConfidenceLevel: String, Codable, CaseIterable, Identifiable {
    case unknown  = "unknown"
    case shaky    = "shaky"
    case learning = "learning"
    case solid    = "solid"
    case mastered = "mastered"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unknown:  return "Unknown"
        case .shaky:    return "Shaky"
        case .learning: return "Learning"
        case .solid:    return "Solid"
        case .mastered: return "Mastered"
        }
    }

    var colorHex: String {
        switch self {
        case .unknown:  return "#555566"
        case .shaky:    return "#FF3366"
        case .learning: return "#FF8844"
        case .solid:    return "#44DD66"
        case .mastered: return "#00E5FF"
        }
    }

    var sfSymbol: String {
        switch self {
        case .unknown:  return "questionmark.circle"
        case .shaky:    return "exclamationmark.triangle.fill"
        case .learning: return "book.fill"
        case .solid:    return "checkmark.circle.fill"
        case .mastered: return "star.fill"
        }
    }

    // Proficiency range that maps to this level
    var proficiencyRange: ClosedRange<Int> {
        switch self {
        case .unknown:  return 0...19
        case .shaky:    return 20...39
        case .learning: return 40...59
        case .solid:    return 60...79
        case .mastered: return 80...100
        }
    }

    static func from(proficiency: Int) -> ConfidenceLevel {
        switch proficiency {
        case 0..<20:  return .unknown
        case 20..<40: return .shaky
        case 40..<60: return .learning
        case 60..<80: return .solid
        default:      return .mastered
        }
    }
}

// MARK: - Question Type

enum QuestionType: String, Codable, CaseIterable, Identifiable {
    case mcq         = "mcq"
    case shortAnswer = "shortAnswer"
    case codeOutput  = "codeOutput"
    case explainThis = "explainThis"
    case trueFalse   = "trueFalse"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mcq:         return "Multiple Choice"
        case .shortAnswer: return "Short Answer"
        case .codeOutput:  return "Code Output"
        case .explainThis: return "Explain This"
        case .trueFalse:   return "True / False"
        }
    }

    var sfSymbol: String {
        switch self {
        case .mcq:         return "list.bullet.circle"
        case .shortAnswer: return "pencil.line"
        case .codeOutput:  return "chevron.left.forwardslash.chevron.right"
        case .explainThis: return "text.bubble.fill"
        case .trueFalse:   return "checkmark.square.fill"
        }
    }
}

// MARK: - Quiz Mode

enum QuizMode: String, Codable, CaseIterable, Identifiable {
    case quickFire        = "quickFire"
    case deepDive         = "deepDive"
    case weakSpotAssault  = "weakSpotAssault"
    case mixedBag         = "mixedBag"
    case bossFight        = "bossFight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quickFire:       return "Quick Fire"
        case .deepDive:        return "Deep Dive"
        case .weakSpotAssault: return "Weak Spot Assault"
        case .mixedBag:        return "Mixed Bag"
        case .bossFight:       return "Boss Fight"
        }
    }

    var description: String {
        switch self {
        case .quickFire:       return "10 questions, mixed topics, 30s each"
        case .deepDive:        return "20 questions, single topic, escalating difficulty"
        case .weakSpotAssault: return "Only your lowest-scoring topics. No mercy."
        case .mixedBag:        return "60% weak, 30% medium, 10% strong"
        case .bossFight:       return "Hardest questions across all subjects"
        }
    }

    var sfSymbol: String {
        switch self {
        case .quickFire:       return "bolt.fill"
        case .deepDive:        return "arrow.down.to.line.circle.fill"
        case .weakSpotAssault: return "target"
        case .mixedBag:        return "shuffle.circle.fill"
        case .bossFight:       return "flame.fill"
        }
    }

    var questionCount: Int {
        switch self {
        case .quickFire:       return 10
        case .deepDive:        return 20
        case .weakSpotAssault: return 15
        case .mixedBag:        return 15
        case .bossFight:       return 20
        }
    }

    var timeLimitPerQuestion: Int {  // seconds
        switch self {
        case .quickFire:       return 30
        case .deepDive:        return 90
        case .weakSpotAssault: return 60
        case .mixedBag:        return 60
        case .bossFight:       return 120
        }
    }
}

// MARK: - Session Type

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case study    = "study"
    case review   = "review"
    case practice = "practice"
    case quiz     = "quiz"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .study:    return "Study"
        case .review:   return "Review"
        case .practice: return "Practice"
        case .quiz:     return "Quiz"
        }
    }

    var sfSymbol: String {
        switch self {
        case .study:    return "book.fill"
        case .review:   return "arrow.clockwise.circle.fill"
        case .practice: return "pencil.circle.fill"
        case .quiz:     return "questionmark.circle.fill"
        }
    }
}

// MARK: - Difficulty Level

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case easy   = "easy"
    case normal = "normal"
    case hard   = "hard"
    case brutal = "brutal"

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var numericValue: Int {
        switch self {
        case .easy:   return 1
        case .normal: return 3
        case .hard:   return 4
        case .brutal: return 5
        }
    }
}

// MARK: - Achievement Rarity

enum AchievementRarity: String, Codable, CaseIterable, Identifiable {
    case common    = "common"
    case rare      = "rare"
    case epic      = "epic"
    case legendary = "legendary"

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var colorHex: String {
        switch self {
        case .common:    return "#8888AA"
        case .rare:      return "#4488FF"
        case .epic:      return "#AA44FF"
        case .legendary: return "#FFAA00"
        }
    }

    var xpReward: Int {
        switch self {
        case .common:    return 25
        case .rare:      return 100
        case .epic:      return 250
        case .legendary: return 1000
        }
    }
}

// MARK: - Feed Card Type

enum FeedCardType: CaseIterable {
    case quiz
    case flashcard
    case realityCheck
    case stats
    case achievementTease
    case challenge

    /// Relative weight for random selection (total = 100)
    var weight: Int {
        switch self {
        case .quiz:            return 40
        case .flashcard:       return 20
        case .realityCheck:    return 15
        case .stats:           return 10
        case .achievementTease: return 10
        case .challenge:       return 5
        }
    }
}

// MARK: - Supporting Value Types

struct QuizAnswer: Codable, Hashable {
    var questionId: UUID
    var userAnswer: String
    var isCorrect: Bool
    var timeSpentSeconds: Int
    var difficulty: Int
}
