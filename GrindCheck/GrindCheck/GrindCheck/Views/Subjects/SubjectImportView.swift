import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Subject Import View
// One-shot import: download JSON template → fill it in → upload → everything created.

struct SubjectImportView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: - State

    @State private var step: ImportStep     = .start
    @State private var templateURL: URL?    = nil
    @State private var showFilePicker       = false
    @State private var parsed: ParsedSubject?
    @State private var parseError: String?
    @State private var isImporting          = false
    @State private var importDone           = false

    enum ImportStep { case start, preview, done }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                switch step {
                case .start:   startView
                case .preview: previewView
                case .done:    doneView
                }
            }
            .navigationTitle("Import Subject")
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
        .onAppear { buildTemplate() }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFilePick(result)
        }
    }

    // MARK: - Step 1: Start

    private var startView: some View {
        ScrollView {
            VStack(spacing: 28) {

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: AppColors.primary).opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: AppColors.primary))
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("Import a Full Subject")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Download the template, paste it into ChatGPT or Claude with a prompt like **\"Fill this for [topic]\"** — then upload the result here.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // What's included card
                VStack(alignment: .leading, spacing: 12) {
                    Text("The template covers")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: AppColors.muted))
                    featureRow(icon: "books.vertical.fill", color: AppColors.primary,
                               text: "Subject — name, icon, color")
                    featureRow(icon: "list.bullet.rectangle", color: AppColors.secondary,
                               text: "Topics — any number of chapters/concepts")
                    featureRow(icon: "questionmark.circle.fill", color: AppColors.warning,
                               text: "Questions — per topic, all 5 types supported")
                    featureRow(icon: "book.pages.fill", color: AppColors.success,
                               text: "Study Guide — sections per topic (optional)")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: AppColors.surfacePrimary)))

                // Download template
                if let url = templateURL {
                    ShareLink(item: url) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download Template")
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
                } else {
                    HStack(spacing: 8) {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
                        Text("Preparing template…")
                    }
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                // Upload filled template
                Button {
                    parseError = nil
                    showFilePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.doc.fill")
                        Text("Upload Filled Template")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.surfacePrimary))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(hex: AppColors.surfaceTertiary), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                if let err = parseError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.danger))
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Step 2: Preview

    private var previewView: some View {
        Group {
            if let p = parsed {
                previewContent(p)
            }
        }
    }

    private func previewContent(_ p: ParsedSubject) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Subject header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: p.subject.colorHex).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: p.subject.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: p.subject.colorHex))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.subject.name)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(p.topics.count) topics · \(p.totalQuestions) questions · \(p.totalGuideSections) guide sections")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: AppColors.surfacePrimary))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(hex: p.subject.colorHex).opacity(0.3), lineWidth: 1))
                )

                // Topics breakdown
                Text("Topics Preview")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: AppColors.muted))

                ForEach(p.topics, id: \.name) { topic in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: p.subject.colorHex).opacity(0.6))
                            .frame(width: 6, height: 6)
                        Text(topic.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(topic.questions.count)q")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: AppColors.warning))
                        if !topic.studyGuide.isEmpty {
                            Text("\(topic.studyGuide.count)§")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: AppColors.success))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: AppColors.surfacePrimary)))
                }

                // Warning if no questions
                if p.totalQuestions == 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: AppColors.warning))
                        Text("No questions found — you can add them later from inside each topic.")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: AppColors.warning).opacity(0.08)))
                }

                // Import button
                Button {
                    Task { await commitImport(p) }
                } label: {
                    Group {
                        if isImporting {
                            HStack(spacing: 8) {
                                ProgressView().progressViewStyle(.circular).tint(.black).scaleEffect(0.8)
                                Text("Importing…").font(.subheadline.weight(.bold))
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Import Subject").font(.subheadline.weight(.bold))
                            }
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(
                                colors: [Color(hex: AppColors.success), Color(hex: AppColors.primary)],
                                startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isImporting)

                Button {
                    step = .start
                    parsed = nil
                } label: {
                    Text("← Pick a different file")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Step 3: Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: AppColors.success).opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: AppColors.success))
            }

            VStack(spacing: 8) {
                Text("Subject Imported!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                if let p = parsed {
                    Text("\(p.subject.name) is ready — \(p.topics.count) topics and \(p.totalQuestions) questions loaded.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Go to Subjects")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: AppColors.primary))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: color))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
        }
    }

    // MARK: - Template Generation

    private func buildTemplate() {
        DispatchQueue.global(qos: .userInitiated).async {
            let template = subjectTemplate()
            guard let data = try? JSONSerialization.data(
                withJSONObject: template,
                options: [.prettyPrinted, .sortedKeys]
            ) else { return }

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("subject_template.json")
            try? data.write(to: url)

            DispatchQueue.main.async {
                self.templateURL = url
            }
        }
    }

    private func handleFilePick(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let e):
            parseError = e.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let data = try Data(contentsOf: url)
                let raw  = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let raw else { throw ImportError.invalidStructure }
                let subject = try ParsedSubject(from: raw)
                parsed    = subject
                parseError = nil
                step       = .preview
            } catch {
                parseError = "Parse error: \(error.localizedDescription)"
            }
        }
    }

    private func commitImport(_ p: ParsedSubject) async {
        isImporting = true
        defer { isImporting = false }

        let subject      = Subject(name: p.subject.name, icon: p.subject.icon, colorHex: p.subject.colorHex)
        subject.sortOrder = 999
        modelContext.insert(subject)

        for (i, topicData) in p.topics.enumerated() {
            let topic = Topic(name: topicData.name, subject: subject)
            modelContext.insert(topic)
            subject.topics.append(topic)

            // Questions
            for qd in topicData.questions {
                let q = Question(
                    topic: topic,
                    questionText: qd.questionText,
                    questionType: QuestionType(rawValue: qd.questionType) ?? .mcq,
                    options: qd.options,
                    correctAnswer: qd.correctAnswer,
                    explanation: qd.explanation,
                    difficulty: max(1, min(5, qd.difficulty)),
                    tags: qd.tags
                )
                modelContext.insert(q)
                topic.questions.append(q)
            }

            // Study guide
            if !topicData.studyGuide.isEmpty {
                let article = TopicArticle()
                article.isAIGenerated = false
                modelContext.insert(article)
                article.topic  = topic
                topic.article  = article

                for (order, sd) in topicData.studyGuide.enumerated() {
                    let section = ArticleSection(
                        order:      order,
                        type:       ArticleSectionType(rawValue: sd.type) ?? .explanation,
                        title:      sd.title,
                        content:    sd.content,
                        confidence: ArticleConfidence(rawValue: sd.confidence) ?? .medium
                    )
                    section.isVerified = true
                    modelContext.insert(section)
                    section.article = article
                    article.sections.append(section)
                }
            }
        }

        try? modelContext.save()
        step = .done
    }

    // MARK: - Template JSON

    private func subjectTemplate() -> [String: Any] {
        [
            // ─────────────────────────────────────────────────────────────────
            // HOW TO USE THIS TEMPLATE (read before giving to an AI)
            // ─────────────────────────────────────────────────────────────────
            // Keys that start with "_" are instructions only — the app ignores them.
            // Only fill in the real keys: subject, topics, questions, studyGuide.
            // After filling, upload this file in GrindCheck → Subjects → + → Import from JSON.
            // ─────────────────────────────────────────────────────────────────
            "_instructions": [
                "purpose": "This file defines one complete subject for the GrindCheck study app. Fill it in (or ask an AI to fill it in) with real content, then import it.",
                "workflow": "1. Copy this file. 2. Replace all placeholder values below. 3. Remove the _instructions block if you want (optional — the app ignores it). 4. Import via GrindCheck → Subjects → + → Import from JSON.",
                "ai_prompt_suggestion": "Paste this entire JSON file into ChatGPT, Claude, or Gemini and say: 'Fill this GrindCheck template for the subject [YOUR SUBJECT]. For each topic, create 5-8 questions (mix of mcq, trueFalse, shortAnswer, explainThis, codeOutput) and a full studyGuide with all 6 section types. Follow the schema exactly. Return only valid JSON.'",
                "rules": [
                    "Do NOT change the key names (questionText, questionType, etc.) — the app parses these exactly.",
                    "questionType must be exactly one of: mcq | trueFalse | shortAnswer | explainThis | codeOutput",
                    "For mcq: options must have exactly 4 items; correctAnswer must exactly match one of the options.",
                    "For trueFalse: options must be [\"True\", \"False\"]; correctAnswer must be \"True\" or \"False\".",
                    "For shortAnswer, explainThis, codeOutput: options must be an empty array [].",
                    "difficulty must be an integer 1 (easiest) to 5 (hardest).",
                    "studyGuide type must be one of: summary | concepts | explanation | code | mistakes | reference",
                    "studyGuide confidence must be one of: high | medium | low",
                    "content in studyGuide supports markdown: **bold**, *italic*, - bullet lists, ``` code blocks ```",
                    "You can have as many topics as you want. Each topic can have 0+ questions and 0-6 guide sections.",
                    "studyGuide is optional per topic — set it to [] if you don't want a study guide for that topic."
                ]
            ],
            // ─────────────────────────────────────────────────────────────────
            // SUBJECT — the top-level subject card shown in the app
            // ─────────────────────────────────────────────────────────────────
            "subject": [
                "_hint_name":     "The subject name shown on the card, e.g. 'Python', 'Machine Learning', 'System Design'",
                "_hint_icon":     "An SF Symbol name. Good options: book.fill, brain.head.profile, cpu, server.rack, chart.bar.xaxis, sum, code.variable, network, function, terminal, gear, graduationcap.fill",
                "_hint_colorHex": "A hex color for the subject card accent. Examples: #3776AB (blue), #FF6B6B (red), #A855F7 (purple), #F7B731 (yellow), #00E5FF (cyan), #68A063 (green), #FF9F43 (orange)",
                "name":     "FILL IN: Subject Name",
                "icon":     "book.fill",
                "colorHex": "#6C63FF"
            ],
            // ─────────────────────────────────────────────────────────────────
            // TOPICS — chapters or concept areas within the subject
            // Add as many topics as needed by duplicating the topic block below.
            // ─────────────────────────────────────────────────────────────────
            "topics": [
                [
                    "_hint_name": "Topic name — be specific, e.g. 'Backpropagation', 'SQL JOINs', 'Big-O Analysis'",
                    "name": "FILL IN: Topic Name",

                    // ── QUESTIONS ──────────────────────────────────────────
                    // Aim for 5-10 questions per topic. Mix question types.
                    // ──────────────────────────────────────────────────────
                    "questions": [

                        // --- MCQ (Multiple Choice) ---
                        // Must have exactly 4 options. correctAnswer must exactly match one option.
                        [
                            "_hint": "MCQ — 4 options, correctAnswer matches one option exactly",
                            "questionText":  "FILL IN: Which of the following best describes X?",
                            "questionType":  "mcq",
                            "options":       [
                                "FILL IN: Correct answer here",
                                "FILL IN: Plausible wrong answer",
                                "FILL IN: Plausible wrong answer",
                                "FILL IN: Plausible wrong answer"
                            ],
                            "correctAnswer": "FILL IN: Correct answer here",
                            "explanation":   "FILL IN: Why this is correct and why the others are wrong.",
                            "difficulty":    2,
                            "tags":          ["FILL IN: keyword1", "keyword2"]
                        ],

                        // --- True / False ---
                        // options must be exactly ["True", "False"]. correctAnswer is "True" or "False".
                        [
                            "_hint": "trueFalse — options must be [\"True\", \"False\"], correctAnswer is \"True\" or \"False\"",
                            "questionText":  "FILL IN: True or False: [Make a statement that is definitively true or false].",
                            "questionType":  "trueFalse",
                            "options":       ["True", "False"],
                            "correctAnswer": "True",
                            "explanation":   "FILL IN: Explanation of why this is true/false, with the nuance a student needs.",
                            "difficulty":    1,
                            "tags":          ["FILL IN: keyword"]
                        ],

                        // --- Short Answer ---
                        // No options. correctAnswer is the model answer. Student self-grades.
                        [
                            "_hint": "shortAnswer — options is [], correctAnswer is the ideal response",
                            "questionText":  "FILL IN: What is the difference between X and Y?",
                            "questionType":  "shortAnswer",
                            "options":       [] as [String],
                            "correctAnswer": "FILL IN: The concise model answer a student should match.",
                            "explanation":   "FILL IN: Deeper context and why this distinction matters.",
                            "difficulty":    3,
                            "tags":          ["FILL IN: keyword"]
                        ],

                        // --- Explain This ---
                        // Open-ended. Student writes a full explanation. Good for deep concepts.
                        [
                            "_hint": "explainThis — options is [], correctAnswer is a reference explanation",
                            "questionText":  "FILL IN: Explain [concept] in your own words. What problem does it solve?",
                            "questionType":  "explainThis",
                            "options":       [] as [String],
                            "correctAnswer": "FILL IN: Full reference explanation covering the key points.",
                            "explanation":   "FILL IN: What a complete answer must include — used to grade Teach It Back.",
                            "difficulty":    3,
                            "tags":          ["FILL IN: keyword", "conceptual"]
                        ],

                        // --- Code Output ---
                        // Paste a code snippet. Student predicts the output.
                        [
                            "_hint": "codeOutput — paste code in questionText, correctAnswer is the exact printed output",
                            "questionText":  "FILL IN: What is the output of this code?\n\n# Paste your code snippet here\nprint('example')",
                            "questionType":  "codeOutput",
                            "options":       [] as [String],
                            "correctAnswer": "FILL IN: exact output, e.g. 'example'",
                            "explanation":   "FILL IN: Step-by-step why the code produces this output. Mention the tricky part.",
                            "difficulty":    3,
                            "tags":          ["FILL IN: keyword", "code"]
                        ]
                    ],

                    // ── STUDY GUIDE ────────────────────────────────────────
                    // 6 section types, used in this order: summary → concepts →
                    // explanation → code → mistakes → reference
                    // Each section rendered as a card in the Study Guide tab.
                    // Use [] to skip the study guide for this topic entirely.
                    // ──────────────────────────────────────────────────────
                    "studyGuide": [

                        // TYPE: summary — 2-3 sentence TL;DR. First thing student sees.
                        [
                            "_hint": "summary — 2-3 sentence TL;DR. What is this topic and why does it matter?",
                            "type":       "summary",
                            "title":      "FILL IN: What is [Topic Name]?",
                            "content":    "FILL IN: 2-3 sentences. What is it, what problem it solves, when you use it.",
                            "confidence": "high"
                        ],

                        // TYPE: concepts — bullet list of must-know terms/ideas
                        [
                            "_hint": "concepts — bullet list, **bold** the term, then one-line explanation",
                            "type":       "concepts",
                            "title":      "Key Concepts",
                            "content":    "- **Concept 1**: One-line explanation of what it is\n- **Concept 2**: One-line explanation\n- **Concept 3**: One-line explanation\n- **Concept 4**: One-line explanation\n- **Concept 5**: One-line explanation",
                            "confidence": "high"
                        ],

                        // TYPE: explanation — the full deep-dive, 3-5 paragraphs
                        [
                            "_hint": "explanation — detailed prose, 3-5 paragraphs, use **bold** for key terms",
                            "type":       "explanation",
                            "title":      "FILL IN: How It Works",
                            "content":    "FILL IN: Paragraph 1 — introduce the core mechanism.\n\nFILL IN: Paragraph 2 — explain the details and how parts connect.\n\nFILL IN: Paragraph 3 — real-world analogy or concrete example.\n\nFILL IN: Paragraph 4 (optional) — edge cases or advanced notes.",
                            "confidence": "high"
                        ],

                        // TYPE: code — a working code example. Use ``` fences.
                        // Set confidence to "medium" or "low" if you're not 100% sure it runs.
                        // Skip this section (remove it) if not a coding topic.
                        [
                            "_hint": "code — wrap in ```language fences, must be runnable. Set confidence to medium/low if uncertain.",
                            "type":       "code",
                            "title":      "FILL IN: Code Example",
                            "content":    "```python\n# FILL IN: Replace with a real, working code example\n# that demonstrates the core concept of this topic.\n\ndef example():\n    pass\n\nresult = example()\nprint(result)  # FILL IN: expected output\n```",
                            "confidence": "high"
                        ],

                        // TYPE: mistakes — common errors, misconceptions, gotchas
                        [
                            "_hint": "mistakes — bullet list of pitfalls. Be specific about what students get wrong and why.",
                            "type":       "mistakes",
                            "title":      "Common Mistakes",
                            "content":    "- **Mistake 1**: What it is and why it's wrong\n- **Mistake 2**: What it is and why it's wrong\n- **Mistake 3**: The subtle gotcha beginners miss\n- **Mistake 4**: The interview trap question variant",
                            "confidence": "high"
                        ],

                        // TYPE: reference — cheat sheet for quick review
                        [
                            "_hint": "reference — cheat sheet format: table, short bullets, or formula list. Dense and scannable.",
                            "type":       "reference",
                            "title":      "Quick Reference",
                            "content":    "FILL IN: Use a table, formula list, or dense bullets.\nExample:\n\n| Term | Meaning |\n|------|--|\n| Term1 | Short definition |\n| Term2 | Short definition |\n\n**Key formula**: FILL IN\n**Time complexity**: FILL IN\n**When to use**: FILL IN",
                            "confidence": "high"
                        ]
                    ]
                ],

                // ── TOPIC 2 (duplicate this block for more topics) ──────────
                [
                    "_hint_name": "Add more topics by duplicating this block",
                    "name": "FILL IN: Second Topic Name",
                    "questions": [
                        [
                            "questionText":  "FILL IN: Question for topic 2?",
                            "questionType":  "mcq",
                            "options":       ["FILL IN: Correct", "FILL IN: Wrong 1", "FILL IN: Wrong 2", "FILL IN: Wrong 3"],
                            "correctAnswer": "FILL IN: Correct",
                            "explanation":   "FILL IN: Why.",
                            "difficulty":    2,
                            "tags":          ["FILL IN: tag"]
                        ]
                    ],
                    "studyGuide": [] as [[String: Any]]
                ]
            ]
        ]
    }
}

