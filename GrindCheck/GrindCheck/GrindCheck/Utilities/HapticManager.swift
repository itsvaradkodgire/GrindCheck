import Foundation
#if os(iOS)
import UIKit
#endif

/// Centralized haptic feedback manager. All calls are no-ops on macOS.
final class HapticManager {

    static let shared = HapticManager()
    private init() {}

    // MARK: - Impact

    func lightTap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    func mediumTap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    func heavyBuzz() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }

    // MARK: - Notification

    /// Correct answer: satisfying success tap
    func correctAnswer() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    /// Wrong answer: heavy error buzz
    func wrongAnswer() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Achievement unlock: burst
    func achievementUnlocked() {
        #if os(iOS)
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gen.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        #endif
    }

    // MARK: - Selection

    /// Card snap / selection tick
    func selectionChanged() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    // MARK: - Combo

    /// Combo milestone hit
    func comboMilestone() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }

    // MARK: - Pull to Refresh

    func pullToRefresh() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    // MARK: - Level Up

    func levelUp() {
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { gen.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { gen.impactOccurred() }
        #endif
    }
}
