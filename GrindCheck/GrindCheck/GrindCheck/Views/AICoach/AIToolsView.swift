import SwiftUI
import SwiftData

// MARK: - AI Tools Hub (Paste Code, Exam Scheduler, Job Description)

struct AIToolsView: View {

    let geminiService: GeminiService
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query private var profiles: [UserProfile]

    @State private var activeTool: AITool? = nil

    enum AITool: String, Identifiable {
        case pasteCode, examScheduler, jobDescription
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                toolCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    color: AppColors.primary,
                    title: "Paste Your Code",
                    subtitle: "AI infers what you've mastered and updates your topic confidence",
                    tool: .pasteCode
                )
                toolCard(
                    icon: "calendar.badge.clock",
                    color: AppColors.warning,
                    title: "Exam Countdown Scheduler",
                    subtitle: "Enter your exam date and get a day-by-day review plan",
                    tool: .examScheduler
                )
                toolCard(
                    icon: "doc.text.magnifyingglass",
                    color: AppColors.secondary,
                    title: "Job Description Import",
                    subtitle: "Paste a JD and see exactly which skills you're missing",
                    tool: .jobDescription
                )
            }
            .padding(16)
        }
        .background(Color(hex: AppColors.background))
        .sheet(item: $activeTool) { tool in
            switch tool {
            case .pasteCode:
                PasteCodeView(geminiService: geminiService, subjects: Array(subjects))
            case .examScheduler:
                ExamSchedulerView(geminiService: geminiService, subjects: Array(subjects), profile: profiles.first)
            case .jobDescription:
                JobDescriptionView(geminiService: geminiService, subjects: Array(subjects))
            }
        }
    }

    private func toolCard(icon: String, color: String, title: String, subtitle: String, tool: AITool) -> some View {
        Button { activeTool = tool } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: color))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: AppColors.surfacePrimary))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: color).opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Paste Code View

struct PasteCodeView: View {

    let geminiService: GeminiService
    let subjects: [Subject]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var code: String = ""
    @State private var isAnalyzing = false
    @State private var result: CodeAnalysisResult? = nil
    @State private var error: String? = nil

    private var allTopicNames: [String] {
        subjects.flatMap(\.topics).map(\.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        Text("Paste code you wrote — could be a script, notebook cell, or solution. AI will identify what you've demonstrated and update your mastery scores.")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: AppColors.neutral))

                        TextEditor(text: $code)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color(hex: AppColors.surfaceSecondary))
                            .cornerRadius(12)
                            .frame(minHeight: 200)

                        if let result {
                            analysisResultView(result)
                        }
                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color(hex: AppColors.danger))
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Paste Your Code")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await analyze() }
                    } label: {
                        if isAnalyzing {
                            ProgressView().tint(Color(hex: AppColors.primary))
                        } else {
                            Label("Analyze", systemImage: "sparkles")
                        }
                    }
                    .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func analyze() async {
        isAnalyzing = true; error = nil; result = nil
        do {
            let r = try await geminiService.analyzeCode(code, topics: allTopicNames)
            result = r
            applyBoosts(r)
        } catch {
            self.error = error.localizedDescription
        }
        isAnalyzing = false
    }

    private func applyBoosts(_ r: CodeAnalysisResult) {
        let allTopics = subjects.flatMap(\.topics)
        for (topicName, boost) in r.confidenceBoost {
            if let topic = allTopics.first(where: { $0.name.localizedCaseInsensitiveContains(topicName) }) {
                topic.proficiencyScore = min(100, topic.proficiencyScore + boost)
                topic.confidenceLevel  = .from(proficiency: topic.proficiencyScore)
            }
        }
        try? modelContext.save()
    }

    @ViewBuilder
    private func analysisResultView(_ r: CodeAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(r.feedback)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: AppColors.surfacePrimary)))

            if !r.masteredConcepts.isEmpty {
                tagSection(title: "Demonstrated", color: AppColors.success, tags: r.masteredConcepts)
            }
            if !r.gaps.isEmpty {
                tagSection(title: "Gaps Found", color: AppColors.danger, tags: r.gaps)
            }
            if !r.confidenceBoost.isEmpty {
                Text("✓ Boosted \(r.confidenceBoost.count) topic scores")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.success))
            }
        }
    }

    private func tagSection(title: String, color: String, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: color))
            TagCloudView(tags: tags, color: color)
        }
    }
}

// MARK: - Exam Scheduler View

struct ExamSchedulerView: View {

    let geminiService: GeminiService
    let subjects: [Subject]
    let profile: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSubject: Subject? = nil
    @State private var examDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var isGenerating = false
    @State private var schedule: String? = nil
    @State private var error: String? = nil

