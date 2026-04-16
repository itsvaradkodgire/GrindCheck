import SwiftUI
import SwiftData

struct ScrollFeedView: View {

    // MARK: - Data

    @Query private var questions:    [Question]
    @Query private var subjects:     [Subject]
    @Query private var profiles:     [UserProfile]
    @Query private var achievements: [Achievement]
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel               = FeedViewModel()
    @State private var showXPFloat             = false
    @State private var xpToFloat               = 0
    @State private var sessionStarted          = false
    @State private var selectedTopic: Topic?   = nil
    @State private var studyGuideTopic: Topic? = nil  // Feature 6: opens study guide tab
    @Environment(AppState.self) private var appState   // Feature 4: switch to quiz tab

    // MARK: - Computed

    private var profile: UserProfile?  { profiles.first }
    private var todayLog: DailyLog?    { logs.first { DailyLog.isToday($0.date) } }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: AppColors.background).ignoresSafeArea()

            if viewModel.cards.isEmpty {
                emptyFeedView
            } else {
                feedScrollView
            }

            // Streak heat glow (edge effect)
            if viewModel.comboStreak >= 3 {
                StreakHeatOverlay(streak: viewModel.comboStreak)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Combo badge (top-right)
            if viewModel.comboStreak >= 3 {
                comboBadge
            }

            // XP float
            if showXPFloat {
                xpFloatLayer
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            guard !sessionStarted else { return }
            sessionStarted = true
            generateCards()
        }
        .onChange(of: questions.count) { old, new in
            if viewModel.cards.isEmpty && new > 0 { generateCards() }
        }
        .sheet(item: $selectedTopic) { topic in
            NavigationStack {
                TopicDetailView(topic: topic)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { selectedTopic = nil }
                                .foregroundStyle(Color(hex: AppColors.primary))
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(item: $studyGuideTopic) { topic in
            NavigationStack {
                TopicDetailView(topic: topic, initialTab: .studyGuide)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { studyGuideTopic = nil }
                                .foregroundStyle(Color(hex: AppColors.primary))
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Feed Scroll View

    private var feedScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    FeedCardDispatcher(
                        card: card,
                        viewModel: viewModel,
                        onCorrect: { q in handleCorrect(cardId: card.id, question: q) },
                        onWrong:   { q in handleWrong(cardId: card.id, question: q) },
                        onBookmark: { q in
                            q.isBookmarked.toggle()
                            try? modelContext.save()
                        },
                        onFlashcardKnew: { _ in
                            viewModel.recordFlashcardKnew(cardId: card.id)
                        },
                        onFlashcardReview: { q in
                            viewModel.recordFlashcardNeedsReview(
                                cardId: card.id, topic: q.topic, context: modelContext)
                        },
                        onTopicTap: { topicName in
                            let allTopics = subjects.flatMap(\.topics)
                            selectedTopic = allTopics.first {
                                $0.name.lowercased() == topicName.lowercased()
                            }
                        },
                        onStudyGuide: { q in studyGuideTopic = q.topic },
                        onStartDueReview: { appState.selectedTab = .quiz }
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .ignoresSafeArea()
                    .onAppear {
                        viewModel.loadMoreIfNeeded(
                            currentIndex: index,
                            questions: questions,
                            subjects: subjects,
                            profile: profile,
                            achievements: achievements,
                            todayLog: todayLog
                        )
                    }
                }
            }
            .scrollTargetLayout()
        }
        #if os(iOS)
        .scrollTargetBehavior(.paging)
        #endif
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .refreshable { await refreshFeed() }
    }

    // MARK: - Empty State

    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: AppColors.muted))

            Text("Feed is empty")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Add subjects and questions first.\nThe feed runs on your content.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Overlays

    private var comboBadge: some View {
        VStack {
            HStack {
                Spacer()
                ComboView(streak: viewModel.comboStreak)
                    .padding(.top, 56)
                    .padding(.trailing, 16)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var xpFloatLayer: some View {
        VStack {
            Spacer()
            XPFloatView(
                amount: xpToFloat,
                multiplier: ComboMultiplier.multiplier(forStreak: viewModel.comboStreak)
            )
            .frame(maxWidth: .infinity)
            Spacer().frame(height: 180)
        }
    }

    // MARK: - Event Handlers

    private func handleCorrect(cardId: UUID, question: Question) {
        let xp = viewModel.recordCorrectAnswer(
            cardId: cardId, question: question, context: modelContext)

        xpToFloat = xp
        withAnimation { showXPFloat = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showXPFloat = false }
        }

        HapticManager.shared.correctAnswer()

        // Update topic proficiency slightly for correct feed answers
        if let topic = question.topic {
            topic.proficiencyScore = min(100, topic.proficiencyScore + 1)
            try? modelContext.save()
        }
    }

    private func handleWrong(cardId: UUID, question: Question) {
        viewModel.recordWrongAnswer(cardId: cardId, question: question, context: modelContext)
        HapticManager.shared.wrongAnswer()
    }

    // MARK: - Feed Generation

    private func generateCards() {
        viewModel.generateCards(
            questions: questions,
            subjects: subjects,
            profile: profile,
            achievements: achievements,
            todayLog: todayLog,
            logs: Array(logs)
        )
    }

    private func refreshFeed() async {
        HapticManager.shared.pullToRefresh()
        // Short delay for pull-to-refresh feel
        try? await Task.sleep(nanoseconds: 400_000_000)
        generateCards()
    }
}
