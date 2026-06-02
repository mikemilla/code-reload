import Foundation

struct CodeReloadCheckpoint: Identifiable {
    let id: String
    let timestamp: Date
    let label: String
}

/// Cursor-style local checkpoints: full-project snapshots stored under
/// `Documents/codereload/.checkpoints/`. Fast, offline, and independent of git.
final class CodeReloadCheckpointStore {
    static let shared = CodeReloadCheckpointStore()

    private let fm = FileManager.default
    private let store = CodeReloadFileStore.shared

    private var dir: URL { store.rootURL.appendingPathComponent(".checkpoints", isDirectory: true) }

    private init() {
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    @discardableResult
    func create(label: String) -> String {
        let id = UUID().uuidString
        let payload: [String: Any] = [
            "id": id,
            "timestamp": Date().timeIntervalSince1970,
            "label": label,
            "files": store.snapshot(),
        ]
        let url = dir.appendingPathComponent("\(id).json")
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            try? data.write(to: url)
        }
        return id
    }

    func list() -> [CodeReloadCheckpoint] {
        guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        var result: [CodeReloadCheckpoint] = []
        for url in contents where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = obj["id"] as? String,
                  let ts = obj["timestamp"] as? Double,
                  let label = obj["label"] as? String else { continue }
            result.append(CodeReloadCheckpoint(id: id, timestamp: Date(timeIntervalSince1970: ts), label: label))
        }
        return result.sorted { $0.timestamp > $1.timestamp }
    }

    /// Restore a checkpoint's full file set into the working tree.
    func restore(_ id: String) -> Bool {
        let url = dir.appendingPathComponent("\(id).json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = obj["files"] as? [String: String] else { return false }
        store.restore(files)
        return true
    }

    func delete(_ id: String) {
        try? fm.removeItem(at: dir.appendingPathComponent("\(id).json"))
    }
}
