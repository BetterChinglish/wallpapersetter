import Foundation
import Observation

// MARK: - Auth Service

@Observable
final class AuthService {
    private let client = APIClient.shared
    private let tokenKey = "auth_token"
    private let userKey = "auth_user"

    var isLoggedIn = false
    var currentUser: UserInfo?
    var authToken: String?

    private var pollTask: Task<Void, Never>?

    init() {
        loadFromStorage()
    }

    // MARK: - Storage

    private func loadFromStorage() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            self.authToken = token
            self.isLoggedIn = true
        }
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserInfo.self, from: userData) {
            self.currentUser = user
        }
    }

    private func saveToStorage(token: String, user: UserInfo) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(try? JSONEncoder().encode(user), forKey: userKey)
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    // MARK: - QR Code Login Flow

    /// Generate a WeChat QR code for login
    func generateQRCode() async throws -> QRCodeData {
        let response: QRCodeResponse = try await client.request(
            method: "GET",
            path: "/api/auth/wechat/qrcode"
        )
        guard let data = response.data else {
            throw APIError.invalidResponse
        }
        return data
    }

    /// Start polling for login status
    func startPolling(sceneId: String, onSuccess: @escaping () -> Void) {
        stopPolling()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let response: PollResponse = try await self.client.request(
                        method: "GET",
                        path: "/api/auth/wechat/poll?sceneId=\(sceneId)"
                    )
                    switch response.code {
                    case "SUCCESS":
                        if let token = response.data?.token,
                           let user = response.data?.user {
                            await MainActor.run {
                                self.authToken = token
                                self.currentUser = user
                                self.isLoggedIn = true
                                self.saveToStorage(token: token, user: user)
                                onSuccess()
                            }
                        }
                        return
                    case "QRCODE_EXPIRED":
                        return
                    default:
                        break
                    }
                } catch {
                    print("Poll error:", error)
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    /// Stop polling
    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Logout

    func logout() async {
        do {
            if let token = authToken {
                let _: EmptyResponse = try await client.request(
                    method: "POST",
                    path: "/api/auth/logout",
                    token: token
                )
            }
        } catch {
            print("Logout API error:", error)
        }

        await MainActor.run {
            self.authToken = nil
            self.currentUser = nil
            self.isLoggedIn = false
            self.clearStorage()
        }
    }
}

// MARK: - Empty Response

struct EmptyResponse: Codable {}
