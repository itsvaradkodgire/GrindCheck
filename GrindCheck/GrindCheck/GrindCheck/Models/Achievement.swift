import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: String   // e.g. "first_blood", "streak_lord"
    var name: String
    var descriptionText: String
    var icon: String                     // SF Symbol
    var rarity: AchievementRarity
    var unlockedAt: Date?
    var isUnlocked: Bool
    var currentValue: Double             // progress toward target
    var targetValue: Double              // unlock threshold

    init(
        id: String,
        name: String,
        descriptionText: String,
        icon: String,
        rarity: AchievementRarity,
        targetValue: Double = 1
    ) {
        self.id              = id
        self.name            = name
        self.descriptionText = descriptionText
        self.icon            = icon
        self.rarity          = rarity
        self.unlockedAt      = nil
        self.isUnlocked      = false
        self.currentValue    = 0
        self.targetValue     = targetValue
    }

    // MARK: - Computed

    var progressFraction: Double {
        guard targetValue > 0 else { return isUnlocked ? 1 : 0 }
        return min(1.0, currentValue / targetValue)
    }

    var isAlmostUnlocked: Bool {
        !isUnlocked && progressFraction >= 0.7
    }

    var progressDescription: String {
        guard !isUnlocked else { return "Unlocked" }
        if targetValue <= 1 { return "Not yet unlocked" }
        return "\(Int(currentValue))/\(Int(targetValue))"
    }

    // MARK: - Mutations

    func updateProgress(_ value: Double) {
        currentValue = min(targetValue, value)
        if currentValue >= targetValue && !isUnlocked {
            unlock()
        }
    }

    func incrementProgress(by amount: Double = 1) {
        updateProgress(currentValue + amount)
    }

    func unlock() {
        isUnlocked   = true
        unlockedAt   = Date()
        currentValue = targetValue
    }
}
