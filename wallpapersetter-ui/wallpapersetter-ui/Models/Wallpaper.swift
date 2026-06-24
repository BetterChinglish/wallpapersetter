import Foundation

// MARK: - Wallpaper Model

struct Wallpaper: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let type: WallpaperType
    let url: String?
    let fileSize: Int?
    let fileType: String?
    let resolution: String?
    let thumbnailUrl: String?
    let downloadCount: Int
    let likeCount: Int
    let createdAt: String
    let updatedAt: String
    let user: WallpaperUser?

    enum CodingKeys: String, CodingKey {
        case id, title, description, type, url
        case fileSize, fileType, resolution, thumbnailUrl
        case downloadCount, likeCount, createdAt, updatedAt
        case user
    }
}

enum WallpaperType: String, Codable {
    case video
    case html
}

struct WallpaperUser: Codable, Hashable {
    let id: String
    let nickname: String?
    let avatarUrl: String?
}

// MARK: - API Response Wrapper

struct WallpaperListResponse: Codable {
    let code: String
    let data: WallpaperListData?
    let message: String?
}

struct WallpaperListData: Codable {
    let wallpapers: [Wallpaper]
    let total: Int
    let page: Int
    let pageSize: Int
}

struct WallpaperDetailResponse: Codable {
    let code: String
    let data: Wallpaper?
    let message: String?
}

// MARK: - Mock Data (Development)

extension Wallpaper {
    static let mock1 = Wallpaper(
        id: "1", title: "星空夜景", description: "一段美丽的星空延时视频",
        type: .video, url: nil, fileSize: 128_000_000, fileType: "mp4",
        resolution: "1080p", thumbnailUrl: nil,
        downloadCount: 2340, likeCount: 567,
        createdAt: "2026-06-01", updatedAt: "2026-06-20",
        user: WallpaperUser(id: "u1", nickname: "夜空摄影师", avatarUrl: nil)
    )

    static let mock2 = Wallpaper(
        id: "2", title: "海浪轻拍", description: "海边海浪慢动作",
        type: .video, url: nil, fileSize: 95_000_000, fileType: "mov",
        resolution: "4K", thumbnailUrl: nil,
        downloadCount: 1820, likeCount: 432,
        createdAt: "2026-06-03", updatedAt: "2026-06-22",
        user: WallpaperUser(id: "u2", nickname: "海洋之心", avatarUrl: nil)
    )

    static let mock3 = Wallpaper(
        id: "3", title: "霓虹都市", description: "赛博朋克风城市场景",
        type: .html, url: nil, fileSize: 2_000_000, fileType: "html",
        resolution: "Dynamic", thumbnailUrl: nil,
        downloadCount: 3100, likeCount: 892,
        createdAt: "2026-06-05", updatedAt: "2026-06-23",
        user: WallpaperUser(id: "u3", nickname: "像素行者", avatarUrl: nil)
    )

    static let mock4 = Wallpaper(
        id: "4", title: "山间晨雾", description: "清晨山间雾气弥漫",
        type: .html, url: nil, fileSize: 1_500_000, fileType: "html",
        resolution: "Dynamic", thumbnailUrl: nil,
        downloadCount: 1560, likeCount: 345,
        createdAt: "2026-06-08", updatedAt: "2026-06-24",
        user: WallpaperUser(id: "u4", nickname: "山野行者", avatarUrl: nil)
    )

    static let mock5 = Wallpaper(
        id: "5", title: "极光之舞", description: "北欧极光实时渲染",
        type: .html, url: nil, fileSize: 3_000_000, fileType: "html",
        resolution: "Dynamic", thumbnailUrl: nil,
        downloadCount: 4200, likeCount: 1200,
        createdAt: "2026-06-10", updatedAt: "2026-06-24",
        user: WallpaperUser(id: "u5", nickname: "极光猎人", avatarUrl: nil)
    )

    static let mock6 = Wallpaper(
        id: "6", title: "樱花季节", description: "樱花飘落的唯美场景",
        type: .video, url: nil, fileSize: 150_000_000, fileType: "mp4",
        resolution: "4K", thumbnailUrl: nil,
        downloadCount: 2800, likeCount: 756,
        createdAt: "2026-06-12", updatedAt: "2026-06-24",
        user: WallpaperUser(id: "u6", nickname: "春日记录", avatarUrl: nil)
    )

    static let mocks: [Wallpaper] = [.mock1, .mock2, .mock3, .mock4, .mock5, .mock6]
}
