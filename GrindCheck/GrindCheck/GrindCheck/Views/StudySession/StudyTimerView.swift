import SwiftUI
import SwiftData
import Combine

struct StudyTimerView: View {

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = StudySessionViewModel()
    @State private var showTopicPicker = false
    @State private var showSettings = false

    let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Topic selector
                        topicSelectorCard
                            .padding(.top, 8)

                        // Phase indicator
                        if viewModel.status != .idle {
                            phaseIndicator
                        }

                        // Timer ring
                        timerRing
                            .padding(.vertical, 8)

                        // Controls
                        controls

                        // Pomodoro dots
                        if viewModel.isPomodoro && viewModel.status != .idle {
                            pomodoroDots
                        }

                        // Session type + settings
                        sessionTypeRow

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Study Timer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .onReceive(timerPublisher) { _ in
                guard viewModel.status == .active else { return }
                viewModel.tick()
            }
            .sheet(isPresented: $showTopicPicker) {
                TopicPickerSheet(
                    subjects: subjects,
                    selectedSubject: $viewModel.selectedSubject,
                    selectedTopic: $viewModel.selectedTopic
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSettings) {
                TimerSettingsSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.showSummary, onDismiss: {
                viewModel.resetForNewSession()
            }) {
                SessionSummaryView(viewModel: viewModel, onDone: {
                    viewModel.showSummary = false
                    viewModel.resetForNewSession()
                })
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Topic Selector

    private var topicSelectorCard: some View {
        Button { showTopicPicker = true } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.selectedSubject?.icon ?? "book.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: viewModel.selectedSubject?.colorHex ?? AppColors.primary))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedTopic?.name ?? viewModel.selectedSubject?.name ?? "Select Topic")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    if let subject = viewModel.selectedSubject, viewModel.selectedTopic != nil {
                        Text(subject.name)
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.muted))
                    } else if viewModel.selectedTopic == nil && viewModel.selectedSubject == nil {
                        Text("Tap to choose what you're studying")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.status == .active)
        .opacity(viewModel.status == .active ? 0.6 : 1)
    }

    // MARK: - Phase Indicator

    private var phaseIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isWorking
                      ? Color(hex: AppColors.primary)
                      : Color(hex: AppColors.success))
                .frame(width: 7, height: 7)
                .overlay(
                    Circle()
                        .stroke(viewModel.isWorking
                                ? Color(hex: AppColors.primary)
                                : Color(hex: AppColors.success), lineWidth: 1.5)
                        .scaleEffect(1.5)
                        .opacity(0.5)
                )

            Text(viewModel.phaseLabel.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(viewModel.isWorking
                                 ? Color(hex: AppColors.primary)
                                 : Color(hex: AppColors.success))
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(hex: AppColors.surfaceSecondary), lineWidth: 10)
                .frame(width: 200, height: 200)

            // Progress arc
            Circle()
                .trim(from: 0, to: viewModel.progressFraction)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progressFraction)

            // Time display
            VStack(spacing: 4) {
                Text(viewModel.timeDisplay)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if viewModel.status == .paused {
                    Text("PAUSED")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color(hex: AppColors.warning))
                } else if viewModel.status == .idle {
                    Text(viewModel.isPomodoro ? "POMODORO" : "FOCUS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
            }
        }
    }

    private var ringColor: Color {
        switch viewModel.phase {
        case .work:       return Color(hex: AppColors.primary)
        case .shortBreak: return Color(hex: AppColors.success)
        case .longBreak:  return Color(hex: AppColors.secondary)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            if viewModel.status == .active || viewModel.status == .paused {
                // Stop button
                Button {
                    HapticManager.shared.comboMilestone()
                    viewModel.stop(context: modelContext)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle().fill(Color(hex: AppColors.surfaceSecondary))
                        )
                }
                .buttonStyle(.plain)
            }

            // Main action button
            Button {
                mainAction()
            } label: {
                Image(systemName: mainActionIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(Color(hex: AppColors.background))
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(Color(hex: AppColors.primary))
                            .primaryGlow()
                    )
            }
            .buttonStyle(.plain)

            if viewModel.status == .idle {
                // Settings
                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle().fill(Color(hex: AppColors.surfaceSecondary))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var mainActionIcon: String {
        switch viewModel.status {
        case .idle:     return "play.fill"
        case .active:   return "pause.fill"
        case .paused:   return "play.fill"
        case .complete: return "arrow.clockwise"
        }
    }

    private func mainAction() {
        switch viewModel.status {
        case .idle:
            HapticManager.shared.correctAnswer()
            viewModel.start()
        case .active:
            HapticManager.shared.selectionChanged()
            viewModel.pause()
        case .paused:
            HapticManager.shared.selectionChanged()
            viewModel.resume()
        case .complete:
            viewModel.resetForNewSession()
        }
    }

    // MARK: - Pomodoro Dots

    private var pomodoroDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < viewModel.completedPomodoros % 4
                          ? Color(hex: AppColors.primary)
                          : Color(hex: AppColors.surfaceTertiary))
                    .frame(width: 28, height: 6)
                    .animation(.spring(duration: 0.3), value: viewModel.completedPomodoros)
            }
        }
    }

    // MARK: - Session Type

    private var sessionTypeRow: some View {
        HStack(spacing: 10) {
            ForEach([SessionType.study, .practice, .review], id: \.self) { type in
                Button {
                    viewModel.sessionType = type
                    HapticManager.shared.selectionChanged()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.sfSymbol)
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.sessionType == type
                                             ? Color(hex: AppColors.primary)
                                             : Color(hex: AppColors.muted))
                        Text(type.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(viewModel.sessionType == type
                                             ? .white
                                             : Color(hex: AppColors.muted))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: viewModel.sessionType == type
                                        ? AppColors.surfaceSecondary
                                        : AppColors.surfacePrimary))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        viewModel.sessionType == type
                                        ? Color(hex: AppColors.primary).opacity(0.4)
                                        : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.status != .idle)
                .opacity(viewModel.status != .idle ? 0.5 : 1)
            }
        }
    }
}

