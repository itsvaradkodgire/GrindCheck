import SwiftUI
import SwiftData

struct SubjectsGridView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    @State private var showingAddSubject    = false
    @State private var showingImportSubject = false
    @State private var subjectToDelete: Subject?
    @State private var showDeleteConfirm    = false
    @State private var exportURL: URL?      = nil

    // 2-column grid on iPhone, 3-column on iPad/Mac
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if subjects.isEmpty {
                    VStack(spacing: 16) {
                        EmptyStateView(
                            icon: "books.vertical.fill",
                            title: "No subjects yet",
                            message: "Add the subjects you're studying. Be honest about how many you're actually keeping up with.",
                            actionLabel: "Add Subject",
                            action: { showingAddSubject = true }
                        )
                        Button {
                            showingImportSubject = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Import from JSON template")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(Color(hex: AppColors.primary))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: AppColors.background))
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(subjects) { subject in
                                NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                    SubjectCard(subject: subject)
                                }
                                .contextMenu {
                                    Button {
                                        exportURL = buildExportURL(for: subject)
                                    } label: {
                                        Label("Export as JSON", systemImage: "arrow.up.doc.fill")
                                    }
                                    Button(role: .destructive) {
                                        subjectToDelete = subject
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete Subject", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(hex: AppColors.background))
                }
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddSubject = true
                        } label: {
                            Label("Create Subject", systemImage: "plus")
                        }
                        Button {
                            showingImportSubject = true
                        } label: {
                            Label("Import from JSON", systemImage: "arrow.down.doc.fill")
                        }
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Color(hex: AppColors.primary))
                            .font(.system(size: 22))
                    }
                    .menuStyle(.automatic)
                    .menuIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingAddSubject) {
                AddSubjectView()
            }
            .sheet(isPresented: $showingImportSubject) {
                SubjectImportView()
            }
            .confirmationDialog(
                "Delete \"\(subjectToDelete?.name ?? "")\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Subject & All Topics", role: .destructive) {
                    if let subject = subjectToDelete {
                        modelContext.delete(subject)
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes all topics and questions in this subject. This cannot be undone.")
            }
            .sheet(isPresented: Binding(
                get: { exportURL != nil },
                set: { if !$0 { exportURL = nil } }
            )) {
                if let url = exportURL {
                    ShareLink(item: url, subject: Text("GrindCheck Subject Export")) {
                        Label("Share JSON", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(Color(hex: AppColors.primary))
                            .padding(24)
                    }
                    .presentationDetents([.height(140)])
                    .preferredColorScheme(.dark)
                }
            }
        }
    }

    private func buildExportURL(for subject: Subject) -> URL? {
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

// MARK: - Subject Card

struct SubjectCard: View {
    let subject: Subject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon + color
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: subject.colorHex).opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: subject.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: subject.colorHex))
                }
                Spacer()

                // Decay warning
                if !subject.decayingTopics.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.warning))
                }
            }

            // Subject name
            Text(subject.name)
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            // Topics
            Text("\(subject.totalTopics) topics")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))

            // Proficiency bar
            TopicProficiencyBar(score: Int(subject.avgProficiency), showLabel: false, height: 5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(hex: subject.colorHex).opacity(0.2), lineWidth: 1)
                )
        )
    }
}
