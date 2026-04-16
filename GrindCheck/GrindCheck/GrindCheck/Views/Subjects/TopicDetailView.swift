import SwiftUI
import SwiftData

struct TopicDetailView: View {

    @Bindable var topic: Topic
    @Environment(\.modelContext) private var modelContext
    @Environment(GeminiService.self) private var geminiService

    var initialTab: TopicTab = .overview
    @State private var showingAddQuestion        = false
    @State private var questionToDelete: Question?
    @State private var showDeleteConfirm         = false
    @State private var isEditingNotes            = false
    @State private var notesText                 = ""
    @State private var showingStudyTimer         = false
    @State private var aiViewModel: AICoachViewModel?
    @State private var showingQuestionReview     = false
    @State private var showingAPIKeySetup        = false
    @State private var generationErrorMsg: String?
    @State private var selectedTopicTab: TopicTab = .overview
    // initialTab applied on first appear only
    @State private var showingBulkUploadQuestions = false
    @State private var showingBulkUploadGuide     = false

    enum TopicTab: String, CaseIterable {
        case overview    = "Overview"
        case studyGuide  = "Study Guide"
        case questions   = "Questions"
    }

    private var sortedQuestions: [Question] {
        topic.questions.sorted { $0.difficulty < $1.difficulty }
    }

    private var isGenerating: Bool { aiViewModel?.isGeneratingQuestions ?? false }

    // MARK: - Tab Picker

    private var topicTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(TopicTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.25)) { selectedTopicTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTopicTab == tab ? .bold : .medium))
                            .foregroundStyle(selectedTopicTab == tab ? .white : Color(hex: AppColors.muted))

                        // Active indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(selectedTopicTab == tab
                                  ? Color(hex: topic.subject?.colorHex ?? AppColors.primary)
                                  : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(hex: AppColors.surfacePrimary))
        .overlay(alignment: .bottom) {
            Divider().background(Color(hex: AppColors.surfaceTertiary))
        }
    }

    // MARK: - Overview Tab

    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProficiencyBlock(topic: topic)
                TopicStatsRow(topic: topic)
                if topic.isDecaying { DecayWarningBanner(topic: topic) }
                NotesSection(topic: topic)
                if !topic.prerequisites.isEmpty || true {
                    PrerequisitesSection(topic: topic)
                }
                TopicMaterialsSection(topic: topic)
            }
            .padding(16)
        }
        .background(Color(hex: AppColors.background))
    }

    // MARK: - Questions Tab

    private var questionsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                QuestionsSection(
                    topic: topic,
                    questions: sortedQuestions,
                    isGenerating: isGenerating,
                    onAdd: { showingAddQuestion = true },
                    onDelete: { q in
                        questionToDelete = q
                        showDeleteConfirm = true
                    },
                    onAIGenerate: { generateAIQuestions() },
                    onBulkUpload: { showingBulkUploadQuestions = true }
                )
            }
            .padding(16)
        }
        .background(Color(hex: AppColors.background))
    }

    private func generateAIQuestions() {
        guard geminiService.hasAPIKey else {
            showingAPIKeySetup = true
            return
        }
        let vm = aiViewModel ?? AICoachViewModel(geminiService: geminiService)
        aiViewModel = vm
        Task {
            await vm.generateQuestionsForTopic(topic, modelContext: modelContext)
            if let err = vm.generationError {
                generationErrorMsg = err
            } else if vm.showQuestionReview {
                showingQuestionReview = true
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            topicTabPicker

            // Tab Content
            switch selectedTopicTab {
            case .overview:
                overviewContent
            case .studyGuide:
                TopicArticleView(topic: topic, onBulkUpload: { showingBulkUploadGuide = true })
            case .questions:
                questionsContent
            }
        }
        .background(Color(hex: AppColors.background))
        .navigationTitle(topic.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear { selectedTopicTab = initialTab }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddQuestion = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: topic.subject?.colorHex ?? AppColors.primary))
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingStudyTimer = true
                } label: {
                    Label("Study Timer", systemImage: "timer")
                }
            }
        }
        .sheet(isPresented: $showingAddQuestion) {
            AddQuestionView(topic: topic)
        }
        .sheet(isPresented: $showingQuestionReview) {
            if let vm = aiViewModel {
                GeneratedQuestionsReviewSheet(viewModel: vm, topic: topic) {
                    showingQuestionReview = false
                }
            }
        }
        .sheet(isPresented: $showingStudyTimer) {
            StudyTimerView()
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 600)
                #endif
        }
        .sheet(isPresented: $showingAPIKeySetup) {
            APIKeySetupView(geminiService: geminiService)
        }
        .sheet(isPresented: $showingBulkUploadQuestions) {
            BulkUploadView(topic: topic, mode: .questions) {
                showingBulkUploadQuestions = false
            }
        }
        .sheet(isPresented: $showingBulkUploadGuide) {
            BulkUploadView(topic: topic, mode: .studyGuide) {
                showingBulkUploadGuide = false
            }
        }
        .alert("Generation Failed", isPresented: Binding(
            get: { generationErrorMsg != nil },
            set: { if !$0 { generationErrorMsg = nil } }
        )) {
            Button("OK") { generationErrorMsg = nil }
        } message: {
            Text(generationErrorMsg ?? "")
        }
        .confirmationDialog(
            "Delete this question?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Question", role: .destructive) {
                if let q = questionToDelete {
                    modelContext.delete(q)
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Proficiency Block

private struct ProficiencyBlock: View {
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProficiencyBadge(level: topic.confidenceLevel)
                Spacer()
                Text("\(topic.proficiencyScore)%")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: topic.confidenceLevel.colorHex))
            }

            TopicProficiencyBar(score: topic.proficiencyScore, showLabel: false, height: 10)

            Text(BrutalMessages.message(forProficiency: topic.proficiencyScore, topic: topic.name))
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Topic Stats Row

