import SwiftUI
import SwiftData

struct ChatView: View {

    @Bindable var viewModel: AICoachViewModel
    let onRoadmapReady: () -> Void

    @Environment(\.modelContext) private var modelContext
    @FocusState private var inputFocused: Bool

    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.chatMessages.isEmpty {
                            emptyState
                                .padding(.top, 60)
                        }

                        ForEach(viewModel.chatMessages, id: \.id) { msg in
                            ChatBubbleView(message: msg)
                        }

                        if viewModel.isChatLoading {
                            TypingIndicatorView()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 16)
                        }

                        if let err = viewModel.chatError {
                            ErrorBannerView(message: err)
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.chatMessages.count) { _, _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: viewModel.isChatLoading) { _, _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                // Tap anywhere on the scroll area to dismiss keyboard
                .onTapGesture { inputFocused = false }
            }

            if viewModel.showBuildRoadmapButton && !viewModel.isGeneratingRoadmap {
                buildRoadmapBanner
            }
            if viewModel.isGeneratingRoadmap {
                generatingRoadmapBanner
            }

            inputBar
        }
        .confirmationDialog("Clear this chat?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear Chat", role: .destructive) {
                viewModel.clearChat(modelContext: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all messages. The roadmap is kept.")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !viewModel.chatMessages.isEmpty {
                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: AppColors.muted))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: AppColors.primary))

            Text("AI Study Coach")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text("Tell me your goal and I'll build you a study roadmap. No BS, just a plan.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Roadmap Banner

    private var buildRoadmapBanner: some View {
        Button {
            Task { await viewModel.buildRoadmap(modelContext: modelContext) }
            onRoadmapReady()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: 16))
                Text("Build My Roadmap")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: AppColors.success))
        }
        .buttonStyle(.plain)
    }

    private var generatingRoadmapBanner: some View {
        HStack(spacing: 10) {
            ProgressView().tint(Color(hex: AppColors.primary))
            Text("Generating your roadmap…")
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: AppColors.surfaceSecondary))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message your coach…", text: $viewModel.currentInput, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: AppColors.surfaceSecondary))
                )
                .focused($inputFocused)
                .onSubmit {
                    sendMessage()
                }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.currentInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isChatLoading
                        ? Color(hex: AppColors.muted)
                        : Color(hex: AppColors.primary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isChatLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: AppColors.surfacePrimary))
    }

    private func sendMessage() {
        let text = viewModel.currentInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        Task { await viewModel.sendMessage(text, modelContext: modelContext) }
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                bubbleContent
            } else {
                // AI avatar
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: AppColors.primary))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(Color(hex: AppColors.surfaceSecondary))
                    )

                bubbleContent
                Spacer(minLength: 60)
            }
        }
    }

    private var bubbleContent: some View {
        Group {
            if message.isUser {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(LocalizedStringKey(message.content))
                    .font(.subheadline)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .tint(Color(hex: AppColors.primary))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(message.isUser
                      ? Color(hex: AppColors.primary)
                      : Color(hex: AppColors.surfaceSecondary))
        )
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: AppColors.muted))
                    .frame(width: 7, height: 7)
                    .scaleEffect(animating ? 1.3 : 0.7)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: AppColors.surfaceSecondary))
        )
        .onAppear { animating = true }
    }
}

// MARK: - Error Banner

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: AppColors.warning))
            Text(message)
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: AppColors.warning).opacity(0.1))
        )
    }
}
