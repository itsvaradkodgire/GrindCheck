import SwiftUI
import SwiftData

// MARK: - Profile Settings View
// Opened from Dashboard toolbar. Edit profile + nuclear Reset Everything.

struct ProfileSettingsView: View {

    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(GeminiService.self) private var geminiService

    // Edit fields
    @State private var editedName: String  = ""
    @State private var goalMinutes: Double = 60

    // Reset flow
    @State private var showResetSheet    = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // ── Avatar + Name ──────────────────────────────────
                        profileHeader

                        // ── Study Settings ────────────────────────────────
                        settingsSection("Study Settings", icon: "target") {
                            // Daily goal
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Daily Goal")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(goalMinutes)) min")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color(hex: AppColors.primary))
                                }
                                Slider(value: $goalMinutes, in: 10...180, step: 5)
                                    .tint(Color(hex: AppColors.primary))
                                HStack {
                                    Text("10 min").font(.caption2).foregroundStyle(Color(hex: AppColors.muted))
                                    Spacer()
                                    Text("3 hrs").font(.caption2).foregroundStyle(Color(hex: AppColors.muted))
                                }
                            }
                            .padding(.vertical, 4)

                            Divider().background(Color(hex: AppColors.surfaceTertiary))

                            // Difficulty
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Difficulty Preference")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                                HStack(spacing: 8) {
                                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                                        Button {
                                            profile.difficultyPreference = level
                                        } label: {
                                            Text(level.displayName)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(
                                                    profile.difficultyPreference == level
                                                    ? .black
                                                    : Color(hex: AppColors.neutral)
                                                )
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule().fill(
                                                        profile.difficultyPreference == level
                                                        ? Color(hex: AppColors.primary)
                                                        : Color(hex: AppColors.surfaceSecondary)
                                                    )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // ── App Settings ──────────────────────────────────
                        settingsSection("App Settings", icon: "gearshape.fill") {
                            Toggle(isOn: $profile.hapticsEnabled) {
                                Label("Haptics", systemImage: "hand.tap.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            .tint(Color(hex: AppColors.primary))

                            Divider().background(Color(hex: AppColors.surfaceTertiary))

                            Toggle(isOn: $profile.soundEffectsEnabled) {
                                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            .tint(Color(hex: AppColors.primary))
                        }

                        // ── Stats Summary ─────────────────────────────────
                        settingsSection("Your Progress", icon: "chart.bar.fill") {
                            statRow("Total XP",       value: "\(profile.totalXP) XP",        color: AppColors.primary)
                            Divider().background(Color(hex: AppColors.surfaceTertiary))
                            statRow("Level",          value: "\(profile.level) — \(profile.levelTitle)", color: AppColors.secondary)
                            Divider().background(Color(hex: AppColors.surfaceTertiary))
                            statRow("Study Time",     value: String(format: "%.1f hrs", profile.totalStudyHours), color: AppColors.success)
                            Divider().background(Color(hex: AppColors.surfaceTertiary))
                            statRow("Longest Streak", value: "\(profile.longestStreak) days", color: AppColors.warning)
                            Divider().background(Color(hex: AppColors.surfaceTertiary))
                            statRow("Freeze Tokens",  value: "\(profile.freezeTokens) 🧊",    color: AppColors.primary)
                            Divider().background(Color(hex: AppColors.surfaceTertiary))
                            statRow("Member Since",   value: profile.createdAt.formatted(.dateTime.month().day().year()), color: AppColors.muted)
                        }

                        // ── API Key ───────────────────────────────────────
                        settingsSection("Gemini AI", icon: "brain") {
                            HStack {
                                Image(systemName: geminiService.hasAPIKey ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(Color(hex: geminiService.hasAPIKey ? AppColors.success : AppColors.danger))
                                Text(geminiService.hasAPIKey ? "API Key configured" : "No API key set")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: AppColors.neutral))
                                Spacer()
                                if geminiService.hasAPIKey {
                                    Button("Remove") {
                                        geminiService.deleteAPIKey()
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: AppColors.danger))
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // ── Danger Zone ───────────────────────────────────
                        dangerZone

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile & Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { profile.name = trimmed }
                        profile.dailyGoalMinutes = Int(goalMinutes)
                        try? modelContext.save()
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: AppColors.primary))
                }
            }
            .sheet(isPresented: $showResetSheet) {
                ResetConfirmationSheet(onConfirmed: {
                    performReset()
                    showResetSheet = false
                    dismiss()
                })
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            editedName  = profile.name
            goalMinutes = Double(profile.dailyGoalMinutes)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Text(initials)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
            }

            // Editable name
            TextField("Your name", text: $editedName)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: AppColors.surfacePrimary))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(hex: AppColors.surfaceTertiary), lineWidth: 1))
                )
                .padding(.horizontal, 40)

            Text(profile.levelTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.primary))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(hex: AppColors.primary).opacity(0.12)))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var initials: String {
        let words = (editedName.isEmpty ? profile.name : editedName)
            .split(separator: " ").map(String.init)
        let letters = words.prefix(2).compactMap(\.first).map(String.init)
        return letters.joined().uppercased()
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: AppColors.danger))
                Text("Danger Zone")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: AppColors.danger))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Reset Everything")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Deletes all subjects, topics, questions, progress, XP, streaks and study history. The app returns to a blank slate.")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .fixedSize(horizontal: false, vertical: true)

                HoldToUnlockButton {
                    showResetSheet = true
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: AppColors.danger).opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: AppColors.danger).opacity(0.3), lineWidth: 1))
            )
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: AppColors.muted))

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: AppColors.surfacePrimary))
            )
        }
    }

    private func statRow(_ label: String, value: String, color: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: color))
        }
    }

    // MARK: - Reset

    private func performReset() {
        try? modelContext.delete(model: Subject.self)
        try? modelContext.delete(model: Topic.self)
        try? modelContext.delete(model: Question.self)
        try? modelContext.delete(model: TopicArticle.self)
        try? modelContext.delete(model: ArticleSection.self)
        try? modelContext.delete(model: StudySession.self)
        try? modelContext.delete(model: QuizAttempt.self)
        try? modelContext.delete(model: DailyLog.self)
        try? modelContext.delete(model: Achievement.self)
        try? modelContext.delete(model: ChatMessage.self)
        try? modelContext.delete(model: StudyMaterial.self)
        try? modelContext.delete(model: AIRoadmap.self)
        try? modelContext.delete(model: RoadmapPhase.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.save()
        // RootView will re-seed on next launch (profiles.isEmpty check)
    }
}

