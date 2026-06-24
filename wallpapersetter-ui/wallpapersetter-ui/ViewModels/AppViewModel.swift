import Foundation
import Observation

// MARK: - App ViewModel (Global State)

@MainActor
@Observable
final class AppViewModel {
    let authService = AuthService()
    let wallpaperService = WallpaperService()

    // Navigation
    var selectedWallpaper: Wallpaper?
    var showLogin = false
    var showSettings = false

    // Filter & Search
    var selectedSource: WallpaperSource?
    var searchText = ""
    var sortOption: SortOption = .newest

    // Computed
    var filteredWallpapers: [Wallpaper] {
        var result = wallpaperService.wallpapers

        if let source = selectedSource {
            result = result.filter { $0.type.rawValue == source.rawValue }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var isLoggedIn: Bool {
        authService.isLoggedIn
    }

    // MARK: - Actions

    func loadWallpapers() async {
        await wallpaperService.fetchWallpapers(
            source: selectedSource,
            sort: sortOption,
            search: searchText.isEmpty ? nil : searchText,
            token: authService.authToken
        )
    }

    func selectWallpaper(_ wallpaper: Wallpaper) {
        selectedWallpaper = wallpaper
    }

    func requireLogin() {
        if !isLoggedIn {
            showLogin = true
        }
    }
}
