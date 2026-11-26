import SwiftUI

@main
struct NovelyPrivateApp: App {
    @StateObject private var store: LibraryStore
    @StateObject private var audioEngine = AmbientAudioEngine()

    init() {
        let isUITesting = CommandLine.arguments.contains("--ui-testing")
        _store = StateObject(wrappedValue: LibraryStore(forceDemoData: isUITesting))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .environmentObject(audioEngine)
                .preferredColorScheme(.dark)
                .tint(NovelyTheme.terracotta)
                .task {
                    await store.hydrateRealCoversIfNeeded()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "novelyprivate" else { return }
        if url.host == "shelf", let shelfRaw = url.pathComponents.last,
           let category = ShelfCategory.allCases.first(where: { $0.rawValue.lowercased() == shelfRaw.lowercased() }) {
            store.selectedCustomShelfId = nil
            store.selectedShelf = category
        }
    }
}
