import Foundation

/// Native agent loop: takes a prompt, streams from the AI, applies the result
/// to the file store (checkpointing first), and reloads the preview. Runs fully
/// in Swift so it keeps working even when the interpreted preview has crashed.
final class CodeReloadAgent {
    static let shared = CodeReloadAgent()

    private weak var viewModel: CodeReloadViewModel?
    private var store: CodeReloadFileStore?
    private let checkpoints = CodeReloadCheckpointStore.shared

    private var client: CodeReloadAiClient?
    private var history: [[String: String]] = []
    private var pendingResponse = ""
    private var lastRuntimeError: String?

    private init() {}

    func configure(viewModel: CodeReloadViewModel, store: CodeReloadFileStore) {
        self.viewModel = viewModel
        self.store = store
    }

    /// Provide API credentials/model from JS at startup.
    func setConfig(apiKey: String, provider: String, modelId: String, maxTokens: Int) {
        client = CodeReloadAiClient(config: .init(
            apiKey: apiKey,
            provider: provider,
            modelId: modelId,
            maxTokens: maxTokens
        ))
    }

    var isConfigured: Bool { client != nil }

    func noteRuntimeError(_ message: String) {
        lastRuntimeError = message
    }

    func send(_ text: String) {
        guard let client = client, let store = store else {
            DispatchQueue.main.async {
                self.viewModel?.streamError("Agent not configured (missing API key)")
            }
            return
        }

        var userContent = text
        if let err = lastRuntimeError {
            userContent += "\n\nThe app currently shows this runtime error, please fix it:\n\(err)"
        }
        history.append(["role": "user", "content": userContent])
        pendingResponse = ""

        let files = store.snapshot()
        let target = targetPath(in: files)
        let system = CodeReloadSystemPrompt.withContext(files: files, targetPath: target)

        client.stream(
            messages: history,
            system: system,
            onChunk: { [weak self] chunk in
                guard let self = self else { return }
                self.pendingResponse += chunk
                DispatchQueue.main.async { self.viewModel?.appendChunk(chunk) }
            },
            onDone: { [weak self] in
                guard let self = self else { return }
                self.history.append(["role": "assistant", "content": self.pendingResponse])
                self.applyResponse(self.pendingResponse, target: target)
                DispatchQueue.main.async { self.viewModel?.streamDone() }
            },
            onError: { [weak self] message in
                DispatchQueue.main.async { self?.viewModel?.streamError(message) }
            }
        )
    }

    func stop() {
        client?.abort()
    }

    // MARK: - Apply

    private func applyResponse(_ response: String, target: String) {
        guard let store = store,
              let code = CodeReloadSystemPrompt.extractCodeBlock(response),
              !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Checkpoint the full project before applying (agent auto-save + rollback).
        checkpoints.create(label: "Before agent edit")
        store.write(target, content: code)
        lastRuntimeError = nil

        DispatchQueue.main.async {
            self.viewModel?.refreshFiles()
            if self.viewModel?.openFilePath == target {
                self.viewModel?.openFileContent = code
            }
            self.viewModel?.host?.reloadPreview()
        }
    }

    private func targetPath(in files: [String: String]) -> String {
        if let open = viewModel?.openFilePath, files[open] != nil {
            return open
        }
        let paths = files.keys.sorted()
        if let entry = paths.first(where: { $0.hasSuffix("index.tsx") }) {
            return entry
        }
        return paths.first ?? "index.tsx"
    }
}
