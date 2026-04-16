import SwiftUI
import SwiftData

// MARK: - TopicArticleView

struct TopicArticleView: View {

    @Bindable var topic: Topic
    var onBulkUpload: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(GeminiService.self) private var geminiService

    @State private var isGenerating  = false
    @State private var errorMsg: String?
    @State private var showError     = false
    @State private var sectionToEdit: ArticleSection?
    @State private var showAPIKeySetup = false
    @State private var pulse = false

    private var article: TopicArticle? { topic.article }

    var body: some View {
        Group {
            if let article {
                articleView(article)
            } else if isGenerating {
                generatingView
            } else {
                emptyStateView
            }
        }
        .sheet(item: $sectionToEdit) { section in
            EditSectionSheet(section: section)
        }
        .sheet(isPresented: $showAPIKeySetup) {
            APIKeySetupView(geminiService: geminiService)
        }
        .alert("Generation Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMsg ?? "")
        }
    }

    // MARK: - Article View

    private func articleView(_ article: TopicArticle) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Verification banner
                if !article.isFullyVerified {
                    VerificationBanner(article: article)
                } else {
                    verifiedBanner
                }

                // Sections
                ForEach(article.sortedSections) { section in
                    ArticleSectionCard(
                        section: section,
                        onVerify: {
                            section.isVerified.toggle()
                            article.updatedAt = Date()
                            try? modelContext.save()
                        },
                        onFlag: { note in
                            section.isFlagged  = true
                            section.isVerified = false
                            section.flagNote   = note
                            try? modelContext.save()
                        },
                        onUnflag: {
                            section.isFlagged = false
                            section.flagNote  = ""
                            try? modelContext.save()
                        },
                        onEdit: {
                            sectionToEdit = section
                        }
                    )
                }

                // Regenerate / Upload buttons at bottom
                HStack(spacing: 10) {
                    Button {
                        Task { await regenerate() }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: AppColors.muted))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: AppColors.surfacePrimary))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onBulkUpload?()
                    } label: {
                        Label("Upload", systemImage: "arrow.up.doc")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: AppColors.neutral))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: AppColors.surfacePrimary))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)

                // AI disclaimer
                Text("AI-generated content. Verify against trusted sources before using in exams.")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(hex: AppColors.background))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: AppColors.primary).opacity(pulse ? 0.15 : 0.07))
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "book.pages.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .onAppear { pulse = true }

            VStack(spacing: 8) {
                Text("No study guide yet")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("AI will generate a structured study guide\nfor **\(topic.name)** — summary, key concepts,\nexplanation, code examples, and more.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await generate() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Study Guide")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                            startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            Button {
                onBulkUpload?()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 13))
                    Text("Upload JSON guide instead")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color(hex: AppColors.neutral))
            }
            .buttonStyle(.plain)

            Text("Content is AI-generated. Use the verify system\nto confirm accuracy before trusting it.")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
        .background(Color(hex: AppColors.background))
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(hex: AppColors.primary))
                .scaleEffect(1.4)

            Text("Generating study guide…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.neutral))

            Text("This takes about 10–15 seconds")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: AppColors.background))
    }

    // MARK: - Verified Banner

    private var verifiedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color(hex: AppColors.success))
            Text("All sections verified")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.success))
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.success).opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: AppColors.success).opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Actions

    private func generate() async {
        guard geminiService.hasAPIKey else { showAPIKeySetup = true; return }
        isGenerating = true
        defer { isGenerating = false }
        do {
            let sections = try await geminiService.generateTopicArticle(
                topicName:   topic.name,
                subjectName: topic.subject?.name ?? ""
            )
            let newArticle = TopicArticle()
            modelContext.insert(newArticle)
            newArticle.topic = topic
            topic.article    = newArticle
            for (i, s) in sections.enumerated() {
                let section = ArticleSection(
                    order:      i,
                    type:       s.type,
                    title:      s.title,
                    content:    s.content,
                    confidence: s.confidence
                )
                modelContext.insert(section)
                section.article = newArticle
                newArticle.sections.append(section)
            }
            try? modelContext.save()
        } catch {
            errorMsg = error.localizedDescription
            showError = true
        }
    }

    private func regenerate() async {
        // Delete existing article
        if let existing = topic.article {
            modelContext.delete(existing)
            topic.article = nil
            try? modelContext.save()
        }
        await generate()
    }
}

// MARK: - Verification Banner

