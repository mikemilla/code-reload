import Foundation
import CryptoKit

/// Thin async wrapper over the GitHub REST + Git Data APIs. This is what gives
/// the on-device project a real round-trip to GitHub (commit/push/pull) using
/// the OAuth token, without bundling a native C git library.
///
/// NOTE: This v1 syncs against the remote via the Git Data API. A libgit2-backed
/// backend (full local history + offline commits) is a planned follow-up; the
/// `BunbuGit` coordinator is written against this so it can be swapped later.
final class BunbuGitHubClient {
    struct TreeEntry {
        let path: String
        let sha: String
        let type: String
    }

    enum GitError: LocalizedError {
        case notAuthenticated
        case http(Int, String)
        case decoding(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "Not signed in to GitHub"
            case .http(let code, let msg): return "GitHub error \(code): \(msg)"
            case .decoding(let what): return "Unexpected response: \(what)"
            }
        }
    }

    private let base = URL(string: "https://api.github.com")!

    private func token() throws -> String {
        guard let token = BunbuKeychain.token() else { throw GitError.notAuthenticated }
        return token
    }

    // MARK: - Generic request

    private func request(
        _ method: String,
        _ path: String,
        body: Any? = nil
    ) async throws -> Any {
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw GitError.http(status, message)
        }
        if data.isEmpty { return [:] }
        return try JSONSerialization.jsonObject(with: data)
    }

    private func object(_ value: Any) throws -> [String: Any] {
        guard let dict = value as? [String: Any] else { throw GitError.decoding("object") }
        return dict
    }

    // MARK: - User / repo

    func currentUserLogin() async throws -> String {
        let json = try object(try await request("GET", "user"))
        guard let login = json["login"] as? String else { throw GitError.decoding("login") }
        return login
    }

    func createRepo(name: String, isPrivate: Bool) async throws -> (owner: String, repo: String) {
        let json = try object(try await request("POST", "user/repos", body: [
            "name": name,
            "private": isPrivate,
            "auto_init": true,
        ]))
        guard let fullName = json["full_name"] as? String,
              let owner = (json["owner"] as? [String: Any])?["login"] as? String else {
            throw GitError.decoding("repo")
        }
        let repo = fullName.split(separator: "/").last.map(String.init) ?? name
        return (owner, repo)
    }

    func defaultBranch(owner: String, repo: String) async throws -> String {
        let json = try object(try await request("GET", "repos/\(owner)/\(repo)"))
        return json["default_branch"] as? String ?? "main"
    }

    func listBranches(owner: String, repo: String) async throws -> [String] {
        let value = try await request("GET", "repos/\(owner)/\(repo)/branches?per_page=100")
        guard let arr = value as? [[String: Any]] else { return [] }
        return arr.compactMap { $0["name"] as? String }
    }

    // MARK: - Refs / commits / trees

    func headCommitSha(owner: String, repo: String, branch: String) async throws -> String {
        let json = try object(try await request("GET", "repos/\(owner)/\(repo)/git/ref/heads/\(branch)"))
        guard let obj = json["object"] as? [String: Any], let sha = obj["sha"] as? String else {
            throw GitError.decoding("ref")
        }
        return sha
    }

    func treeSha(owner: String, repo: String, commitSha: String) async throws -> String {
        let json = try object(try await request("GET", "repos/\(owner)/\(repo)/git/commits/\(commitSha)"))
        guard let tree = json["tree"] as? [String: Any], let sha = tree["sha"] as? String else {
            throw GitError.decoding("commit tree")
        }
        return sha
    }

    func tree(owner: String, repo: String, treeSha: String) async throws -> [TreeEntry] {
        let json = try object(try await request(
            "GET", "repos/\(owner)/\(repo)/git/trees/\(treeSha)?recursive=1"))
        guard let entries = json["tree"] as? [[String: Any]] else { return [] }
        return entries.compactMap { e in
            guard let path = e["path"] as? String,
                  let sha = e["sha"] as? String,
                  let type = e["type"] as? String else { return nil }
            return TreeEntry(path: path, sha: sha, type: type)
        }
    }

    func blobContent(owner: String, repo: String, sha: String) async throws -> String? {
        let json = try object(try await request("GET", "repos/\(owner)/\(repo)/git/blobs/\(sha)"))
        guard let content = json["content"] as? String,
              let encoding = json["encoding"] as? String else { return nil }
        if encoding == "base64" {
            let cleaned = content.replacingOccurrences(of: "\n", with: "")
            guard let data = Data(base64Encoded: cleaned) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        return content
    }

    func createBlob(owner: String, repo: String, content: String) async throws -> String {
        let json = try object(try await request("POST", "repos/\(owner)/\(repo)/git/blobs", body: [
            "content": content,
            "encoding": "utf-8",
        ]))
        guard let sha = json["sha"] as? String else { throw GitError.decoding("blob sha") }
        return sha
    }

    struct NewTreeEntry {
        let path: String
        let sha: String?   // nil = delete
    }

    func createTree(
        owner: String,
        repo: String,
        baseTree: String?,
        entries: [NewTreeEntry]
    ) async throws -> String {
        var treeArr: [[String: Any]] = []
        for e in entries {
            var item: [String: Any] = ["path": e.path, "mode": "100644", "type": "blob"]
            if let sha = e.sha {
                item["sha"] = sha
            } else {
                item["sha"] = NSNull()
            }
            treeArr.append(item)
        }
        var body: [String: Any] = ["tree": treeArr]
        if let baseTree = baseTree { body["base_tree"] = baseTree }
        let json = try object(try await request("POST", "repos/\(owner)/\(repo)/git/trees", body: body))
        guard let sha = json["sha"] as? String else { throw GitError.decoding("tree sha") }
        return sha
    }

    func createCommit(
        owner: String,
        repo: String,
        message: String,
        treeSha: String,
        parents: [String]
    ) async throws -> String {
        let json = try object(try await request("POST", "repos/\(owner)/\(repo)/git/commits", body: [
            "message": message,
            "tree": treeSha,
            "parents": parents,
        ]))
        guard let sha = json["sha"] as? String else { throw GitError.decoding("commit sha") }
        return sha
    }

    func updateRef(owner: String, repo: String, branch: String, sha: String, force: Bool) async throws {
        _ = try await request("PATCH", "repos/\(owner)/\(repo)/git/refs/heads/\(branch)", body: [
            "sha": sha,
            "force": force,
        ])
    }

    func createBranch(owner: String, repo: String, branch: String, fromSha: String) async throws {
        _ = try await request("POST", "repos/\(owner)/\(repo)/git/refs", body: [
            "ref": "refs/heads/\(branch)",
            "sha": fromSha,
        ])
    }

    // MARK: - Local git blob SHA (for status diffing)

    /// Compute the git blob SHA-1 of a file's contents: sha1("blob <len>\0<content>").
    static func gitBlobSha(_ content: String) -> String {
        let bytes = Array(content.utf8)
        var data = Data("blob \(bytes.count)\u{0}".utf8)
        data.append(contentsOf: bytes)
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
