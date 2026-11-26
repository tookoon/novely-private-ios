import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: LibraryStore
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BookshelfView()
                .tabItem {
                    Label("Regal", systemImage: "books.vertical.fill")
                }
                .tag(0)

            ProgressAndQuotesView()
                .tabItem {
                    Label("Aktuell", systemImage: "book.pages.fill")
                }
                .tag(1)

            ReadingRoomView()
                .tabItem {
                    Label("Lesezeit", systemImage: "flame.fill")
                }
                .tag(2)

            StatisticsView()
                .tabItem {
                    Label("Statistik", systemImage: "calendar")
                }
                .tag(3)

            DiscoverAndSettingsView()
                .tabItem {
                    Label("Mehr", systemImage: "sparkles")
                }
                .tag(4)
        }
        .tint(NovelyTheme.terracotta)
    }
}