private struct VerificationBanner: View {
    let article: TopicArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(hex: AppColors.warning))
                    .font(.system(size: 13))
                Text("AI-Generated — Unverified")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: AppColors.warning))
                Spacer()
                Text("\(article.verifiedCount)/\(article.totalSections)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.warning))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: AppColors.surfaceTertiary))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: AppColors.warning))
                        .frame(width: geo.size.width * article.verificationProgress, height: 5)
                        .animation(.spring(duration: 0.4), value: article.verificationProgress)
                }
            }
            .frame(height: 5)

            Text("Tap ✓ on each section after cross-checking against a trusted source.")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.warning).opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: AppColors.warning).opacity(0.3), lineWidth: 1))
        )
    }
}

// MARK: - Article Section Card

struct ArticleSectionCard: View {
    @Bindable var section: ArticleSection
    let onVerify:  () -> Void
    let onFlag:    (String) -> Void
    let onUnflag:  () -> Void
    let onEdit:    () -> Void

    @State private var isExpanded     = true
    @State private var showFlagInput  = false
    @State private var flagText       = ""
    @State private var showTeachItBack = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Section header
            Button {
                withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    // Type icon
                    Image(systemName: section.type.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: section.type.accentColor))
                        .frame(width: 22)

                    Text(section.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Confidence dot
                    if section.confidence != .high {
                        Image(systemName: section.confidence.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: section.confidence.colorHex))
                    }

