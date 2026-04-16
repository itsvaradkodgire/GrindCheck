import SwiftUI
import SwiftData

struct AddTopicView: View {

    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name  = ""
    @State private var notes = ""

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespaces).isNotEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Topic Name") {
                    TextField("e.g. Closures, Binary Search, CAP Theorem", text: $name)
                        .foregroundStyle(.white)
                        .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                Section("Notes (optional)") {
                    TextField("Key points, resources, reminders...", text: $notes, axis: .vertical)
                        .foregroundStyle(.white)
                        .lineLimit(3...6)
                        .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color(hex: AppColors.neutral))
                        Text("Topic starts at 0% proficiency. Take a quiz or add questions to start building your score.")
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.neutral))
                    }
                    .listRowBackground(Color(hex: AppColors.surfacePrimary))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: AppColors.background))
            .navigationTitle("Add Topic")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.neutral))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveTopic()
                    }
                    .disabled(!isValid)
                    .foregroundStyle(isValid ? Color(hex: AppColors.primary) : Color(hex: AppColors.muted))
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveTopic() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard trimmedName.isNotEmpty else { return }

        let topic = Topic(
            name: trimmedName,
            subject: subject,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(topic)
        subject.topics.append(topic)
        try? modelContext.save()
        HapticManager.shared.correctAnswer()
        dismiss()
    }
}