// MARK: - Topic Picker Sheet

private struct TopicPickerSheet: View {
    let subjects: [Subject]
    @Binding var selectedSubject: Subject?
    @Binding var selectedTopic: Topic?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // General option
                Button {
                    selectedSubject = nil
                    selectedTopic   = nil
                    dismiss()
                } label: {
                    HStack {
                        Label("General Study", systemImage: "books.vertical.fill")
                            .foregroundStyle(.white)
                        Spacer()
                        if selectedSubject == nil && selectedTopic == nil {
                            Image(systemName: "checkmark").foregroundStyle(Color(hex: AppColors.primary))
                        }
                    }
                }
                .listRowBackground(Color(hex: AppColors.surfacePrimary))

                ForEach(subjects) { subject in
                    Section(subject.name) {
                        // Subject-level
                        Button {
                            selectedSubject = subject
                            selectedTopic   = nil
                            dismiss()
                        } label: {
                            HStack {
                                Label("All \(subject.name)", systemImage: subject.icon)
                                    .foregroundStyle(Color(hex: subject.colorHex))
                                Spacer()
                                if selectedSubject?.id == subject.id && selectedTopic == nil {
                                    Image(systemName: "checkmark").foregroundStyle(Color(hex: AppColors.primary))
                                }
                            }
                        }
                        .listRowBackground(Color(hex: AppColors.surfacePrimary))

                        // Topics
                        ForEach(subject.topics.sorted { $0.name < $1.name }) { topic in
                            Button {
                                selectedSubject = subject
                                selectedTopic   = topic
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(topic.name)
                                            .foregroundStyle(.white)
                                        Text("\(topic.proficiencyScore)% proficiency")
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: AppColors.muted))
                                    }
                                    Spacer()
                                    if selectedTopic?.id == topic.id {
                                        Image(systemName: "checkmark").foregroundStyle(Color(hex: AppColors.primary))
                                    }
                                }
                            }
                            .listRowBackground(Color(hex: AppColors.surfacePrimary))
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .scrollContentBackground(.hidden)
            .background(Color(hex: AppColors.background))
            .navigationTitle("What are you studying?")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.primary))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Timer Settings Sheet

private struct TimerSettingsSheet: View {
    @Bindable var viewModel: StudySessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Toggle("Pomodoro", isOn: $viewModel.isPomodoro)
                        .tint(Color(hex: AppColors.primary))
                }

                Section("Work Duration") {
                    Stepper("\(viewModel.workMinutes) minutes",
                            value: $viewModel.workMinutes, in: 5...90, step: 5)
                }

                if viewModel.isPomodoro {
                    Section("Breaks") {
                        Stepper("Short: \(viewModel.shortBreakMinutes) min",
                                value: $viewModel.shortBreakMinutes, in: 1...15, step: 1)
                        Stepper("Long: \(viewModel.longBreakMinutes) min",
                                value: $viewModel.longBreakMinutes, in: 10...30, step: 5)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: AppColors.background))
            .navigationTitle("Timer Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.primary))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

