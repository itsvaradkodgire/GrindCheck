import Foundation
import Observation

// MARK: - Errors

enum GeminiError: LocalizedError {
    case noAPIKey
    case rateLimitExceeded
    case networkError(Error)
    case invalidResponse
    case parseError(String)
    case keychainWriteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Gemini API key. Tap the key icon to add yours."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .invalidResponse:
            return "Gemini returned an unexpected response."
        case .parseError(let msg):
            return "Could not parse AI response: \(msg)"
        case .keychainWriteFailed(let s):
            return "Could not save API key (error \(s))."
        }
    }
}

// MARK: - Gemini REST Wire Types

struct GeminiMessage: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

private struct GeminiRequest: Codable {
    let contents: [GeminiMessage]
    let generationConfig: GenerationConfig

    struct GenerationConfig: Codable {
        let temperature: Double
        let maxOutputTokens: Int
    }
}

private struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: GeminiMessage
    }
}

// MARK: - Parsed Output Types (transient — not SwiftData models)

struct GeneratedQuestion {
    let questionText: String
    let questionType: QuestionType
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let difficulty: Int
    let tags: [String]
}

struct RoadmapJSON: Codable {
    let goal: String
    let subjectName: String
    let phases: [PhaseJSON]

    struct PhaseJSON: Codable {
        let title: String
        let description: String
        let topics: [String]
        let estimatedWeeks: Int
    }
}

/// Transient — used during article generation before saving to SwiftData
struct ArticleSectionData {
    let type: ArticleSectionType
    let title: String
    let content: String
    let confidence: ArticleConfidence

    init?(_ dict: [String: Any]) {
        guard
            let typeStr  = dict["type"]    as? String,
            let title    = dict["title"]   as? String,
            let content  = dict["content"] as? String
        else { return nil }

        self.type       = ArticleSectionType(rawValue: typeStr) ?? .explanation
        self.title      = title
        self.content    = content
        let confStr     = dict["confidence"] as? String ?? "medium"
        self.confidence = ArticleConfidence(rawValue: confStr) ?? .medium
    }
}

struct CodeAnalysisResult: Codable {
    let masteredConcepts: [String]
    let gaps: [String]
    let feedback: String
    let confidenceBoost: [String: Int]
}

struct JobGapAnalysis: Codable {
    let requiredSkills: [String]
    let alreadyHave: [String]
    let gaps: [String]
    let priority: [String]
    let matchScore: Int
}

// MARK: - GeminiService

@Observable
@MainActor
final class GeminiService {

    // MARK: - State

    private(set) var hasAPIKey: Bool = false

    // MARK: - Rate Limiting

    private var requestsThisMinute: Int = 0
    private var requestsToday: Int      = 0
    private var minuteWindowStart: Date = Date()
    private var dayWindowStart: Date    = Calendar.current.startOfDay(for: Date())

    // MARK: - Init

    init() {
        hasAPIKey = KeychainHelper.load(key: GeminiConfig.keychainKey) != nil
    }

    // MARK: - Key Management

