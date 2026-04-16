import SwiftUI

struct XPFloatView: View {
    let amount: Int
    let multiplier: Int

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double  = 1

    var body: some View {
        VStack(spacing: 2) {
            if multiplier > 1 {
                Text("\(multiplier)× COMBO")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.warning))
                    .opacity(opacity)
            }

            Text("+\(amount) XP")
                .font(.system(size: multiplier >= 5 ? 32 : 22,
                              weight: .black,
                              design: .monospaced))
                .foregroundStyle(
                    multiplier >= 10 ? Color(hex: AppColors.warning) :
                    multiplier >= 5  ? Color(hex: AppColors.primary) :
                    Color(hex: AppColors.secondary)
                )
                .shadow(color: Color(hex: AppColors.secondary).opacity(0.6), radius: 8)
        }
        .offset(y: yOffset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) {
                yOffset  = -120
                opacity  = 0
            }
        }
    }
}

// MARK: - Combo View (persistent overlay)

struct ComboView: View {
    let streak: Int

    private var multiplier: Int { ComboMultiplier.multiplier(forStreak: streak) }

    private var color: String {
        switch streak {
        case ComboMultiplier.tier4Streak...: return AppColors.warning
        case ComboMultiplier.tier3Streak...: return AppColors.primary
        case ComboMultiplier.tier2Streak...: return AppColors.secondary
        default:                             return AppColors.secondary
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: color))
                Text("\(streak)")
                    .font(.system(.headline, design: .monospaced, weight: .black))
                    .foregroundStyle(Color(hex: color))
            }

            if multiplier > 1 {
                Text("\(multiplier)×")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: color).opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: AppColors.surfacePrimary).opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(Color(hex: color).opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color(hex: color).opacity(0.3), radius: 8)
        .scaleEffect(streak % 5 == 0 ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: streak)
    }
}

// MARK: - Streak Heat Glow (edge overlay that warms with streak)

struct StreakHeatOverlay: View {
    let streak: Int

    private var intensity: Double {
        let normalized = min(1.0, Double(streak) / 20.0)
        return normalized * 0.25  // max 25% opacity
    }

    var body: some View {
        ZStack {
            // Left edge
            HStack {
                LinearGradient(
                    colors: [Color(hex: AppColors.warning).opacity(intensity), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 40)
                Spacer()
                // Right edge
                LinearGradient(
                    colors: [.clear, Color(hex: AppColors.warning).opacity(intensity)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 40)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.5), value: streak)
    }
}
