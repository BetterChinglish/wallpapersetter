import Foundation
import Observation

// MARK: - Wallpaper Service

@Observable
final class WallpaperService {
    private let client = APIClient.shared

    var wallpapers: [Wallpaper] = Wallpaper.mocks
    var isLoading = false
    var error: String?

    // MARK: - Fetch Wallpapers

    func fetchWallpapers(
        source: WallpaperSource? = nil,
        sort: SortOption = .newest,
        search: String? = nil,
        page: Int = 1,
        pageSize: Int = 20,
        token: String? = nil
    ) async {
        isLoading = true
        error = nil

        do {
            var queryItems: [String] = [
                "page=\(page)",
                "pageSize=\(pageSize)",
                "sort=\(sort.rawValue)"
            ]
            if let source { queryItems.append("filter=\(source.rawValue)") }
            if let search, !search.isEmpty {
                queryItems.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)")
            }

            let path = "/api/wallpapers?\(queryItems.joined(separator: "&"))"
            let response: WallpaperListResponse = try await client.request(
                method: "GET",
                path: path,
                token: token
            )

            await MainActor.run {
                if let data = response.data {
                    self.wallpapers = data.wallpapers
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                // Fallback to mock data during development
                print("Using mock data (API unavailable):", error)
            }
        }
    }

    // MARK: - Fetch Detail

    func fetchDetail(id: String, token: String? = nil) async -> Wallpaper? {
        do {
            let response: WallpaperDetailResponse = try await client.request(
                method: "GET",
                path: "/api/wallpapers/\(id)",
                token: token
            )
            return response.data
        } catch {
            print("Fetch detail error:", error)
            return Wallpaper.mocks.first { $0.id == id }
        }
    }

    // MARK: - Upload

    func upload(
        fileData: Data,
        fileName: String,
        mimeType: String,
        title: String,
        description: String?,
        fileType: String,
        token: String? = nil
    ) async throws {
        let fields: [String: String] = [
            "title": title,
            "description": description ?? "",
            "fileType": fileType
        ]

        let _ = try await client.upload(
            path: "/api/wallpapers/upload",
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            fields: fields,
            token: token
        )
    }
}

// MARK: - Filter & Sort

enum WallpaperSource: String, CaseIterable {
    case localVideo = "video"
    case localWeb = "html"
    case community = "community"
}

enum SortOption: String, CaseIterable {
    case newest = "newest"
    case popular = "downloads"
    case liked = "likes"
}
