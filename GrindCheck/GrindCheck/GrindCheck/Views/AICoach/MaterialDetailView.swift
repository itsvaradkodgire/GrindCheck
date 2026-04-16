import SwiftUI
import SwiftData

struct MaterialDetailView: View {

    let material: StudyMaterial
    @Bindable var viewModel: AICoachViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingReview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Metadata card
                metadataCard

                // Generate button
                generateSection

                // Full text preview
                textPreview
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(Color(hex: AppColors.background))
        .navigationTitle(material.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showingReview) {
            if let topic = material.topic {
                GeneratedQuestionsReviewSheet(
                    viewModel: viewModel,
                    topic: topic
                )
            }
        }
        .onChange(of: viewModel.showQuestionReview) { _, newValue in
            if newValue { showingReview = true }
        }
        .onChange(of: showingReview) { _, newValue in
            if !newValue { viewModel.showQuestionReview = false }
        }
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: material.isPDF ? "doc.fill" : "doc.text.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: AppColors.primary))

                VStack(alignment: .leading, spacing: 4) {
                    Text(material.isPDF ? "PDF Import" : "Pasted Text")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: AppColors.muted))
                    if !material.sourceFileName.isEmpty {
                        Text(material.sourceFileName)
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }

            Divider().background(Color(hex: AppColors.surfaceTertiary))

            HStack(spacing: 0) {
                metaStat(value: "\(material.wordCount)", label: "Words")
                Divider()
                    .frame(height: 28)
                    .background(Color(hex: AppColors.surfaceTertiary))
                    .padding(.horizontal, 12)
                metaStat(
                    value: material.topic?.name ?? material.subject?.name ?? "Unlinked",
                    label: material.topic != nil ? "Topic" : (material.subject != nil ? "Subject" : "Link")
                )
                Divider()
                    .frame(height: 28)
                    .background(Color(hex: AppColors.surfaceTertiary))
                    .padding(.horizontal, 12)
                metaStat(
                    value: material.createdAt.formatted(.dateTime.month(.abbreviated).day()),
                    label: "Added"
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    private func metaStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.footnote, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Generate Section

    private var generateSection: some View {
        VStack(spacing: 10) {
            if material.topic == nil {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color(hex: AppColors.warning))
                    Text("Link this material to a Topic to generate questions.")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: AppColors.warning).opacity(0.1))
                )
            }

            Button {
                Task {
                    await viewModel.generateQuestions(
                        from: material,
                        topic: material.topic,
                        modelContext: modelContext
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isGeneratingQuestions {
                        ProgressView().tint(Color(hex: AppColors.background))
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isGeneratingQuestions
                         ? "Generating Questions…"
                         : "Generate Questions with AI")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canGenerate
                              ? Color(hex: AppColors.primary)
                              : Color(hex: AppColors.muted))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canGenerate || viewModel.isGeneratingQuestions)

            if let err = viewModel.generationError {
                ErrorBannerView(message: err)
            }
        }
    }

    private var canGenerate: Bool { material.topic != nil }

    // MARK: - Text Preview

    private var textPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Content Preview", systemImage: "doc.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: AppColors.muted))

            Text(material.rawText)
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: AppColors.surfacePrimary))
                )
        }
    }
}

// MARK: - Generated Questions Review Sheet

struct GeneratedQuestionsReviewSheet: View {

    @Bindable var viewModel: AICoachViewModel
    let topic: Topic
    var onDismiss: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndices: Set<Int>

    init(viewModel: AICoachViewModel, topic: Topic, onDismiss: (() -> Void)? = nil) {
        self.viewModel  = viewModel
        self.topic      = topic
        self.onDismiss  = onDismiss
        _selectedIndices = State(initialValue: Set(viewModel.pendingQuestions.indices))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                if viewModel.pendingQuestions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: AppColors.muted))
                        Text("No questions generated.")
                            .foregroundStyle(Color(hex: AppColors.neutral))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.pendingQuestions.indices, id: \.self) { i in
                                ReviewQuestionCard(
                                    question: viewModel.pendingQuestions[i],
                                    isSelected: selectedIndices.contains(i)
                                ) {
                                    if selectedIndices.contains(i) {
                                        selectedIndices.remove(i)
                                    } else {
                                        selectedIndices.insert(i)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Review Questions")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard All") {
                        viewModel.pendingQuestions   = []
                        viewModel.showQuestionReview = false
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: AppColors.danger))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Accept (\(selectedIndices.count))") {
                        acceptSelected()
                    }
                    .foregroundStyle(Color(hex: AppColors.primary))
                    .disabled(selectedIndices.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func acceptSelected() {
        let chosen = selectedIndices.sorted().map { viewModel.pendingQuestions[$0] }
        viewModel.acceptQuestions(chosen, topic: topic, modelContext: modelContext)
        onDismiss?()
        dismiss()
    }
}

// MARK: - Review Question Card

private struct ReviewQuestionCard: View {
    let question: GeneratedQuestion
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected
                              ? Color(hex: AppColors.primary)
                              : Color(hex: AppColors.surfaceSecondary))
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                // Type + difficulty
                HStack(spacing: 6) {
                    Text(question.questionType.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: AppColors.surfaceTertiary))
                        .cornerRadius(4)

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Circle()
                                .fill(i <= question.difficulty
                                      ? Color(hex: AppColors.warning)
                                      : Color(hex: AppColors.muted))
                                .frame(width: 5, height: 5)
                        }
                    }
                    Spacer()
                }

                Text(question.questionText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Answer: \(question.correctAnswer)")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.success))
                    .lineLimit(2)

                if !question.explanation.isEmpty {
                    Text(question.explanation)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0.8)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected
                            ? Color(hex: AppColors.primary).opacity(0.4)
                            : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