private struct TopicStatsRow: View {
    let topic: Topic

    var body: some View {
        HStack(spacing: 10) {
            MiniStat(value: topic.totalTimeSpentMinutes.studyTimeFormatted,
                     label: "Studied", icon: "clock.fill", color: AppColors.primary)
            MiniStat(value: "\(topic.totalQuestions)",
                     label: "Questions", icon: "questionmark.circle.fill", color: AppColors.secondary)
            MiniStat(value: topic.overallAccuracyRate > 0
                        ? (topic.overallAccuracyRate * 100).percentFormatted : "--",
                     label: "Accuracy", icon: "checkmark.circle.fill", color: AppColors.warning)
            MiniStat(value: "\(topic.nemesisQuestions.count)",
                     label: "Nemesis", icon: "flame.fill",
                     color: topic.nemesisQuestions.isEmpty ? AppColors.muted : AppColors.danger)
        }
    }
}

private struct MiniStat: View {
    let value: String
    let label: String
    let icon: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(.footnote, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardStyle()
    }
}

// MARK: - Decay Warning

private struct DecayWarningBanner: View {
    let topic: Topic

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: AppColors.warning))

            Text(BrutalMessages.stagnationMessage(topic: topic.name, daysSince: topic.daysSinceLastStudy))
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.warning))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: AppColors.warning).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(hex: AppColors.warning).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Notes Section

private struct NotesSection: View {
    @Bindable var topic: Topic
    @State private var isEditing = false
    @State private var draft     = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(icon: "note.text", iconColor: AppColors.neutral,
                              title: "Notes", subtitle: "")
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        topic.notes = draft
                        try? topic.modelContext?.save()
                    } else {
                        draft = topic.notes
                    }
                    isEditing.toggle()
                }
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.primary))
            }

            if isEditing {
                TextEditor(text: $draft)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: AppColors.surfaceSecondary))
                    .cornerRadius(10)
                    .frame(minHeight: 100)
            } else {
                Text(topic.notes.isEmpty ? "No notes yet. Add key concepts, formulas, or reminders." : topic.notes)
                    .font(.subheadline)
                    .foregroundStyle(topic.notes.isEmpty ? Color(hex: AppColors.muted) : Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: AppColors.surfacePrimary))
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Topic Materials Section

private struct TopicMaterialsSection: View {
    let topic: Topic
    @Query private var allMaterials: [StudyMaterial]

    init(topic: Topic) {
        self.topic = topic
        _allMaterials = Query(sort: \StudyMaterial.createdAt, order: .reverse)
    }

    private var topicMaterials: [StudyMaterial] {
        allMaterials.filter { $0.topic?.id == topic.id }
    }

    var body: some View {
        if !topicMaterials.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(icon: "doc.text.fill", iconColor: AppColors.primary,
                              title: "Materials", subtitle: "\(topicMaterials.count) linked")

                ForEach(topicMaterials) { material in
                    NavigationLink {
                        // Navigate to material — needs AICoachViewModel
                        // Use a lightweight row here instead
                        Text(material.rawText)
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                            .padding()
                            .navigationTitle(material.title)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: material.isPDF ? "doc.fill" : "doc.text.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: AppColors.primary))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(material.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(material.wordCount) words")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: AppColors.muted))
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: AppColors.surfacePrimary))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Questions Section

private struct QuestionsSection: View {
    let topic: Topic
    let questions: [Question]
    var isGenerating: Bool = false
    let onAdd: () -> Void
    let onDelete: (Question) -> Void
    let onAIGenerate: () -> Void
    var onBulkUpload: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(icon: "questionmark.circle.fill",
                              iconColor: AppColors.secondary,
                              title: "Questions",
                              subtitle: "\(questions.count) total")
                Spacer()
                // Bulk upload button
                Button(action: { onBulkUpload?() }) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: AppColors.surfaceSecondary)))
                }
                .buttonStyle(.plain)
                if !questions.isEmpty {
                    Button(action: onAIGenerate) {
                        Label("AI ✦", systemImage: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: AppColors.primary))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: AppColors.primary).opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isGenerating)
                }
                Button("Add", action: onAdd)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.primary))
            }

            if questions.isEmpty {
                AIGenerateCard(
                    topicName: topic.name,
                    isGenerating: isGenerating,
                    onGenerate: onAIGenerate,
                    onAdd: onAdd
                )
            } else {
                ForEach(questions) { question in
                    QuestionRowView(question: question, onDelete: { onDelete(question) })
                }
            }
        }
    }
}

