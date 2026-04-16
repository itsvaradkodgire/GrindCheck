import SwiftUI

struct APIKeySetupView: View {

    let geminiService: GeminiService
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey      = ""
    @State private var errorMsg: String? = nil
    @State private var isSaving    = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Icon + header
                        VStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: AppColors.primary))

                            Text("Connect Gemini AI")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)

                            Text("GrindCheck uses Google Gemini to power the AI Coach, roadmap generation, and question creation from your notes.")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: AppColors.neutral))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Key input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your API Key")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: AppColors.muted))

                            SecureField("Paste your Gemini API key", text: $apiKey)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: AppColors.surfaceSecondary))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(
                                                    apiKey.isEmpty
                                                    ? Color(hex: AppColors.surfaceTertiary)
                                                    : Color(hex: AppColors.primary).opacity(0.5),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }

                        // Error
                        if let err = errorMsg {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(hex: AppColors.danger))
                                Text(err)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: AppColors.danger))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: AppColors.danger).opacity(0.1))
                            )
                        }

                        // Save button
                        Button {
                            saveKey()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(Color(hex: AppColors.background))
                                } else {
                                    Image(systemName: "checkmark")
                                }
                                Text("Save Key")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(Color(hex: AppColors.background))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(apiKey.isEmpty
                                          ? Color(hex: AppColors.muted)
                                          : Color(hex: AppColors.primary))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(apiKey.isEmpty || isSaving)

                        // Get key link
                        Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.square")
                                Text("Get a free API key at Google AI Studio")
                            }
                            .font(.caption)
                            .foregroundStyle(Color(hex: AppColors.primary))
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("AI Setup")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: AppColors.neutral))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveKey() {
        isSaving = true
        errorMsg = nil
        do {
            try geminiService.saveAPIKey(apiKey)
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
        isSaving = false
    }
}
