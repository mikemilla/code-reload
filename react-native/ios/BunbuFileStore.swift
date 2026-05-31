import Foundation

/// The single on-device source of truth for the editable project.
///
/// Files live as real artifacts under `Documents/bunbu/` so they can be pulled
/// off the device and so the same directory can later host a git working tree.
/// The store is fully native (Swift) and does not depend on the RN JS engine,
/// which is what lets the editor/agent keep working when the user's JS is broken.
final class BunbuFileStore {
    static let shared = BunbuFileStore()

    /// Directory names inside the project root that are not part of the
    /// editable source set (git metadata, checkpoint snapshots, bunbu state).
    private let reservedDirs: Set<String> = [".git", ".checkpoints", ".bunbu"]

    private let fm = FileManager.default
    private let queue = DispatchQueue(label: "dev.bunbu.filestore", attributes: .concurrent)

    /// Absolute path to the project working tree.
    let rootURL: URL

    private init() {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        rootURL = docs.appendingPathComponent("bunbu", isDirectory: true)
        try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    // MARK: - Path helpers

    private func url(for relativePath: String) -> URL {
        let clean = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        return rootURL.appendingPathComponent(clean)
    }

    private func isReserved(_ relativePath: String) -> Bool {
        let first = relativePath.split(separator: "/").first.map(String.init) ?? ""
        return reservedDirs.contains(first)
    }

    // MARK: - Read / write

    func read(_ path: String) -> String? {
        queue.sync {
            try? String(contentsOf: url(for: path), encoding: .utf8)
        }
    }

    func write(_ path: String, content: String) {
        queue.sync(flags: .barrier) {
            let fileURL = url(for: path)
            try? fm.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func delete(_ path: String) {
        queue.sync(flags: .barrier) {
            try? fm.removeItem(at: url(for: path))
        }
    }

    func rename(from: String, to: String) {
        queue.sync(flags: .barrier) {
            let src = url(for: from)
            let dst = url(for: to)
            try? fm.createDirectory(
                at: dst.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? fm.moveItem(at: src, to: dst)
        }
    }

    func exists(_ path: String) -> Bool {
        queue.sync { fm.fileExists(atPath: url(for: path).path) }
    }

    // MARK: - Listing / snapshot

    /// Relative paths of every editable source file (reserved dirs excluded), sorted.
    func list() -> [String] {
        queue.sync {
            collectFiles().sorted()
        }
    }

    /// Full project as a path -> content map (reserved dirs excluded).
    func snapshot() -> [String: String] {
        queue.sync {
            var result: [String: String] = [:]
            for rel in collectFiles() {
                if let content = try? String(contentsOf: url(for: rel), encoding: .utf8) {
                    result[rel] = content
                }
            }
            return result
        }
    }

    /// Replace the entire editable file set with `files` (reserved dirs untouched).
    func restore(_ files: [String: String]) {
        queue.sync(flags: .barrier) {
            // Remove existing editable files (keep .git/.checkpoints/.bunbu).
            for rel in collectFiles() {
                try? fm.removeItem(at: url(for: rel))
            }
            for (rel, content) in files {
                let fileURL = url(for: rel)
                try? fm.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    /// True when there are no editable source files yet (fresh install).
    var isEmpty: Bool {
        queue.sync { collectFiles().isEmpty }
    }

    private func collectFiles() -> [String] {
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var files: [String] = []
        let rootPath = rootURL.standardizedFileURL.path
        for case let fileURL as URL in enumerator {
            let rel = relativePath(of: fileURL, fromRoot: rootPath)
            if rel.isEmpty || isReserved(rel) { continue }
            var isDir: ObjCBool = false
            fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            if !isDir.boolValue {
                files.append(rel)
            }
        }
        return files
    }

    private func relativePath(of fileURL: URL, fromRoot rootPath: String) -> String {
        let full = fileURL.standardizedFileURL.path
        guard full.hasPrefix(rootPath) else { return "" }
        var rel = String(full.dropFirst(rootPath.count))
        if rel.hasPrefix("/") { rel = String(rel.dropFirst()) }
        return rel
    }

    // MARK: - Bunbu state (snapshot hash, etc.)

    private var stateURL: URL { rootURL.appendingPathComponent(".bunbu/state.json") }

    func readState() -> [String: Any] {
        queue.sync {
            guard let data = try? Data(contentsOf: stateURL),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return [:] }
            return obj
        }
    }

    /// Merge `state` into the persisted bunbu state (does not clobber other keys).
    func writeState(_ state: [String: Any]) {
        queue.sync(flags: .barrier) {
            var merged: [String: Any] = [:]
            if let data = try? Data(contentsOf: stateURL),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                merged = existing
            }
            for (k, v) in state { merged[k] = v }
            try? fm.createDirectory(
                at: stateURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if let data = try? JSONSerialization.data(withJSONObject: merged, options: [.prettyPrinted]) {
                try? data.write(to: stateURL)
            }
        }
    }
}
