import SwiftUI

// MARK: - Sidebar View

struct SidebarView: View {
    @Environment(AppViewModel.self) private var vm

    // Navigation state
    @State private var selectedNav: NavItem = .myWallpapers

    enum NavItem: String, CaseIterable {
        case myWallpapers = "我的壁纸"
        case community = "社区"
        case settings = "设置"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Logo Row
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appAccent)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.appAccent.opacity(0.2), radius: 8, y: 2)

                Text("Wallpaper Setter")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }

            Spacer().frame(height: 24)

            // Navigation Section
            SectionLabel("导航")

            ForEach(NavItem.allCases, id: \.self) { item in
                NavRow(
                    title: item.rawValue,
                    icon: iconFor(item),
                    isSelected: selectedNav == item
                ) {
                    selectedNav = item
                    if item == .settings {
                        vm.showSettings = true
                    }
                }
            }

            Divider()
                .overlay(Color.appDivider)
                .padding(.vertical, 8)

            Spacer().frame(height: 8)

            // Source Filter Section
            SectionLabel("壁纸来源")

            ForEach(FilterOption.allCases, id: \.self) { option in
                FilterRow(
                    title: option.label,
                    isSelected: option.source == vm.selectedSource
                ) {
                    if option.source == vm.selectedSource {
                        vm.selectedSource = nil
                    } else {
                        vm.selectedSource = option.source
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 240)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }

    private func iconFor(_ item: NavItem) -> String {
        switch item {
        case .myWallpapers: "photo.on.rectangle.angled"
        case .community: "person.3.fill"
        case .settings: "gearshape"
        }
    }
}

// MARK: - Sub-Components

struct SectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appTextMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 2)
            .padding(.bottom, 2)
    }
}

struct NavRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .appTextMuted)
                    .frame(width: 18, height: 18)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 36)
            .background(
                isSelected
                    ? Color.appAccent
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct FilterRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.appAccent : Color.appTextPlaceholder, lineWidth: 2)
                        .frame(width: 16, height: 16)

                    if isSelected {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .appTextPrimary : .appTextMuted)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 32)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Options

enum FilterOption: CaseIterable {
    case localVideo, localWeb, community

    var label: String {
        switch self {
        case .localVideo: "本地视频"
        case .localWeb: "本地网页"
        case .community: "社区网页"
        }
    }

    var source: WallpaperSource {
        switch self {
        case .localVideo: .localVideo
        case .localWeb: .localWeb
        case .community: .community
        }
    }
}

// MARK: - Preview

#Preview {
    SidebarView()
        .environment(AppViewModel())
        .frame(height: 600)
}
