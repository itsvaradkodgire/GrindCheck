import SwiftUI

// MARK: - Weak Spot Heatmap (Feature 7)
// Grid: rows = topics, columns = question types, cells = accuracy

struct WeakSpotHeatmapView: View {

    let subject: Subject

    private let questionTypes: [QuestionType] = [.mcq, .trueFalse, .shortAnswer, .explainThis, .codeOutput]

    private var displayedTopics: [Topic] {
        subject.topics
            .filter { $0.totalQuestions > 0 }
            .sorted { $0.proficiencyScore < $1.proficiencyScore }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                icon: "map.fill",
                iconColor: AppColors.secondary,
                title: "Weak Spot Map",
                subtitle: "accuracy by topic × question type"
            )

            if displayedTopics.isEmpty {
                Text("Answer some questions to build your weak spot map.")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: AppColors.surfacePrimary)))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    // Column headers
                    HStack(spacing: 0) {
                        // Topic name column spacer
                        Color.clear.frame(width: topicColumnWidth, height: 28)

                        ForEach(questionTypes, id: \.rawValue) { type in
                            Text(typeShortLabel(type))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color(hex: AppColors.muted))
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Divider().background(Color(hex: AppColors.surfaceTertiary))

                    // Rows
                    ForEach(displayedTopics) { topic in
                        HStack(spacing: 0) {
                            // Topic name
                            Text(topic.name)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color(hex: AppColors.neutral))
                                .lineLimit(2)
                                .frame(width: topicColumnWidth, alignment: .leading)
                                .padding(.vertical, 6)

                            // Cells
                            ForEach(questionTypes, id: \.rawValue) { type in
                                let acc = accuracy(topic: topic, type: type)
                                heatCell(accuracy: acc)
                            }
                        }

                        Divider()
                            .background(Color(hex: AppColors.surfaceTertiary).opacity(0.5))
                    }
                }
                .background(Color(hex: AppColors.surfacePrimary))
                .cornerRadius(12)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: AppColors.success, label: "80%+  Strong")
                    legendItem(color: AppColors.warning, label: "40–79%  Shaky")
                    legendItem(color: AppColors.danger,  label: "<40%  Weak")
                    legendItem(color: AppColors.surfaceSecondary, label: "No data")
                }
                .padding(.top, 4)
            }
        }
    }

    private var topicColumnWidth: CGFloat { 88 }

    private func accuracy(topic: Topic, type: QuestionType) -> Double? {
        let qs = topic.questions.filter { $0.questionType == type && $0.timesAsked > 0 }
        guard !qs.isEmpty else { return nil }
        let correct = qs.map(\.timesCorrect).reduce(0, +)
        let asked   = qs.map(\.timesAsked).reduce(0, +)
        return Double(correct) / Double(asked)
    }

    private func heatCell(accuracy: Double?) -> some View {
        let color: Color = {
            guard let acc = accuracy else { return Color(hex: AppColors.surfaceSecondary) }
            if acc >= 0.8 { return Color(hex: AppColors.success).opacity(0.75) }
            if acc >= 0.4 { return Color(hex: AppColors.warning).opacity(0.75) }
            return Color(hex: AppColors.danger).opacity(0.75)
        }()

        let label: String = {
            guard let acc = accuracy else { return "–" }
            return "\(Int(acc * 100))%"
        }()

        return Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(accuracy == nil ? Color(hex: AppColors.muted) : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(color)
    }

    private func typeShortLabel(_ type: QuestionType) -> String {
        switch type {
        case .mcq:         return "MCQ"
        case .trueFalse:   return "T/F"
        case .shortAnswer: return "Short"
        case .explainThis: return "Expl."
        case .codeOutput:  return "Code"
        }
    }

    private func legendItem(color: String, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: color).opacity(0.75))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: AppColors.muted))
        }
    }
}