    func saveAPIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        try KeychainHelper.save(key: GeminiConfig.keychainKey, value: trimmed)
        hasAPIKey = true
    }

    func deleteAPIKey() {
        KeychainHelper.delete(key: GeminiConfig.keychainKey)
        hasAPIKey = false
    }

    // MARK: - Rate Limit

    private func checkRateLimit() throws {
        let now = Date()

        if now.timeIntervalSince(minuteWindowStart) > 60 {
            requestsThisMinute = 0
            minuteWindowStart  = now
        }

        let todayStart = Calendar.current.startOfDay(for: now)
        if todayStart > dayWindowStart {
            requestsToday  = 0
            dayWindowStart = todayStart
        }

        guard requestsThisMinute < GeminiConfig.maxRequestsPerMin else {
            throw GeminiError.rateLimitExceeded
        }
        guard requestsToday < GeminiConfig.maxRequestsPerDay else {
            throw GeminiError.rateLimitExceeded
        }

        requestsThisMinute += 1
        requestsToday      += 1
    }

    // MARK: - Core HTTP Call

    private func callAPI(messages: [GeminiMessage]) async throws -> String {
        guard let apiKey = KeychainHelper.load(key: GeminiConfig.keychainKey) else {
            throw GeminiError.noAPIKey
        }

        try checkRateLimit()

        let urlString = "\(GeminiConfig.baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw GeminiError.invalidResponse }

        let body = GeminiRequest(
            contents: messages,
            generationConfig: .init(
                temperature:     GeminiConfig.temperature,
                maxOutputTokens: GeminiConfig.maxOutputTokens
            )
        )

        var request          = URLRequest(url: url)
        request.httpMethod   = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody     = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            // Extract Google's error message from the response body
            if let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = body["error"] as? [String: Any],
               let msg = errObj["message"] as? String {
                throw GeminiError.parseError("HTTP \(http.statusCode): \(msg)")
            }
            let raw = String(data: data.prefix(300), encoding: .utf8) ?? "no body"
            throw GeminiError.parseError("HTTP \(http.statusCode): \(raw)")
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.first?.text else {
            let raw = String(data: data.prefix(300), encoding: .utf8) ?? ""
            throw GeminiError.parseError("No text in response. Raw: \(raw)")
        }
        return text
    }

    // MARK: - Public API

    func chat(messages: [GeminiMessage]) async throws -> String {
        try await callAPI(messages: messages)
    }

    func generateRoadmap(chatHistory: String) async throws -> (roadmap: RoadmapJSON, rawJSON: String) {
        let messages: [GeminiMessage] = [
            .init(role: "user",  parts: [.init(text: Self.roadmapSystemPrompt)]),
            .init(role: "model", parts: [.init(text: "Understood. I will output only valid JSON.")]),
            .init(role: "user",  parts: [.init(text: "Here is the conversation:\n\n\(chatHistory)\n\nGenerate my roadmap now.")])
        ]

        let raw = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)

        guard let data = json.data(using: .utf8) else {
            throw GeminiError.parseError("Cannot encode JSON string")
        }
        do {
            let roadmap = try JSONDecoder().decode(RoadmapJSON.self, from: data)
            return (roadmap, json)
        } catch {
            throw GeminiError.parseError(error.localizedDescription)
        }
    }

    func generateQuestionsForTopic(
        topicName: String,
        subjectName: String,
        existingQuestions: [String]
    ) async throws -> [GeneratedQuestion] {
        let prompt = Self.topicQuestionPrompt(topicName: topicName, subjectName: subjectName, existing: existingQuestions)
        let messages: [GeminiMessage] = [.init(role: "user", parts: [.init(text: prompt)])]
        let raw  = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)
        return try parseQuestions(from: json)
    }

    func generateQuestionsFromMaterial(
        _ text: String,
        topicName: String,
        existingQuestions: [String]
    ) async throws -> [GeneratedQuestion] {
        let prompt = Self.questionPrompt(text: text, topicName: topicName, existing: existingQuestions)
        let messages: [GeminiMessage] = [
            .init(role: "user", parts: [.init(text: prompt)])
        ]

        let raw  = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)
        return try parseQuestions(from: json)
    }

    // MARK: - Knowledge Base Article

    func generateTopicArticle(
        topicName: String,
        subjectName: String
    ) async throws -> [ArticleSectionData] {
        let prompt = Self.articlePrompt(topicName: topicName, subjectName: subjectName)
        let messages: [GeminiMessage] = [
            .init(role: "user",  parts: [.init(text: prompt)])
        ]
        let raw  = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)
        return try parseArticleSections(from: json)
    }

    private func parseArticleSections(from jsonString: String) throws -> [ArticleSectionData] {
        guard let data = jsonString.data(using: .utf8) else {
            throw GeminiError.parseError("Cannot encode JSON")
        }
        // Expect either {"sections":[...]} or [...]
        if let wrapper = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let array = wrapper["sections"] as? [[String: Any]] {
            return array.compactMap(ArticleSectionData.init)
        }
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return array.compactMap(ArticleSectionData.init)
        }
        throw GeminiError.parseError("Expected JSON array of sections")
    }

    private static func articlePrompt(topicName: String, subjectName: String) -> String {
        let context = subjectName.isEmpty ? "" : " within the subject \(subjectName)"
        return """
        You are an expert technical educator. Write a comprehensive study guide for \
        "\(topicName)"\(context).

        OUTPUT RULES:
        - Output ONLY a valid JSON array. No markdown, no explanation, no code fences.
        - Each element must match this exact schema:
        {
          "type": "summary" | "concepts" | "explanation" | "code" | "mistakes" | "reference",
          "title": "section title string",
          "content": "content in markdown (use **bold**, bullet lists with -, code blocks with ```)",
          "confidence": "high" | "medium" | "low"
        }
        - Include exactly these sections in order:
          1. summary — 2-3 sentence TL;DR of what this topic is
          2. concepts — bullet list of the 5-8 must-know concepts with one-line explanations
          3. explanation — detailed explanation of how it works (3-5 paragraphs)
          4. code — working code example with ```language fences (skip if not applicable)
          5. mistakes — 4-6 common mistakes or misconceptions as a bullet list
          6. reference — cheat-sheet style quick reference table or bullet list
        - Set confidence to "low" or "medium" honestly if you are not fully certain.
        - Do NOT invent function names, APIs, or behaviors you are uncertain about.
        - For code sections: only include code you are certain compiles and runs correctly.
        """
    }

    // MARK: - Weekly Gap Report

    func generateWeeklyGapReport(
        subjects: [Subject],
        recentLogs: [DailyLog]
    ) async throws -> String {
        guard hasAPIKey else { throw GeminiError.noAPIKey }
        let topicSummary = subjects.flatMap(\.topics).map {
            "\($0.name): proficiency \($0.proficiencyScore)%, accuracy \(Int($0.overallAccuracyRate * 100))%, \($0.totalQuestions) questions"
        }.joined(separator: "\n")
        let weekStudy = recentLogs.prefix(7).reduce(0) { $0 + $1.totalStudyMinutes }
        let prompt = """
        You are a study coach. Here is a student's performance this week:

        Study time this week: \(weekStudy) minutes
        Topic breakdown:
        \(topicSummary)

        Write a concise weekly report (4–6 sentences) that:
        1. Identifies their 2–3 weakest concept clusters
        2. Calls out what they should focus on next week specifically
        3. Gives one encouraging line
        Be brutally honest but brief. No fluff.
        """
        let messages: [GeminiMessage] = [.init(role: "user", parts: [.init(text: prompt)])]
        return try await callAPI(messages: messages)
    }

    // MARK: - Code Analysis (infer mastery from pasted code)

    func analyzeCode(
        _ code: String,
        topics: [String]
    ) async throws -> CodeAnalysisResult {
        guard hasAPIKey else { throw GeminiError.noAPIKey }
        let topicList = topics.joined(separator: ", ")
        let prompt = """
        A student pasted this code. Analyze it and return JSON only:
        {
          "masteredConcepts": ["list of topic names from [\(topicList)] demonstrated in the code"],
          "gaps": ["concepts the student appears weak on or missed"],
          "feedback": "2-sentence code quality feedback",
          "confidenceBoost": {"topicName": confidence_delta_0_to_20}
        }

        Code:
        ```
        \(code.prefix(3000))
        ```

        Only include topics from the provided list in masteredConcepts. Return only the JSON.
        """
        let messages: [GeminiMessage] = [.init(role: "user", parts: [.init(text: prompt)])]
        let raw  = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)
        guard let data = json.data(using: .utf8),
              let result = try? JSONDecoder().decode(CodeAnalysisResult.self, from: data) else {
            throw GeminiError.parseError("Could not parse code analysis")
        }
        return result
    }

    // MARK: - Exam Scheduler

    func generateExamSchedule(
        examDate: Date,
        subjectName: String,
        topics: [(name: String, proficiency: Int)]
    ) async throws -> String {
        guard hasAPIKey else { throw GeminiError.noAPIKey }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 7
        let topicLines = topics.map { "- \($0.name): \($0.proficiency)% proficiency" }.joined(separator: "\n")
        let prompt = """
        Create a day-by-day study schedule for a student preparing for a \(subjectName) exam in \(daysUntil) days.

        Their current topic proficiencies:
        \(topicLines)

        Rules:
        - Prioritize low-proficiency topics
        - Each day: 2–3 specific topics to review
        - Final 2 days: review only, no new material
        - Format as a clean day-by-day list
        - Be concise — max 2 lines per day
        - Include a total daily time estimate (30–120 min)
        """
        let messages: [GeminiMessage] = [.init(role: "user", parts: [.init(text: prompt)])]
        return try await callAPI(messages: messages)
    }

    // MARK: - Teach It Back Grading

    func gradeTeachItBack(
        userExplanation: String,
        concept: String,
        correctContent: String
    ) async throws -> (score: Int, feedback: String, missed: [String]) {
        let prompt = """
        A student is practicing "Teach It Back" for the concept: "\(concept)".

        REFERENCE CONTENT:
        \(correctContent.prefix(2000))

        STUDENT'S EXPLANATION:
        \(userExplanation.prefix(1500))

        Grade the student and return JSON only:
        {
          "score": 1,
          "feedback": "2-3 sentence constructive feedback",
          "missed": ["key concept they missed 1", "key concept they missed 2"]
        }

        Scoring rubric:
        - 5: Complete and accurate, covers all key concepts
        - 4: Mostly complete, minor gaps
        - 3: Core idea correct but missing significant details
        - 2: Partial understanding, major gaps
        - 1: Mostly incorrect or very superficial

        score must be an integer 1–5. Return only valid JSON, no markdown.
        """
        let messages: [GeminiMessage] = [.init(role: "user", parts: [.init(text: prompt)])]
        let raw  = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawScore = dict["score"],
              let feedback = dict["feedback"] as? String else {
            throw GeminiError.parseError("Could not parse grading response")
        }
        let score  = (rawScore as? Int) ?? Int((rawScore as? Double) ?? 1)
        let missed = dict["missed"] as? [String] ?? []
        return (max(1, min(5, score)), feedback, missed)
    }

    // MARK: - Job Description Import

    func analyzeJobDescription(
        _ jd: String,
        currentTopics: [String]
    ) async throws -> JobGapAnalysis {
        guard hasAPIKey else { throw GeminiError.noAPIKey }
        let topicList = currentTopics.joined(separator: ", ")
        let prompt = """
        Analyze this job description and return JSON only:
        {
          "requiredSkills": ["extracted technical skills from the JD"],
          "alreadyHave": ["skills from [\(topicList)] that match requirements"],
          "gaps": ["required skills NOT in [\(topicList)]"],
          "priority": ["top 5 skills to learn first, ordered by importance"],
          "matchScore": 0-100
        }

        Job Description:
        \(jd.prefix(4000))

        Return only valid JSON.
        """
        let messages: [GeminiMessage] = [.init(role: "user", parts: [.init(text: prompt)])]
        let raw  = try await callAPI(messages: messages)
        let json = stripCodeFences(raw)
        guard let data = json.data(using: .utf8),
              let result = try? JSONDecoder().decode(JobGapAnalysis.self, from: data) else {
            throw GeminiError.parseError("Could not parse job gap analysis")
        }
        return result
    }

    // MARK: - Helpers

    private func stripCodeFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```",     with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseQuestions(from jsonString: String) throws -> [GeneratedQuestion] {
        guard let data = jsonString.data(using: .utf8) else {
            throw GeminiError.parseError("Cannot encode JSON string")
        }
        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw GeminiError.parseError("Expected JSON array")
        }
        return array.compactMap { dict -> GeneratedQuestion? in
            guard
                let text    = dict["questionText"]  as? String,
                let typeRaw = dict["questionType"]   as? String,
                let answer  = dict["correctAnswer"]  as? String
            else { return nil }

            return GeneratedQuestion(
                questionText:  text,
                questionType:  QuestionType(rawValue: typeRaw) ?? .mcq,
                options:       dict["options"]     as? [String] ?? [],
                correctAnswer: answer,
                explanation:   dict["explanation"] as? String  ?? "",
                difficulty:    max(1, min(5, dict["difficulty"] as? Int ?? 3)),
                tags:          dict["tags"]        as? [String] ?? []
            )
        }
    }

    // MARK: - Prompts

    private static let roadmapSystemPrompt = """
    You are an expert learning roadmap designer. Based on the student's goals \
    from the conversation, generate a structured learning roadmap.

    OUTPUT RULES:
    - Output ONLY valid JSON. No markdown, no explanation, no code fences.
    - Strictly match this schema:
    {
      "goal": "the student's primary learning goal in one sentence",
      "subjectName": "the single field/domain name (e.g. 'AI Engineering', 'Web Development', 'Data Science')",
      "phases": [
        {
          "title": "Phase N: Short Title",
          "description": "2-3 sentences describing this phase",
          "topics": ["Exact Topic Name 1", "Exact Topic Name 2"],
          "estimatedWeeks": 2
        }
      ]
    }
    - subjectName must be the short clean name of the field — this becomes the Subject in the app.
    - topics must be specific, real concept names (not vague like "basics") — these become Topics under the Subject.
    - Topics should be distinct across phases — no repeats.
    - Include 3 to 5 phases that build progressively.
    - Each phase: 3 to 6 topic strings, estimatedWeeks 1–8 (integer).
    - Do not include any keys not in the schema.
    """

    private static func topicQuestionPrompt(topicName: String, subjectName: String, existing: [String]) -> String {
        let context  = subjectName.isEmpty ? "" : " within \(subjectName)"
        let existingBlock = existing.isEmpty
            ? "None"
            : existing.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        return """
        You are an expert quiz question generator. Generate 5 to 8 high-quality \
        study questions for the topic "\(topicName)"\(context). \
        Draw on your knowledge — no material is provided.

        EXISTING QUESTIONS — DO NOT repeat or closely resemble these:
        \(existingBlock)

        OUTPUT RULES:
        - Output ONLY a valid JSON array. No markdown, no text, no code fences.
        - Each object must match this exact schema:
        {
          "questionText": "string",
          "questionType": "mcq" | "trueFalse" | "shortAnswer" | "explainThis" | "codeOutput",
          "options": ["string"] (4 items for mcq, ["True","False"] for trueFalse, [] otherwise),
          "correctAnswer": "exact text of correct option for mcq; 'True' or 'False' for trueFalse",
          "explanation": "why this is the correct answer",
          "difficulty": 1 | 2 | 3 | 4 | 5,
          "tags": ["keyword1", "keyword2"]
        }
        - Mix types: at least 2 MCQ, 1 trueFalse, rest as shortAnswer or explainThis.
        - Vary difficulty across the range 1–5.
        """
    }

    private static func questionPrompt(text: String, topicName: String, existing: [String]) -> String {
        let existingBlock = existing.isEmpty
            ? "None"
            : existing.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        return """
        You are an expert quiz question generator. Generate 5 to 10 high-quality \
        study questions from the material below for the topic "\(topicName)".

        MATERIAL:
        \(text.prefix(6000))

        EXISTING QUESTIONS — DO NOT repeat or closely resemble these:
        \(existingBlock)

        OUTPUT RULES:
        - Output ONLY a valid JSON array. No markdown, no text, no code fences.
        - Each object must match this exact schema:
        {
          "questionText": "string",
          "questionType": "mcq" | "trueFalse" | "shortAnswer" | "explainThis" | "codeOutput",
          "options": ["string"] (4 items for mcq, ["True","False"] for trueFalse, [] otherwise),
          "correctAnswer": "exact text of correct option for mcq; 'True' or 'False' for trueFalse",
          "explanation": "why this is the correct answer",
          "difficulty": 1 | 2 | 3 | 4 | 5,
          "tags": ["keyword1", "keyword2"]
        }
        - Mix types: at least 2 MCQ, 1 trueFalse, rest as shortAnswer or explainThis.
        - Vary difficulty across the range 1–5.
        """
    }
}
