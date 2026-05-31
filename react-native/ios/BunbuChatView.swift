import SwiftUI

struct BunbuChatView: View {
    @ObservedObject var viewModel: BunbuViewModel
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            messageList
            composer
        }
        .background(BunbuColors.background)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        BubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.last?.text) { _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Build me a...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { send() }

            Button(action: viewModel.isStreaming ? { viewModel.stopGeneration() } : send) {
                Image(systemName: viewModel.isStreaming ? "stop.fill" : "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(viewModel.isStreaming ? Color.red.opacity(0.8) : BunbuColors.accent)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.isStreaming && inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BunbuColors.surfaceElevated)
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.sendMessage(text)
    }
}

struct BubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 48) }
            Text(message.text.isEmpty && !message.isUser ? "..." : message.text)
                .font(.system(size: 14))
                .foregroundStyle(message.text.isEmpty ? BunbuColors.textMuted : BunbuColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.isUser ? BunbuColors.accent : BunbuColors.surface)
                .cornerRadius(16)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}
