import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AppViewModel.self) private var vm

    @State private var autoLaunch = false
    @State private var autoSync = true
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "通用"
        case display = "显示"
        case about = "关于"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Settings Nav Sidebar
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconFor(tab))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .white : .appTextMuted)
                                .frame(width: 18, height: 18)

                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .appTextSecondary)
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 36)
                        .background(
                            selectedTab == tab
                                ? Color.appAccent
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .frame(width: 240)
            .background(.ultraThinMaterial)

            // Settings Content
            VStack(alignment: .leading, spacing: 28) {
                Text(headingFor(selectedTab))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                if selectedTab == .general {
                    generalContent
                } else if selectedTab == .display {
                    displayContent
                } else {
                    aboutContent
                }

                Spacer()
            }
            .padding(36)
            .frame(maxWidth: 480)
            .background(Color.appContentBg)
        }
    }

    // MARK: - General Tab

    var generalContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("启动与同步")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextMuted)

            VStack(spacing: 0) {
                settingsRow(
                    title: "开机自动启动",
                    toggle: $autoLaunch
                )

                Divider().overlay(Color.appDivider)

                settingsRow(
                    title: "登录后自动同步壁纸",
                    toggle: $autoSync
                )
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Display Tab

    var displayContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("显示设置")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextMuted)

            VStack(spacing: 0) {
                infoRow(title: "窗口样式", value: "macOS 原生")
                Divider().overlay(Color.appDivider)
                infoRow(title: "壁纸质量", value: "自动（推荐）")
                Divider().overlay(Color.appDivider)
                infoRow(title: "多屏幕", value: "独立设置")
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - About Tab

    var aboutContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关于")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appTextMuted)

            VStack(spacing: 0) {
                infoRow(title: "版本", value: "0.1.0 (Beta)")
                Divider().overlay(Color.appDivider)
                infoRow(title: "技术栈", value: "SwiftUI + macOS 14+")
                Divider().overlay(Color.appDivider)
                infoRow(title: "后端", value: "Node.js + PostgreSQL")
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    func settingsRow(title: String, toggle: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.appTextPrimary)
            Spacer()
            ToggleSwitch(isOn: toggle)
        }
        .padding(14)
        .frame(height: 48)
    }

    func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.appTextPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.appTextMuted)
        }
        .padding(14)
        .frame(height: 48)
    }

    func iconFor(_ tab: SettingsTab) -> String {
        switch tab {
        case .general: "gearshape"
        case .display: "display"
        case .about: "info.circle"
        }
    }

    func headingFor(_ tab: SettingsTab) -> String {
        switch tab {
        case .general: "通用设置"
        case .display: "显示设置"
        case .about: "关于应用"
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppViewModel())
        .frame(width: 1100, height: 760)
}
