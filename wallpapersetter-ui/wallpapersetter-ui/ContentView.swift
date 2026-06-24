import SwiftUI

// ContentView is now a convenience wrapper for preview/testing.
// The main entry point is WallpaperSetterApp.swift in the App/ folder.

struct ContentView: View {
    var body: some View {
        MainView()
            .environment(AppViewModel())
    }
}

#Preview {
    ContentView()
        .frame(width: 1100, height: 760)
}
