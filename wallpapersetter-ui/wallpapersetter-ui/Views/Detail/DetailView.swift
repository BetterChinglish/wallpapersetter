import SwiftUI

// MARK: - Detail View

struct DetailView: View {
    @Environment(AppViewModel.self) private var vm
    let wallpaper: Wallpaper

    @State private var hasSound = false
    @State private var isLooping = true

    private var gradientColors: [Color] {
        switch wallpaper.id {
        case "1": return [Color(red: 0.10, green: 0.05, blue: 0.25), Color(red: 0.25, green: 0.15, blue: 0.60)]
        case "3": return [Color(red: 0.06, green: 0.01, blue: 0.15), Color(red: 0.45, green: 0.10, blue: 0.45)]
        default: return [Color.appAccent, Color.appAccent.opacity(0.5)]
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            // Preview Area
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text(wallpaper.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(wallpaper.resolution ?? "Unknown") · \(wallpaper.fileType?.uppercased() ?? "") · \(formatFileSize(wallpaper.fileSize ?? 0))")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(32)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )

            // Info Panel
            VStack(spacing: 20) {
                // Title
                Text(wallpaper.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Meta
                HStack(spacing: 10) {
                    TypeBadge(type: wallpaper.type)

                    Text("\(wallpaper.resolution ?? "Unknown") · \(formatFileSize(wallpaper.fileSize ?? 0))")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().overlay(Color.appDivider)

                // Description
                if let description = wallpaper.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer().frame(height: 8)

                // Set Buttons
                PrimaryButton(title: "设为主屏幕壁纸") {
                    // TODO: Apply wallpaper
                }

                SecondaryButton(title: "设为所有屏幕壁纸") {
                    // TODO: Apply to all screens
                }

                Spacer()

                // Playback Options
                VStack(alignment: .leading, spacing: 10) {
                    Text("播放选项")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appTextSecondary)

                    HStack {
                        Text("声音")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextMuted)
                        Spacer()
                        ToggleSwitch(isOn: $hasSound)
                    }
                    .frame(height: 30)

                    HStack {
                        Text("循环播放")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextMuted)
                        Spacer()
                        ToggleSwitch(isOn: $isLooping)
                    }
                    .frame(height: 30)
                }
            }
            .frame(width: 340)
            .padding(24)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )
        }
        .padding(24)
        .background(Color.appContentBg)
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview

#Preview {
    DetailView(wallpaper: Wallpaper.mock1)
        .environment(AppViewModel())
        .frame(width: 1100, height: 760)
}