// MARK: - AI Generate Card (shown when topic has 0 questions)

private struct AIGenerateCard: View {
    let topicName: String
    let isGenerating: Bool
    let onGenerate: () -> Void
    let onAdd: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: AppColors.primary).opacity(0.25), .clear],
                            center: .center, startRadius: 0, endRadius: 48
                        )
                    )
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "sparkles")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("No questions yet")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("Let AI generate a set of questions\nfor \(topicName) — MCQs, definitions,\ncode challenges and more.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Generate button
            Button(action: onGenerate) {
                Group {
                    if isGenerating {
                        HStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.85)
                            Text("Generating questions…")
                                .font(.subheadline.weight(.semibold))
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                }
                .foregroundStyle(Color(hex: AppColors.background))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: isGenerating
                                    ? [Color(hex: AppColors.muted), Color(hex: AppColors.muted)]
                                    : [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isGenerating)

            // Manual fallback
            Button("Add manually instead", action: onAdd)
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hex: AppColors.primary).opacity(0.35),
                                    Color(hex: AppColors.secondary).opacity(0.15)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear { pulse = true }
    }
}

// MARK: - Question Row View

private struct QuestionRowView: View {
    let question: Question
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Type badge
                Text(question.questionType.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: AppColors.surfaceTertiary))
                    .cornerRadius(4)

                // Difficulty dots
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= question.difficulty
                                  ? Color(hex: AppColors.warning)
                                  : Color(hex: AppColors.muted))
                            .frame(width: 5, height: 5)
                    }
                }

                Spacer()

                if question.isNemesis {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: AppColors.danger))
                }

                if question.timesAsked > 0 {
                    Text("\(Int(question.accuracyRate * 100))%")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color(hex: AppColors.muted))
                }

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.danger).opacity(0.7))
                }
            }

            Text(question.questionText)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(3)

            if !question.correctAnswer.isEmpty {
                Text("Answer: \(question.correctAnswer)")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.success))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .cardStyle()
    }
}

// MARK: - Prerequisites Section

private struct PrerequisitesSection: View {
    @Bindable var topic: Topic
    @Query private var allTopics: [Topic]
    @State private var showingPicker = false

    private var otherTopics: [Topic] {
        allTopics.filter { $0.id != topic.id && !topic.prerequisites.map(\.id).contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(icon: "arrow.triangle.branch", iconColor: AppColors.warning,
                              title: "Prerequisites", subtitle: "\(topic.prerequisites.count) required")
                Spacer()
                Button {
                    showingPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.warning))
                }
                .buttonStyle(.plain)
            }

            if topic.prerequisites.isEmpty {
                Text("No prerequisites set. Add topics that should be mastered before this one.")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: AppColors.surfacePrimary)))
            } else {
                VStack(spacing: 6) {
                    // Unmet prerequisites warning
                    if !topic.unmetPrerequisites.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(Color(hex: AppColors.warning))
                            Text("\(topic.unmetPrerequisites.count) prerequisite(s) below 60% — consider reviewing first.")
                                .font(.caption)
                                .foregroundStyle(Color(hex: AppColors.warning))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: AppColors.warning).opacity(0.1))
                        )
                    }

                    ForEach(topic.prerequisites) { prereq in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(prereq.proficiencyScore >= 60
                                      ? Color(hex: AppColors.success)
                                      : Color(hex: AppColors.warning))
                                .frame(width: 8, height: 8)
                            Text(prereq.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(prereq.proficiencyScore)%")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundStyle(prereq.proficiencyScore >= 60
                                                 ? Color(hex: AppColors.success)
                                                 : Color(hex: AppColors.warning))
                            Button {
                                topic.prerequisites.removeAll { $0.id == prereq.id }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: AppColors.surfacePrimary)))
                    }
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            PrerequisitePickerView(topic: topic, candidates: otherTopics)
        }
    }
}

private struct PrerequisitePickerView: View {
    @Bindable var topic: Topic
    let candidates: [Topic]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(candidates) { candidate in
                Button {
                    if !topic.prerequisites.map(\.id).contains(candidate.id) {
                        topic.prerequisites.append(candidate)
                    }
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(candidate.name).foregroundStyle(.white)
                            Text(candidate.subject?.name ?? "").font(.caption).foregroundStyle(Color(hex: AppColors.muted))
                        }
                        Spacer()
                        Text("\(candidate.proficiencyScore)%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                }
                .listRowBackground(Color(hex: AppColors.surfacePrimary))
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: AppColors.background))
            .navigationTitle("Add Prerequisite")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}