                    // Verified check
                    Button(action: onVerify) {
                        Image(systemName: section.isVerified ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(section.isVerified
                                ? Color(hex: AppColors.success)
                                : Color(hex: AppColors.surfaceTertiary))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Flagged warning
            if section.isFlagged {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.danger))
                    Text(section.flagNote.isEmpty ? "Flagged as incorrect" : section.flagNote)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.danger))
                    Spacer()
                    Button("Unflag", action: onUnflag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: AppColors.danger).opacity(0.08))
            }

            // Content (collapsible)
            if isExpanded {
                Divider()
                    .background(Color(hex: AppColors.surfaceTertiary))
                    .padding(.horizontal, 14)

                if section.type == .code {
                    codeContent
                } else {
                    markdownContent
                }

                // Confidence note for medium/low
                if section.confidence != .high {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text(section.confidence.label)
                            .font(.caption2)
                    }
                    .foregroundStyle(Color(hex: section.confidence.colorHex).opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                }

                // Flag input
                if showFlagInput {
                    flagInputRow
                }

                // Footer actions
                HStack(spacing: 0) {
                    Button {
                        withAnimation { showFlagInput.toggle() }
                    } label: {
                        Label(section.isFlagged ? "Reflag" : "Flag issue", systemImage: "flag")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showTeachItBack = true
                    } label: {
                        Label("Teach It", systemImage: "brain.head.profile")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: AppColors.secondary))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(section.isFlagged
                      ? Color(hex: AppColors.danger).opacity(0.05)
                      : Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(sectionBorderColor, lineWidth: 1)
                )
        )
        .sheet(isPresented: $showTeachItBack) {
            TeachItBackSheet(section: section)
        }
    }

    private var sectionBorderColor: Color {
        if section.isFlagged   { return Color(hex: AppColors.danger).opacity(0.4) }
        if section.isVerified  { return Color(hex: AppColors.success).opacity(0.25) }
        if section.confidence == .low { return Color(hex: AppColors.danger).opacity(0.2) }
        if section.confidence == .medium { return Color(hex: AppColors.warning).opacity(0.2) }
        return Color(hex: AppColors.surfaceTertiary)
    }

    private var markdownContent: some View {
        Text(LocalizedStringKey(section.content))
            .font(.subheadline)
            .foregroundStyle(Color(hex: AppColors.neutral))
            .lineSpacing(5)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var codeContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(stripCodeFences(section.content))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(hex: AppColors.success))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(hex: "0D1117"))
        .cornerRadius(8)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func stripCodeFences(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove ```lang or ``` at start
        if s.hasPrefix("```") {
            let firstNewline = s.firstIndex(of: "\n") ?? s.startIndex
            s = String(s[s.index(after: firstNewline)...])
        }
        if s.hasSuffix("```") {
            s = String(s.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s
    }

    private var flagInputRow: some View {
        HStack(spacing: 8) {
            TextField("What's wrong? (optional)", text: $flagText)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: AppColors.surfaceSecondary)))

            Button("Flag") {
                onFlag(flagText)
                flagText = ""
                showFlagInput = false
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(hex: AppColors.danger))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - Teach It Back Sheet

struct TeachItBackSheet: View {
    let section: ArticleSection
    @Environment(\.dismiss) private var dismiss
    @Environment(GeminiService.self) private var geminiService

    @State private var userText   = ""
    @State private var isGrading  = false
    @State private var score: Int?
    @State private var feedback   = ""
    @State private var missed: [String] = []
    @State private var errorMsg: String?
    @State private var showAPIKeySetup = false

    private var hasResult: Bool { score != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Concept chip
                        HStack(spacing: 6) {
                            Image(systemName: section.type.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: section.type.accentColor))
                            Text(section.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: AppColors.neutral))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: AppColors.surfacePrimary)))

                        if hasResult {
                            resultView
                        } else {
                            inputView
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Teach It Back")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(hasResult ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                if hasResult {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Try Again") {
                            score   = nil
                            userText = ""
                            feedback = ""
                            missed  = []
                        }
                        .foregroundStyle(Color(hex: AppColors.primary))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAPIKeySetup) {
            APIKeySetupView(geminiService: geminiService)
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Explain this in your own words")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text("Don't peek — close the guide and describe what you understood about **\(section.title)**.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $userText)
                .font(.body)
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .background(Color(hex: AppColors.surfacePrimary))
                .cornerRadius(12)
                .frame(minHeight: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: AppColors.surfaceTertiary), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if userText.isEmpty {
                        Text("Type your explanation here…")
                            .font(.body)
                            .foregroundStyle(Color(hex: AppColors.muted))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }

            if let errorMsg {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.danger))
            }

            Button {
                Task { await grade() }
            } label: {
                Group {
                    if isGrading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                                .scaleEffect(0.8)
                            Text("Grading…")
                                .font(.subheadline.weight(.bold))
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                            Text("Submit for AI Grading")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if userText.count < 20 || isGrading {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: AppColors.surfaceSecondary))
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [Color(hex: AppColors.secondary), Color(hex: AppColors.primary)],
                                    startPoint: .leading, endPoint: .trailing))
                        }
                    }
                )
            }
            .buttonStyle(.plain)
            .disabled(userText.count < 20 || isGrading)

            if userText.count < 20 && !userText.isEmpty {
                Text("Write at least a few sentences")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Score card
            VStack(spacing: 12) {
                Text("Your Score")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.muted))

                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= (score ?? 0) ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(i <= (score ?? 0)
                                ? starColor(score ?? 0)
                                : Color(hex: AppColors.surfaceTertiary))
                    }
                }

                Text(scoreLine(score ?? 0))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(starColor(score ?? 0))
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: AppColors.surfacePrimary))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(starColor(score ?? 0).opacity(0.35), lineWidth: 1.5))
            )

            // AI Feedback
            VStack(alignment: .leading, spacing: 8) {
                Label("Feedback", systemImage: "text.bubble")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: AppColors.muted))

                Text(feedback)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: AppColors.surfacePrimary))
            )

            // Missed concepts
            if !missed.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("What you missed", systemImage: "exclamationmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: AppColors.warning))

                    ForEach(missed, id: \.self) { concept in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color(hex: AppColors.warning))
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(concept)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: AppColors.neutral))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: AppColors.warning).opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(hex: AppColors.warning).opacity(0.25), lineWidth: 1))
                )
            }
        }
    }

    // MARK: - Helpers

    private func grade() async {
        guard geminiService.hasAPIKey else { showAPIKeySetup = true; return }
        isGrading = true
        errorMsg  = nil
        defer { isGrading = false }
        do {
            let result = try await geminiService.gradeTeachItBack(
                userExplanation: userText,
                concept:         section.title,
                correctContent:  section.content
            )
            score    = result.score
            feedback = result.feedback
            missed   = result.missed
        } catch {
            errorMsg = error.localizedDescription
        }
    }

    private func starColor(_ s: Int) -> Color {
        switch s {
        case 5:    return Color(hex: AppColors.success)
        case 4:    return Color(hex: AppColors.primary)
        case 3:    return Color(hex: AppColors.warning)
        default:   return Color(hex: AppColors.danger)
        }
    }

    private func scoreLine(_ s: Int) -> String {
        switch s {
        case 5: return "Excellent — you nailed it!"
        case 4: return "Great — almost complete"
        case 3: return "On the right track"
        case 2: return "Partial understanding"
        default: return "Keep reading and try again"
        }
    }
}

// MARK: - Edit Section Sheet

struct EditSectionSheet: View {
    @Bindable var section: ArticleSection
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editedContent: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    TextEditor(text: $editedContent)
                        .font(.system(.body, design: section.type == .code ? .monospaced : .default))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color(hex: AppColors.surfacePrimary))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .frame(maxHeight: .infinity)

                    Text("Supports markdown: **bold**, *italic*, - bullet lists")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Edit Section")
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
                        section.content    = editedContent
                        section.isVerified = true   // user-edited = trusted
                        section.isFlagged  = false
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: AppColors.primary))
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { editedContent = section.content }
    }
}
