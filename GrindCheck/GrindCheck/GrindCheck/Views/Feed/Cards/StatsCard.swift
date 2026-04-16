import SwiftUI

struct StatsCard: View {
    let todayMinutes: Int
    let weekXP: Int
    let streak: Int
    let level: Int
    let levelTitle: String

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()
            LinearGradient(
                colors: [Color(hex: AppColors.primary).opacity(0.06), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Centered content
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("YOUR STATS")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: AppColors.primary))
                        .tracking(3)
                    Text("Right now. No excuses.")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: appeared)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    BigStatTile(value: todayMinutes.studyTimeFormatted, label: "Today",
                                icon: "clock.fill", color: AppColors.primary, delay: 0.1)
                    BigStatTile(value: streak > 0 ? "\(streak)🔥" : "0", label: "Day Streak",
                                icon: "flame.fill", color: streak > 0 ? "#FF6B35" : AppColors.muted, delay: 0.2)
                    BigStatTile(value: weekXP.xpFormatted, label: "XP Today",
                                icon: "bolt.fill", color: AppColors.secondary, delay: 0.3)
                    BigStatTile(value: "Lv.\(level)", label: levelTitle,
                                icon: "star.fill", color: AppColors.warning, delay: 0.4)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

                Text(BrutalMessages.streakMessage(days: streak))
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.5), value: appeared)
            }

            // Hint pinned to bottom
            VStack {
                Spacer()
                Text("Swipe up →")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(.bottom, 28)
                    .opacity(appeared ? 0.6 : 0)
                    .animation(.easeIn.delay(0.7), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

private struct BigStatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: String
    let delay: Double

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: color))

            Text(value)
                .font(.system(.title2, design: .monospaced, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: AppColors.muted))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(hex: color).opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(delay)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}
