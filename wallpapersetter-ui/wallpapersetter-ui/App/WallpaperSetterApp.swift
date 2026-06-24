import SwiftUI

// MARK: - App Entry Point

@main
struct WallpaperSetterApp: App {
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(viewModel)
                .frame(minWidth: 900, minHeight: 600)
                .sheet(isPresented: $viewModel.showLogin) {
                    LoginView()
                        .environment(viewModel)
                }
                .sheet(isPresented: $viewModel.showSettings) {
                    SettingsView()
                        .environment(viewModel)
                }
                .onAppear {
                    // Show login on first launch if not authenticated
                    if !viewModel.isLoggedIn {
                        viewModel.showLogin = true
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1100, height: 760)

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(viewModel)
                .frame(width: 700, height: 500)
        }
        #endif
    }
}
