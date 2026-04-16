import SwiftUI
import SwiftData

struct SubjectDetailView: View {

    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(GeminiService.self) private var geminiService
    @Query(sort: \DailyLog.date, order: .reverse) private var recentLogs: [DailyLog]

    @State private var showingAddTopic      = false
    @State private var topicToDelete: Topic?
    @State private var showDeleteConfirm    = false
    @State private var bulkTopicText        = ""
    @State private var showingBulkAdd       = false
    @State private var showingBulkGenerate  = false
    @State private var exportURL: URL?      = nil

    private var sortedTopics: [Topic] {
        subject.topics.sorted { $0.proficiencyScore < $1.proficiencyScore }
    }

    // MARK: - Feature 8: Interview Readiness Score

    private var readinessScore: Int {
        let topics = subject.topics
        guard !topics.isEmpty else { return 0 }
        let avgProf    = Double(topics.map(\.proficiencyScore).reduce(0, +)) / Double(topics.count)
        let coverage   = Double(topics.filter { $0.proficiencyScore >= 60 }.count) / Double(topics.count)
        let accdTopics = topics.filter { $0.overallAccuracyRate > 0 }
        let avgAcc     = accdTopics.isEmpty ? 0.5 : accdTopics.map(\.overallAccuracyRate).reduce(0, +) / Double(accdTopics.count)
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let recency    = Double(topics.filter { ($0.lastStudiedAt ?? .distantPast) > twoWeeksAgo }.count) / Double(topics.count)
        let score = (avgProf * 0.40) + (coverage * 100 * 0.30) + (avgAcc * 100 * 0.20) + (recency * 100 * 0.10)
        return min(100, Int(score))
    }

    // MARK: - Feature 9: Pace Projection

    private var daysTo80: Int? {
        let current = Int(subject.avgProficiency)
        guard current < 80 else { return nil }
        let sevenAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let weekLogs = recentLogs.filter { $0.date >= sevenAgo }
        let avgDaily = weekLogs.isEmpty ? 30 : weekLogs.map(\.totalStudyMinutes).reduce(0, +) / weekLogs.count
        let pointsNeeded = 80 - current
        let minutesNeeded = Double(pointsNeeded) * 12.0  // ~12 min per proficiency point
        let days = Int(ceil(minutesNeeded / Double(max(1, avgDaily))))
        return days
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Subject header stats + readiness
                SubjectStatsHeader(subject: subject, readinessScore: readinessScore)

                // Feature 9: Pace projection
                if !subject.topics.isEmpty {
                    PaceProjectionView(daysTo80: daysTo80, subject: subject)
                }

                // Feature 7: Weak spot heatmap
                if !subject.topics.isEmpty {
                    WeakSpotHeatmapView(subject: subject)
                }

                // Topics list
                if subject.topics.isEmpty {
                    EmptyStateView(
                        icon: "tag.fill",
                        title: "No topics yet",
                        message: "Add the specific topics within \(subject.name). Be granular — each topic gets its own proficiency score.",
                        actionLabel: "Add Topic",
                        action: { showingAddTopic = true }
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(
                            icon: "tag.fill",
                            iconColor: subject.colorHex,
                            title: "Topics",
                            subtitle: "\(subject.totalTopics) total"
                        )

                        ForEach(sortedTopics) { topic in
                            NavigationLink(destination: TopicDetailView(topic: topic)) {
                                TopicRowView(topic: topic, accentColor: subject.colorHex)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    topicToDelete = topic
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: AppColors.background))
        .navigationTitle(subject.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddTopic = true
                    } label: {
                        Label("Add Topic", systemImage: "plus")
                    }
                    Button {
                        showingBulkAdd = true
                    } label: {
                        Label("Bulk Add Topics", systemImage: "list.bullet.indent")
                    }
                    Divider()
                    Button {
                        showingBulkGenerate = true
                    } label: {
                        Label("Generate Questions with AI", systemImage: "sparkles")
                    }
                    .disabled(subject.topics.isEmpty)

                    Divider()

                    Button {
                        exportURL = buildExportURL()
                    } label: {
                        Label("Export as JSON", systemImage: "arrow.up.doc.fill")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: subject.colorHex))
                }
            }
        }
        .sheet(isPresented: $showingAddTopic) {
            AddTopicView(subject: subject)
        }
        .sheet(isPresented: $showingBulkAdd) {
            BulkAddTopicsView(subject: subject)
        }
        .sheet(isPresented: $showingBulkGenerate) {
            BulkGenerateQuestionsView(subject: subject, geminiService: geminiService)
        }
        .sheet(isPresented: Binding(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )) {
            if let url = exportURL {
                ShareLink(
                    item: url,
                    subject: Text(subject.name),
                    message: Text("GrindCheck subject export")
                ) {
                    Label("Share \(subject.name).json", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(Color(hex: AppColors.primary))
                        .padding()
                }
                .presentationDetents([.height(160)])
                .preferredColorScheme(.dark)
            }
        }
        .confirmationDialog(
            "Delete \"\(topicToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Topic & All Questions", role: .destructive) {
                if let topic = topicToDelete {
                    modelContext.delete(topic)
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This deletes all questions in this topic. Cannot be undone.")
        }
    }

    // MARK: - Export

    private func buildExportURL() -> URL? {
        var topicsArray: [[String: Any]] = []

        for topic in subject.topics.sorted(by: { $0.name < $1.name }) {
            var questionsArray: [[String: Any]] = []
            for q in topic.questions {
                questionsArray.append([
                    "questionText":  q.questionText,
                    "questionType":  q.questionType.rawValue,
                    "options":       q.options,
                    "correctAnswer": q.correctAnswer,
                    "explanation":   q.explanation,
                    "difficulty":    q.difficulty,
                    "tags":          q.tags
                ])
            }

            var guideArray: [[String: Any]] = []
            if let article = topic.article {
                for section in article.sortedSections {
                    guideArray.append([
                        "type":       section.type.rawValue,
                        "title":      section.title,
                        "content":    section.content,
                        "confidence": section.confidence.rawValue
                    ])
                }
            }

            topicsArray.append([
                "name":       topic.name,
                "questions":  questionsArray,
                "studyGuide": guideArray
            ])
        }

        let payload: [String: Any] = [
            "subject": [
                "name":     subject.name,
                "icon":     subject.icon,
                "colorHex": subject.colorHex
            ],
            "topics": topicsArray
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return nil }

        let safeName = subject.name
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .joined(separator: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName)_export.json")
        try? data.write(to: url)
        return url
    }
}

