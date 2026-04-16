import SwiftUI

struct DueReviewCard: View {
    let count: Int
    let topicNames: [String]
    var onStartReview: () -> Void

    @State private var pulse = false

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: AppColors.warning).opacity(0.09), .clear],
                startPoint: .top, endPoint: .center
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: AppColors.warning).opacity(pulse ? 0.18 : 0.08))
                            .frame(width: 100, height: 100)
                            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

                        Image(systemName: "brain.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(Color(hex: AppColors.warning))
                    }
                    .onAppear { pulse = true }

                    VStack(spacing: 8) {
                        Text("\(count) Question\(count == 1 ? "" : "s") Due")
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("Spaced repetition scheduled these for today.\nReview now while they're still in memory.")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Topic chips
                    if !topicNames.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(topicNames.prefix(3), id: \.self) { name in
                                Text(name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: AppColors.warning))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: AppColors.warning).opacity(0.12))
                                            .overlay(Capsule()
                                                .strokeBorder(Color(hex: AppColors.warning).opacity(0.3), lineWidth: 1))
                                    )
                                    .lineLimit(1)
                            }
                            if topicNames.count > 3 {
                                Text("+\(topicNames.count - 3)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                            }
                        }
                    }

                    // CTA
                    Button(action: onStartReview) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start Review Session")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: AppColors.warning))
                                .shadow(color: Color(hex: AppColors.warning).opacity(0.4),
                                        radius: 12, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Swipe up to skip →")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(.bottom, 100)
            }
        }
    }
}
