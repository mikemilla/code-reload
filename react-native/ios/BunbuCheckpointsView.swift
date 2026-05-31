import SwiftUI

struct BunbuCheckpointsView: View {
    @ObservedObject var viewModel: BunbuViewModel

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            if viewModel.checkpoints.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.checkpoints) { cp in
                            checkpointRow(cp)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(BunbuColors.background)
        .onAppear { viewModel.refreshCheckpoints() }
    }

    private var toolbar: some View {
        HStack {
            Text("Checkpoints")
                .font(.subheadline)
                .foregroundStyle(BunbuColors.textSecondary)
            Spacer()
            Button(action: { viewModel.createCheckpoint(label: "Manual checkpoint") }) {
                Label("Snapshot", systemImage: "camera")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(BunbuColors.textDisabled)
            Text("No checkpoints yet")
                .font(.subheadline)
                .foregroundStyle(BunbuColors.textSecondary)
            Text("The agent snapshots before each edit, or tap Snapshot.")
                .font(.caption)
                .foregroundStyle(BunbuColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func checkpointRow(_ cp: BunbuCheckpoint) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(cp.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BunbuColors.textPrimary)
                Text(Self.formatter.string(from: cp.timestamp))
                    .font(.caption2)
                    .foregroundStyle(BunbuColors.textSecondary)
            }
            Spacer()
            Button("Restore") {
                viewModel.restoreCheckpoint(cp.id)
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(BunbuColors.surface)
        .cornerRadius(10)
        .contextMenu {
            Button(role: .destructive) { viewModel.deleteCheckpoint(cp.id) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
