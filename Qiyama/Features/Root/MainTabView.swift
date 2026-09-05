import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "moon.stars") }
            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(QiyamaTheme.lantern)
    }
}
