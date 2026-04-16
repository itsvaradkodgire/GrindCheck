import SwiftUI

struct FlashCard: View {
    let card: FeedCard
    let question: Question
    let onKnew: () -> Void
    let onNeedsReview: () -> Void
    let onBookmark: (Question) -> Void

    @State private var isFlipped       = false
    @State private var flipDegrees     = 0.0
    @State private var isBookmarked    = false
    @State private var hasResponded    = false

    private var accentColor: String {
        question.topic?.subject?.colorHex ?? AppColors.primary
    }

    var body: some View {
        ZStack {
            // Full-screen background
            Color(hex: AppColors.background).ignoresSafeArea()

            // Subtle accent gradient from top
            LinearGradient(
                colors: [Color(hex: accentColor).opacity(0.07), .clear],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()

            // The flippable card — fills the screen
            ZStack {
                frontFace
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(flipDegrees), axis: (0, 1, 0))

                backFace
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(flipDegrees - 180), axis: (0, 1, 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !hasResponded else { return }
                flipCard()
            }

            // Top overlay: meta info + bookmark
            VStack {
                HStack(alignment: .center, spacing: 8) {
                    // Card type pill
                    Label("Flashcard", systemImage: "rectangle.on.rectangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: AppColors.muted))

                    if let subject = question.topic?.subject {
                        Label(subject.name, systemImage: subject.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: subject.colorHex))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: subject.colorHex).opacity(0.15)))
                    }

                    Spacer()

                    Button {
                        isBookmarked.toggle()
                        onBookmark(question)
                        HapticManager.shared.lightTap()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15))
                            .foregroundStyle(isBookmarked
                                ? Color(hex: AppColors.warning)
                                : Color(hex: AppColors.muted))
                            .padding(10)
                            .background(Circle().fill(Color(hex: AppColors.surfacePrimary).opacity(0.8)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()
            }

            // Bottom overlay: hint or response buttons
            VStack {
                Spacer()

                if isFlipped && !hasResponded {
                    responseButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if hasResponded {
                    Text("Swipe up for next →")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                        .padding(.bottom, 100)
                } else {
                    tapHint
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear { isBookmarked = question.isBookmarked }
        .animation(.spring(duration: 0.4), value: isFlipped)
        .animation(.spring(duration: 0.3), value: hasResponded)
    }

    // MARK: - Front Face

    private var frontFace: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                Text("TERM")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .tracking(3)

                if let topic = question.topic {
                    Text(topic.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: accentColor))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: accentColor).opacity(0.12)))
                }

                Text(question.questionText)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            // Top inset clears the meta overlay; bottom inset clears the tap hint
            .padding(.top, 96)
            .padding(.bottom, 140)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Back Face

    private var backFace: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Text("ANSWER")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: accentColor))
                    .tracking(3)

                Text(question.correctAnswer)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 32)

                if !question.explanation.isEmpty {
                    Divider()
                        .background(Color(hex: AppColors.surfaceTertiary))
                        .padding(.horizontal, 40)

                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            // Top inset clears the meta overlay; bottom inset clears the response buttons
            .padding(.top, 96)
            .padding(.bottom, 160)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Hint

    private var tapHint: some View {
        VStack(spacing: 4) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: AppColors.muted))
            Text("Tap to flip")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
        }
    }

    // MARK: - Response Buttons

    private var responseButtons: some View {
        HStack(spacing: 12) {
            Button {
                hasResponded = true
                HapticManager.shared.wrongAnswer()
                onNeedsReview()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Review")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.danger))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: AppColors.danger).opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(hex: AppColors.danger).opacity(0.4), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            Button {
                hasResponded = true
                HapticManager.shared.correctAnswer()
                onKnew()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                    Text("Knew it")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.success))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: AppColors.success).opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(hex: AppColors.success).opacity(0.4), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Logic

    private func flipCard() {
        HapticManager.shared.selectionChanged()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            flipDegrees += 180
            isFlipped.toggle()
        }
    }
}
