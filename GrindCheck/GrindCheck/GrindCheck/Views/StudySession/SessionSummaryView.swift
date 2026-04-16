import SwiftUI

struct SessionSummaryView: View {

    @Bindable var viewModel: StudySessionViewModel
    let onDone: () -> Void

    @State private var animateIn = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: AppColors.surfaceTertiary))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Stats grid
                        statsGrid

                        // Brutal summary
                        brutalSummaryCard

                        // Focus rating
                        focusRatingSection

                        // Notes
                        notesSection

                        // XP earned
                        xpSection

                        // Done button
                        Button(action: onDone) {
                            Text("Close")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color(hex: AppColors.background))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(hex: AppColors.primary))
                                        .primaryGlow()
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5).delay(0.15)) {
                animateIn = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: AppColors.success))
                .scaleEffect(animateIn ? 1 : 0.5)
                .animation(.spring(duration: 0.5), value: animateIn)

            Text("Session Complete")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text(viewModel.currentTopicName)
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .padding(.top, 4)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCell(
                icon: "clock.fill",
                value: viewModel.elapsedMinutes.studyTimeFormatted,
                label: "Study Time",
                color: AppColors.primary
            )
            statCell(
                icon: "flame.fill",
                value: "\(viewModel.completedPomodoros)",
                label: viewModel.completedPomodoros == 1 ? "Pomodoro" : "Pomodoros",
                color: AppColors.warning
            )
            statCell(
                icon: sessionTypeIcon,
                value: viewModel.sessionType.displayName,
                label: "Session Type",
                color: AppColors.secondary
            )
            statCell(
                icon: "star.fill",
                value: "\(viewModel.focusRating)/5",
                label: "Focus Rating",
                color: AppColors.success
            )
        }
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.2), value: animateIn)
    }

    private var sessionTypeIcon: String {
        viewModel.sessionType.sfSymbol
    }

    private func statCell(icon: String, value: String, label: String, color: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: AppColors.muted))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    // MARK: - Brutal Summary

    private var brutalSummaryCard: some View {
        let message = BrutalMessages.dailyCheck(
            studyMinutes: viewModel.elapsedMinutes,
            goalMinutes: 60,
            streak: 0
        )

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(Color(hex: AppColors.danger))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: AppColors.danger).opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Focus Rating

    private var focusRatingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How focused were you?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        HapticManager.shared.selectionChanged()
                        viewModel.focusRating = star
                    } label: {
                        Image(systemName: star <= viewModel.focusRating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(star <= viewModel.focusRating
                                             ? Color(hex: AppColors.warning)
                                             : Color(hex: AppColors.surfaceTertiary))
                            .animation(.spring(duration: 0.2), value: viewModel.focusRating)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text(focusLabel)
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var focusLabel: String {
        switch viewModel.focusRating {
        case 1: return "Barely there"
        case 2: return "Distracted"
        case 3: return "Decent"
        case 4: return "Locked in"
        case 5: return "Deep focus"
        default: return ""
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            TextField("What did you learn?", text: $viewModel.notes, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(3...6)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: AppColors.surfaceSecondary))
                )
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - XP Section

    private var xpSection: some View {
        let blocks = max(1, viewModel.elapsedMinutes / 25)
        let baseXP = blocks * XPAward.studyBlock25Min
        let focusBonus = (viewModel.focusRating - 3) * 5
        let totalXP = max(0, baseXP + focusBonus)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("XP Earned")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                Text("+\(totalXP) XP")
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.primary))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Focus Bonus")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                Text(focusBonus >= 0 ? "+\(focusBonus)" : "\(focusBonus)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(focusBonus >= 0
                                     ? Color(hex: AppColors.success)
                                     : Color(hex: AppColors.danger))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.primary).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: AppColors.primary).opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.35), value: animateIn)
    }
}
