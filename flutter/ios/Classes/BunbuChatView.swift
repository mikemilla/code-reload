import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    var text: String
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false

    func addUserMessage(_ text: String) {
        messages.append(ChatMessage(isUser: true, text: text))
        messages.append(ChatMessage(isUser: false, text: ""))
        isStreaming = true
    }

    func appendChunk(_ chunk: String) {
        guard !messages.isEmpty, !messages.last!.isUser else { return }
        messages[messages.count - 1].text += chunk
    }

    func streamDone() {
        isStreaming = false
    }

    func streamError(_ error: String) {
        isStreaming = false
        if !messages.isEmpty && !messages.last!.isUser {
            messages[messages.count - 1].text = "Error: \(error)"
        }
    }
}

struct BunbuChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var inputText = ""
    var onSend: (String) -> Void
    var onStop: () -> Void
    var onApplyCode: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color(hex: 0x3A3A3E))
            presetButtons
            Divider().background(Color(hex: 0x3A3A3E))
            messageList
            composer
        }
        .background(Color(hex: 0x1A1A1E))
    }

    private var header: some View {
        HStack {
            Text("bunbu")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x222226))
    }

    private var presetButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(bunbuPresets.enumerated()), id: \.offset) { _, preset in
                    Button(action: { onApplyCode(preset.code) }) {
                        HStack(spacing: 6) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 12))
                            Text(preset.label)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0x6C63FF))
                        .cornerRadius(20)
                    }
                }

                Button(action: { onApplyCode("") }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12))
                        Text("Reset")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0x3A3A3E))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 10)
        .background(Color(hex: 0x222226))
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
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: 0x2A2A2E))
                .cornerRadius(10)
                .foregroundColor(.white)
                .onSubmit { send() }

            Button(action: viewModel.isStreaming ? onStop : send) {
                Image(systemName: viewModel.isStreaming ? "stop.fill" : "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(viewModel.isStreaming ? Color.red.opacity(0.8) : Color(hex: 0x6C63FF))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.isStreaming && inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: 0x222226))
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.addUserMessage(text)
        onSend(text)
    }
}

struct BubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 48) }
            Text(message.text.isEmpty && !message.isUser ? "..." : message.text)
                .font(.system(size: 14))
                .foregroundColor(message.text.isEmpty ? .gray : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.isUser ? Color(hex: 0x6C63FF) : Color(hex: 0x2A2A2E))
                .cornerRadius(16)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
