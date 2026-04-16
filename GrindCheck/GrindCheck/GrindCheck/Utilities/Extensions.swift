import SwiftUI
import Foundation

// MARK: - Color from Hex String

extension Color {
    init(hex: String) {
        let hex      = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:   // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:   // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:   // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Helpers

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }

    func formatted(style: DateFormatter.Style) -> String {
        let f       = DateFormatter()
        f.dateStyle = style
        f.timeStyle = .none
        return f.string(from: self)
    }

    var relativeDescription: String {
        switch daysAgo {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        case 2...6: return "\(daysAgo) days ago"
        case 7...13: return "Last week"
        default: return "\(daysAgo / 7) weeks ago"
        }
    }
}

// MARK: - Double Helpers

extension Double {
    var percentFormatted: String {
        String(format: "%.0f%%", self)
    }

    var hoursFormatted: String {
        if self < 1 { return String(format: "%.0fm", self * 60) }
        return String(format: "%.1fh", self)
    }

    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}

// MARK: - Int Helpers

extension Int {
    var studyTimeFormatted: String {
        guard self > 0 else { return "0m" }
        let h = self / 60
        let m = self % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        return "\(m)m"
    }

    var xpFormatted: String {
        if self >= 1_000_000 { return String(format: "%.1fM", Double(self) / 1_000_000) }
        if self >= 1_000     { return String(format: "%.1fK", Double(self) / 1_000) }
        return "\(self)"
    }
}

// MARK: - String Helpers

extension String {
    var isNotEmpty: Bool { !isEmpty }

    func truncated(to length: Int, trailing: String = "…") -> String {
        count > length ? String(prefix(length)) + trailing : self
    }
}

// MARK: - View Helpers

extension View {
    func appBackground() -> some View {
        self.background(Color(hex: AppColors.background))
    }

    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(Color(hex: AppColors.surfacePrimary))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    func primaryGlow(color: String = AppColors.primary, radius: CGFloat = 8) -> some View {
        self.shadow(color: Color(hex: color).opacity(0.4), radius: radius, x: 0, y: 0)
    }

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Array Helpers

extension Array {
    func safeElement(at index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    /// Weighted random selection. Each element's weight is provided by the closure.
    func weightedRandom(weight: (Element) -> Int) -> Element? {
        let total = reduce(0) { $0 + weight($1) }
        guard total > 0 else { return randomElement() }
        var r = Int.random(in: 0..<total)
        for element in self {
            r -= weight(element)
            if r < 0 { return element }
        }
        return last
    }
}