// MARK: - Subject Stats Header (Feature 8: readiness score)

private struct SubjectStatsHeader: View {
    let subject: Subject
    let readinessScore: Int

    private var readinessColor: String {
        if readinessScore >= 75 { return AppColors.success }
        if readinessScore >= 45 { return AppColors.warning }
        return AppColors.danger
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: subject.colorHex).opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: subject.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(Color(hex: subject.colorHex))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(subject.totalTopics) topics · \(subject.masteredTopics) mastered")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                    TopicProficiencyBar(score: Int(subject.avgProficiency))
                    HStack(spacing: 16) {
                        Label("\(subject.totalTimeSpentMinutes.studyTimeFormatted) studied",
                              systemImage: "clock.fill")
                        Label("\(subject.totalQuestions) questions",
                              systemImage: "questionmark.circle.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                }

                Spacer()

                // Readiness score badge
                VStack(spacing: 2) {
                    Text("\(readinessScore)")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: readinessColor))
                    Text("READY")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color(hex: readinessColor).opacity(0.7))
                        .tracking(1)
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Pace Projection (Feature 9)

private struct PaceProjectionView: View {
    let daysTo80: Int?
    let subject: Subject

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: AppColors.primary))

            if let days = daysTo80 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("At your current pace")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                    Text("~\(days) days to 80% proficiency")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Proficiency target")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                    Text("80% target reached ✓")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.success))
                }
            }

            Spacer()

            Text("\(Int(subject.avgProficiency))%")
                .font(.system(.title3, design: .monospaced, weight: .black))
                .foregroundStyle(Color(hex: AppColors.primary))
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Topic Row View

struct TopicRowView: View {
    let topic: Topic
    let accentColor: String

    var body: some View {
        HStack(spacing: 12) {
            // Confidence indicator dot
            Circle()
                .fill(Color(hex: topic.confidenceLevel.colorHex))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(topic.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    if topic.isDecaying {
                        Image(systemName: "arrow.down.heart.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: AppColors.warning))
                    }

                    if !topic.nemesisQuestions.isEmpty {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: AppColors.danger))
                    }
                }

                HStack(spacing: 8) {
                    Text(topic.lastStudiedAt?.relativeDescription ?? "Never studied")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))

                    if topic.totalQuestions > 0 {
                        Text("·")
                            .foregroundStyle(Color(hex: AppColors.muted))
                        Text("\(topic.totalQuestions) questions")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(topic.proficiencyScore)%")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: topic.confidenceLevel.colorHex))

                TopicProficiencyBar(score: topic.proficiencyScore, showLabel: false, height: 4)
                    .frame(width: 48)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }
}

// MARK: - Bulk Add Topics

private struct BulkAddTopicsView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""

    private var topicNames: [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("One topic per line. They'll be added to \(subject.name).")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .padding(.horizontal)

                TextEditor(text: $text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: AppColors.surfacePrimary))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .frame(minHeight: 200)

                if !topicNames.isEmpty {
                    Text("\(topicNames.count) topics will be added")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.primary))
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .background(Color(hex: AppColors.background))
            .navigationTitle("Bulk Add Topics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(topicNames.count)") {
                        bulkAdd()
                    }
                    .disabled(topicNames.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bulkAdd() {
        for name in topicNames {
            let topic = Topic(name: name, subject: subject)
            modelContext.insert(topic)
            subject.topics.append(topic)
        }
        try? modelContext.save()
        HapticManager.shared.correctAnswer()
        dismiss()
    }
}