// MARK: - Parsed Types (transient)

private struct ParsedSubject {
    struct SubjectMeta {
        let name: String
        let icon: String
        let colorHex: String
    }

    struct TopicData {
        let name: String
        let questions: [QuestionData]
        let studyGuide: [GuideSection]
    }

    struct QuestionData {
        let questionText: String
        let questionType: String
        let options: [String]
        let correctAnswer: String
        let explanation: String
        let difficulty: Int
        let tags: [String]
    }

    struct GuideSection {
        let type: String
        let title: String
        let content: String
        let confidence: String
    }

    let subject: SubjectMeta
    let topics: [TopicData]

    var totalQuestions: Int    { topics.reduce(0) { $0 + $1.questions.count } }
    var totalGuideSections: Int { topics.reduce(0) { $0 + $1.studyGuide.count } }

    init(from dict: [String: Any]) throws {
        guard
            let subjectDict = dict["subject"] as? [String: Any],
            let name = subjectDict["name"] as? String,
            !name.isEmpty
        else { throw ImportError.missingSubject }

        subject = SubjectMeta(
            name:     name,
            icon:     subjectDict["icon"]     as? String ?? "book.fill",
            colorHex: subjectDict["colorHex"] as? String ?? "#6C63FF"
        )

        let topicsRaw = dict["topics"] as? [[String: Any]] ?? []
        topics = topicsRaw.compactMap { td -> TopicData? in
            guard let topicName = td["name"] as? String, !topicName.isEmpty else { return nil }

            let questionsRaw = td["questions"] as? [[String: Any]] ?? []
            let questions = questionsRaw.compactMap { qd -> QuestionData? in
                guard
                    let text   = qd["questionText"]  as? String,
                    let type   = qd["questionType"]   as? String,
                    let answer = qd["correctAnswer"]  as? String
                else { return nil }
                return QuestionData(
                    questionText:  text,
                    questionType:  type,
                    options:       qd["options"]     as? [String] ?? [],
                    correctAnswer: answer,
                    explanation:   qd["explanation"] as? String  ?? "",
                    difficulty:    qd["difficulty"]  as? Int     ?? 2,
                    tags:          qd["tags"]        as? [String] ?? []
                )
            }

            let guideRaw = td["studyGuide"] as? [[String: Any]] ?? []
            let guide = guideRaw.compactMap { sd -> GuideSection? in
                guard
                    let type    = sd["type"]    as? String,
                    let title   = sd["title"]   as? String,
                    let content = sd["content"] as? String
                else { return nil }
                return GuideSection(
                    type:       type,
                    title:      title,
                    content:    content,
                    confidence: sd["confidence"] as? String ?? "medium"
                )
            }

            return TopicData(name: topicName, questions: questions, studyGuide: guide)
        }
    }
}

private enum ImportError: LocalizedError {
    case invalidStructure
    case missingSubject

    var errorDescription: String? {
        switch self {
        case .invalidStructure: return "The file is not valid JSON or doesn't match the template structure."
        case .missingSubject:   return "Missing required 'subject.name' field."
        }
    }
}
