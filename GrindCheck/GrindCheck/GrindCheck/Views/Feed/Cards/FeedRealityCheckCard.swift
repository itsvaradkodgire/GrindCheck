import SwiftUI

struct FeedRealityCheckCard: View {
    let message: String
    let topicName: String?
    let subjectName: String?
    var onTopicTap: ((String) -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dark red-tinted background
            Color(hex: AppColors.background).ignoresSafeArea()
            LinearGradient(
                colors: [Color(hex: "#1A0008").opacity(0.6), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Centered content
            VStack(spacing: 32) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: AppColors.danger))
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                Text("REALITY CHECK")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.danger))
                    .tracking(4)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.2), value: appeared)

                Text(message)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.3), value: appeared)

                if let topicName {
                    Button {
                        onTopicTap?(topicName)
                        HapticManager.shared.selectionChanged()
                    } label: {
                        VStack(spacing: 6) {
                            if let subjectName {
                                Text(subjectName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                            }
                            Text(topicName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color(hex: AppColors.danger))

                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 11))
                                Text("Go study it")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(Color(hex: AppColors.danger).opacity(0.7))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: AppColors.danger).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(hex: AppColors.danger).opacity(0.4), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.45), value: appeared)
                }
            }

            // Hint pinned to bottom
            VStack {
                Spacer()
                Text("Swipe up to keep scrolling, or go fix this.")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(.bottom, 28)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: appeared)
            }
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}
