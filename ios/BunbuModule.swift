import UIKit
import React
import SwiftUI

@objc(BunbuModule)
class BunbuModule: RCTEventEmitter, BunbuHost, UIAdaptivePresentationControllerDelegate {
    static weak var shared: BunbuModule?

    private var fabWindow: BunbuFABWindow?
    private var sheetWindow: UIWindow?
    private weak var presentedSheet: UIViewController?
    private let viewModel = BunbuViewModel.shared
    private let store = BunbuFileStore.shared
    private var hasListeners = false
    private var pendingFiles: [String: String]?

    override init() {
        super.init()
        BunbuModule.shared = self
        viewModel.host = self
        BunbuAgent.shared.configure(viewModel: viewModel, store: store)
    }

    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }

    override func supportedEvents() -> [String]! {
        return ["BunbuEvent"]
    }

    override func startObserving() {
        hasListeners = true
        if let pending = pendingFiles {
            pendingFiles = nil
            deliverFiles(pending)
        } else {
            reloadPreview()
        }
    }

    override func stopObserving() { hasListeners = false }

    // MARK: - Lifecycle from JS

    /// JS provides the build-time bundled snapshot + its content hash. Native
    /// seeds on first launch, reconciles on a changed rebuild, then pushes the
    /// authoritative file set back to JS.
    @objc(bootstrap:hash:)
    func bootstrap(_ files: [String: String], hash: String) {
        DispatchQueue.main.async {
            if self.store.isEmpty {
                self.store.restore(files)
                self.store.writeState(["snapshotHash": hash])
                self.finishBootstrap()
                return
            }

            let state = self.store.readState()
            let storedHash = state["snapshotHash"] as? String
            if storedHash != hash {
                self.presentReconciliation(freshFiles: files, hash: hash)
            } else {
                self.finishBootstrap()
            }
        }
    }

    private func finishBootstrap() {
        viewModel.refreshFiles()
        reloadPreview()
    }

    private func presentReconciliation(freshFiles: [String: String], hash: String) {
        let alert = UIAlertController(
            title: "Bundled code changed",
            message: "This build ships different code than what's on the device. Keep your on-device changes, or replace them with the freshly loaded code?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep on-device", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            // Acknowledge the new build so we don't prompt again for the same build.
            self.store.writeState(["snapshotHash": hash])
            self.finishBootstrap()
        })
        alert.addAction(UIAlertAction(title: "Replace", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.store.restore(freshFiles)
            self.store.writeState(["snapshotHash": hash])
            self.finishBootstrap()
        })
        topViewController()?.present(alert, animated: true)
    }

    /// JS passes the AI credentials/model so the native agent can stream.
    @objc(configureAgent:)
    func configureAgent(_ config: [String: Any]) {
        let apiKey = config["apiKey"] as? String ?? ""
        let provider = config["provider"] as? String ?? "anthropic"
        let modelId = config["model"] as? String ?? "claude-sonnet-4-20250514"
        let maxTokens = config["maxTokens"] as? Int ?? 4096
        BunbuAgent.shared.setConfig(apiKey: apiKey, provider: provider, modelId: modelId, maxTokens: maxTokens)
    }

    /// JS provides the GitHub OAuth app client id for the device-flow sign-in.
    @objc(configureGitHub:)
    func configureGitHub(_ clientId: String) {
        BunbuGitHubAuth.shared.configure(clientId: clientId)
    }

    /// JS reports an uncaught render/eval error in the interpreted preview.
    @objc(onRuntimeError:)
    func onRuntimeError(_ message: String) {
        DispatchQueue.main.async {
            self.viewModel.lastRuntimeError = message
            BunbuAgent.shared.noteRuntimeError(message)
        }
    }

    /// Ask native to push the current on-device file set to JS (after the bridge
    /// listener is registered).
    @objc func requestSync() {
        DispatchQueue.main.async {
            self.reloadPreview()
        }
    }

    @objc func initialize() {
        DispatchQueue.main.async {
            guard self.fabWindow == nil else { return }
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            self.fabWindow = BunbuFABWindow(windowScene: scene) { [weak self] in
                self?.showSheet()
            }
        }
    }

    @objc func showSheet() {
        DispatchQueue.main.async {
            guard self.presentedSheet == nil else { return }
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

            self.viewModel.refreshFiles()

            let sheetView = BunbuSheetView(viewModel: self.viewModel)
            let hosting = UIHostingController(rootView: sheetView)
            hosting.overrideUserInterfaceStyle = .dark
            hosting.view.backgroundColor = .systemBackground
            hosting.modalPresentationStyle = .pageSheet

            if let sheet = hosting.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 14
            }

            hosting.presentationController?.delegate = self

            let window = UIWindow(windowScene: scene)
            window.windowLevel = .normal + 2
            window.backgroundColor = .clear
            let hostVC = UIViewController()
            hostVC.overrideUserInterfaceStyle = .dark
            hostVC.view.backgroundColor = .clear
            window.rootViewController = hostVC
            window.makeKeyAndVisible()
            self.sheetWindow = window

            hostVC.present(hosting, animated: true)
            self.presentedSheet = hosting
        }
    }

    @objc func hideSheet() {
        DispatchQueue.main.async {
            guard let sheet = self.presentedSheet else { return }
            sheet.dismiss(animated: true) { [weak self] in
                self?.tearDownSheetWindow()
            }
            self.presentedSheet = nil
        }
    }

    // MARK: - BunbuHost

    /// Push the current native file set to JS and re-evaluate the preview.
    func reloadPreview() {
        let files = store.snapshot()
        pushFilesToJS(files)
    }

    private func pushFilesToJS(_ files: [String: String]) {
        guard !files.isEmpty else { return }
        if hasListeners {
            deliverFiles(files)
        } else {
            pendingFiles = files
        }
    }

    private func deliverFiles(_ files: [String: String]) {
        emit("setFiles", payload: ["files": files])
    }

    func sendAgentMessage(_ text: String) {
        BunbuAgent.shared.send(text)
    }

    func stopAgent() {
        BunbuAgent.shared.stop()
    }

    func closeEditor() {
        hideSheet()
    }

    // MARK: - Emit to JS

    func emit(_ type: String, payload: Any? = nil) {
        guard hasListeners else { return }
        var body: [String: Any] = ["type": type]
        if let payload = payload {
            body["payload"] = payload
        }
        sendEvent(withName: "BunbuEvent", body: body)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        presentedSheet = nil
        tearDownSheetWindow()
    }

    private func tearDownSheetWindow() {
        sheetWindow?.isHidden = true
        sheetWindow = nil
    }

    private func topViewController() -> UIViewController? {
        if let presented = presentedSheet { return presented }
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}
