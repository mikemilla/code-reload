import SwiftUI

struct BunbuSourceControlView: View {
    @ObservedObject var viewModel: BunbuViewModel
    @ObservedObject var auth = BunbuGitHubAuth.shared

    @State private var commitMessage = ""
    @State private var showConnect = false
    @State private var connectRepo = ""
    @State private var connectBranch = ""
    @State private var showNewBranch = false
    @State private var newBranchName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !auth.isSignedIn {
                    signInSection
                } else if !viewModel.gitConfigured {
                    connectSection
                } else {
                    repoSection
                }
                if let msg = viewModel.gitStatusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if let err = auth.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
        }
        .background(BunbuColors.background)
        .onAppear {
            viewModel.refreshGit()
            auth.restorePendingSessionIfNeeded()
        }
    }

    // MARK: - Sign in (OAuth device flow)

    private var signInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect GitHub")
                .font(.title3.bold())
                .foregroundStyle(BunbuColors.textPrimary)
            Text("Sign in to commit, push, and pull from your repo.")
                .font(.subheadline)
                .foregroundStyle(BunbuColors.textSecondary)

            if auth.isAuthorizing, let code = auth.userCode {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Enter this code on GitHub")
                        .font(.subheadline)
                        .foregroundStyle(BunbuColors.textSecondary)

                    Text(code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(BunbuColors.accent)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)

                    HStack(spacing: 10) {
                        Button(action: { auth.copyUserCode() }) {
                            Label(auth.codeCopied ? "Copied!" : "Copy Code",
                                  systemImage: auth.codeCopied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .tint(auth.codeCopied ? .green : nil)

                        Button(action: { auth.openInBrowser() }) {
                            Label("Open in Safari", systemImage: "safari")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Waiting for authorization…")
                            .font(.subheadline)
                            .foregroundStyle(BunbuColors.textSecondary)
                    }
                }
                .padding(12)
                .background(BunbuColors.surface)
                .cornerRadius(10)
            } else if auth.isAuthorizing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Getting sign-in code…")
                        .font(.subheadline)
                        .foregroundStyle(BunbuColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(BunbuColors.surface)
                .cornerRadius(10)
            } else {
                Button("Sign in with GitHub") { auth.startDeviceFlow() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Connect repo

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect a repository")
                .font(.title3.bold())
                .foregroundStyle(BunbuColors.textPrimary)
            field("owner/repo", text: $connectRepo)
            field("branch (optional)", text: $connectBranch)
            Button(viewModel.gitBusy ? "Working…" : "Clone / Connect") {
                let parts = connectRepo.split(separator: "/").map(String.init)
                guard parts.count == 2 else {
                    viewModel.gitStatusMessage = "Use owner/repo format"
                    return
                }
                viewModel.gitConnect(
                    owner: parts[0], repo: parts[1],
                    branch: connectBranch.isEmpty ? nil : connectBranch
                )
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            Button("Sign out", role: .destructive) { auth.signOut() }
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Connected repo

    private var repoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(BunbuColors.accent)
                Text(viewModel.gitBranch)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BunbuColors.textPrimary)
                Spacer()
                if viewModel.gitBusy { ProgressView() }
            }

            HStack(spacing: 10) {
                Button("Pull") { viewModel.gitPull() }
                    .buttonStyle(.borderedProminent)
                Button("Branch") {
                    newBranchName = ""
                    showNewBranch = true
                }
                .buttonStyle(.bordered)
            }

            changesSection

            VStack(alignment: .leading, spacing: 8) {
                Text("Commit message")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BunbuColors.textSecondary)
                field("Describe your change", text: $commitMessage)
                Button("Commit & Push") {
                    viewModel.gitCommitPush(message: commitMessage)
                    commitMessage = ""
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .opacity(viewModel.gitChanges.isEmpty ? 0.5 : 1.0)
                .disabled(viewModel.gitChanges.isEmpty)
            }

            Button("Sign out", role: .destructive) { auth.signOut() }
                .frame(maxWidth: .infinity)
        }
        .alert("New branch", isPresented: $showNewBranch) {
            TextField("branch-name", text: $newBranchName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Create") {
                let name = newBranchName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { viewModel.gitCreateBranch(name) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.gitChanges.isEmpty
                 ? "No changes"
                 : "\(viewModel.gitChanges.count) changed file(s)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BunbuColors.textSecondary)
            ForEach(viewModel.gitChanges) { change in
                HStack(spacing: 8) {
                    Text(badge(change.kind))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color(change.kind))
                        .frame(width: 16)
                    Text(change.path)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(BunbuColors.textPrimary)
                    Spacer()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BunbuColors.surface)
        .cornerRadius(10)
    }

    private func badge(_ kind: BunbuGit.ChangeKind) -> String {
        switch kind {
        case .added: return "A"
        case .modified: return "M"
        case .deleted: return "D"
        }
    }

    private func color(_ kind: BunbuGit.ChangeKind) -> Color {
        switch kind {
        case .added: return .green
        case .modified: return .orange
        case .deleted: return .red
        }
    }

    // MARK: - Reusable controls

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .font(.system(.subheadline, design: .monospaced))
            .padding(10)
            .background(BunbuColors.surface)
            .cornerRadius(8)
    }

}
