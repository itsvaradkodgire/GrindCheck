import SwiftUI

struct PlatformAdaptiveLayout: View {
    var body: some View {
        #if os(iOS)
        AppTabView()
        #elseif os(macOS)
        MacNavigationView()
        #endif
    }
}