// MARK: - Bulk Generate Questions

private struct BulkGenerateQuestionsView: View {
    let subject: Subject
    let geminiService: GeminiService

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum TopicStatus: Equatable {
        case waiting, generating, done(Int), skipped, failed(String)
        var isDone: Bool {
            if case .done = self { return true }
            if case .skipped = self { return true }
            if case .failed = self { return true }
            return false
        }
    }

    @State private var statuses: [UUID: TopicStatus] = [:]
    @State private var isRunning = false
    @State private var totalAdded = 0
    @State private var showAPIKeyAlert = false

    private var topics: [Topic] { subject.topics.sorted { $0.name < $1.name } }
    private var allDone: Bool { isRunning && topics.allSatisfy { statuses[$0.id]?.isDone == true } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Header card
                        VStack(alignment: .leading, spacing: 8) {
                            Label("AI Question Generation", systemImage: "sparkles")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            Text("Gemini will generate ~10 questions per topic. Questions are auto-added — review them in each topic afterward.")
                                .font(.caption)
                                .foregroundStyle(Color(hex: AppColors.neutral))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: AppColors.surfacePrimary))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color(hex: AppColors.primary).opacity(0.2), lineWidth: 1)
                                )
                        )

                        // Topics list
                        VStack(spacing: 6) {
                            ForEach(topics) { topic in
                                topicRow(topic)
                            }
                        }

                        if allDone {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: AppColors.success))
                                Text("\(totalAdded) questions added across \(topics.count) topics")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: AppColors.success).opacity(0.1))
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Generate Questions")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(allDone ? "Done" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !isRunning {
                        Button {
                            guard geminiService.hasAPIKey else { showAPIKeyAlert = true; return }
                            Task { await generateAll() }
                        } label: {
                            Label("Generate All", systemImage: "sparkles")
                                .fontWeight(.semibold)
                        }
                    } else if !allDone {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.85)
                    }
                }
            }
            .alert("API Key Required", isPresented: $showAPIKeyAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Add your Gemini API key in the AI Coach tab first.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            statuses = Dictionary(uniqueKeysWithValues: topics.map { ($0.id, .waiting) })
        }
    }

    @ViewBuilder
    private func topicRow(_ topic: Topic) -> some View {
        let status = statuses[topic.id] ?? .waiting
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor(status).opacity(0.15))
                    .frame(width: 32, height: 32)
                statusIcon(status)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(statusLabel(status, existing: topic.questions.count))
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }

            Spacer()

            if case .done(let n) = status {
                Text("+\(n)")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.success))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    private func statusColor(_ s: TopicStatus) -> Color {
        switch s {
        case .waiting:    return Color(hex: AppColors.muted)
        case .generating: return Color(hex: AppColors.primary)
        case .done:       return Color(hex: AppColors.success)
        case .skipped:    return Color(hex: AppColors.warning)
        case .failed:     return Color(hex: AppColors.danger)
        }
    }

    @ViewBuilder
    private func statusIcon(_ s: TopicStatus) -> some View {
        switch s {
        case .waiting:
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
        case .generating:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.65)
                .tint(Color(hex: AppColors.primary))
        case .done:
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: AppColors.success))
        case .skipped:
            Image(systemName: "forward.fill")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.warning))
        case .failed:
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: AppColors.danger))
        }
    }

    private func statusLabel(_ s: TopicStatus, existing: Int) -> String {
        switch s {
        case .waiting:        return "\(existing) existing questions"
        case .generating:     return "Generating…"
        case .done(let n):    return "\(n) new questions added"
        case .skipped:        return "Skipped — already has \(existing) questions"
        case .failed(let e):  return "Failed: \(e)"
        }
    }

    private func generateAll() async {
        isRunning = true
        for topic in topics {
            statuses[topic.id] = .generating
            do {
                let generated = try await geminiService.generateQuestionsForTopic(
                    topicName: topic.name,
                    subjectName: subject.name,
                    existingQuestions: topic.questions.map(\.questionText)
                )
                for gq in generated {
                    let q = Question(
                        topic: topic,
                        questionText:  gq.questionText,
                        questionType:  gq.questionType,
                        options:       gq.options,
                        correctAnswer: gq.correctAnswer,
                        explanation:   gq.explanation,
                        difficulty:    gq.difficulty,
                        tags:          gq.tags,
                        isAIGenerated: true
                    )
                    modelContext.insert(q)
                    topic.questions.append(q)
                }
                try? modelContext.save()
                totalAdded += generated.count
                statuses[topic.id] = .done(generated.count)
            } catch {
                let msg = error.localizedDescription
                statuses[topic.id] = .failed(String(msg.prefix(60)))
            }
        }
        HapticManager.shared.correctAnswer()
    }
}
