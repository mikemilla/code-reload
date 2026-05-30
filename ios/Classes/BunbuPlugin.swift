import Flutter
import UIKit
import SwiftUI

public class BunbuPlugin: NSObject, FlutterPlugin, UIAdaptivePresentationControllerDelegate {
    private var channel: FlutterMethodChannel
    private var fabWindow: BunbuFABWindow?
    private var sheetWindow: UIWindow?
    private weak var presentedSheet: UIViewController?
    private let chatViewModel = ChatViewModel()

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bunbu/agent_manager",
            binaryMessenger: registrar.messenger()
        )
        let instance = BunbuPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            setupFAB()
            result(nil)
        case "show":
            showSheet(result: result)
        case "hide":
            hideSheet(result: result)
        case "onStreamChunk":
            if let chunk = call.arguments as? String {
                DispatchQueue.main.async {
                    self.chatViewModel.appendChunk(chunk)
                }
            }
            result(nil)
        case "onStreamDone":
            DispatchQueue.main.async {
                self.chatViewModel.streamDone()
            }
            result(nil)
        case "onStreamError":
            if let error = call.arguments as? String {
                DispatchQueue.main.async {
                    self.chatViewModel.streamError(error)
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setupFAB() {
        guard fabWindow == nil else { return }
        DispatchQueue.main.async {
            self.fabWindow = BunbuFABWindow { [weak self] in
                self?.showSheet(result: { _ in })
            }
        }
    }

    private func showSheet(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            let chatView = BunbuChatView(
                viewModel: self.chatViewModel,
                onSend: { [weak self] text in
                    self?.channel.invokeMethod("sendMessage", arguments: text)
                },
                onStop: { [weak self] in
                    self?.channel.invokeMethod("stopGeneration", arguments: nil)
                }
            )

            let hosting = UIHostingController(rootView: chatView)
            hosting.view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
            hosting.modalPresentationStyle = .pageSheet

            if let sheet = hosting.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 14
            }

            hosting.presentationController?.delegate = self

            // Present from a dedicated window above the FAB
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                result(FlutterError(code: "NO_SCENE", message: "No window scene found", details: nil))
                return
            }

            let sheetWindow = UIWindow(windowScene: scene)
            sheetWindow.windowLevel = .normal + 2
            sheetWindow.backgroundColor = .clear
            let rootVC = UIViewController()
            rootVC.view.backgroundColor = .clear
            sheetWindow.rootViewController = rootVC
            sheetWindow.makeKeyAndVisible()
            self.sheetWindow = sheetWindow

            rootVC.present(hosting, animated: true) {
                result(nil)
            }

            self.presentedSheet = hosting
        }
    }

    private func hideSheet(result: @escaping FlutterResult) {
        guard let sheet = presentedSheet else {
            result(nil)
            return
        }
        sheet.dismiss(animated: true) { [weak self] in
            self?.sheetWindow?.isHidden = true
            self?.sheetWindow = nil
            result(nil)
        }
        presentedSheet = nil
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        presentedSheet = nil
        sheetWindow?.isHidden = true
        sheetWindow = nil
        channel.invokeMethod("onDismiss", arguments: nil)
    }
}
