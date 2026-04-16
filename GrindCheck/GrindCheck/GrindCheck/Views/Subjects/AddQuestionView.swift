import SwiftUI
import SwiftData

struct AddQuestionView: View {

    let topic: Topic
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var questionText  = ""
    @State private var questionType  = QuestionType.mcq
    @State private var correctAnswer = ""
    @State private var explanation   = ""
    @State private var difficulty    = 3
    @State private var options       = ["", "", "", ""]  // MCQ options
    @State private var trueFalseAnswer = true

    private var isValid: Bool {
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespaces)
        let trimmedAnswer   = correctAnswer.trimmingCharacters(in: .whitespaces)
        guard trimmedQuestion.isNotEmpty else { return false }
        switch questionType {
        case .mcq:
            return options.filter { $0.trimmingCharacters(in: .whitespaces).isNotEmpty }.count >= 2
                && trimmedAnswer.isNotEmpty
        case .trueFalse:
            return true
        default:
            return trimmedAnswer.isNotEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {

                // Question Type
                Section("Question Type") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(QuestionType.allCases) { type in
                            Button {
                                questionType = type
                            } label: {
                                Text(type.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(questionType == type
                                                  ? Color(hex: AppColors.primary)
                                                  : Color(hex: AppColors.surfaceTertiary))
                                    )
                                    .foregroundStyle(questionType == type ? .black : .white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                // Question text
                Section("Question") {
                    TextEditor(text: $questionText)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                        .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                // MCQ options
                if questionType == .mcq {
                    Section("Options (mark correct in Answer field)") {
                        ForEach(0..<4, id: \.self) { i in
                            HStack {
                                Text("\(["A", "B", "C", "D"][i]).")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(Color(hex: AppColors.muted))
                                TextField("Option \(["A","B","C","D"][i])", text: $options[i])
                                    .foregroundStyle(.white)
                            }
                            .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                        }
                    }
                }

                // Answer
                Section("Correct Answer") {
                    if questionType == .trueFalse {
                        Toggle("True", isOn: $trueFalseAnswer)
                            .tint(Color(hex: AppColors.success))
                            .foregroundStyle(.white)
                            .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                            .onChange(of: trueFalseAnswer) { _, val in
                                correctAnswer = val ? "True" : "False"
                            }
                            .onAppear {
                                if correctAnswer.isEmpty { correctAnswer = "True" }
                            }
                    } else {
                        TextField(questionType == .mcq ? "Paste the exact correct option text" : "The correct answer",
                                  text: $correctAnswer, axis: .vertical)
                            .foregroundStyle(.white)
                            .lineLimit(2...4)
                            .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                    }
                }

                // Explanation
                Section("Explanation (Why is this the answer?)") {
                    TextEditor(text: $explanation)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                        .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                // Difficulty
                Section("Difficulty") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Level \(difficulty):")
                                .foregroundStyle(Color(hex: AppColors.neutral))
                            Text(difficultyLabel)
                                .foregroundStyle(Color(hex: AppColors.warning))
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)

                        Slider(value: Binding(
                            get: { Double(difficulty) },
                            set: { difficulty = Int($0) }
                        ), in: 1...5, step: 1)
                        .tint(Color(hex: AppColors.warning))
                    }
                    .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: AppColors.background))
            .navigationTitle("Add Question")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.neutral))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveQuestion() }
                        .disabled(!isValid)
                        .foregroundStyle(isValid ? Color(hex: AppColors.primary) : Color(hex: AppColors.muted))
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var difficultyLabel: String {
        switch difficulty {
        case 1: return "Basics"
        case 2: return "Understanding"
        case 3: return "Application"
        case 4: return "Analysis"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }

    private func saveQuestion() {
        var finalOptions: [String] = []
        if questionType == .mcq {
            finalOptions = options.filter { $0.trimmingCharacters(in: .whitespaces).isNotEmpty }
        } else if questionType == .trueFalse {
            finalOptions = ["True", "False"]
        }

        let finalAnswer = questionType == .trueFalse
            ? (trueFalseAnswer ? "True" : "False")
            : correctAnswer.trimmingCharacters(in: .whitespaces)

        let question = Question(
            topic: topic,
            questionText: questionText.trimmingCharacters(in: .whitespaces),
            questionType: questionType,
            options: finalOptions,
            correctAnswer: finalAnswer,
            explanation: explanation.trimmingCharacters(in: .whitespaces),
            difficulty: difficulty
        )
        modelContext.insert(question)
        topic.questions.append(question)
        try? modelContext.save()
        HapticManager.shared.correctAnswer()
        dismiss()
    }
}
