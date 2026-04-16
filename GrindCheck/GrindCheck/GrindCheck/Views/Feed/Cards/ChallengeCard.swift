import SwiftUI

struct ChallengeCard: View {
    let text: String
    let icon: String
    let subtext: String

    @State private var appeared = false
    @State private var pulse    = false

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()
            LinearGradient(
                colors: [Color(hex: AppColors.warning).opacity(0.08), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Centered content
            VStack(spacing: 32) {
                Text("DAILY CHALLENGE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.warning))
                    .tracking(4)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.1), value: appeared)

                ZStack {
                    Circle()
                        .fill(Color(hex: AppColors.warning).opacity(pulse ? 0.12 : 0.06))
                        .frame(width: 120, height: 120)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: AppColors.warning))
                        .shadow(color: Color(hex: AppColors.warning).opacity(0.5), radius: 10)
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: appeared)

                Text(text)
                    .font(.system(.title2, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.5).delay(0.3), value: appeared)

                Text(subtext)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.45), value: appeared)

                Text("Go do it.")
                    .font(.system(.headline, design: .monospaced, weight: .black))
                    .foregroundStyle(Color(hex: AppColors.warning))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.warning).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color(hex: AppColors.warning).opacity(0.4), lineWidth: 1.5)
                            )
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .animation(.spring(response: 0.45).delay(0.55), value: appeared)
            }

            // Hint pinned to bottom (outside the centered group)
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
            appeared = true
            pulse    = true
        }
        .onDisappear {
            appeared = false
            pulse    = false
        }
    }
}
