import SwiftUI
import SwiftData

struct RoadmapView: View {

    @Bindable var viewModel: AICoachViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    @State private var importedAll   = false
    @State private var showImportDone = false

    var body: some View {
        Group {
            if viewModel.isGeneratingRoadmap {
                generatingState
            } else if let roadmap = viewModel.currentRoadmap {
                roadmapContent(roadmap)
            } else {
                emptyState
            }
        }

        if let err = viewModel.roadmapError {
            ErrorBannerView(message: err)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }

    // MARK: - States

    private var generatingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(Color(hex: AppColors.primary))
            Text("Building your roadmap…")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: AppColors.muted))
            Text("No Roadmap Yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Chat with your AI Coach and tap\n\"Build My Roadmap\" to get started.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Roadmap Content

    private func roadmapContent(_ roadmap: AIRoadmap) -> some View {
        ScrollView {
            VStack(spacing: 16) {

                // Subject + Goal card
                subjectGoalCard(roadmap)

                // Import All button (if not already imported)
                if !isFullyImported(roadmap) {
                    importAllButton(roadmap)
                } else {
                    importedBanner(roadmap)
                }

                // Progress
                progressBar(roadmap)

                // Phases
                ForEach(roadmap.sortedPhases, id: \.id) { phase in
                    RoadmapPhaseCard(
                        phase: phase,
                        existingTopicProficiencies: topicProficiencies(for: phase),
                        onToggle: {
                            viewModel.togglePhaseComplete(phase, modelContext: modelContext)
                        }
                    )
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: - Import All

    private func isFullyImported(_ roadmap: AIRoadmap) -> Bool {
        guard !roadmap.subjectName.isEmpty else { return false }
        return subjects.contains { $0.name.lowercased() == roadmap.subjectName.lowercased() }
    }

    /// Returns [topicName: proficiency] for topics that already exist in subjects
    private func topicProficiencies(for phase: RoadmapPhase) -> [String: Int] {
        let allTopics = subjects.flatMap(\.topics)
        var result: [String: Int] = [:]
        for name in phase.topicNames {
            if let match = allTopics.first(where: { $0.name.lowercased() == name.lowercased() }) {
                result[name] = match.proficiencyScore
            }
        }
        return result
    }

    private func importAll(_ roadmap: AIRoadmap) {
        let name     = roadmap.subjectName.isEmpty ? roadmap.goal : roadmap.subjectName
        let palette  = [AppColors.primary, AppColors.secondary, AppColors.warning, AppColors.success, "#A855F7"]
        let color    = palette[subjects.count % palette.count]

        // Find or create the subject
        let subject: Subject
        if let existing = subjects.first(where: { $0.name.lowercased() == name.lowercased() }) {
            subject = existing
        } else {
            subject = Subject(name: name, colorHex: color)
            subject.sortOrder = subjects.count
            modelContext.insert(subject)
        }

        // Add all unique topics from all phases
        let existingTopicNames = Set(subject.topics.map { $0.name.lowercased() })
        for phase in roadmap.sortedPhases {
            for topicName in phase.topicNames {
                guard !existingTopicNames.contains(topicName.lowercased()) else { continue }
                let topic = Topic(name: topicName, subject: subject)
                modelContext.insert(topic)
                subject.topics.append(topic)
            }
        }

        try? modelContext.save()
        withAnimation { importedAll = true }
        HapticManager.shared.correctAnswer()
    }

    // MARK: - Subviews

    private func subjectGoalCard(_ roadmap: AIRoadmap) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Subject name badge
            if !roadmap.subjectName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(roadmap.subjectName)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color(hex: AppColors.secondary))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: AppColors.secondary).opacity(0.12)))
            }

            Text(roadmap.goal)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Total topics count
            let totalTopics = roadmap.phases.flatMap(\.topicNames).count
            Text("\(roadmap.totalPhaseCount) phases · \(totalTopics) topics · \(roadmap.phases.reduce(0) { $0 + $1.estimatedWeeks })w estimated")
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(hex: AppColors.primary).opacity(0.25), lineWidth: 1))
        )
    }

    private func importAllButton(_ roadmap: AIRoadmap) -> some View {
        Button { importAll(roadmap) } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 15))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add to Subjects")
                        .font(.subheadline.weight(.bold))
                    Text("Creates \"\(roadmap.subjectName.isEmpty ? roadmap.goal : roadmap.subjectName)\" with all \(roadmap.phases.flatMap(\.topicNames).count) topics")
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(
                        colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                        startPoint: .leading, endPoint: .trailing))
            )
        }
        .buttonStyle(.plain)
    }

    private func importedBanner(_ roadmap: AIRoadmap) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: AppColors.success))
            Text("\"\(roadmap.subjectName)\" is in your Subjects")
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

    private func progressBar(_ roadmap: AIRoadmap) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(roadmap.completedPhaseCount) of \(roadmap.totalPhaseCount) phases complete")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                Spacer()
                Text("\(Int(roadmap.progressFraction * 100))%")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: AppColors.success))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: AppColors.surfaceSecondary))
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: AppColors.success))
                        .frame(width: geo.size.width * roadmap.progressFraction)
                        .animation(.spring(duration: 0.5), value: roadmap.progressFraction)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Phase Card

