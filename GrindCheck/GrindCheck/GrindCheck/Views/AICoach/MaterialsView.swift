import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(PDFKit)
import PDFKit
#endif

struct MaterialsView: View {

    @Bindable var viewModel: AICoachViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StudyMaterial.createdAt, order: .reverse)
    private var materials: [StudyMaterial]

    @State private var showingUpload = false

    var body: some View {
        Group {
            if materials.isEmpty {
                emptyState
            } else {
                materialList
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingUpload = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: AppColors.primary))
                }
            }
        }
        .sheet(isPresented: $showingUpload) {
            MaterialUploadSheet(viewModel: viewModel)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: AppColors.muted))
            Text("No Materials Yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Upload notes or paste text and let AI\ngenerate study questions from them.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .multilineTextAlignment(.center)

            Button {
                showingUpload = true
            } label: {
                Label("Add Material", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: AppColors.primary))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - List

    private var materialList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(materials) { material in
                    NavigationLink {
                        MaterialDetailView(material: material, viewModel: viewModel)
                    } label: {
                        MaterialRowView(material: material)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Material Row

private struct MaterialRowView: View {
    let material: StudyMaterial

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: material.isPDF ? "doc.fill" : "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: AppColors.primary))

                Text(material.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Text("\(material.wordCount)w")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: AppColors.surfaceSecondary)))
            }

            if let topic = material.topic {
                Label(topic.name, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.secondary))
            } else if let subject = material.subject {
                Label(subject.name, systemImage: "books.vertical.fill")
                    .font(.caption)
                    .foregroundStyle(Color(hex: subject.colorHex))
            }

            Text(material.preview)
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .lineLimit(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }
}

// MARK: - Upload Sheet

struct MaterialUploadSheet: View {

    @Bindable var viewModel: AICoachViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var subjects: [Subject]

    @State private var mode: UploadMode = .paste
    @State private var titleText   = ""
    @State private var pastedText  = ""
    @State private var selectedTopic: Topic?
    @State private var selectedSubject: Subject?
    @State private var showingFilePicker = false
    @State private var importedFileName  = ""
    @State private var importedText      = ""
    @State private var errorMessage: String?

    enum UploadMode: String, CaseIterable {
        case paste = "Paste Text"
        case pdf   = "Import PDF"
    }

    private var availableTopics: [Topic] {
        selectedSubject?.topics.sorted { $0.name < $1.name } ?? []
    }

    private var canSave: Bool {
        !titleText.trimmingCharacters(in: .whitespaces).isEmpty &&
        currentText.count > 20
    }

    private var currentText: String {
        mode == .paste ? pastedText : importedText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Mode picker
                        Picker("Mode", selection: $mode) {
                            ForEach(UploadMode.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: AppColors.muted))
                            TextField("e.g. Chapter 3 — Big O Notation", text: $titleText)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: AppColors.surfaceSecondary))
                                )
                        }

                        // Content
                        if mode == .paste {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Content")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                                TextEditor(text: $pastedText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 160)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: AppColors.surfaceSecondary))
                                    )
                            }
                        } else {
                            pdfImportSection
                        }

                        // Subject picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Subject (optional)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: AppColors.muted))
                            Picker("Subject", selection: $selectedSubject) {
                                Text("None").tag(Optional<Subject>.none)
                                ForEach(subjects) { s in
                                    Text(s.name).tag(Optional(s))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: AppColors.primary))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: AppColors.surfaceSecondary))
                            )
                            .onChange(of: selectedSubject) { _, _ in selectedTopic = nil }
                        }

                        // Topic picker
                        if !availableTopics.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Topic (links AI questions to this topic)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                                Picker("Topic", selection: $selectedTopic) {
                                    Text("None").tag(Optional<Topic>.none)
                                    ForEach(availableTopics) { t in
                                        Text(t.name).tag(Optional(t))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color(hex: AppColors.secondary))
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: AppColors.surfaceSecondary))
                                )
                            }
                        }

                        // Error
                        if let err = errorMessage {
                            ErrorBannerView(message: err)
                        }

                        // Save
                        Button {
                            saveMaterial()
                        } label: {
                            Text("Save Material")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(canSave
                                              ? Color(hex: AppColors.primary)
                                              : Color(hex: AppColors.muted))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Add Material")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.neutral))
                }
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    // MARK: - PDF Section

    private var pdfImportSection: some View {
        VStack(spacing: 10) {
            if importedText.isEmpty {
                Button {
                    showingFilePicker = true
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(hex: AppColors.primary))
                        Text("Tap to import PDF")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: AppColors.surfaceSecondary))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        Color(hex: AppColors.primary).opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(Color(hex: AppColors.primary))
                        Text(importedFileName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            importedText = ""
                            importedFileName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(hex: AppColors.muted))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("\(importedText.split(separator: " ").count) words extracted")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.success))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: AppColors.surfaceSecondary))
                )
            }
        }
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            importedFileName = url.lastPathComponent
            if titleText.isEmpty {
                titleText = url.deletingPathExtension().lastPathComponent
            }
            importedText = extractTextFromPDF(url: url)
            if importedText.isEmpty {
                errorMessage = "Could not extract text from this PDF. Try pasting text instead."
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func extractTextFromPDF(url: URL) -> String {
        #if canImport(PDFKit)
        guard let doc = PDFDocument(url: url) else { return "" }
        var pages: [String] = []
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let text = page.string {
                pages.append(text)
            }
        }
        return pages.joined(separator: "\n\n")
        #else
        return ""
        #endif
    }

    private func saveMaterial() {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = titleText.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, text.count > 20 else { return }

        let fileName = mode == .pdf ? importedFileName : ""
        let mat = StudyMaterial(
            title: title,
            rawText: text,
            sourceFileName: fileName,
            topic: selectedTopic,
            subject: selectedSubject
        )
        modelContext.insert(mat)
        try? modelContext.save()
        dismiss()
    }
}
