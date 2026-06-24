import SwiftUI

// MARK: - Wallpaper Card

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let onTap: () -> Void

    // Gradient colors per wallpaper
    private var gradientColors: [Color] {
        switch wallpaper.id {
        case "1": return [Color(red: 0.10, green: 0.05, blue: 0.25), Color(red: 0.25, green: 0.15, blue: 0.60)]
        case "2": return [Color(red: 0.02, green: 0.28, blue: 0.44), Color(red: 0.05, green: 0.62, blue: 0.70)]
        case "3": return [Color(red: 0.06, green: 0.01, blue: 0.15), Color(red: 0.45, green: 0.10, blue: 0.45)]
        case "4": return [Color(red: 0.08, green: 0.15, blue: 0.18), Color(red: 0.18, green: 0.55, blue: 0.42)]
        case "5": return [Color(red: 0.03, green: 0.20, blue: 0.22), Color(red: 0.15, green: 0.60, blue: 0.40)]
        case "6": return [Color(red: 0.55, green: 0.40, blue: 0.50), Color(red: 0.90, green: 0.65, blue: 0.68)]
        default: return [Color.appAccent, Color.appAccent.opacity(0.5)]
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Thumbnail
                ZStack(alignment: .topLeading) {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 160)

                    Text(wallpaper.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(16)
                }

                // Info
                HStack {
                    Text(wallpaper.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    TypeBadge(type: wallpaper.type)
                }
                .padding(12)
                .frame(height: 60)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wallpaper Grid

struct WallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let onSelect: (Wallpaper) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(wallpapers) { wallpaper in
                    WallpaperCard(wallpaper: wallpaper) {
                        onSelect(wallpaper)
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Preview

#Preview {
    WallpaperGrid(wallpapers: Wallpaper.mocks) { _ in }
        .frame(width: 860, height: 580)
}
