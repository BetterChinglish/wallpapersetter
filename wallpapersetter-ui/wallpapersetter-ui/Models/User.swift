import Foundation

// MARK: - User Model

struct User: Codable, Hashable {
    let id: String
    let nickname: String?
    let avatarUrl: String?
    let openId: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, nickname, avatarUrl, openId, createdAt
    }
}

// MARK: - Auth Response Types

struct QRCodeResponse: Codable {
    let code: String
    let data: QRCodeData?
    let message: String?
}

struct QRCodeData: Codable {
    let sceneId: String
    let qrcodeUrl: String
    let expiresIn: Int
}

struct PollResponse: Codable {
    let code: String
    let data: PollData?
    let message: String?
}

struct PollData: Codable {
    let token: String?
    let user: UserInfo?
}

struct UserInfo: Codable {
    let id: String
    let nickname: String?
    let avatarUrl: String?
}

enum AuthStatus: String, Codable {
    case pending = "PENDING"
    case success = "SUCCESS"
    case expired = "QRCODE_EXPIRED"
}
