import Foundation

/// Native AI streaming client (Anthropic + OpenAI), ported from the TS AiClient.
/// Uses URLSession's async bytes API for SSE so it runs entirely in Swift,
/// independent of the RN JS engine.
final class BunbuAiClient {
    struct Config {
        var apiKey: String
        var provider: String   // "anthropic" | "openai"
        var modelId: String
        var maxTokens: Int
    }

    var config: Config
    private var streamTask: Task<Void, Never>?

    init(config: Config) {
        self.config = config
    }

    func stream(
        messages: [[String: String]],
        system: String?,
        onChunk: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) {
        streamTask?.cancel()
        streamTask = Task {
            do {
                if config.provider == "openai" {
                    try await streamOpenAi(messages: messages, system: system, onChunk: onChunk)
                } else {
                    try await streamAnthropic(messages: messages, system: system, onChunk: onChunk)
                }
                if !Task.isCancelled { onDone() }
            } catch is CancellationError {
                // Stopped by user; no error surfaced.
            } catch {
                if !Task.isCancelled { onError(error.localizedDescription) }
            }
        }
    }

    func abort() {
        streamTask?.cancel()
        streamTask = nil
    }

    // MARK: - Anthropic

    private func streamAnthropic(
        messages: [[String: String]],
        system: String?,
        onChunk: @escaping (String) -> Void
    ) async throws {
        var body: [String: Any] = [
            "model": config.modelId,
            "max_tokens": config.maxTokens,
            "stream": true,
            "messages": messages,
        ]
        if let system = system { body["system"] = system }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        try checkResponse(response, bytes: bytes, provider: "Anthropic")

        for try await line in bytes.lines {
            if Task.isCancelled { return }
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6))
            if data == "[DONE]" { return }
            guard let json = parseJSON(data) else { continue }
            if let type = json["type"] as? String, type == "content_block_delta",
               let delta = json["delta"] as? [String: Any],
               let deltaType = delta["type"] as? String, deltaType == "text_delta",
               let text = delta["text"] as? String {
                onChunk(text)
            }
        }
    }

    // MARK: - OpenAI

    private func streamOpenAi(
        messages: [[String: String]],
        system: String?,
        onChunk: @escaping (String) -> Void
    ) async throws {
        var all: [[String: String]] = []
        if let system = system { all.append(["role": "system", "content": system]) }
        all.append(contentsOf: messages)

        let body: [String: Any] = [
            "model": config.modelId,
            "max_tokens": config.maxTokens,
            "stream": true,
            "messages": all,
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        try checkResponse(response, bytes: bytes, provider: "OpenAI")

        for try await line in bytes.lines {
            if Task.isCancelled { return }
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6))
            if data == "[DONE]" { return }
            guard let json = parseJSON(data),
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String else { continue }
            onChunk(content)
        }
    }

    // MARK: - Helpers

    private func checkResponse(_ response: URLResponse, bytes: URLSession.AsyncBytes, provider: String) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if !(200..<300).contains(http.statusCode) {
            throw NSError(
                domain: "BunbuAiClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "\(provider) API error \(http.statusCode)"]
            )
        }
    }

    private func parseJSON(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
