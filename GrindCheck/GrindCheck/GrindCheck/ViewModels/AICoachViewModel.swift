import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AICoachViewModel {

    // MARK: - Dependencies
    let geminiService: GeminiService

    // MARK: - Chat
    var chatMessages: [ChatMessage] = []
    var currentInput: String        = ""
    var isChatLoading: Bool         = false
    var chatError: String?          = nil

    var showBuildRoadmapButton: Bool {
        chatMessages.filter(\.isUser).count >= 3
    }

    // MARK: - Roadmap
    var currentRoadmap: AIRoadmap?   = nil
    var isGeneratingRoadmap: Bool    = false
    var roadmapError: String?        = nil

    // MARK: - Materials
    var isGeneratingQuestions: Bool  = false
    var generationError: String?     = nil
    var pendingQuestions: [GeneratedQuestion] = []
    var showQuestionReview: Bool     = false

    // MARK: - API Key
    var showAPIKeySetup: Bool        = false

    // MARK: - Socratic Mode
    var isSocraticMode: Bool         = false

    // MARK: - Init

    init(geminiService: GeminiService) {
        self.geminiService = geminiService
    }

    // MARK: - Chat

    func sendMessage(_ text: String, modelContext: ModelContext) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        guard geminiService.hasAPIKey else {
            showAPIKeySetup = true
            return
        }

        let userMsg = ChatMessage(role: "user", content: trimmed)
        modelContext.insert(userMsg)
        chatMessages.append(userMsg)
        currentInput  = ""
        isChatLoading = true
        chatError     = nil

        // Build API history from persisted messages
        var apiMessages: [GeminiMessage] = chatMessages.map {
            GeminiMessage(role: $0.role, parts: [GeminiPart(text: $0.content)])
        }

        // Inject persona context before the very first exchange
        if chatMessages.filter({ $0.isUser }).count == 1 {
            let persona = isSocraticMode ? Self.socraticPersona : Self.chatPersona
            let ack     = GeminiMessage(role: "model", parts: [GeminiPart(text: "Got it. I'm your GrindCheck AI Study Coach. Let's build your plan.")])
            let personaMsg = GeminiMessage(role: "user", parts: [GeminiPart(text: persona)])
            apiMessages = [personaMsg, ack] + apiMessages
        }

        do {
            let reply   = try await geminiService.chat(messages: apiMessages)
            let modelMsg = ChatMessage(role: "model", content: reply)
            modelContext.insert(modelMsg)
            chatMessages.append(modelMsg)
            try? modelContext.save()
        } catch {
            chatError = error.localizedDescription
            if case GeminiError.noAPIKey = error { showAPIKeySetup = true }
        }

        isChatLoading = false
    }

    func loadChatMessages(from context: ModelContext) {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        chatMessages = (try? context.fetch(descriptor)) ?? []
    }

    func clearChat(modelContext: ModelContext) {
        chatMessages.forEach { modelContext.delete($0) }
        chatMessages = []
        try? modelContext.save()
    }

    // MARK: - Roadmap

    func buildRoadmap(modelContext: ModelContext) async {
        guard geminiService.hasAPIKey else { showAPIKeySetup = true; return }

        isGeneratingRoadmap = true
        roadmapError        = nil

        let history = chatMessages
            .map { "\($0.isUser ? "Student" : "Coach"): \($0.content)" }
            .joined(separator: "\n")

        do {
            let (parsed, rawJSON) = try await geminiService.generateRoadmap(chatHistory: history)

            if let existing = currentRoadmap { modelContext.delete(existing) }

            let roadmap = AIRoadmap(goal: parsed.goal, subjectName: parsed.subjectName, rawJSON: rawJSON)
            modelContext.insert(roadmap)

            for (i, phase) in parsed.phases.enumerated() {
                let p = RoadmapPhase(
                    title:            phase.title,
                    phaseDescription: phase.description,
                    topicNames:       phase.topics,
                    estimatedWeeks:   phase.estimatedWeeks,
                    order:            i,
                    roadmap:          roadmap
                )
                modelContext.insert(p)
                roadmap.phases.append(p)
            }

            try? modelContext.save()
            currentRoadmap = roadmap

        } catch {
            roadmapError = error.localizedDescription
            if case GeminiError.noAPIKey = error { showAPIKeySetup = true }
        }

        isGeneratingRoadmap = false
    }

    func loadRoadmap(from context: ModelContext) {
        let descriptor = FetchDescriptor<AIRoadmap>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        currentRoadmap = (try? context.fetch(descriptor))?.first
    }

    func togglePhaseComplete(_ phase: RoadmapPhase, modelContext: ModelContext) {
        phase.isCompleted.toggle()
        try? modelContext.save()
    }

    // MARK: - Question Generation

    func generateQuestions(
        from material: StudyMaterial,
        topic: Topic?,
        modelContext: ModelContext
    ) async {
        guard geminiService.hasAPIKey else { showAPIKeySetup = true; return }

        isGeneratingQuestions = true
        generationError       = nil
        pendingQuestions      = []

        let existing  = topic?.questions.map(\.questionText) ?? []
        let topicName = topic?.name ?? material.title

        do {
            let questions = try await geminiService.generateQuestionsFromMaterial(
                material.rawText,
                topicName: topicName,
                existingQuestions: existing
            )
            pendingQuestions   = questions
            showQuestionReview = true
        } catch {
            generationError = error.localizedDescription
            if case GeminiError.noAPIKey = error { showAPIKeySetup = true }
        }

        isGeneratingQuestions = false
    }

    func generateQuestionsForTopic(_ topic: Topic, modelContext: ModelContext) async {
        guard geminiService.hasAPIKey else { showAPIKeySetup = true; return }

        isGeneratingQuestions = true
        generationError       = nil
        pendingQuestions      = []

        do {
            let questions = try await geminiService.generateQuestionsForTopic(
                topicName:         topic.name,
                subjectName:       topic.subject?.name ?? "",
                existingQuestions: topic.questions.map(\.questionText)
            )
            pendingQuestions   = questions
            showQuestionReview = true
        } catch {
            generationError = error.localizedDescription
            if case GeminiError.noAPIKey = error { showAPIKeySetup = true }
        }

        isGeneratingQuestions = false
    }

    func acceptQuestions(
        _ questions: [GeneratedQuestion],
        topic: Topic,
        modelContext: ModelContext
    ) {
        for gq in questions {
            let q = Question(
                topic:         topic,
                questionText:  gq.questionText,
                questionType:  gq.questionType,
                options:       gq.options,
                correctAnswer: gq.correctAnswer,
                explanation:   gq.explanation,
                difficulty:    gq.difficulty,
                tags:          gq.tags,
                isAIGenerated: true
            )
            modelContext.insert(q)
            topic.questions.append(q)
        }
        try? modelContext.save()
        HapticManager.shared.correctAnswer()
        pendingQuestions   = []
        showQuestionReview = false
    }

    // MARK: - Persona

    private static let chatPersona = """
    You are an AI Study Coach inside GrindCheck, a brutally honest study tracker app. \
    Your personality: direct, no fluff, zero tolerance for excuses. You help students \
    build concrete study plans, NOT explain concepts.

    Your job in this conversation:
    1. Ask what their main learning goal is (e.g. "get a job as a frontend dev", "pass FAANG interviews").
    2. Ask what specific skills or topics they want to improve.
    3. Ask what they plan to study next.
    4. After 3–5 exchanges, offer to generate a personalized roadmap.

    Rules:
    - Keep responses to 2–4 sentences max.
    - Be direct. No filler phrases like "Great question!".
    - Do NOT explain concepts — only help with planning.
    - If they stray off-topic, redirect to their study plan.
    """

    private static let socraticPersona = """
    You are a Socratic AI Study Coach inside GrindCheck. Your ONLY method is Socratic questioning.

    Rules (strictly enforced):
    - NEVER give a direct answer or explanation.
    - ALWAYS respond with a question that guides the student toward the answer themselves.
    - If they say "I don't know", ask a simpler leading question — break it down further.
    - If they get it right, acknowledge briefly and deepen with another question.
    - Keep each response to ONE question only. Never multiple questions at once.
    - Your goal: force deep thinking, not information delivery.

    Example style:
    Student: "What is gradient descent?"
    You: "Imagine you're lost on a foggy mountain and want to reach the valley. What's the one thing you can see around you that tells you which direction is downhill?"
    """
}