    var body: some View {
        NavigationStack {
            ZStack { Color(hex: AppColors.background).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Subject picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject").font(.caption.weight(.semibold)).foregroundStyle(Color(hex: AppColors.muted))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(subjects) { subject in
                                        Button { selectedSubject = subject } label: {
                                            Text(subject.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(selectedSubject?.id == subject.id ? .white : Color(hex: AppColors.neutral))
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(Capsule().fill(selectedSubject?.id == subject.id ? Color(hex: subject.colorHex) : Color(hex: AppColors.surfacePrimary)))
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exam Date").font(.caption.weight(.semibold)).foregroundStyle(Color(hex: AppColors.muted))
                            DatePicker("", selection: $examDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .accentColor(Color(hex: AppColors.primary))
                        }

                        if let schedule {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Study Plan").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                                Text(LocalizedStringKey(schedule))
                                    .font(.subheadline).foregroundStyle(Color(hex: AppColors.neutral))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: AppColors.surfacePrimary)))
                            }
                        }
                        if let error { Text(error).font(.caption).foregroundStyle(Color(hex: AppColors.danger)) }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Exam Scheduler")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await generate() } } label: {
                        if isGenerating { ProgressView().tint(Color(hex: AppColors.primary)) }
                        else { Label("Generate", systemImage: "sparkles") }
                    }
                    .disabled(selectedSubject == nil || isGenerating)
                }
            }
            .onAppear { selectedSubject = subjects.first }
        }
        .preferredColorScheme(.dark)
    }

    private func generate() async {
        guard let subject = selectedSubject else { return }
        isGenerating = true; error = nil
        let topics = subject.topics.map { (name: $0.name, proficiency: $0.proficiencyScore) }
        do {
            schedule = try await geminiService.generateExamSchedule(
                examDate: examDate, subjectName: subject.name, topics: topics)
            // Save exam date to profile
            if let p = profile {
                p.examDate = examDate
                p.examSubjectName = subject.name
                try? modelContext.save()
            }
        } catch { self.error = error.localizedDescription }
        isGenerating = false
    }
}

// MARK: - Job Description View

struct JobDescriptionView: View {

    let geminiService: GeminiService
    let subjects: [Subject]

    @Environment(\.dismiss) private var dismiss

    @State private var jdText: String = ""
    @State private var isAnalyzing = false
    @State private var result: JobGapAnalysis? = nil
    @State private var error: String? = nil

    private var allTopicNames: [String] { subjects.flatMap(\.topics).map(\.name) }

    var body: some View {
        NavigationStack {
            ZStack { Color(hex: AppColors.background).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Paste a job description. AI will compare required skills against your current topics and show exactly what you're missing.")
                            .font(.subheadline).foregroundStyle(Color(hex: AppColors.neutral))

                        TextEditor(text: $jdText)
                            .font(.subheadline).foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color(hex: AppColors.surfaceSecondary))
                            .cornerRadius(12).frame(minHeight: 180)

                        if let result { jobResultView(result) }
                        if let error { Text(error).font(.caption).foregroundStyle(Color(hex: AppColors.danger)) }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Job Description Import")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await analyze() } } label: {
                        if isAnalyzing { ProgressView().tint(Color(hex: AppColors.primary)) }
                        else { Label("Analyze", systemImage: "sparkles") }
                    }
                    .disabled(jdText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func analyze() async {
        isAnalyzing = true; error = nil; result = nil
        do { result = try await geminiService.analyzeJobDescription(jdText, currentTopics: allTopicNames) }
        catch { self.error = error.localizedDescription }
        isAnalyzing = false
    }

    @ViewBuilder
    private func jobResultView(_ r: JobGapAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Match score
            HStack {
                Text("Match Score")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Spacer()
                Text("\(r.matchScore)%")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundStyle(r.matchScore >= 70 ? Color(hex: AppColors.success) : r.matchScore >= 40 ? Color(hex: AppColors.warning) : Color(hex: AppColors.danger))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: AppColors.surfacePrimary)))

            if !r.alreadyHave.isEmpty { tagSection(title: "✓ You already have", color: AppColors.success, tags: r.alreadyHave) }
            if !r.gaps.isEmpty { tagSection(title: "✗ Gaps to fill", color: AppColors.danger, tags: r.gaps) }
            if !r.priority.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Study These First")
                        .font(.caption.weight(.semibold)).foregroundStyle(Color(hex: AppColors.warning))
                    ForEach(Array(r.priority.enumerated()), id: \.offset) { i, skill in
                        HStack(spacing: 8) {
                            Text("\(i+1)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: AppColors.warning))
                                .frame(width: 18)
                            Text(skill).font(.subheadline).foregroundStyle(.white)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: AppColors.surfacePrimary)))
            }
        }
    }

    private func tagSection(title: String, color: String, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Color(hex: color))
            TagCloudView(tags: tags, color: color)
        }
    }
}

// MARK: - Flow Layout (tag cloud)

struct TagCloudView: View {
    let tags: [String]
    let color: String

    var body: some View {
        // Simple wrapping using a fixed-width approach
        VStack(alignment: .leading, spacing: 4) {
            let rows = makeRows()
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 4) {
                    ForEach(rows[i], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: color))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color(hex: color).opacity(0.12))
                            )
                    }
                }
            }
        }
    }

    private func makeRows() -> [[String]] {
        var rows: [[String]] = [[]]
        var lineLength = 0
        for tag in tags {
            if lineLength + tag.count > 40 && !rows.last!.isEmpty {
                rows.append([tag])
                lineLength = tag.count
            } else {
                rows[rows.count - 1].append(tag)
                lineLength += tag.count + 2
            }
        }
        return rows
    }
}
