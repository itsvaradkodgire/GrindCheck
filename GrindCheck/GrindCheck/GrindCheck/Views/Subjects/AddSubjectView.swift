import SwiftUI
import SwiftData

struct AddSubjectView: View {

    @Environment(\.modelContext)  private var modelContext
    @Environment(\.dismiss)       private var dismiss
    @Query(sort: \Subject.sortOrder) private var existingSubjects: [Subject]

    @State private var name       = ""
    @State private var icon       = "book.fill"
    @State private var colorHex   = "#00E5FF"
    @State private var showIconPicker = false

    private var isValid: Bool { name.trimmingCharacters(in: .whitespaces).isNotEmpty }

    // Preset colors
    private let presetColors: [String] = [
        "#00E5FF", "#00FF88", "#FF3366", "#FF8844", "#FFCC00",
        "#AA44FF", "#4488FF", "#FF66AA", "#44DDBB", "#F7DF1E",
        "#68A063", "#3178C6", "#61DAFB", "#264DE4", "#A855F7",
    ]

    // Curated icon options
    private let icons: [String] = [
        "book.fill", "books.vertical.fill", "brain.head.profile", "atom",
        "chevron.left.forwardslash.chevron.right", "network", "server.rack",
        "chart.bar.xaxis", "cpu.fill", "terminal.fill", "swift",
        "paintbrush.fill", "leaf.fill", "globe", "function",
        "j.circle.fill", "t.circle.fill", "p.circle.fill", "c.circle.fill",
        "star.fill", "flag.fill", "bolt.fill", "lock.fill",
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Preview
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: colorHex).opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: icon)
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(hex: colorHex))
                            }
                            Text(name.isEmpty ? "Subject Name" : name)
                                .font(.headline)
                                .foregroundStyle(name.isEmpty ? Color(hex: AppColors.muted) : .white)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                    .padding(.vertical, 8)
                }

                // Name
                Section("Name") {
                    TextField("e.g. System Design, DSA, React", text: $name)
                        .foregroundStyle(.white)
                        .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                // Color
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button {
                                colorHex = hex
                                HapticManager.shared.selectionChanged()
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white, lineWidth: colorHex == hex ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }

                // Icon
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { sf in
                            Button {
                                icon = sf
                                HapticManager.shared.selectionChanged()
                            } label: {
                                Image(systemName: sf)
                                    .font(.system(size: 20))
                                    .foregroundStyle(icon == sf ? Color(hex: colorHex) : Color(hex: AppColors.neutral))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(icon == sf
                                                  ? Color(hex: colorHex).opacity(0.15)
                                                  : Color(hex: AppColors.surfaceTertiary))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(hex: AppColors.surfaceSecondary))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: AppColors.background))
            .navigationTitle("Add Subject")
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
                        saveSubject()
                    }
                    .disabled(!isValid)
                    .foregroundStyle(isValid ? Color(hex: AppColors.primary) : Color(hex: AppColors.muted))
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveSubject() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.isNotEmpty else { return }

        let subject      = Subject(name: trimmed, icon: icon, colorHex: colorHex)
        subject.sortOrder = existingSubjects.count
        modelContext.insert(subject)
        try? modelContext.save()
        HapticManager.shared.correctAnswer()
        dismiss()
    }
}