struct RoadmapPhaseCard: View {
    let phase: RoadmapPhase
    let existingTopicProficiencies: [String: Int]   // topicName → proficiency if already in subjects
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline column
            VStack(spacing: 0) {
                phaseCircle
                Rectangle()
                    .fill(Color(hex: AppColors.surfaceTertiary))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 28)

            // Content
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(phase.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(phase.isCompleted ? Color(hex: AppColors.muted) : .white)
                        .strikethrough(phase.isCompleted)

                    Spacer()

                    Text("\(phase.estimatedWeeks)w")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: AppColors.muted))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: AppColors.surfaceSecondary)))
                }

                Text(phase.phaseDescription)
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(phase.isCompleted ? 0.5 : 1)

                // Topic chips with proficiency
                if !phase.topicNames.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(phase.topicNames, id: \.self) { topicName in
                            topicChip(topicName)
                        }
                    }
                }

                // Phase completion hint
                if !phase.isCompleted && !existingTopicProficiencies.isEmpty {
                    let covered = existingTopicProficiencies.values.filter { $0 >= 60 }.count
                    let total   = phase.topicNames.count
                    if covered > 0 {
                        Text("\(covered)/\(total) topics at 60%+ proficiency")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: AppColors.success).opacity(0.8))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: AppColors.surfacePrimary))
                    .opacity(phase.isCompleted ? 0.6 : 1)
            )
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func topicChip(_ name: String) -> some View {
        if let prof = existingTopicProficiencies[name] {
            // Already in subjects — show proficiency
            HStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                Text("\(prof)%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(profColor(prof))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(profColor(prof).opacity(0.15))
                    .overlay(Capsule().strokeBorder(profColor(prof).opacity(0.4), lineWidth: 1))
            )
        } else {
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(phase.isCompleted ? Color(hex: AppColors.muted) : Color(hex: AppColors.primary))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(hex: AppColors.primary).opacity(phase.isCompleted ? 0.05 : 0.12))
                )
        }
    }

    private func profColor(_ p: Int) -> Color {
        p >= 70 ? Color(hex: AppColors.success) : p >= 40 ? Color(hex: AppColors.warning) : Color(hex: AppColors.danger)
    }

    private var phaseCircle: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(phase.isCompleted
                          ? Color(hex: AppColors.success)
                          : Color(hex: AppColors.surfaceSecondary))
                    .frame(width: 28, height: 28)
                if phase.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                } else {
                    Text("\(phase.order + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: AppColors.neutral))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: phase.isCompleted)
    }
}

// MARK: - Flow Layout (for topic chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +)
            + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            rowWidth += size.width + spacing
        }
        return rows
    }
}
