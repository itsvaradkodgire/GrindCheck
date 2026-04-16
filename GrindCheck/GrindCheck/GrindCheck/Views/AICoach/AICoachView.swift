import SwiftUI
import SwiftData

struct AICoachView: View {

    let geminiService: GeminiService
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var viewModel: AICoachViewModel
    @State private var selectedSection: CoachSection = .chat

    init(geminiService: GeminiService) {
        self.geminiService = geminiService
        _viewModel = State(initialValue: AICoachViewModel(geminiService: geminiService))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: AppColors.background).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Section picker
                    sectionPicker

                    // Content
                    switch selectedSection {
                    case .chat:
                        ChatView(viewModel: viewModel) {
                            withAnimation { selectedSection = .roadmap }
                        }
                    case .roadmap:
                        RoadmapView(viewModel: viewModel)
                    case .materials:
                        MaterialsView(viewModel: viewModel)
                    case .tools:
                        AIToolsView(geminiService: geminiService)
                    }
                }
            }
            .navigationTitle("AI Coach")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        viewModel.isSocraticMode.toggle()
                        HapticManager.shared.correctAnswer()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isSocraticMode ? "questionmark.bubble.fill" : "questionmark.bubble")
                                .font(.system(size: 11, weight: .semibold))
                            Text(viewModel.isSocraticMode ? "Socratic ON" : "Socratic")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(viewModel.isSocraticMode
                                         ? Color(hex: AppColors.background)
                                         : Color(hex: AppColors.neutral))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(viewModel.isSocraticMode
                                           ? Color(hex: AppColors.secondary)
                                           : Color(hex: AppColors.surfacePrimary))
                        )
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAPIKeySetup = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.geminiService.hasAPIKey
                                  ? "key.fill"
                                  : "key.slash.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(viewModel.geminiService.hasAPIKey ? "Key Set" : "Add Key")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(viewModel.geminiService.hasAPIKey
                                         ? Color(hex: AppColors.success)
                                         : Color(hex: AppColors.warning))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill((viewModel.geminiService.hasAPIKey
                                       ? Color(hex: AppColors.success)
                                       : Color(hex: AppColors.warning))
                                    .opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAPIKeySetup) {
            APIKeySetupView(geminiService: geminiService)
        }
        .onAppear {
            viewModel.loadChatMessages(from: modelContext)
            viewModel.loadRoadmap(from: modelContext)
        }
        .task(id: appState.pendingAIMessage) {
            guard let msg = appState.pendingAIMessage else { return }
            appState.pendingAIMessage = nil
            withAnimation { selectedSection = .chat }
            await viewModel.sendMessage(msg, modelContext: modelContext)
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            ForEach(CoachSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: section.icon)
                            .font(.system(size: 12))
                        Text(section.title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(selectedSection == section
                                     ? Color(hex: AppColors.primary)
                                     : Color(hex: AppColors.muted))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedSection == section
                                  ? Color(hex: AppColors.primary).opacity(0.12)
                                  : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: AppColors.surfacePrimary))
        .overlay(
            Rectangle()
                .fill(Color(hex: AppColors.surfaceTertiary))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Coach Section

enum CoachSection: String, CaseIterable, Identifiable {
    case chat      = "Chat"
    case roadmap   = "Roadmap"
    case materials = "Materials"
    case tools     = "Tools"

    var id: String { rawValue }

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .chat:      return "bubble.left.and.bubble.right.fill"
        case .roadmap:   return "map.fill"
        case .materials: return "doc.text.fill"
        case .tools:     return "wrench.and.screwdriver.fill"
        }
    }
}