// MARK: - Hold to Unlock Button
// Must hold for 3 seconds — fills a progress bar. Releases early = resets.

struct HoldToUnlockButton: View {
    let onUnlocked: () -> Void

    @State private var progress: Double = 0
    @State private var isHolding        = false
    @State private var holdTimer: Timer?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: AppColors.surfaceSecondary))

                // Fill
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: AppColors.danger).opacity(0.6), Color(hex: AppColors.danger)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, progress) * geo.size.width)
                    .animation(.linear(duration: 0.05), value: progress)

                // Label
                HStack(spacing: 8) {
                    Image(systemName: progress > 0 ? "hand.point.up.left.fill" : "hand.tap.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(progress > 0 ? "Hold… \(Int((1 - progress) * 3 + 1))s" : "Hold to arm reset")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(progress > 0.1 ? .white : Color(hex: AppColors.danger))
                .frame(maxWidth: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isHolding { startHolding() } }
                    .onEnded   { _ in stopHolding() }
            )
        }
        .frame(height: 48)
    }

    private func startHolding() {
        isHolding = true
        HapticManager.shared.lightTap()
        let interval = 0.05
        let totalTicks = 3.0 / interval
        var ticks = 0.0
        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            ticks += 1
            progress = ticks / totalTicks
            if progress >= 1.0 {
                t.invalidate()
                holdTimer = nil
                isHolding = false
                HapticManager.shared.wrongAnswer()
                onUnlocked()
                progress = 0
            }
        }
    }

    private func stopHolding() {
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        withAnimation(.spring(duration: 0.3)) { progress = 0 }
    }
}

// MARK: - Reset Confirmation Sheet
// Second gate: must type "RESET" exactly.

private struct ResetConfirmationSheet: View {
    let onConfirmed: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var typedText = ""
    @State private var shake     = false

    private var isMatch: Bool { typedText == "RESET" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: AppColors.danger).opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color(hex: AppColors.danger))
                    }

                    VStack(spacing: 8) {
                        Text("This Cannot Be Undone")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text("All your subjects, questions, progress, XP and streaks will be permanently deleted.")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Type RESET
                    VStack(spacing: 8) {
                        Text("Type **RESET** to confirm")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: AppColors.neutral))

                        TextField("", text: $typedText)
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .foregroundStyle(isMatch ? Color(hex: AppColors.danger) : .white)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.characters)
                            #endif
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: AppColors.surfacePrimary))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            isMatch
                                            ? Color(hex: AppColors.danger)
                                            : Color(hex: AppColors.surfaceTertiary),
                                            lineWidth: isMatch ? 2 : 1
                                        ))
                            )
                            .offset(x: shake ? -6 : 0)
                            .animation(shake ? Animation.default.repeatCount(4, autoreverses: true).speed(6) : Animation.default, value: shake)
                    }
                    .padding(.horizontal, 40)

                    // Confirm button
                    Button {
                        if isMatch {
                            HapticManager.shared.wrongAnswer()
                            onConfirmed()
                        } else {
                            shake = true
                            HapticManager.shared.lightTap()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shake = false }
                        }
                    } label: {
                        Text("Delete Everything")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isMatch
                                          ? Color(hex: AppColors.danger)
                                          : Color(hex: AppColors.surfaceSecondary))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                    .animation(.spring(duration: 0.25), value: isMatch)

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Confirm Reset")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
