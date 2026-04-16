import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Bulk Upload View

struct BulkUploadView: View {

    enum Mode {
        case questions
        case studyGuide
    }

    let topic: Topic
    let mode: Mode
    var onDismiss: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker  = false
    @State private var parsedQuestions: [CSVParser.ParsedQuestion] = []
    @State private var parsedSections:  [StudyGuideParser.ParsedSection] = []
    @State private var parseErrors:   [String] = []
    @State private var parseWarnings: [String] = []
    @State private var hasParsed    = false
    @State private var isParsing    = false
    @State private var importSuccess = false
    @State private var importCount   = 0
    @State private var templateURL: URL?

    // MARK: - Template

    private var templateString: String {
        mode == .questions
            ? CSVParser.questionsTemplate(topicName: topic.name)
            : StudyGuideParser.studyGuideTemplate(topicName: topic.name)
    }

    private var templateFileName: String {
        let safe = topic.name.replacingOccurrences(of: " ", with: "_")
        return mode == .questions
            ? "\(safe)_questions_template.csv"
            : "\(safe)_study_guide_template.json"
    }

    private var allowedTypes: [UTType] {
        mode == .questions ? [.commaSeparatedText, .text, .plainText] : [.json]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stepOneCard
                    stepTwoCard
                    if hasParsed {
                        previewCard
                    }
                    if importSuccess {
                        successBanner
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color(hex: AppColors.background))
            .navigationTitle(mode == .questions ? "Bulk Upload Questions" : "Upload Study Guide")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: AppColors.muted))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { buildTemplateURL() }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: allowedTypes
        ) { result in
            handleFilePick(result)
        }
    }

    // MARK: - Step 1: Download Template

    private var stepOneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                number: "①",
                title: "Download Template",
                color: AppColors.primary
            )

            Text(mode == .questions
                 ? "A CSV file with the correct columns. Fill in your questions — don't change the header row. MCQ, True/False, Short Answer, and more are supported."
                 : "A JSON file with pre-filled section templates. Replace the placeholder content with your study material.")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)

            if let url = templateURL {
                ShareLink(
                    item: url,
                    preview: SharePreview(
                        templateFileName,
                        image: Image(systemName: mode == .questions ? "tablecells" : "doc.text")
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                        Text("Download \(mode == .questions ? "CSV" : "JSON") Template")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: AppColors.primary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: AppColors.primary).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(hex: AppColors.primary).opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            } else {
                // Template not ready yet
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: AppColors.surfaceSecondary))
                    .frame(height: 48)
                    .overlay(ProgressView().tint(Color(hex: AppColors.primary)))
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Step 2: Choose File

    private var stepTwoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                number: "②",
                title: "Upload Your File",
                color: AppColors.secondary
            )

            Text(mode == .questions
                 ? "Select your filled CSV file. Questions will be added to \"\(topic.name)\"."
                 : "Select your filled JSON file. It will replace the current study guide for \"\(topic.name)\".")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: 8) {
                    if isParsing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color(hex: AppColors.secondary))
                            .scaleEffect(0.8)
                        Text("Parsing file…")
                    } else {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 16))
                        Text(hasParsed ? "Choose a Different File" : "Choose File")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.secondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: AppColors.secondary).opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: AppColors.secondary).opacity(0.35), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isParsing)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Preview Card

    @ViewBuilder
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            let itemCount = mode == .questions ? parsedQuestions.count : parsedSections.count

            HStack {
                stepHeader(
                    number: "③",
                    title: "Review & Import",
                    color: AppColors.success
                )
                Spacer()
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: itemCount > 0 ? AppColors.success : AppColors.danger))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(hex: itemCount > 0 ? AppColors.success : AppColors.danger).opacity(0.15))
                    )
            }

            // Parse errors
            if !parseErrors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Parse Issues (\(parseErrors.count))", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.warning))

                    ForEach(parseErrors, id: \.self) { err in
                        Text("• \(err)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.warning))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: AppColors.warning).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color(hex: AppColors.warning).opacity(0.2), lineWidth: 1)
                        )
                )
            }

            // Warnings
            if !parseWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(parseWarnings, id: \.self) { w in
                        Label(w, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                    }
                }
            }

            // Preview list
            if itemCount > 0 {
                Divider().background(Color(hex: AppColors.surfaceTertiary))
                if mode == .questions {
                    questionsPreview
                } else {
                    sectionsPreview
                }
                Divider().background(Color(hex: AppColors.surfaceTertiary))

                Button {
                    importItems()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Import \(itemCount) \(mode == .questions ? (itemCount == 1 ? "Question" : "Questions") : (itemCount == 1 ? "Section" : "Sections"))")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.success))
                    )
                }
                .buttonStyle(.plain)
            } else {
                Text("No valid items found. Fix the issues in your file and upload again.")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.danger))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Questions Preview

    private var questionsPreview: some View {
        VStack(spacing: 6) {
            ForEach(Array(parsedQuestions.prefix(5).enumerated()), id: \.offset) { i, q in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: AppColors.muted))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(q.questionText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(q.questionType.displayName)
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: AppColors.neutral))
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Color(hex: AppColors.surfaceTertiary))
                                .cornerRadius(3)

                            Text("Diff \(q.difficulty)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(hex: AppColors.muted))

                            if let w = q.parseWarning {
                                Text("⚠ \(w)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: AppColors.warning))
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color(hex: AppColors.surfacePrimary))
                .cornerRadius(8)
            }

            if parsedQuestions.count > 5 {
                Text("+ \(parsedQuestions.count - 5) more question\(parsedQuestions.count - 5 == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Sections Preview

    private var sectionsPreview: some View {
        VStack(spacing: 6) {
            ForEach(Array(parsedSections.enumerated()), id: \.offset) { _, s in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: s.type.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: s.type.accentColor))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(s.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(s.type.rawValue)
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: AppColors.neutral))
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Color(hex: AppColors.surfaceTertiary))
                                .cornerRadius(3)

                            Text("\(s.content.count) chars")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(hex: AppColors.muted))

                            if let w = s.parseWarning {
                                Text("⚠ \(w)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: AppColors.warning))
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color(hex: AppColors.surfacePrimary))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: AppColors.success))
            VStack(alignment: .leading, spacing: 2) {
                Text("Import Successful")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(importCount) \(mode == .questions ? "question\(importCount == 1 ? "" : "s")" : "section\(importCount == 1 ? "" : "s")") added to \(topic.name).")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.neutral))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.success).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: AppColors.success).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Shared Sub-views

    private func stepHeader(number: String, title: String, color: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.headline.weight(.black))
                .foregroundStyle(Color(hex: color))
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Template File

    private func buildTemplateURL() {
        let content = templateString
        let filename = templateFileName
        Task.detached(priority: .utility) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? content.write(to: url, atomically: true, encoding: .utf8)
            await MainActor.run { templateURL = url }
        }
    }

    // MARK: - File Handling

    private func handleFilePick(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }

        isParsing  = true
        hasParsed  = false
        parsedQuestions = []
        parsedSections  = []
        parseErrors     = []
        parseWarnings   = []

        Task {
            defer { isParsing = false }
            guard url.startAccessingSecurityScopedResource() else {
                parseErrors = ["Could not access the selected file."]
                hasParsed = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                parseErrors = ["Could not read file as UTF-8 text."]
                hasParsed = true
                return
            }

            await MainActor.run {
                if mode == .questions {
                    let parsed = CSVParser.parseQuestions(from: content)
                    parsedQuestions = parsed.questions
                    parseErrors     = parsed.errors
                    parseWarnings   = parsed.questions.compactMap(\.parseWarning)
                } else {
                    let parsed = StudyGuideParser.parseSections(from: content)
                    parsedSections = parsed.sections
                    parseErrors    = parsed.errors
                    parseWarnings  = parsed.sections.compactMap(\.parseWarning)
                }
                hasParsed = true
            }
        }
    }

    // MARK: - Import

    private func importItems() {
        if mode == .questions { importQuestions() }
        else                  { importStudyGuide() }
    }

    private func importQuestions() {
        for pq in parsedQuestions {
            let q = Question(
                topic:          topic,
                questionText:   pq.questionText,
                questionType:   pq.questionType,
                options:        pq.options,
                correctAnswer:  pq.correctAnswer,
                explanation:    pq.explanation,
                difficulty:     pq.difficulty,
                tags:           pq.tags,
                isAIGenerated:  false
            )
            modelContext.insert(q)
            topic.questions.append(q)
        }
        try? modelContext.save()
        finishImport(count: parsedQuestions.count)
    }

    private func importStudyGuide() {
        // Replace existing article
        if let existing = topic.article {
            modelContext.delete(existing)
        }

        let article = TopicArticle()
        article.isAIGenerated = false
        modelContext.insert(article)
        topic.article = article
        article.topic = topic

        for (i, ps) in parsedSections.enumerated() {
            let section = ArticleSection(
                order:      i,
                type:       ps.type,
                title:      ps.title,
                content:    ps.content,
                confidence: ps.confidence
            )
            // User-uploaded content is pre-verified
            section.isVerified = true
            section.article = article
            modelContext.insert(section)
            article.sections.append(section)
        }

        try? modelContext.save()
        finishImport(count: parsedSections.count)
    }

    private func finishImport(count: Int) {
        importCount   = count
        importSuccess = true
        HapticManager.shared.correctAnswer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onDismiss?()
            dismiss()
        }
    }
}
