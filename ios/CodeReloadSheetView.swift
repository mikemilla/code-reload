import SwiftUI

enum CodeReloadTab: String, CaseIterable {
    case files = "Files"
    // case chat = "Chat"
    case checkpoints = "History"

    static var allCases: [CodeReloadTab] { [.files, .checkpoints] }
}

struct CodeReloadSheetView: View {
    @ObservedObject var viewModel: CodeReloadViewModel
    @State private var tab: CodeReloadTab = .files

    var body: some View {
        VStack(spacing: 0) {
            header
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(CodeReloadColors.background)
        .codereloadDarkTheme()
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("CodeReload")
                    .font(.title2.bold())
                    .foregroundStyle(CodeReloadColors.textPrimary)
                Spacer()
                Button("Close") {
                    viewModel.dismiss()
                }
                .font(.body.weight(.semibold))
            }

            Picker("Section", selection: $tab) {
                ForEach(CodeReloadTab.allCases, id: \.self) { t in
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
            CodeReloadFileBrowserView(viewModel: viewModel)
        // case .chat:
        //     CodeReloadChatView(viewModel: viewModel)
        case .checkpoints:
            CodeReloadCheckpointsView(viewModel: viewModel)
        }
    }
}
