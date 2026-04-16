import Foundation

// MARK: - App Colors (hex strings → use Color(hex:) extension)

enum AppColors {
    // Backgrounds
    static let background        = "#0B0B11"
    static let surfacePrimary    = "#12121A"
    static let surfaceSecondary  = "#1A1A26"
    static let surfaceTertiary   = "#232334"

    // Accents
    static let primary           = "#00E5FF"   // electric cyan
    static let secondary         = "#00FF88"   // sharp green

    // Proficiency scale
    static let proficiencyRed    = "#FF3366"
    static let proficiencyOrange = "#FF8844"
    static let proficiencyYellow = "#FFCC00"
    static let proficiencyGreen  = "#44DD66"
    static let proficiencyCyan   = "#00E5FF"

    // Semantic
    static let danger            = "#FF3366"
    static let warning           = "#FFAA00"
    static let success           = "#00FF88"
    static let neutral           = "#8888AA"
    static let muted             = "#555566"
}

// MARK: - XP Awards

enum XPAward {
    static let studyBlock25Min   = 10
    static let quizBase          = 15
    static let perfectQuiz       = 50
    static let questionAdded     = 5
    static let reviewDecaying    = 20
    static let bossFightComplete = 30
    static let feedCorrect       = 5
    static let dailyStreak       = 5   // × streak day
}

// MARK: - Proficiency Thresholds

enum ProficiencyThreshold {
    static let decayStart        = 14   // days without study → decay begins
    static let autoDecayStart    = 30   // days → proficiency auto-decreases
    static let autoDecayPerWeek  = 5    // points lost per week after threshold
    static let stagnationRepeats = 3    // same quiz score this many times = stagnation
}

// MARK: - Quiz

enum QuizConfig {
    static let adaptiveCorrectStreak = 3   // consecutive correct → increase difficulty
    static let adaptiveWrongStreak   = 2   // consecutive wrong   → decrease difficulty
    static let minDifficulty         = 1
    static let maxDifficulty         = 5
}

// MARK: - Combo Multipliers

enum ComboMultiplier {
    static let tier1Streak = 3    // 2× XP
    static let tier2Streak = 5    // 3× XP
    static let tier3Streak = 10   // 5× XP
    static let tier4Streak = 20   // 10× XP

    static func multiplier(forStreak streak: Int) -> Int {
        switch streak {
        case tier4Streak...: return 10
        case tier3Streak...: return 5
        case tier2Streak...: return 3
        case tier1Streak...: return 2
        default:             return 1
        }
    }
}

// MARK: - Gemini API

enum GeminiConfig {
    static let baseURL            = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    static let maxRequestsPerMin  = 10
    static let maxRequestsPerDay  = 250
    static let temperature        = 0.7
    static let maxOutputTokens    = 8192
    static let keychainKey        = "com.grindcheck.gemini_api_key"
}

// MARK: - Widget

enum WidgetConfig {
    static let smallWidgetKind  = "GrindCheckSmall"
    static let mediumWidgetKind = "GrindCheckMedium"
    static let lockScreenKind   = "GrindCheckLockScreen"
}

// MARK: - Misc

enum AppConfig {
    static let minSessionMinutesForCredit = 5
    static let pomodoroWorkMinutes        = 25
    static let pomodoroBreakMinutes       = 5
    static let feedRefreshCardCount       = 20
    static let maxDailyGoalMinutes        = 480  // 8 hours
    static let minDailyGoalMinutes        = 15
}
