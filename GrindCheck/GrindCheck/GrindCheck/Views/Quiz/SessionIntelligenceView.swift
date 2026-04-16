import SwiftUI
import SwiftData

// MARK: - Session Intelligence
// "You have X minutes — here are the cards most at risk"

struct SessionIntelligenceView: View {

    let allSubjects: [Subject]
    let onStartSession: ([Question]) -> Void
    let onDismiss: () -> Void

    @State private var selectedMinutes: Int = 15
    @State private var recommendations: [QuestionRecommendation] = []

    private let minuteOptions = [5, 10, 15, 20, 30, 45]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Time picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How much time do you have?")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                ForEach(minuteOptions, id: \.self) { mins in
                                    Button {
                                        withAnimation { selectedMinutes = mins }
                                    } label: {
                                        Text("\(mins)m")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(selectedMinutes == mins ? .white : Color(hex: AppColors.neutral))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule().fill(selectedMinutes == mins
                                                               ? Color(hex: AppColors.primary)
                                                               : Color(hex: AppColors.surfacePrimary))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Recommendations
                        if recommendations.isEmpty {
                            EmptyStateView(
                                icon: "sparkles",
                                title: "No cards due yet",
                                message: "Start quizzing to build your FSRS schedule. Come back tomorrow."
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("AI Recommends (\(recommendations.count) cards)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("≈ \(estimatedMinutes) min")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Color(hex: AppColors.muted))
                                }

                                ForEach(recommendations) { rec in
                                    RecommendationRow(rec: rec)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Smart Session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let qs = recommendations.map(\.question)
                        onStartSession(qs)
                    }
                    .fontWeight(.bold)
                    .disabled(recommendations.isEmpty)
                }
            }
            .onAppear { buildRecommendations() }
            .onChange(of: selectedMinutes) { _, _ in buildRecommendations() }
        }
        .preferredColorScheme(.dark)
    }

    private var estimatedMinutes: Int {
        // ~90 seconds per card
        max(1, recommendations.count * 90 / 60)
    }

    private func buildRecommendations() {
        let allQuestions = allSubjects.flatMap(\.topics).flatMap(\.questions)
        let maxCards = max(5, selectedMinutes * 60 / 90)  // 90 sec per card

        // Priority: FSRS overdue first, then nemesis questions, then unseen questions
        let overdue  = FSRSService.shared.dueQuestions(from: allQuestions)
        let nemesis  = allQuestions.filter(\.isNemesis).filter { !overdue.map(\.id).contains($0.id) }
        let unseen   = allQuestions.filter { $0.timesAsked == 0 }.filter {
            !overdue.map(\.id).contains($0.id) && !nemesis.map(\.id).contains($0.id)
        }

        var queue: [Question] = []
        queue += overdue.prefix(maxCards)
        if queue.count < maxCards { queue += nemesis.prefix(maxCards - queue.count) }
        if queue.count < maxCards { queue += unseen.prefix(maxCards - queue.count) }

        recommendations = queue.prefix(maxCards).map { q in
            let reason: String
            if overdue.map(\.id).contains(q.id) {
                let days = abs(q.daysUntilDue)
                reason = days == 0 ? "Due today" : "\(days)d overdue"
            } else if q.isNemesis {
                reason = "Nemesis — you keep getting this wrong"
            } else {
                reason = "Never reviewed"
            }
            return QuestionRecommendation(question: q, reason: reason)
        }
    }
}

// MARK: - Supporting Types

struct QuestionRecommendation: Identifiable {
    let id = UUID()
    let question: Question
    let reason: String
}

private struct RecommendationRow: View {
    let rec: QuestionRecommendation

    var body: some View {
        HStack(spacing: 12) {
            // Urgency dot
            Circle()
                .fill(urgencyColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(rec.question.questionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(rec.question.topic?.name ?? "Unknown")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: AppColors.muted))
                    Text("·")
                        .foregroundStyle(Color(hex: AppColors.muted))
                    Text(rec.reason)
                        .font(.system(size: 10))
                        .foregroundStyle(urgencyColor)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: AppColors.surfacePrimary))
        )
    }

    private var urgencyColor: Color {
        if rec.reason.contains("overdue") || rec.reason.contains("today") {
            return Color(hex: AppColors.danger)
        } else if rec.reason.contains("Nemesis") {
            return Color(hex: AppColors.warning)
        } else {
            return Color(hex: AppColors.muted)
        }
    }
}
