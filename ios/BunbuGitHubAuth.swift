import Foundation
import UIKit

/// GitHub OAuth Device Flow. Requests a device code, shows it in the UI,
/// then polls until the user authorizes in GitHub (opened in Safari).
final class BunbuGitHubAuth: ObservableObject {
    static let shared = BunbuGitHubAuth()

    private var clientId: String = ""
    private let scope = "repo"

    @Published var userCode: String? = nil
    @Published var verificationUri: String? = nil
    @Published var isAuthorizing = false
    @Published var isSignedIn = false
    @Published var errorMessage: String? = nil
    @Published var codeCopied = false

    /// In-flight device-flow session survives tab switches within the editor sheet.
    private struct PendingSession {
        let deviceCode: String
        let userCode: String
        let verificationUri: String
        let expiresAt: Date
        let pollInterval: Int
    }

    private var pendingSession: PendingSession?
    private var pollTask: Task<Void, Never>?

    private init() {
        isSignedIn = BunbuKeychain.token() != nil
    }

    var token: String? { BunbuKeychain.token() }

    func configure(clientId: String) {
        self.clientId = clientId
    }

    func signOut() {
        BunbuKeychain.setToken(nil)
        pollTask?.cancel()
        pollTask = nil
        pendingSession = nil
        DispatchQueue.main.async {
            self.isSignedIn = false
            self.userCode = nil
            self.verificationUri = nil
            self.isAuthorizing = false
            self.codeCopied = false
        }
    }

    func copyUserCode() {
        guard let code = userCode else { return }
        UIPasteboard.general.string = code
        codeCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.codeCopied = false }
        }
    }

    func openInBrowser() {
        guard let uri = verificationUri else { return }
        openVerificationPage(uri)
    }

    /// Sync UI from an in-flight session when the Git tab reappears (tab switch).
    func restorePendingSessionIfNeeded() {
        guard !isSignedIn else { return }
        guard let session = pendingSession else { return }

        if session.expiresAt <= Date() {
            clearPendingSession()
            return
        }

        userCode = session.userCode
        verificationUri = session.verificationUri
        isAuthorizing = true
        ensurePolling(session)
    }

    func startDeviceFlow() {
        guard !clientId.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "Missing GitHub OAuth client id" }
            return
        }

        // Don't request a fresh code if the user is mid-flow (e.g. switched tabs).
        if let session = pendingSession, session.expiresAt > Date() {
            restorePendingSessionIfNeeded()
            return
        }

        pollTask?.cancel()
        pollTask = nil
        pendingSession = nil
        errorMessage = nil
        isAuthorizing = true
        pollTask = Task { await runDeviceFlow() }
    }

    private func runDeviceFlow() async {
        do {
            let code = try await requestDeviceCode()
            let session = PendingSession(
                deviceCode: code.deviceCode,
                userCode: code.userCode,
                verificationUri: code.verificationUri,
                expiresAt: Date().addingTimeInterval(TimeInterval(code.expiresIn)),
                pollInterval: code.interval
            )
            pendingSession = session
            await MainActor.run {
                self.userCode = session.userCode
                self.verificationUri = session.verificationUri
                self.isAuthorizing = true
            }
            let token = try await poll(session: session)
            BunbuKeychain.setToken(token)
            await MainActor.run {
                self.finishSignIn()
            }
        } catch is CancellationError {
            // Superseded by a new flow or sign-out — leave state to the new owner.
        } catch {
            await MainActor.run {
                self.isAuthorizing = false
                self.errorMessage = error.localizedDescription
                self.pendingSession = nil
            }
        }
    }

    private func ensurePolling(_ session: PendingSession) {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let token = try await self.poll(session: session)
                BunbuKeychain.setToken(token)
                await MainActor.run { self.finishSignIn() }
            } catch is CancellationError {
                // ignore
            } catch {
                await MainActor.run {
                    self.isAuthorizing = false
                    self.errorMessage = error.localizedDescription
                    self.pendingSession = nil
                }
            }
        }
    }

    private func finishSignIn() {
        isSignedIn = true
        isAuthorizing = false
        userCode = nil
        verificationUri = nil
        codeCopied = false
        pendingSession = nil
        pollTask = nil
    }

    private func clearPendingSession() {
        pollTask?.cancel()
        pollTask = nil
        pendingSession = nil
        isAuthorizing = false
        userCode = nil
        verificationUri = nil
    }

    private struct DeviceCodeResponse {
        let deviceCode: String
        let userCode: String
        let verificationUri: String
        let interval: Int
        let expiresIn: Int
    }

    private func requestDeviceCode() async throws -> DeviceCodeResponse {
        var request = URLRequest(url: URL(string: "https://github.com/login/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "client_id=\(clientId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientId)&scope=\(scope)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw authError("Invalid device code response")
        }

        if let error = json["error"] as? String {
            let detail = json["error_description"] as? String ?? error
            if error == "device_flow_disabled" {
                throw authError(
                    "Device Flow is not enabled for this GitHub OAuth app. " +
                    "Open github.com/settings/developers → your app → enable Device Flow."
                )
            }
            throw authError(detail)
        }

        guard let deviceCode = json["device_code"] as? String,
              let userCode = json["user_code"] as? String else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw authError("Invalid device code response (HTTP \(status))")
        }

        let verificationUri =
            (json["verification_uri_complete"] as? String)
            ?? (json["verification_uri"] as? String)
            ?? "https://github.com/login/device"

        return DeviceCodeResponse(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationUri: verificationUri,
            interval: json["interval"] as? Int ?? 5,
            expiresIn: json["expires_in"] as? Int ?? 900
        )
    }

    private func openVerificationPage(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    private func authError(_ message: String) -> NSError {
        NSError(domain: "BunbuGitHubAuth", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func poll(session: PendingSession) async throws -> String {
        let deadline = session.expiresAt
        var wait = session.pollInterval

        while Date() < deadline {
            try await Task.sleep(nanoseconds: UInt64(wait) * 1_000_000_000)
            if Task.isCancelled { throw CancellationError() }

            var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let pollBody =
                "client_id=\(clientId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientId)" +
                "&device_code=\(session.deviceCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? session.deviceCode)" +
                "&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code"
            request.httpBody = pollBody.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            if let token = json["access_token"] as? String {
                return token
            }
            if let error = json["error"] as? String {
                switch error {
                case "authorization_pending":
                    break
                case "slow_down":
                    wait += 5
                default:
                    throw NSError(domain: "BunbuGitHubAuth", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: error])
                }
            }
        }
        throw NSError(domain: "BunbuGitHubAuth", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Device flow timed out"])
    }
}
