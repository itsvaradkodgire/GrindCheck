import SwiftUI

struct AchievementTeaseCard: View {
    let name: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
    let progress: Double
    let currentValue: Double
    let targetValue: Double

    @State private var glowPulse = false
    @State private var appeared  = false

    private var accentColor: String { rarity.colorHex }

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()
            // Rarity glow background
            RadialGradient(
                colors: [Color(hex: accentColor).opacity(0.12), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Header
                Text("ACHIEVEMENT UNLOCKABLE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: accentColor))
                    .tracking(3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.1), value: appeared)

                // Locked icon (blurred/glowing)
                ZStack {
                    Circle()
                        .fill(Color(hex: accentColor).opacity(0.12))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(Color(hex: accentColor).opacity(glowPulse ? 0.08 : 0.04))
                        .frame(width: 160, height: 160)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowPulse)

                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: accentColor))
                        .shadow(color: Color(hex: accentColor).opacity(0.6), radius: 12)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: appeared)

                // Name + rarity
                VStack(spacing: 6) {
                    Text(name)
                        .font(.system(.title2, weight: .black))
                        .foregroundStyle(.white)

                    Text(rarity.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: accentColor))
                        .tracking(2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(hex: accentColor).opacity(0.15))
                        )
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn.delay(0.35), value: appeared)

                // Description
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.45), value: appeared)

                // Progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: AppColors.muted))
                        Spacer()
                        Text("\(Int(currentValue)) / \(Int(targetValue))")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(Color(hex: accentColor))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: AppColors.surfaceSecondary))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: accentColor).opacity(0.7), Color(hex: accentColor)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: appeared ? geo.size.width * progress : 0, height: 8)
                                .animation(.spring(duration: 0.8).delay(0.5), value: appeared)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(progress * 100))% there. Don't stop now.")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn.delay(0.55), value: appeared)

                Spacer()

                Text("Swipe up →")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(.bottom, 32)
                    .opacity(appeared ? 0.6 : 0)
                    .animation(.easeIn.delay(0.7), value: appeared)
            }
        }
        .onAppear {
            appeared   = true
            glowPulse  = true
        }
        .onDisappear {
            appeared   = false
            glowPulse  = false
        }
    }
}
