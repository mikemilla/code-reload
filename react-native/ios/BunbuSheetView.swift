import SwiftUI

enum BunbuTab: String, CaseIterable {
    case files = "Files"
    case chat = "Chat"
    case checkpoints = "History"
    case git = "Git"
}

struct BunbuSheetView: View {
    @ObservedObject var viewModel: BunbuViewModel
    @State private var tab: BunbuTab = .files

    var body: some View {
        VStack(spacing: 0) {
            header
            tabContent
        }
        .background(BunbuColors.background)
        .bunbuDarkTheme()
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Bunbu")
                    .font(.title2.bold())
                    .foregroundStyle(BunbuColors.textPrimary)
                Spacer()
                Button("Close") {
                    viewModel.dismiss()
                }
                .font(.body.weight(.semibold))
            }

            Picker("Section", selection: $tab) {
                ForEach(BunbuTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .files:
            BunbuFileBrowserView(viewModel: viewModel)
        case .chat:
            BunbuChatView(viewModel: viewModel)
        case .checkpoints:
            BunbuCheckpointsView(viewModel: viewModel)
        case .git:
            BunbuSourceControlView(viewModel: viewModel)
        }
    }
}
