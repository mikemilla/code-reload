import Foundation

/// Coordinates the on-device working tree (`BunbuFileStore`) with a GitHub repo.
/// Tracks the last-synced commit + per-path blob SHAs so it can compute status
/// (added/modified/deleted) and push only what changed.
final class BunbuGit {
    static let shared = BunbuGit()

    private let client = BunbuGitHubClient()
    private let store = BunbuFileStore.shared

    struct Config {
        var owner: String
        var repo: String
        var branch: String
    }

    enum ChangeKind: String { case added, modified, deleted }
    struct FileChange: Identifiable {
        var id: String { path }
        let path: String
        let kind: ChangeKind
    }

    private init() {}

    // MARK: - Config persistence

    var config: Config? {
        guard let git = store.readState()["git"] as? [String: Any],
              let owner = git["owner"] as? String,
              let repo = git["repo"] as? String,
              let branch = git["branch"] as? String else { return nil }
        return Config(owner: owner, repo: repo, branch: branch)
    }

    var isConfigured: Bool { config != nil }

    func configure(owner: String, repo: String, branch: String) {
        var git = (store.readState()["git"] as? [String: Any]) ?? [:]
        git["owner"] = owner
        git["repo"] = repo
        git["branch"] = branch
        store.writeState(["git": git])
    }

    private func setBase(commitSha: String, blobs: [String: String]) {
        var git = (store.readState()["git"] as? [String: Any]) ?? [:]
        git["baseCommitSha"] = commitSha
        git["baseBlobs"] = blobs
        store.writeState(["git": git])
    }

    private var baseCommitSha: String? {
        (store.readState()["git"] as? [String: Any])?["baseCommitSha"] as? String
    }

    private var baseBlobs: [String: String] {
        (store.readState()["git"] as? [String: Any])?["baseBlobs"] as? [String: String] ?? [:]
    }

    // MARK: - Repo discovery

    func listBranches() async throws -> [String] {
        guard let c = config else { return [] }
        return try await client.listBranches(owner: c.owner, repo: c.repo)
    }

    func currentUserLogin() async throws -> String {
        try await client.currentUserLogin()
    }

    /// Connect to (or create) a repo and pull its contents into the working tree.
    func connect(owner: String, repo: String, branch: String?) async throws {
        let resolvedBranch: String
        if let branch = branch, !branch.isEmpty {
            resolvedBranch = branch
        } else {
            resolvedBranch = try await client.defaultBranch(owner: owner, repo: repo)
        }
        configure(owner: owner, repo: repo, branch: resolvedBranch)
        try await pull()
    }

    func createRepoAndPush(name: String, isPrivate: Bool, message: String) async throws {
        let (owner, repo) = try await client.createRepo(name: name, isPrivate: isPrivate)
        let branch = try await client.defaultBranch(owner: owner, repo: repo)
        configure(owner: owner, repo: repo, branch: branch)
        // auto_init created an initial commit; set it as our base, then push the
        // current working tree on top.
        let head = try await client.headCommitSha(owner: owner, repo: repo, branch: branch)
        setBase(commitSha: head, blobs: [:])
        try await commitAndPush(message: message)
    }

    // MARK: - Pull

    /// Fetch the head commit's tree and replace the working tree with it.
    func pull() async throws {
        guard let c = config else { throw BunbuGitHubClient.GitError.decoding("no repo configured") }
        let head = try await client.headCommitSha(owner: c.owner, repo: c.repo, branch: c.branch)
        let treeSha = try await client.treeSha(owner: c.owner, repo: c.repo, commitSha: head)
        let entries = try await client.tree(owner: c.owner, repo: c.repo, treeSha: treeSha)

        var files: [String: String] = [:]
        var blobs: [String: String] = [:]
        for entry in entries where entry.type == "blob" {
            if let content = try await client.blobContent(owner: c.owner, repo: c.repo, sha: entry.sha) {
                files[entry.path] = content
                blobs[entry.path] = entry.sha
            }
        }

        store.restore(files)
        setBase(commitSha: head, blobs: blobs)
    }

    // MARK: - Status

    func status() -> [FileChange] {
        let base = baseBlobs
        let working = store.snapshot()
        var changes: [FileChange] = []

        for (path, content) in working {
            let sha = BunbuGitHubClient.gitBlobSha(content)
            if let baseSha = base[path] {
                if baseSha != sha { changes.append(FileChange(path: path, kind: .modified)) }
            } else {
                changes.append(FileChange(path: path, kind: .added))
            }
        }
        for path in base.keys where working[path] == nil {
            changes.append(FileChange(path: path, kind: .deleted))
        }
        return changes.sorted { $0.path < $1.path }
    }

    // MARK: - Commit + push

    func commitAndPush(message: String) async throws {
        guard let c = config else { throw BunbuGitHubClient.GitError.decoding("no repo configured") }
        let changes = status()
        guard !changes.isEmpty else { return }

        let working = store.snapshot()
        var newEntries: [BunbuGitHubClient.NewTreeEntry] = []
        var newBlobs = baseBlobs

        for change in changes {
            switch change.kind {
            case .added, .modified:
                let content = working[change.path] ?? ""
                let sha = try await client.createBlob(owner: c.owner, repo: c.repo, content: content)
                newEntries.append(.init(path: change.path, sha: sha))
                newBlobs[change.path] = sha
            case .deleted:
                newEntries.append(.init(path: change.path, sha: nil))
                newBlobs[change.path] = nil
            }
        }

        let parent: String
        if let base = baseCommitSha {
            parent = base
        } else {
            parent = try await client.headCommitSha(owner: c.owner, repo: c.repo, branch: c.branch)
        }

        let baseTree = try await client.treeSha(owner: c.owner, repo: c.repo, commitSha: parent)
        let newTree = try await client.createTree(
            owner: c.owner, repo: c.repo, baseTree: baseTree, entries: newEntries)
        let commit = try await client.createCommit(
            owner: c.owner, repo: c.repo, message: message, treeSha: newTree, parents: [parent])
        try await client.updateRef(
            owner: c.owner, repo: c.repo, branch: c.branch, sha: commit, force: false)

        setBase(commitSha: commit, blobs: newBlobs)
    }

    // MARK: - Branching

    func createAndSwitchBranch(_ name: String) async throws {
        guard let c = config else { return }
        let from: String
        if let base = baseCommitSha {
            from = base
        } else {
            from = try await client.headCommitSha(owner: c.owner, repo: c.repo, branch: c.branch)
        }
        try await client.createBranch(owner: c.owner, repo: c.repo, branch: name, fromSha: from)
        configure(owner: c.owner, repo: c.repo, branch: name)
    }

    func switchBranch(_ name: String) async throws {
        guard let c = config else { return }
        configure(owner: c.owner, repo: c.repo, branch: name)
        try await pull()
    }
}
