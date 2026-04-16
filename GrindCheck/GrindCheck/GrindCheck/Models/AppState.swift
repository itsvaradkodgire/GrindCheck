import Foundation
import Observation

/// Shared app-level state for cross-tab navigation and deep-linking.
@Observable
final class AppState {
    /// Currently selected tab (drives AppTabView).
    var selectedTab: AppTab = .feed

    /// If set, AICoachView will auto-send this message on appear and clear it.
    var pendingAIMessage: String? = nil
}
