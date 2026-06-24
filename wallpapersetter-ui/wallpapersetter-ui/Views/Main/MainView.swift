import SwiftUI

// MARK: - Main View (Split View container)

struct MainView: View {
    @Environment(AppViewModel.self) private var vm
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var viewModel = vm

        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView()
                .navigationSplitViewColumnWidth(240)
        } content: {
            // Content - Wallpaper Grid
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: 12) {
                    SearchField(text: $viewModel.searchText) {
                        Task { await vm.loadWallpapers() }
                    }

                    Spacer()

                    SortMenu(selection: $viewModel.sortOption)

                    Button {
                        vm.requireLogin()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("上传壁纸")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 36)
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: Color.appAccent.opacity(0.2), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 4)

                // Section Header
                HStack {
                    Text("全部壁纸")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appTextPrimary)

                    Text("\(vm.filteredWallpapers.count) 个壁纸")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                // Grid
                WallpaperGrid(wallpapers: vm.filteredWallpapers) { wallpaper in
                    vm.selectWallpaper(wallpaper)
                }
            }
            .background(Color.appContentBg)
        } detail: {
            // Detail
            if let wallpaper = vm.selectedWallpaper {
                DetailView(wallpaper: wallpaper)
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.appTextPlaceholder)
                    Text("选择一张壁纸查看详情")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appContentBg)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await vm.loadWallpapers()
        }
        .onChange(of: vm.selectedSource) { _, _ in
            Task { await vm.loadWallpapers() }
        }
        .onChange(of: vm.sortOption) { _, _ in
            Task { await vm.loadWallpapers() }
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environment(AppViewModel())
        .frame(width: 1100, height: 760)
}
