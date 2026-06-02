import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    var text: String
}

/// Coordinator the UI talks to. Implemented by `CodeReloadModule`.
protocol CodeReloadHost: AnyObject {
    /// Push the current native file set to JS and re-evaluate the preview.
    func reloadPreview()
    /// Hand a chat prompt to the native agent.
    func sendAgentMessage(_ text: String)
    /// Stop an in-flight agent stream.
    func stopAgent()
    /// Dismiss the native editor sheet.
    func closeEditor()
}

/// Observable state for the native editor/chat UI. The file browser reads and
/// writes the on-device `CodeReloadFileStore` directly (no RN bridge), so it keeps
/// working even when the interpreted preview has crashed.
final class CodeReloadViewModel: ObservableObject {
    static let shared = CodeReloadViewModel()

    weak var host: CodeReloadHost?
    private let store = CodeReloadFileStore.shared

    // Chat state
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false

    // File browser state
    @Published var fileList: [String] = []
    @Published var openFilePath: String? = nil
    @Published var openFileContent: String = ""

    // Runtime status
    @Published var lastRuntimeError: String? = nil
    @Published var autoSave: Bool = false

    // Checkpoints
    @Published var checkpoints: [CodeReloadCheckpoint] = []
    private let checkpointStore = CodeReloadCheckpointStore.shared

    private init() {}

    // MARK: - Checkpoints

    func refreshCheckpoints() {
        checkpoints = checkpointStore.list()
    }

    func createCheckpoint(label: String) {
        checkpointStore.create(label: label.isEmpty ? "Manual checkpoint" : label)
        refreshCheckpoints()
    }

    func restoreCheckpoint(_ id: String) {
        guard checkpointStore.restore(id) else { return }
        if let path = openFilePath {
            openFileContent = store.read(path) ?? ""
        }
        refreshFiles()
        host?.reloadPreview()
    }

    func deleteCheckpoint(_ id: String) {
        checkpointStore.delete(id)
        refreshCheckpoints()
    }

    // MARK: - File browser (acts directly on the native store)

    func refreshFiles() {
        fileList = store.list()
    }

    func openFile(_ path: String) {
        openFilePath = path
        openFileContent = store.read(path) ?? ""
    }

    func closeFile() {
        openFilePath = nil
        openFileContent = ""
    }

    /// Manual save: persist to the native store and reload the preview.
    func saveFile(_ path: String, content: String) {
        store.write(path, content: content)
        openFileContent = content
        refreshFiles()
        host?.reloadPreview()
    }

    func createFile(_ path: String, content: String = "") {
        guard !path.isEmpty, !store.exists(path) else { return }
        store.write(path, content: content)
        refreshFiles()
        openFile(path)
        host?.reloadPreview()
    }

    func deleteFile(_ path: String) {
        store.delete(path)
        if openFilePath == path { closeFile() }
        refreshFiles()
        host?.reloadPreview()
    }

    func renameFile(from: String, to: String) {
        guard !to.isEmpty, !store.exists(to) else { return }
        store.rename(from: from, to: to)
        if openFilePath == from { openFile(to) }
        refreshFiles()
        host?.reloadPreview()
    }

    // MARK: - Chat (delegates to the native agent)

    func sendMessage(_ text: String) {
        messages.append(ChatMessage(isUser: true, text: text))
        messages.append(ChatMessage(isUser: false, text: ""))
        isStreaming = true
        host?.sendAgentMessage(text)
    }

    func stopGeneration() {
        host?.stopAgent()
        isStreaming = false
    }

    // Called by the agent as it streams.
    func appendChunk(_ chunk: String) {
        guard let last = messages.last, !last.isUser else { return }
        messages[messages.count - 1].text += chunk
    }

    func streamDone() {
        isStreaming = false
    }

    func streamError(_ error: String) {
        isStreaming = false
        if let last = messages.last, !last.isUser {
            messages[messages.count - 1].text = "Error: \(error)"
        }
    }

    func dismiss() {
        host?.closeEditor()
    }
}
