import SwiftUI

// MARK: - File tree model

final class FileTreeNode: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDir: Bool
    var children: [FileTreeNode] = []

    init(name: String, path: String, isDir: Bool) {
        self.name = name
        self.path = path
        self.isDir = isDir
    }
}

private func buildTree(_ paths: [String]) -> [FileTreeNode] {
    let root = FileTreeNode(name: "", path: "", isDir: true)
    for p in paths {
        let comps = p.split(separator: "/").map(String.init)
        var node = root
        var cur = ""
        for (i, comp) in comps.enumerated() {
            cur = cur.isEmpty ? comp : cur + "/" + comp
            let isDir = i < comps.count - 1
            if let existing = node.children.first(where: { $0.name == comp && $0.isDir == isDir }) {
                node = existing
            } else {
                let n = FileTreeNode(name: comp, path: cur, isDir: isDir)
                node.children.append(n)
                node = n
            }
        }
    }
    sortTree(root)
    return root.children
}

private func sortTree(_ node: FileTreeNode) {
    node.children.sort { a, b in
        if a.isDir != b.isDir { return a.isDir && !b.isDir }
        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }
    node.children.forEach(sortTree)
}

// MARK: - Browser

struct BunbuFileBrowserView: View {
    @ObservedObject var viewModel: BunbuViewModel

    @State private var showNewFile = false
    @State private var newFilePath = ""
    @State private var renameTarget: String? = nil
    @State private var renamePath = ""

    var body: some View {
        Group {
            if viewModel.openFilePath != nil {
                BunbuCodeEditorView(viewModel: viewModel)
            } else {
                fileList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            toolbar
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(buildTree(viewModel.fileList)) { node in
                        FileTreeRow(
                            node: node,
                            depth: 0,
                            onOpen: { viewModel.openFile($0) },
                            onDelete: { viewModel.deleteFile($0) },
                            onRename: { startRename($0) }
                        )
                    }
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BunbuColors.background)
        .alert("New File", isPresented: $showNewFile) {
            TextField("path/to/File.tsx", text: $newFilePath)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Create") {
                let path = newFilePath.trimmingCharacters(in: .whitespaces)
                if !path.isEmpty { viewModel.createFile(path) }
                newFilePath = ""
            }
            Button("Cancel", role: .cancel) { newFilePath = "" }
        }
        .alert("Rename", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("new path", text: $renamePath)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Rename") {
                if let from = renameTarget {
                    let to = renamePath.trimmingCharacters(in: .whitespaces)
                    if !to.isEmpty { viewModel.renameFile(from: from, to: to) }
                }
                renameTarget = nil
            }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
    }

    private var toolbar: some View {
        HStack {
            Text("\(viewModel.fileList.count) files")
                .font(.subheadline)
                .foregroundStyle(BunbuColors.textSecondary)
            Spacer()
            Button(action: { newFilePath = ""; showNewFile = true }) {
                Label("New File", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func startRename(_ path: String) {
        renamePath = path
        renameTarget = path
    }
}

private struct FileTreeRow: View {
    let node: FileTreeNode
    let depth: Int
    let onOpen: (String) -> Void
    let onDelete: (String) -> Void
    let onRename: (String) -> Void

    @State private var expanded = true

    var body: some View {
        if node.isDir {
            VStack(alignment: .leading, spacing: 4) {
                Button(action: { withAnimation(.easeInOut(duration: 0.12)) { expanded.toggle() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(BunbuColors.textSecondary)
                        Image(systemName: "folder.fill")
                            .foregroundStyle(BunbuColors.accent)
                        Text(node.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BunbuColors.textPrimary)
                        Spacer()
                    }
                    .padding(.leading, CGFloat(depth) * 14)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
                if expanded {
                    ForEach(node.children) { child in
                        FileTreeRow(
                            node: child,
                            depth: depth + 1,
                            onOpen: onOpen,
                            onDelete: onDelete,
                            onRename: onRename
                        )
                    }
                }
            }
        } else {
            Button(action: { onOpen(node.path) }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(BunbuColors.textSecondary)
                    Text(node.name)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(BunbuColors.textPrimary)
                    Spacer()
                }
                .padding(.leading, CGFloat(depth) * 14)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(BunbuColors.surface)
                .cornerRadius(8)
            }
            .contextMenu {
                Button { onRename(node.path) } label: { Label("Rename", systemImage: "pencil") }
                Button(role: .destructive) { onDelete(node.path) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Code editor (manual save)

struct BunbuCodeEditorView: View {
    @ObservedObject var viewModel: BunbuViewModel
    @State private var editedContent: String = ""
    @State private var hasLocalChanges = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            editor
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BunbuColors.background)
        .onAppear {
            editedContent = viewModel.openFileContent
            hasLocalChanges = false
        }
        .onChange(of: viewModel.openFileContent) { newValue in
            if !hasLocalChanges {
                editedContent = newValue
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button(action: {
                viewModel.closeFile()
                hasLocalChanges = false
            }) {
                Text("‹ Back")
                    .font(.body.weight(.semibold))
            }

            Text(viewModel.openFilePath ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(BunbuColors.textSecondary)
                .lineLimit(1)

            Spacer()

            if hasLocalChanges {
                Text("● unsaved")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var editor: some View {
        HStack(alignment: .top, spacing: 0) {
            lineNumbers
            TextEditor(text: $editedContent)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(BunbuColors.textPrimary)
                .scrollContentBackground(.hidden)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: editedContent) { _ in
                    hasLocalChanges = (editedContent != viewModel.openFileContent)
                }
        }
        .padding(.vertical, 8)
    }

    private var lineNumbers: some View {
        let lines = editedContent.components(separatedBy: "\n")
        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                Text("\(index + 1)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(BunbuColors.textDisabled)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, 8)
        .frame(minWidth: 40, alignment: .trailing)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button("Save") {
                if let path = viewModel.openFilePath {
                    viewModel.saveFile(path, content: editedContent)
                    hasLocalChanges = false
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!hasLocalChanges)
            .padding(12)
            .padding(.bottom, 18)
        }
    }
}
